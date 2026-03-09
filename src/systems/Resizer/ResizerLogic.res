/* src/systems/Resizer/ResizerLogic.res */

open ReBindings
open SharedTypes
open ResizerTypes
open ResizerUtils

let hasGps = (exif: exifMetadata): bool => exif.gps->Nullable.toOption->Option.isSome

let pickNullable = (primary: Nullable.t<'a>, fallback: Nullable.t<'a>): Nullable.t<'a> =>
  switch primary->Nullable.toOption {
  | Some(_) => primary
  | None => fallback
  }

let mergeExifPreferBase = (~base: exifMetadata, ~fallback: exifMetadata): exifMetadata => {
  make: pickNullable(base.make, fallback.make),
  model: pickNullable(base.model, fallback.model),
  dateTime: pickNullable(base.dateTime, fallback.dateTime),
  gps: pickNullable(base.gps, fallback.gps),
  width: if base.width > 0 {
    base.width
  } else {
    fallback.width
  },
  height: if base.height > 0 {
    base.height
  } else {
    fallback.height
  },
  focalLength: pickNullable(base.focalLength, fallback.focalLength),
  aperture: pickNullable(base.aperture, fallback.aperture),
  iso: pickNullable(base.iso, fallback.iso),
}

let ensureGpsExtraction = async (
  ~originalFile: File.t,
  ~derivedExif: exifMetadata,
  ~frontendExifOpt: option<exifMetadata>,
) => {
  if hasGps(derivedExif) {
    derivedExif
  } else {
    switch frontendExifOpt->Option.filter(hasGps) {
    | Some(frontendExif) =>
      Logger.info(
        ~module_="Resizer",
        ~message="GPS_RECOVERED_FROM_FRONTEND_EXIF",
        ~data=Some({"filename": File.name(originalFile)}),
        (),
      )
      mergeExifPreferBase(~base=derivedExif, ~fallback=frontendExif)
    | None =>
      let backendMetaResult = await BackendApi.extractMetadata(originalFile)
      switch backendMetaResult {
      | Ok(meta) if hasGps(meta.exif) =>
        Logger.info(
          ~module_="Resizer",
          ~message="GPS_RECOVERED_FROM_BACKEND_METADATA",
          ~data=Some({"filename": File.name(originalFile)}),
          (),
        )
        mergeExifPreferBase(~base=derivedExif, ~fallback=meta.exif)
      | _ => derivedExif
      }
    }
  }
}

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

let generateAndOverrideTiny = previewBlob => {
  Promise.make((resolve, _reject) => {
    let img = Dom.createElement("img")
    let url = UrlUtils.safeCreateObjectURL(previewBlob)

    let onLoad = () => {
      URL.revokeObjectURL(url)
      ThumbnailGenerator.generateRectilinearThumbnail(img, 256, 144, ~hfov=90.0)
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
        let newName = ResizerLogicSupport.computeNewName(~suggestedName, ~originalName)

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

  Promise.all2((
    FeatureLoaders.extractExifFromFileLazy(file),
    ImageOptimizer.compressToWebP(file, Constants.Media.uploadWebpQuality),
  ))
  ->Promise.then(((exifResult, compressionResult)) => {
    let exifDataOpt = switch exifResult {
    | Ok(exif) => Some(exif)
    | Error(_) => None
    }
    switch compressionResult {
    | Ok(webpBlob) =>
      let webpFile = File.newFile([webpBlob], File.name(file), {"type": "image/webp"})
      reportStatus("Uploading")
      BackendApi.processImageFull(
        webpFile,
        ~isOptimized=true,
        ~metadata=?exifDataOpt,
      )->Promise.then(result => Promise.resolve((result, exifDataOpt)))
    | Error(msg) => Promise.resolve((Error(msg), exifDataOpt))
    }
  })
  ->Promise.then(((processResult, exifDataOpt)) => {
    switch processResult {
    | Ok(zipBlob) =>
      reportStatus("Extracting")
      LazyLoad.loadJSZip()
      ->Promise.then(() => JSZip.loadAsync(zipBlob))
      ->Promise.then(zip => Promise.resolve((Ok(zip), exifDataOpt)))
    | Error(msg) => Promise.resolve((Error(msg), exifDataOpt))
    }
  })
  ->Promise.then(((zipResult, exifDataOpt)) =>
    processZipResponse(zipResult)->Promise.then(extractedResult =>
      Promise.resolve((extractedResult, exifDataOpt))
    )
  )
  ->Promise.then(((extractedResult, exifDataOpt)) =>
    createResultFiles(extractedResult, File.name(file))->Promise.then(createdResult => {
      switch createdResult {
      | Ok(processed) =>
        ensureGpsExtraction(
          ~originalFile=file,
          ~derivedExif=processed.metadata,
          ~frontendExifOpt=exifDataOpt,
        )->Promise.then(exif => Promise.resolve(Ok({...processed, metadata: exif})))
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
  )
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
      ResizerLogicSupport.extractResolutionFiles(zip)->Promise.then(results =>
        Promise.resolve(Ok(results))
      )
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.then(resultsResult => {
    switch resultsResult {
    | Ok(results) => Promise.resolve(Ok(ResizerLogicSupport.buildResolutionBlobDict(results)))
    | Error(msg) => Promise.resolve(Error(msg))
    }
  })
  ->Promise.catch(err => {
    let (msg, _) = Logger.getErrorDetails(err)
    Promise.resolve(Error(msg))
  })
}
