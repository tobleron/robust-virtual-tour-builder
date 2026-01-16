/* src/systems/Resizer.res */

open ReBindings

open SharedTypes

type processResult = {
  preview: File.t,
  tiny: option<File.t>,
  metadata: exifMetadata,
  quality: qualityAnalysis,
  checksum: string,
}

/* --- TELEMETRY --- */
@val @scope(("performance", "memory"))
external usedJSHeapSize: float = "usedJSHeapSize"
@val @scope(("performance", "memory"))
external totalJSHeapSize: float = "totalJSHeapSize"
@val @scope(("performance", "memory"))
external jsHeapSizeLimit: float = "jsHeapSizeLimit"
@val @scope("performance")
external now: unit => float = "now"

let getMemoryUsage = () => {
  try {
    let used = usedJSHeapSize /. 1024.0 /. 1024.0
    let total = totalJSHeapSize /. 1024.0 /. 1024.0
    let limit = jsHeapSizeLimit /. 1024.0 /. 1024.0

    {
      "used": Float.toFixed(used, ~digits=0) ++ "MB",
      "total": Float.toFixed(total, ~digits=0) ++ "MB",
      "limit": Float.toFixed(limit, ~digits=0) ++ "MB",
    }
  } catch {
  | _ => {"used": "N/A", "total": "N/A", "limit": "N/A"}
  }
}

/* --- PUBLIC API --- */

/**
 * Generate a SHA-256 checksum for a file (Client-side).
 * Used for "fingerprinting" images to detect duplicates before upload.
 */
let getChecksum = (file: File.t): Promise.t<string> => {
  /* Partial implementation of sample logic using Slice and ArrayBuffer */
  /* Since this is complex to port 1:1 with bindings instantly, let's keep it simple or binding-heavy. */
  /* Actually, let's just use a simple binding to a raw JS function inside Resizer.res for this specific crypto logic to save time/risk. */

  let internalGetChecksum: File.t => Promise.t<string> = %raw(`
     async function(file) {
        const SMALL_FILE_THRESHOLD = 10 * 1024 * 1024;
        const SAMPLE_SIZE = 1024 * 1024;
        let hashBuffer;
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
            sampleBuffers.forEach(buf => {
                combined.set(new Uint8Array(buf), offset);
                offset += buf.byteLength;
            });
            hashBuffer = await crypto.subtle.digest('SHA-256', combined);
        }
        const hashArray = Array.from(new Uint8Array(hashBuffer));
        const hash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
        return hash + "_" + file.size;
     }
   `)

  internalGetChecksum(file)
}

/**
 * Checks if the backend is reachable
 */
let checkBackendHealth = () => {
  let controller = AbortController.newAbortController()
  let _signal = AbortController.signal(controller)
  let timeoutId = Window.setTimeout(() => AbortController.abort(controller), 2000)

  Fetch.fetch(
    Constants.backendUrl ++ "/health",
    {
      method: "GET",
      body: Nullable.null,
      headers: Nullable.null,
      signal: _signal,
    },
  )
  ->Promise.then(res => {
    Window.clearTimeout(timeoutId)
    Promise.resolve(Fetch.ok(res))
  })
  ->Promise.catch(_ => {
    Window.clearTimeout(timeoutId)
    Promise.resolve(false)
  })
}

/**
 * Combined processing: Optimize image AND extract metadata in one request.
 */
