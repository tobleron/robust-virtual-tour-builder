/* src/systems/Resizer.res - Consolidated Resizer System */

open ReBindings
open SharedTypes

// --- TYPES & EXTERNAL ---

type processResult = {
  preview: File.t,
  tiny: option<File.t>,
  metadata: exifMetadata,
  qualityData: qualityAnalysis,
  checksumData: string,
}

type statusCallback = string => unit

@val @scope(("performance", "memory"))
external usedJSHeapSize: float = "usedJSHeapSize"
@val @scope(("performance", "memory"))
external totalJSHeapSize: float = "totalJSHeapSize"
@val @scope(("performance", "memory"))
external jsHeapSizeLimit: float = "jsHeapSizeLimit"
@val @scope("performance")
external now: unit => float = "now"

let formatBytesToMB = (v: float): string => {
  Float.toFixed(v /. 1024.0 /. 1024.0, ~digits=0) ++ "MB"
}

let getMemoryUsage = () => {
  try {
    {
      "used": formatBytesToMB(usedJSHeapSize),
      "total": formatBytesToMB(totalJSHeapSize),
      "limit": formatBytesToMB(jsHeapSizeLimit),
    }
  } catch {
  | _ => {"used": "N/A", "total": "N/A", "limit": "N/A"}
  }
}

// --- UTILS ---

module Utils = {
  let getChecksum = (file: File.t): Promise.t<string> => {
    let internalGetChecksum: File.t => Promise.t<string> = %raw(`
       async function(file) {
          const SMALL_FILE_THRESHOLD = 10 * 1024 * 1024;
          const SAMPLE_SIZE = 1024 * 1024;
          let hashBuffer;
          
          if (typeof crypto === 'undefined' || !crypto.subtle) {
              console.warn('[ResizerUtils] crypto.subtle is unavailable. Using weak fallback for fingerprinting.');
              const simpleHash = (s) => {
                  let h = 0;
                  for(let i = 0; i < s.length; i++) h = Math.imul(31, h) + s.charCodeAt(i) | 0;
                  return Math.abs(h).toString(16);
              };
              const meta = file.name + "_" + file.size + "_" + file.lastModified;
              return "weak_" + simpleHash(meta) + "_" + file.size;
          }

          if (file.size <= SMALL_FILE_THRESHOLD) {
              const arrayBuffer = await file.arrayBuffer();
              hashBuffer = await crypto.subtle.digest('SHA-256', arrayBuffer);
          } else {
              const samples = [
                  file.slice(0, SAMPLE_SIZE),
                  file.slice(Math.floor(file.size / 2), Math.floor(file.size / 2) + SAMPLE_SIZE),
                  file.slice(Math.max(0, file.size - SAMPLE_SIZE), file.size)
              ];
              const sampleBuffers = await Promise.all(samples.map(s => s.arrayBuffer()));
              const totalSize = sampleBuffers.reduce((acc, buf) => acc + buf.byteLength, 0);
              const combined = new Uint8Array(totalSize);
              let offset = 0;
              sampleBuffers.forEach(buf => { combined.set(new Uint8Array(buf), offset); offset += buf.byteLength; });
              hashBuffer = await crypto.subtle.digest('SHA-256', combined);
          }
          const hashArray = Array.from(new Uint8Array(hashBuffer));
          const hash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
          return hash + "_" + file.size;
       }
     `)
    internalGetChecksum(file)
  }

