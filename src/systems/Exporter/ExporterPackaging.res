open ReBindings
open Types

type optimizedAsset = {blob: Blob.t, filename: string}
type marketingBannerPayload = {
  showRent: bool,
  showSale: bool,
  body: string,
  phone1: string,
  phone2: string,
}

let normalizeMarketingValue = (value: string): string =>
  value->String.trim->String.replaceRegExp(/\\s+/g, " ")->String.trim

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
  switch await ImageOptimizer.compressToWebPConstrained(
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
  ~authToken: option<string>,
  ~signal: option<BrowserBindings.AbortSignal.t>,
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
      switch await optimizeBlobAsWebp(
        ~blob,
        ~filenameHint,
        ~quality=Constants.Media.logoWebpQuality,
        ~maxWidth=Constants.Media.logoMaxWidth,
        ~maxHeight=Constants.Media.logoMaxHeight,
      ) {
      | Ok({blob: webpBlob}) =>
        FormData.appendWithFilename(
          formData,
          Constants.Media.logoOutputFilename,
          webpBlob,
          Constants.Media.logoOutputFilename,
        )
        logoFilename := Some(Constants.Media.logoOutputFilename)
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
    ignore(
      await appendOptimizedLogoBlob(
        ~blob=UiHelpers.fileToBlob(File(f)),
        ~filenameHint=File.name(f),
      ),
    )
  | Some(Blob(b)) => ignore(await appendOptimizedLogoBlob(~blob=b, ~filenameHint="logo-upload"))
  | Some(Url(url)) =>
    // Internal API URLs (e.g. /api/project/{sid}/file/logo_upload) are extensionless
    // but trusted — blob content is validated downstream by isLikelyImageBlob
    let isInternalApiUrl = String.includes(url, "/api/project/") && String.includes(url, "/file/")
    if url == "" || (!ExporterUtils.isLikelyImageUrl(url) && !isInternalApiUrl) {
      Logger.warn(
        ~module_="Exporter",
        ~message="LOGO_URL_SKIPPED_INVALID",
        ~data=Some({"url": url}),
        (),
      )
    } else {
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

  if logoFilename.contents == None {
    try {
      let extensions = ["png", "jpg", "jpeg", "webp"]
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
              let path = "/images/" ++ filename
              let res = await Fetch.fetchSimple(path)
              if Fetch.ok(res) {
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

let appendTemplates = (
  ~formData: FormData.t,
  ~exportScenes: array<scene>,
  ~tourName: string,
  ~logoFilename: option<string>,
  ~version: string,
  ~projectData: option<JSON.t>=?,
  ~publishProfiles: array<string>,
): unit => {
  let hasProfile = profile => publishProfiles->Belt.Array.some(p => p == profile)
  let webProfiles =
    publishProfiles
    ->Belt.Array.keep(p => p == "4k" || p == "2k" || p == "hd")
    ->Belt.Array.reduce([], (acc, profile) =>
      if acc->Belt.Array.some(existing => existing == profile) {
        acc
      } else {
        Belt.Array.concat(acc, [profile])
      }
    )

  let generateWebIndex = () => {
    let logoBlock = switch logoFilename {
    | Some(filename) =>
      `<div style="position:fixed;right:16px;bottom:16px;background:rgba(255,255,255,0.1);padding:4px;border-radius:8px;"><img src="../assets/logo/${filename}" style="height:52px;width:auto;display:block;" /></div>`
    | None => ""
    }
    let cards =
      webProfiles
      ->Belt.Array.map(profile =>
        switch profile {
        | "4k" => `<a href="tour_4k/index.html" style="display:block;padding:14px 16px;border-radius:12px;border:1px solid rgba(255,255,255,0.18);color:#fff;text-decoration:none;background:rgba(255,255,255,0.04);font-weight:700;">4K Ultra HD</a>`
        | "2k" => `<a href="tour_2k/index.html" style="display:block;padding:14px 16px;border-radius:12px;border:1px solid rgba(255,255,255,0.18);color:#fff;text-decoration:none;background:rgba(255,255,255,0.04);font-weight:700;">2K Desktop</a>`
        | _ => `<a href="tour_hd/index.html" style="display:block;padding:14px 16px;border-radius:12px;border:1px solid rgba(255,255,255,0.18);color:#fff;text-decoration:none;background:rgba(255,255,255,0.04);font-weight:700;">HD Mobile</a>`
        }
      )
      ->Array.joinUnsafe("\n")
    `<!doctype html><html><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>${tourName}</title></head><body style="margin:0;font-family:Outfit,Arial,sans-serif;background:#0b1931;color:#fff;min-height:100vh;display:flex;align-items:center;justify-content:center;"><div style="width:min(92vw,760px);padding:24px;"><h1 style="margin:0 0 16px 0;font-size:32px;">${tourName->String.replaceRegExp(
        /_/g,
        " ",
      )}</h1><p style="margin:0 0 18px 0;color:rgba(255,255,255,0.75);">Virtual Tour v${version}</p><div style="display:grid;gap:12px;">${cards}</div></div>${logoBlock}</body></html>`
  }

  let generateEmbedCodes = () => {
    let lines = ref([`VIRTUAL TOUR - EMBED CODES\nVersion: ${version}\nProperty: ${tourName}\n`])
    if hasProfile("4k") {
      lines :=
        Belt.Array.concat(
          lines.contents,
          [
            `\n1. 4K (Desktop):\n   <iframe src="tour_4k/index.html" width="100%" height="640" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n`,
          ],
        )
    }
    if hasProfile("2k") {
      lines :=
        Belt.Array.concat(
          lines.contents,
          [
            `\n2. 2K (Desktop/Laptop):\n   <iframe src="tour_2k/index.html" width="100%" height="400" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n`,
          ],
        )
    }
    if hasProfile("hd") {
      lines :=
        Belt.Array.concat(
          lines.contents,
          [
            `\n3. HD (Mobile):\n   <iframe src="tour_hd/index.html" width="375" height="667" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n`,
          ],
        )
    }
    lines.contents->Array.joinUnsafe("")
  }

  let marketingBanner: option<marketingBannerPayload> = switch projectData {
  | Some(data) =>
    switch JsonCombinators.Json.decode(data, JsonParsers.Domain.project) {
    | Ok(projectData) =>
      let composed = MarketingText.compose(
        ~comment=projectData.marketingComment,
        ~phone1=projectData.marketingPhone1,
        ~phone2=projectData.marketingPhone2,
        ~forRent=projectData.marketingForRent,
        ~forSale=projectData.marketingForSale,
      )
      let phone1 = normalizeMarketingValue(projectData.marketingPhone1)
      let phone2 = normalizeMarketingValue(projectData.marketingPhone2)
      if composed.full != "" {
        Some({
          showRent: composed.showRent,
          showSale: composed.showSale,
          body: composed.body,
          phone1,
          phone2,
        })
      } else {
        None
      }
    | Error(_) => None
    }
  | None => None
  }
  let marketingShowRent = marketingBanner->Option.map(m => m.showRent)->Option.getOr(false)
  let marketingShowSale = marketingBanner->Option.map(m => m.showSale)->Option.getOr(false)
  let marketingBody = marketingBanner->Option.map(m => m.body)->Option.getOr("")
  let marketingPhone1 = marketingBanner->Option.map(m => m.phone1)->Option.getOr("")
  let marketingPhone2 = marketingBanner->Option.map(m => m.phone2)->Option.getOr("")

  let html4k = TourTemplates.generateTourHTML(
    exportScenes,
    tourName,
    logoFilename,
    "4k",
    28,
    54,
    version,
    ~marketingBody,
    ~marketingShowRent,
    ~marketingShowSale,
    ~marketingPhone1,
    ~marketingPhone2,
  )
  let html2k = TourTemplates.generateTourHTML(
    exportScenes,
    tourName,
    logoFilename,
    "2k",
    28,
    50,
    version,
    ~marketingBody,
    ~marketingShowRent,
    ~marketingShowSale,
    ~marketingPhone1,
    ~marketingPhone2,
  )
  let htmlHd = TourTemplates.generateTourHTML(
    exportScenes,
    tourName,
    logoFilename,
    "hd",
    28,
    40,
    version,
    ~marketingBody,
    ~marketingShowRent,
    ~marketingShowSale,
    ~marketingPhone1,
    ~marketingPhone2,
  )
  let htmlDesktop2kBlob = TourTemplates.generateTourHTML(
    exportScenes,
    tourName,
    logoFilename,
    "desktop_blob_2k",
    28,
    50,
    version,
    ~marketingBody,
    ~marketingShowRent,
    ~marketingShowSale,
    ~marketingPhone1,
    ~marketingPhone2,
  )
  let htmlIndex = TourTemplates.generateExportIndex(tourName, version, logoFilename)
  let embed = TourTemplates.generateEmbedCodes(tourName, Version.version)

  if hasProfile("4k") {
    FormData.append(formData, "html_4k", html4k)
  }
  if hasProfile("2k") {
    FormData.append(formData, "html_2k", html2k)
  }
  if hasProfile("hd") {
    FormData.append(formData, "html_hd", htmlHd)
  }
  if hasProfile("desktop_blob_2k") {
    FormData.append(formData, "html_desktop_2k_blob", htmlDesktop2kBlob)
  }
  if Belt.Array.length(webProfiles) > 0 {
    FormData.append(formData, "html_index", generateWebIndex())
    FormData.append(formData, "embed_codes", generateEmbedCodes())
  } else {
    FormData.append(formData, "html_index", htmlIndex)
    FormData.append(formData, "embed_codes", embed)
  }
  FormData.append(formData, "publish_profiles", publishProfiles->Array.joinUnsafe(","))
  projectData->Option.forEach(data =>
    FormData.append(formData, "project_data", JsonCombinators.Json.stringify(data))
  )
}

let appendLibraries = async (
  ~formData: FormData.t,
  ~signal: option<BrowserBindings.AbortSignal.t>,
): unit => {
  try {
    let panJSRes: result<Blob.t, string> = await ExporterUtils.fetchLib("pannellum.js", ~signal?)
    let isAborted = switch signal {
    | Some(s) => BrowserBindings.AbortSignal.aborted(s)
    | None => false
    }
    if isAborted {
      ()
    } else {
      let panCSSRes: result<Blob.t, string> = await ExporterUtils.fetchLib(
        "pannellum.css",
        ~signal?,
      )
      let isAborted2 = switch signal {
      | Some(s) => BrowserBindings.AbortSignal.aborted(s)
      | None => false
      }
      if isAborted2 {
        ()
      } else {
        switch (panJSRes, panCSSRes) {
        | (Ok(panJS), Ok(panCSS)) => {
            FormData.appendWithFilename(formData, "pannellum.js", panJS, "pannellum.js")
            FormData.appendWithFilename(formData, "pannellum.css", panCSS, "pannellum.css")
          }
        | (Error(e), _) | (_, Error(e)) =>
          Logger.error(~module_="Exporter", ~message="FETCH_LIBS_FAILED", ~data={"error": e}, ())
        }
      }
    }
  } catch {
  | exn =>
    let (msg, stack) = Logger.getErrorDetails(exn)
    Logger.error(
      ~module_="Exporter",
      ~message="FETCH_LIBS_FAILED",
      ~data={"error": msg, "stack": stack},
      (),
    )
  }
}

let appendScenes = async (
  ~formData: FormData.t,
  ~exportScenes: array<scene>,
  ~authToken: option<string>,
  ~progress: (float, float, string) => unit,
  ~signal: option<BrowserBindings.AbortSignal.t>,
): result<unit, string> => {
  let totalScenes = Belt.Array.length(exportScenes)

  let rec appendScenesList = async (sceneList, idx, ~signal) => {
    let isAborted = switch signal {
    | Some(s) => BrowserBindings.AbortSignal.aborted(s)
    | None => false
    }
    if isAborted {
      Error("AbortError: Export cancelled by user")
    } else {
      switch sceneList {
      | list{} => Ok()
      | list{s, ...rest} => {
          let sourceFile = switch s.originalFile {
          | Some(f) => f
          | None => s.file
          }

          let blobResult = switch sourceFile {
          | Blob(b) => Ok(b)
          | File(f) => Ok(UiHelpers.fileToBlob(File(f)))
          | Url(url) =>
            let initial = await ExporterUtils.fetchSceneUrlBlob(~url, ~authToken, ~signal?)
            switch initial {
            | Ok(_) => initial
            | Error(msg) =>
              let usingDevToken = switch authToken {
              | Some(t) => t == "dev-token"
              | None => false
              }
              if (
                Constants.isDebugBuild() &&
                !usingDevToken &&
                ExporterUtils.isUnauthorizedHttpError(msg)
              ) {
                await ExporterUtils.fetchSceneUrlBlob(~url, ~authToken=Some("dev-token"), ~signal?)
              } else {
                initial
              }
            }
          }

          switch blobResult {
          | Ok(fileBlob) =>
            switch await optimizeBlobAsWebp(
              ~blob=fileBlob,
              ~filenameHint=s.name,
              ~quality=Constants.Media.exportSceneWebpQuality,
              ~maxWidth=Constants.Media.exportSceneMaxWidth,
              ~maxHeight=Constants.Media.exportSceneMaxWidth,
            ) {
            | Ok({blob: normalizedBlob, filename}) =>
              FormData.appendWithFilename(
                formData,
                `scene_${Belt.Int.toString(idx)}`,
                normalizedBlob,
                filename,
              )
              let scenePct = 15.0 +. 25.0 *. Int.toFloat(idx + 1) /. Int.toFloat(totalScenes)
              progress(
                scenePct,
                100.0,
                "Packaging scene " ++
                Int.toString(idx + 1) ++
                " of " ++
                Int.toString(totalScenes) ++ "...",
              )
              await appendScenesList(rest, idx + 1, ~signal)
            | Error(msg) => Error("Scene normalization failed for '" ++ s.name ++ "': " ++ msg)
            }
          | Error(msg) => Error("Scene packaging failed for '" ++ s.name ++ "': " ++ msg)
          }
        }
      }
    }
  }

  await appendScenesList(Belt.List.fromArray(exportScenes), 0, ~signal)
}
