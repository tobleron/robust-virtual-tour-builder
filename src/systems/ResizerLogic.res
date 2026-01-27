/* src/systems/ResizerLogic.res */

open ReBindings
open SharedTypes
open ResizerTypes

/**
 * Combined processing: Optimize image AND extract metadata in one request.
 */
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
    ~data={
      "file": File.name(file),
      "size": File.size(file),
      "memory": mem,
    },
    (),
  )

  reportStatus("Optimizing")
  let fetchStart = now()

  // 1 & 2. Extract EXIF and Compress image in parallel
  Promise.all2((ExifParser.extractExifTags(File(file)), ImageOptimizer.compressToWebP(file, 0.90)))
  ->Promise.then(((exifResult, compressionResult)) => {
    let exifData = switch exifResult {
    | Ok((exif, _pano)) => Some(exif)
    | Error(_) => None
    }

    switch compressionResult {
    | Ok(webpBlob) => {
        let compressedFileSize = Blob.size(webpBlob)
        Logger.info(
          ~module_="Resizer",
          ~message="FRONTEND_COMPRESSION_COMPLETE",
          ~data={
            "file": File.name(file),
            "originalSize": File.size(file),
            "compressedSize": compressedFileSize,
            "ratio": Float.toFixed(compressedFileSize /. File.size(file), ~digits=2),
          },
          (),
        )

        let webpFile = File.newFile([webpBlob], File.name(file), %raw("{type: 'image/webp'}"))

        // 3. Send optimized image + preserved metadata to backend
        reportStatus("Uploading")
        BackendApi.processImageFull(webpFile, ~isOptimized=true, ~metadata=?exifData)
      }
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
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

        reportStatus("Extracting")
        LazyLoad.loadJSZip()
        ->Promise.then(() => JSZip.loadAsync(zipBlob))
        ->Promise.then(zip => Promise.resolve(Ok(zip)))
      }
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.then(zipResult => {
    switch zipResult {
    | Ok(zip) => {
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

          Promise.all3((p1, p2, p3))->Promise.then(res => Promise.resolve(Ok(res)))
        | _ => Promise.resolve(Error("Missing preview.webp or metadata.json in response"))
        }
      }
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.then(extractedResult => {
    switch extractedResult {
    | Ok((previewBlob, metaText, tinyBlobOpt)) => {
        Logger.debug(
          ~module_="Resizer",
          ~message="PROCESSING_FILES_EXTRACTED",
          ~data=Some({"metaLength": String.length(metaText)}),
          (),
        )
        let metadata: metadataResponse = Schemas.castToMetadataResponse(JSON.parseOrThrow(metaText))
        Logger.debug(
          ~module_="Resizer",
          ~message="METADATA_PARSED",
          ~data=Some({"suggestedName": metadata.suggestedName}),
          (),
        )

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

        Promise.resolve(
          Ok({
            preview: previewFile,
            tiny: tinyFile,
            metadata: metadata.exif,
            qualityData: metadata.quality,
            checksumData: metadata.checksum,
          }),
        )
      }
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.catch(err => {
    let (msg, stack) = Logger.getErrorDetails(err)
    Logger.error(
      ~module_="Resizer",
      ~message="BACKEND_PROCESS_FULL_FAILED",
      ~data={"error": msg, "stack": stack, "file": File.name(file)},
      (),
    )
    Promise.resolve(Error(msg))
  })
}

/**
 * Generate multiple resolutions of an image via Rust Backend
 */
let generateResolutions = (file: File.t): Promise.t<result<dict<Blob.t>, string>> => {
  let formData = FormData.newFormData()
  FormData.append(formData, "file", file)

  RequestQueue.schedule(() => {
    Fetch.fetch(
      Constants.backendUrl ++ "/api/media/resize-batch",
      Fetch.requestInit(~method="POST", ~body=formData, ()),
    )
  })
  ->Promise.then(BackendApi.handleResponse)
  ->Promise.then(resultZip => {
    switch resultZip {
    | Ok(response) =>
      Fetch.blob(response)
      ->Promise.then(zipBlob => {
        LazyLoad.loadJSZip()
        ->Promise.then(() => JSZip.loadAsync(zipBlob))
        ->Promise.then(zip => Promise.resolve(Ok(zip)))
      })
      ->Promise.catch(e => {
        let (msg, stack) = Logger.getErrorDetails(e)
        Logger.error(
          ~module_="Resizer",
          ~message="BATCH_RESIZE_EXTRACT_ERROR",
          ~data=Logger.castToJson({"error": msg, "stack": stack}),
          (),
        )
        Promise.resolve(Error("Failed to extract resolutions ZIP"))
      })
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.then(zipResult => {
    switch zipResult {
    | Ok(zip) => {
        let files = [("4k", "4k.webp"), ("2k", "2k.webp"), ("hd", "hd.webp")]

        let promises = Belt.Array.map(files, ((key, name)) => {
          let zipFile = JSZip.file(zip, name)
          switch Nullable.toOption(zipFile) {
          | Some(z) => JSZip.async(z, "blob")->Promise.then(b => Promise.resolve((key, Some(b))))
          | None =>
            Logger.warn(
              ~module_="Resizer",
              ~message="MISSING_FILE_IN_ZIP",
              ~data={"file": name},
              (),
            )
            Promise.resolve((key, None))
          }
        })

        Promise.all(promises)->Promise.then(results => Promise.resolve(Ok(results)))
      }
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.then(resultsResult => {
    switch resultsResult {
    | Ok(results) => {
        let d = Dict.make()
        Belt.Array.forEach(results, ((key, blobOpt)) => {
          switch blobOpt {
          | Some(b) => Dict.set(d, key, b)
          | None => ()
          }
        })
        Promise.resolve(Ok(d))
      }
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.catch(err => {
    let (msg, stack) = Logger.getErrorDetails(err)
    Logger.error(
      ~module_="Resizer",
      ~message="BATCH_RESIZE_FAILED",
      ~data={"error": msg, "stack": stack, "file": File.name(file)},
      (),
    )
    Promise.resolve(Error(msg))
  })
}
