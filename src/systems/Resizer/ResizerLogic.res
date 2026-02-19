/* src/systems/Resizer/ResizerLogic.res */

open ReBindings
open SharedTypes
open ResizerTypes
open ResizerUtils

let processZipResponse = zipResult => {
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
}

let generateAndOverrideTiny = (previewBlob) => {
  Promise.make((resolve, _reject) => {
    let img = Dom.createElement("img")
    let url = UrlUtils.safeCreateObjectURL(previewBlob)

    let onLoad = () => {
      URL.revokeObjectURL(url)
      ThumbnailGenerator.generateRectilinearThumbnail(img, 120, 80)
      ->Promise.then(tinyBlob => {
        resolve(tinyBlob)
        Promise.resolve()
      })
      ->ignore
    }

    let onError = () => {
      URL.revokeObjectURL(url)
      resolve(previewBlob)
    }

    Dom.addEventListenerNoEv(img, "load", onLoad)
    Dom.addEventListenerNoEv(img, "error", onError)
    Dom.setAttribute(img, "src", url)
  })
}

let createResultFiles = async (extractedResult, originalName) => {
  switch extractedResult {
  | Ok((previewBlob, metaText, _tinyBlobOpt)) =>
    switch JsonCombinators.Json.parse(metaText) {
    | Ok(json) =>
      switch JsonCombinators.Json.decode(json, JsonParsers.Shared.metadataResponse) {
      | Ok(metadata) =>
        let suggestedName = Nullable.toOption(metadata.suggestedName)

        let computeNewName = (suggestedName: option<string>, originalName: string) => {
          switch suggestedName {
          | Some(name) => name
          | None =>
            let baseName = String.replaceRegExp(originalName, /\.[^/.]+$/, "")
            // Try PureShot format first: IMG_YYYYMMDD_HHMMSS_XX_SSS -> IMG_MMSS_SSS
            switch String.match(originalName, /IMG_\d{8}_(\d{6})_\d{2}_(\d{3})/) {
            | Some(captures) =>
              let hhmmss = switch Belt.Array.get(captures, 1) {
              | Some(Some(v)) => v
              | _ => ""
              }
              let sss = switch Belt.Array.get(captures, 2) {
              | Some(Some(v)) => v
              | _ => ""
              }
              if hhmmss != "" && sss != "" {
                let mmss = String.slice(hhmmss, ~start=2, ~end=6)
                "IMG_" ++ mmss ++ "_" ++ sss
              } else {
                baseName
              }
            | None =>
              // Fallback to legacy format
              switch String.match(originalName, /_(\d{6})_\d{2}_(\d{3})/) {
              | Some(captures) =>
                let p1 = switch Belt.Array.get(captures, 1) {
                | Some(Some(v)) => v
                | _ => ""
                }
                let p2 = switch Belt.Array.get(captures, 2) {
                | Some(Some(v)) => v
                | _ => ""
                }
                if p1 != "" && p2 != "" {
                  p1 ++ "_" ++ p2
                } else {
                  baseName
                }
              | None => baseName
              }
            }
          }
        }

        let newName = computeNewName(suggestedName, originalName)

        let previewFile = File.newFile(
          [previewBlob],
          newName ++ ".webp",
          {"type": "image/webp", "lastModified": Date.now()},
        )

        // Generate high-quality rectilinear tiny thumbnail (HFOV 90 override)
        let tinyBlobFixed = await generateAndOverrideTiny(previewBlob)
        let tinyFile = Some(
          File.newFile(
            [tinyBlobFixed],
            newName ++ "_tiny.webp",
            {"type": "image/webp", "lastModified": Date.now()},
          ),
        )

        Ok({
          preview: previewFile,
          tiny: tinyFile,
          metadata: metadata.exif,
          qualityData: metadata.quality,
          checksumData: metadata.checksum,
        })
      | Error(msg) => Error("Metadata decode error: " ++ msg)
      }
    | Error(msg) => Error("Metadata parse error: " ++ msg)
    }
  | Error(msg) => Error(msg)
  }
}

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

  Promise.all2((ExifParser.extractExifTags(File(file)), ImageOptimizer.compressToWebP(file, 0.90)))
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
  ->Promise.then(processZipResponse)
  ->Promise.then(extractedResult => createResultFiles(extractedResult, File.name(file)))
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