  let checkBackendHealth = () => {
    let controller = AbortController.newAbortController()
    let _signal = AbortController.signal(controller)
    let timeoutId = Window.setTimeout(() => AbortController.abort(controller), 5000)
    let timestamp = Date.now()->Float.toString

    Logger.debug(
      ~module_="Resizer",
      ~message="CHECKING_HEALTH",
      ~data=Some({"url": Constants.backendUrl ++ "/health?t=" ++ timestamp}),
      (),
    )

    RequestQueue.schedule(() => {
      Fetch.fetch(
        Constants.backendUrl ++ "/health?t=" ++ timestamp,
        Fetch.requestInit(~method="GET", ~signal=_signal, ()),
      )
    })
    ->Promise.then(res => {
      Window.clearTimeout(timeoutId)
      if !Fetch.ok(res) {
        Logger.warn(
          ~module_="Resizer",
          ~message="HEALTH_CHECK_FAILED",
          ~data={
            "status": Fetch.status(res),
            "statusText": Fetch.statusText(res),
            "url": Constants.backendUrl ++ "/health",
          },
          (),
        )
      }
      Promise.resolve(Fetch.ok(res))
    })
    ->Promise.catch(err => {
      Window.clearTimeout(timeoutId)
      let (msg, stack) = Logger.getErrorDetails(err)
      Logger.warn(
        ~module_="Resizer",
        ~message="HEALTH_CHECK_ERROR",
        ~data={"error": msg, "stack": stack, "url": Constants.backendUrl ++ "/health"},
        (),
      )
      Promise.resolve(false)
    })
  }
}

// --- LOGIC ---

