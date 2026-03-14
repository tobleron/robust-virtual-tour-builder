open ReBindings
open Types

type marketingBannerPayload = {
  showRent: bool,
  showSale: bool,
  body: string,
  phone1: string,
  phone2: string,
}

let normalizeMarketingValue = (value: string): string =>
  value->String.trim->String.replaceRegExp(/\\s+/g, " ")->String.trim

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
      `<div style="position:fixed;right:16px;bottom:16px;background:rgba(255,255,255,0.1);padding:5px;border-radius:10px;"><img src="../assets/logo/${filename}" style="height:64px;width:auto;display:block;" /></div>`
    | None => ""
    }
    let has4k = hasProfile("4k")
    let has2k = hasProfile("2k")
    let fallbackHref = if has4k {
      "tour_4k/index.html"
    } else if has2k {
      "tour_2k/index.html"
    } else {
      "tour_hd/index.html"
    }
    let adaptiveTarget = if has4k && has2k {
      "(() => { const coarse = window.matchMedia && window.matchMedia('(pointer: coarse)').matches; const shortEdge = Math.min(window.innerWidth || 0, window.innerHeight || 0); return coarse && shortEdge <= 430 ? 'tour_2k/index.html' : 'tour_4k/index.html'; })()"
    } else {
      "'" ++ fallbackHref ++ "'"
    }
    `<!doctype html><html><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>${tourName}</title></head><body style="margin:0;font-family:Outfit,Arial,sans-serif;background:#0b1931;color:#fff;min-height:100vh;display:flex;align-items:center;justify-content:center;"><div style="width:min(92vw,760px);padding:24px;text-align:center;"><h1 style="margin:0 0 16px 0;font-size:32px;">${tourName->String.replaceRegExp(
        /_/g,
        " ",
      )}</h1><p style="margin:0 0 18px 0;color:rgba(255,255,255,0.75);">Adaptive web package v${version}</p><p style="margin:0 0 24px 0;color:rgba(255,255,255,0.68);">4K loads by default, with a 2K fallback on small phones.</p><a href="${fallbackHref}" style="display:inline-block;padding:14px 18px;border-radius:12px;border:1px solid rgba(255,255,255,0.18);color:#fff;text-decoration:none;background:rgba(255,255,255,0.04);font-weight:700;">Open Tour</a><noscript><p style="margin:16px 0 0 0;color:rgba(255,255,255,0.6);">JavaScript is disabled, so the default tour entry is being shown.</p></noscript></div><script>window.location.replace(${adaptiveTarget});</script>${logoBlock}</body></html>`
  }

  let generateEmbedCodes = () => {
    let lines = ref([`VIRTUAL TOUR - EMBED CODES\nVersion: ${version}\nProperty: ${tourName}\n`])
    lines :=
      Belt.Array.concat(
        lines.contents,
        [
          `\n1. Web Package (4K default, 2K on small phones):\n   <iframe src="index.html" width="100%" height="640" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n`,
        ],
      )
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
  let htmlDesktopHdLandscapeTouchBlob = TourTemplates.generateTourHTML(
    exportScenes,
    tourName,
    logoFilename,
    "desktop_blob_hd_landscape_touch",
    28,
    40,
    version,
    ~marketingBody,
    ~marketingShowRent,
    ~marketingShowSale,
    ~marketingPhone1,
    ~marketingPhone2,
  )
  let htmlDesktop2kLandscapeTouchBlob = TourTemplates.generateTourHTML(
    exportScenes,
    tourName,
    logoFilename,
    "desktop_blob_2k_landscape_touch",
    28,
    50,
    version,
    ~marketingBody,
    ~marketingShowRent,
    ~marketingShowSale,
    ~marketingPhone1,
    ~marketingPhone2,
  )
  let htmlDesktop4kLandscapeTouchBlob = TourTemplates.generateTourHTML(
    exportScenes,
    tourName,
    logoFilename,
    "desktop_blob_4k_landscape_touch",
    28,
    54,
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
  if hasProfile("desktop_blob_hd_landscape_touch") {
    FormData.append(
      formData,
      "html_desktop_hd_landscape_touch_blob",
      htmlDesktopHdLandscapeTouchBlob,
    )
  }
  if hasProfile("desktop_blob_2k_landscape_touch") {
    FormData.append(
      formData,
      "html_desktop_2k_landscape_touch_blob",
      htmlDesktop2kLandscapeTouchBlob,
    )
  }
  if hasProfile("desktop_blob_4k_landscape_touch") {
    FormData.append(
      formData,
      "html_desktop_4k_landscape_touch_blob",
      htmlDesktop4kLandscapeTouchBlob,
    )
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
