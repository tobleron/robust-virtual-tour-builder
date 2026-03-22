open ReBindings
open Types

type optimizedAsset = {blob: Blob.t, filename: string}

let toWebpFilename = (name: string, ~fallback: string): string => {
  let base = name->UrlUtils.stripExtension
  let safeBase = if base == "" {
    fallback
  } else {
    base
  }
  safeBase ++ ".webp"
}

let optimizeBlobAsWebp = async (
  ~blob: Blob.t,
  ~filenameHint: string,
  ~quality: float,
  ~maxWidth: float,
  ~maxHeight: float,
): result<optimizedAsset, string> => {
  let sourceType = blob->Blob.type_
  let sourceFile = File.newFile(
    [blob],
    filenameHint,
    {
      "type": if sourceType == "" {
        "application/octet-stream"
      } else {
        sourceType
      },
    },
  )
  switch await ImageOptimizer.compressLogoToWebPConstrained(
    sourceFile,
    ~quality,
    ~maxWidth,
    ~maxHeight,
  ) {
  | Ok(webpBlob) =>
    Ok({
      blob: webpBlob,
      filename: toWebpFilename(filenameHint, ~fallback="asset"),
    })
  | Error(msg) => Error(msg)
  }
}

let appendLogo = async (
  ~formData: FormData.t,
  ~logo: option<file>,
  ~allowDefaultLogoFallback: bool=true,
  ~authToken: option<string>,
  ~signal: option<BrowserBindings.AbortSignal.t>,
  ~reportProgress: (~fraction: float, ~message: string) => unit,
): option<string> => {
  let logoFilename = ref(None)
  let appendOptimizedLogoBlob = async (~blob: Blob.t, ~filenameHint: string): bool => {
    let isAborted = switch signal {
    | Some(s) => BrowserBindings.AbortSignal.aborted(s)
    | None => false
    }
    if isAborted {
      false
    } else {
      reportProgress(~fraction=0.55, ~message="Optimizing logo...")
      switch await optimizeBlobAsWebp(
        ~blob,
        ~filenameHint,
        ~quality=Constants.Media.logoWebpQuality,
        ~maxWidth=Constants.Media.logoMaxWidth,
        ~maxHeight=Constants.Media.logoMaxHeight,
      ) {
      | Ok({blob: webpBlob}) =>
        reportProgress(~fraction=0.88, ~message="Attaching logo...")
        FormData.appendWithFilename(
          formData,
          Constants.Media.logoOutputFilename,
          webpBlob,
          Constants.Media.logoOutputFilename,
        )
        logoFilename := Some(Constants.Media.logoOutputFilename)
        reportProgress(~fraction=1.0, ~message="Logo ready")
        true
      | Error(msg) =>
        Logger.warn(
          ~module_="Exporter",
          ~message="LOGO_OPTIMIZATION_FAILED",
          ~data=Some({"filenameHint": filenameHint, "error": msg}),
          (),
        )
        false
      }
    }
  }

  switch logo {
  | Some(File(f)) =>
    reportProgress(~fraction=0.18, ~message="Preparing custom logo...")
    ignore(
      await appendOptimizedLogoBlob(
        ~blob=UiHelpers.fileToBlob(File(f)),
        ~filenameHint=File.name(f),
      ),
    )
  | Some(Blob(b)) =>
    reportProgress(~fraction=0.18, ~message="Preparing custom logo...")
    ignore(await appendOptimizedLogoBlob(~blob=b, ~filenameHint="logo-upload"))
  | Some(Url(url)) =>
    let isInternalApiUrl = String.includes(url, "/api/project/") && String.includes(url, "/file/")
    if url == "" || (!ExporterUtils.isLikelyImageUrl(url) && !isInternalApiUrl) {
      Logger.warn(
        ~module_="Exporter",
        ~message="LOGO_URL_SKIPPED_INVALID",
        ~data=Some({"url": url}),
        (),
      )
    } else {
      reportProgress(~fraction=0.2, ~message="Downloading custom logo...")
      switch await ExporterUtils.fetchSceneUrlBlob(~url, ~authToken, ~signal?) {
      | Ok(logoBlob) =>
        if ExporterUtils.isLikelyImageBlob(~blob=logoBlob, ~urlHint=Some(url)) {
          let hint = switch ExporterUtils.filenameFromUrl(url) {
          | Some(fileName) => fileName
          | None => "logo-url"
          }
          ignore(await appendOptimizedLogoBlob(~blob=logoBlob, ~filenameHint=hint))
        } else {
          Logger.warn(
            ~module_="Exporter",
            ~message="LOGO_URL_NOT_IMAGE",
            ~data=Some({"url": url, "blobType": logoBlob->Blob.type_}),
            (),
          )
        }
      | Error(msg) =>
        Logger.warn(
          ~module_="Exporter",
          ~message="LOGO_URL_FETCH_FAILED",
          ~data=Some({"url": url, "error": msg}),
          (),
        )
      }
    }
  | None => ()
  }

  if allowDefaultLogoFallback && logoFilename.contents == None {
    try {
      reportProgress(~fraction=0.2, ~message="Locating default logo...")
      let extensions = ["webp", "png", "jpg", "jpeg"]
      let rec findLogo = async exts => {
        let isAborted = switch signal {
        | Some(s) => BrowserBindings.AbortSignal.aborted(s)
        | None => false
        }
        if isAborted {
          ()
        } else {
          switch exts {
          | list{} => ()
          | list{ext, ...rest} => {
              let filename = "logo." ++ ext
              let path = if ext == "webp" {
                "/" ++ Constants.defaultLogoPath
              } else {
                "/images/" ++ filename
              }
              let res = await Fetch.fetchSimple(path)
              if Fetch.ok(res) {
                reportProgress(~fraction=0.35, ~message="Loading default logo...")
                let logoBlob = await Fetch.blob(res)
                if ExporterUtils.isLikelyImageBlob(~blob=logoBlob, ~urlHint=Some(path)) {
                  let applied = await appendOptimizedLogoBlob(
                    ~blob=logoBlob,
                    ~filenameHint=filename,
                  )
                  if !applied {
                    await findLogo(rest)
                  }
                } else {
                  await findLogo(rest)
                }
              } else {
                await findLogo(rest)
              }
            }
          }
        }
      }
      await findLogo(Belt.List.fromArray(extensions))
    } catch {
    | _ => Logger.warn(~module_="Exporter", ~message="LOGO_NOT_FOUND", ())
    }
  }

  logoFilename.contents
}