module Logic = {
  let processAndAnalyzeImage = (file: File.t, ~onStatus: option<statusCallback>): Promise.t<
    result<processResult, string>,
  > => {
    let mem = getMemoryUsage()
    let reportStatus = (status: string) => {
      switch onStatus {
      | Some(cb) => cb(status)
      | None => ()
      }
    }

    Logger.startOperation(
      ~module_="Resizer",
      ~operation="BACKEND_PROCESS_FULL",
      ~data={"file": File.name(file), "size": File.size(file), "memory": mem},
      (),
    )
    reportStatus("Optimizing")
    let _fetchStart = now()

    Promise.all2((
      ExifParser.extractExifTags(File(file)),
      ImageOptimizer.compressToWebP(file, 0.90),
    ))
    ->Promise.then(((exifResult, compressionResult)) => {
      let exifData = switch exifResult {
      | Ok((exif, _pano)) => Some(exif)
      | Error(_) => None
      }
      switch compressionResult {
      | Ok(webpBlob) =>
        let webpFile = File.newFile([webpBlob], File.name(file), %raw("{type: 'image/webp'}"))
        reportStatus("Uploading")
        BackendApi.processImageFull(webpFile, ~isOptimized=true, ~metadata=?exifData)
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.then(result => {
      switch result {
      | Ok(zipBlob) =>
        reportStatus("Extracting")
        LazyLoad.loadJSZip()
        ->Promise.then(() => JSZip.loadAsync(zipBlob))
        ->Promise.then(zip => Promise.resolve(Ok(zip)))
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.then(zipResult => {
      switch zipResult {
      | Ok(zip) =>
        let previewZipFile = JSZip.file(zip, "preview.webp")
        let tinyZipFile = JSZip.file(zip, "tiny.webp")
        let metaZipFile = JSZip.file(zip, "metadata.json")
        switch (Nullable.toOption(previewZipFile), Nullable.toOption(metaZipFile)) {
        | (Some(pInZip), Some(mInZip)) =>
          let p1 = JSZip.async(pInZip, "blob")
          let p2 = JSZip.async(mInZip, "text")
          let p3 = switch Nullable.toOption(tinyZipFile) {
          | Some(f) => JSZip.async(f, "blob")->Promise.then(b => Promise.resolve(Some(b)))
          | None => Promise.resolve(None)
          }
          Promise.all3((p1, p2, p3))->Promise.then(res => Promise.resolve(Ok(res)))
        | _ => Promise.resolve(Error("Missing preview.webp or metadata.json in response"))
        }
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.then(extractedResult => {
      switch extractedResult {
      | Ok((previewBlob, metaText, tinyBlobOpt)) =>
        let metadata: metadataResponse = Schemas.castToMetadataResponse(JSON.parseOrThrow(metaText))
        let suggestedName = Nullable.toOption(metadata.suggestedName)
        let originalName = File.name(file)

        let computeNewName = (suggestedName: option<string>, originalName: string) => {
          switch suggestedName {
          | Some(name) => name
          | None =>
            let baseName = String.replaceRegExp(originalName, /\.[^/.]+$/, "")
            switch String.match(originalName, /_(\d{6})_\d{2}_(\d{3})/) {
            | Some(captures) =>
              let p1 = captures->Array.get(1)->Option.flatMap(x => x)
              let p2 = captures->Array.get(2)->Option.flatMap(x => x)
              switch (p1, p2) {
              | (Some(p1), Some(p2)) => p1 ++ "_" ++ p2
              | _ => baseName
              }
            | None => baseName
            }
          }
        }

        let newName = computeNewName(suggestedName, originalName)

        let previewFile = File.newFile(
          [previewBlob],
          newName ++ ".webp",
          {"type": "image/webp", "lastModified": Date.now()},
        )
        let tinyFile = switch tinyBlobOpt {
        | Some(b) =>
          Some(
            File.newFile(
              [b],
              newName ++ "_tiny.webp",
              {"type": "image/webp", "lastModified": Date.now()},
            ),
          )
        | None => None
        }

        Promise.resolve(
          Ok({
            preview: previewFile,
            tiny: tinyFile,
            metadata: metadata.exif,
            qualityData: metadata.quality,
            checksumData: metadata.checksum,
          }),
        )
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(err => {
      let (msg, _) = Logger.getErrorDetails(err)
      Promise.resolve(Error(msg))
    })
  }

  let generateResolutions = (file: File.t): Promise.t<result<dict<Blob.t>, string>> => {
    let formData = FormData.newFormData()
    FormData.append(formData, "file", file)

    RequestQueue.schedule(() =>
      Fetch.fetch(
        Constants.backendUrl ++ "/api/media/resize-batch",
        Fetch.requestInit(~method="POST", ~body=formData, ()),
      )
    )
    ->Promise.then(BackendApi.handleResponse)
    ->Promise.then(resultZip => {
      switch resultZip {
      | Ok(response) =>
        Fetch.blob(response)->Promise.then(zipBlob => {
          LazyLoad.loadJSZip()
          ->Promise.then(() => JSZip.loadAsync(zipBlob))
          ->Promise.then(zip => Promise.resolve(Ok(zip)))
        })
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.then(zipResult => {
      switch zipResult {
      | Ok(zip) =>
        let files = [("4k", "4k.webp"), ("2k", "2k.webp"), ("hd", "hd.webp")]
        let promises = Belt.Array.map(files, ((key, name)) => {
          let zipFile = JSZip.file(zip, name)
          switch Nullable.toOption(zipFile) {
          | Some(z) => JSZip.async(z, "blob")->Promise.then(b => Promise.resolve((key, Some(b))))
          | None => Promise.resolve((key, None))
          }
        })
        Promise.all(promises)->Promise.then(results => Promise.resolve(Ok(results)))
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.then(resultsResult => {
      switch resultsResult {
      | Ok(results) =>
        let d = Dict.make()
        Belt.Array.forEach(results, ((key, blobOpt)) => {
          switch blobOpt {
          | Some(b) => Dict.set(d, key, b)
          | None => ()
          }
        })
        Promise.resolve(Ok(d))
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(err => {
      let (msg, _) = Logger.getErrorDetails(err)
      Promise.resolve(Error(msg))
    })
  }
}

// --- FACADE ---

let init = () => {Logger.initialized(~module_="Resizer")}
let getChecksum = Utils.getChecksum
let checkBackendHealth = Utils.checkBackendHealth
let processAndAnalyzeImage = Logic.processAndAnalyzeImage
let generateResolutions = Logic.generateResolutions
