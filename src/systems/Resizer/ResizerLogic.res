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

let createResultFiles = (extractedResult, originalName) => {
  switch extractedResult {
  | Ok((previewBlob, metaText, tinyBlobOpt)) =>
    let metadata: metadataResponse = Schemas.castToMetadataResponse(JSON.parseOrThrow(metaText))
    let suggestedName = Nullable.toOption(metadata.suggestedName)

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
