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
      `<div style="position:fixed;right:16px;bottom:16px;background:rgba(255,255,255,0.1);padding:4px;border-radius:8px;"><img src="../assets/logo/${filename}" style="height:52px;width:auto;display:block;" /></div>`
    | None => ""
    }
    let cards =
      webProfiles
      ->Belt.Array.map(profile =>
        switch profile {
        | "4k" => `<a href="tour_4k/index.html" style="display:block;padding:14px 16px;border-radius:12px;border:1px solid rgba(255,255,255,0.18);color:#fff;text-decoration:none;background:rgba(255,255,255,0.04);font-weight:700;">4K Adaptive</a>`
        | "2k" => `<a href="tour_2k/index.html" style="display:block;padding:14px 16px;border-radius:12px;border:1px solid rgba(255,255,255,0.18);color:#fff;text-decoration:none;background:rgba(255,255,255,0.04);font-weight:700;">2K Adaptive</a>`
        | _ => `<a href="tour_hd/index.html" style="display:block;padding:14px 16px;border-radius:12px;border:1px solid rgba(255,255,255,0.18);color:#fff;text-decoration:none;background:rgba(255,255,255,0.04);font-weight:700;">HD Adaptive</a>`
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
            `\n1. 4K (Adaptive):\n   <iframe src="tour_4k/index.html" width="100%" height="640" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n`,
          ],
        )
    }
    if hasProfile("2k") {
      lines :=
        Belt.Array.concat(
          lines.contents,
          [
            `\n2. 2K (Adaptive):\n   <iframe src="tour_2k/index.html" width="100%" height="400" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n`,
          ],
        )
    }
    if hasProfile("hd") {
      lines :=
        Belt.Array.concat(
          lines.contents,
          [
            `\n3. HD (Adaptive):\n   <iframe src="tour_hd/index.html" width="375" height="667" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n`,
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