let processAndAnalyzeImage = (file: File.t): Promise.t<processResult> => {
  let mem = getMemoryUsage()

  Logger.startOperation(
    ~module_="Resizer",
    ~operation="BACKEND_PROCESS_FULL",
    ~data={
      "file": File.name(file),
      "size": File.size(file),
      "memory": mem,
    },
    (),
  )

  let fetchStart = now()

  BackendApi.processImageFull(file)
  ->Promise.then(result => {
    switch result {
    | Ok(zipBlob) => {
        let fetchDuration = now() -. fetchStart
        Logger.info(
          ~module_="Resizer",
          ~message="BACKEND_FETCH_COMPLETE",
          ~data={
            "fileName": File.name(file),
            "durationMs": Float.toFixed(fetchDuration, ~digits=2),
            "size": File.size(file),
          },
          (),
        )

        LazyLoad.loadJSZip()->Promise.then(() => JSZip.loadAsync(zipBlob))
      }
    | Error(msg) => Promise.reject(JsError.throwWithMessage(msg))
    }
  })
  ->Promise.then(zip => {
    // 1. Extract Preview
    let previewZipFile = JSZip.file(zip, "preview.webp")
    let tinyZipFile = JSZip.file(zip, "tiny.webp")
    let metaZipFile = JSZip.file(zip, "metadata.json")

    switch (Nullable.toOption(previewZipFile), Nullable.toOption(metaZipFile)) {
    | (Some(previewFileInZip), Some(metaFileInZip)) =>
      let p1 = JSZip.async(previewFileInZip, "blob")
      let p2 = JSZip.async(metaFileInZip, "text")
      let p3 = switch Nullable.toOption(tinyZipFile) {
      | Some(f) => JSZip.async(f, "blob")->Promise.then(b => Promise.resolve(Some(b)))
      | None => Promise.resolve(None)
      }

      Promise.all3((p1, p2, p3))
    | _ =>
      Promise.reject(JsError.throwWithMessage("Missing preview.webp or metadata.json in response"))
    }
  })
  ->Promise.then(((previewBlob, metaText, tinyBlobOpt)) => {
    let metadata: metadataResponse = Obj.magic(JSON.parseOrThrow(metaText))

    // Smart filename logic
    let suggestedName = Nullable.toOption(metadata.suggestedName)
    let originalName = File.name(file)

    let newName = switch suggestedName {
    | Some(name) => name
    | None =>
      // Fallback regex logic matching JS version
      let baseName = String.replaceRegExp(originalName, /\.[^/.]+$/, "")
      let matchResult = String.match(originalName, /_(\d{6})_\d{2}_(\d{3})/)

      switch matchResult {
      | Some(captures) => {
          let p1Opt = captures->Array.get(1)->Option.flatMap(x => x)
          let p2Opt = captures->Array.get(2)->Option.flatMap(x => x)

          switch (p1Opt, p2Opt) {
          | (Some(p1), Some(p2)) => p1 ++ "_" ++ p2
          | _ => baseName
          }
        }
      | None => baseName
      }
    }

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

    Promise.resolve({
      preview: previewFile,
      tiny: tinyFile,
      metadata: metadata.exif,
      quality: metadata.quality,
      checksum: metadata.checksum,
    })
  })
  ->Promise.catch(err => {
    Logger.error(
      ~module_="Resizer",
      ~message="BACKEND_PROCESS_FULL_FAILED",
      ~data={"error": err, "file": File.name(file)},
      (),
    )
    Promise.reject(err)
  })
}

/**
 * Generate multiple resolutions of an image via Rust Backend
 */
let generateResolutions = (file: File.t): Promise.t<dict<Blob.t>> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "file", file)

  Fetch.fetch(
    Constants.backendUrl ++ "/resize-image-batch",
    {
      method: "POST",
      body: formData,
      headers: Nullable.null,
    },
  )
  ->Promise.then(BackendApi.handleResponse)
  ->Promise.then(Fetch.blob)
  ->Promise.then(zipBlob => {
    LazyLoad.loadJSZip()->Promise.then(() => JSZip.loadAsync(zipBlob))
  })
  ->Promise.then(zip => {
    let files = [("4k", "4k.webp"), ("2k", "2k.webp"), ("hd", "hd.webp")]

    let promises = Belt.Array.map(files, ((key, name)) => {
      let zipFile = JSZip.file(zip, name)
      switch Nullable.toOption(zipFile) {
      | Some(z) => JSZip.async(z, "blob")->Promise.then(b => Promise.resolve((key, Some(b))))
      | None =>
        Logger.warn(~module_="Resizer", ~message="MISSING_FILE_IN_ZIP", ~data={"file": name}, ())
        Promise.resolve((key, None))
      }
    })

    Promise.all(promises)
  })
  ->Promise.then(results => {
    let d = Dict.make()
    Belt.Array.forEach(results, ((key, blobOpt)) => {
      switch blobOpt {
      | Some(b) => Dict.set(d, key, b)
      | None => ()
      }
    })
    Promise.resolve(d)
  })
  ->Promise.catch(err => {
    Logger.error(
      ~module_="Resizer",
      ~message="BATCH_RESIZE_FAILED",
      ~data={"error": err, "file": File.name(file)},
      (),
    )
    Promise.reject(err)
  })
}
