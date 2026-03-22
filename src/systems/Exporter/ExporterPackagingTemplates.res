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

  let generateWebIndex = (
    ~bundleLabel="Adaptive web package",
    ~bundleNote="4K loads by default, with a 2K fallback only on constrained devices when image detail remains acceptable.",
  ) => {
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
      `(() => {
        const clamp = (value, min, max) => Math.max(min, Math.min(max, value));
        const coarse = !!(window.matchMedia && (
          window.matchMedia('(pointer: coarse)').matches ||
          window.matchMedia('(any-pointer: coarse)').matches
        ));
        const width = window.innerWidth || 0;
        const height = window.innerHeight || 0;
        const safeViewportWidth = Math.max(width - 10, 0);
        const safeViewportHeight = Math.max(height - 10, 0);
        const estimatePortraitStageWidth = maxWidth =>
          Math.min(
            safeViewportWidth,
            (safeViewportHeight * 9) / 16,
            maxWidth,
          );
        const estimatePortraitHfov = (stageWidth, minHfov) => {
          const portraitMaxHfov = clamp(Math.floor((90 * 0.93) * 10) / 10, minHfov, 90);
          if (stageWidth >= 700) return portraitMaxHfov;
          if (stageWidth >= 600) return clamp(78, minHfov, portraitMaxHfov);
          if (stageWidth >= 480) return clamp(72, minHfov, portraitMaxHfov);
          return minHfov;
        };
        const dpr = clamp(window.devicePixelRatio || 1, 1, 2);
        const estimated2kStageWidth = estimatePortraitStageWidth(493);
        const predicted2kPortraitHfov = estimatePortraitHfov(estimated2kStageWidth, 50);
        const visible2kSourcePixels = 2048 * (predicted2kPortraitHfov / 360);
        const requiredDisplayPixels = estimated2kStageWidth * dpr;
        const qualityAcceptable = visible2kSourcePixels >= requiredDisplayPixels * 0.9;
        if (!coarse || !qualityAcceptable) {
          return 'tour_4k/index.html';
        }
        const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
        const saveData = !!connection?.saveData;
        const effectiveType = typeof connection?.effectiveType === 'string'
          ? connection.effectiveType
          : '';
        const slowNetwork =
          effectiveType === 'slow-2g' ||
          effectiveType === '2g' ||
          effectiveType === '3g';
        const lowMemory =
          typeof navigator.deviceMemory === 'number' && navigator.deviceMemory <= 2;
        return lowMemory || saveData || slowNetwork
          ? 'tour_2k/index.html'
          : 'tour_4k/index.html';
      })()`
    } else {
      "'" ++ fallbackHref ++ "'"
    }
    `<!doctype html><html><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>${tourName}</title></head><body style="margin:0;font-family:Outfit,Arial,sans-serif;background:#0b1931;color:#fff;min-height:100vh;display:flex;align-items:center;justify-content:center;"><div style="width:min(92vw,760px);padding:24px;text-align:center;"><h1 style="margin:0 0 16px 0;font-size:32px;">${tourName->String.replaceRegExp(
        /_/g,
        " ",
      )}</h1><p style="margin:0 0 18px 0;color:rgba(255,255,255,0.75);">${bundleLabel} v${version}</p><p style="margin:0 0 24px 0;color:rgba(255,255,255,0.68);">${bundleNote}</p><a href="${fallbackHref}" style="display:inline-block;padding:14px 18px;border-radius:12px;border:1px solid rgba(255,255,255,0.18);color:#fff;text-decoration:none;background:rgba(255,255,255,0.04);font-weight:700;">Open Tour</a><noscript><p style="margin:16px 0 0 0;color:rgba(255,255,255,0.6);">JavaScript is disabled, so the default tour entry is being shown.</p></noscript></div><script>window.location.replace(${adaptiveTarget});</script>${logoBlock}</body></html>`
  }

  let generateEmbedCodes = (~bundleLabel="Web Package") => {
    let lines = ref([`VIRTUAL TOUR - EMBED CODES\nVersion: ${version}\nProperty: ${tourName}\n`])
    lines :=
      Belt.Array.concat(
        lines.contents,
        [
          `\n1. ${bundleLabel} (4K default, 2K on constrained devices when detail remains acceptable):\n   <iframe src="index.html" width="100%" height="640" style="border:none;" title="360° Virtual Tour - ${tourName}"></iframe>\n`,
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
  let tripodDeadZoneEnabled = switch projectData {
  | Some(data) =>
    switch JsonCombinators.Json.decode(data, JsonParsers.Domain.project) {
    | Ok(projectData) => projectData.tripodDeadZoneEnabled
    | Error(_) => true
    }
  | None => true
  }

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
    ~tripodDeadZoneEnabled,
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
    ~tripodDeadZoneEnabled,
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
    ~tripodDeadZoneEnabled,
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
    ~tripodDeadZoneEnabled,
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
    ~tripodDeadZoneEnabled,
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
    ~tripodDeadZoneEnabled,
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
    ~tripodDeadZoneEnabled,
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
