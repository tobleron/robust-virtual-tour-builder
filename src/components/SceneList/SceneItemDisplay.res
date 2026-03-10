// @efficiency-role: domain-logic

type qualityDisplay = {
  score: float,
  isLowQuality: bool,
  colorClass: string,
  progressPercent: float,
}

type fileMetaDisplay = {
  badgeColor: string,
  formatLabel: string,
  formattedSize: string,
}

type displayInfo = {
  tooltipName: string,
  quality: qualityDisplay,
  fileMeta: fileMetaDisplay,
}

let getThumbUrl = (scene: Types.scene) => {
  switch scene.tinyFile {
  | Some(Blob(_) as tiny) | Some(File(_) as tiny) =>
    let tinyUrl = SceneCache.getThumbUrl(scene.id ++ "_tiny", tiny)
    if tinyUrl == "" {
      SceneCache.getThumbUrl(scene.id, scene.file)
    } else {
      tinyUrl
    }
  | None | Some(Url(_)) => SceneCache.getThumbUrl(scene.id, scene.file)
  }
}

let decodeQualityScore = (scene: Types.scene) => {
  switch scene.quality {
  | Some(q) =>
    switch JsonCombinators.Json.decode(q, JsonParsers.Shared.qualityAnalysis) {
    | Ok(qObj) => qObj.score
    | Error(_) => 10.0
    }
  | None => 10.0
  }
}

let describeQuality = (scene: Types.scene): qualityDisplay => {
  let score = decodeQualityScore(scene)
  let isLowQuality = score < 6.5
  let rawPercent = score *. 10.0
  let progressPercent = if rawPercent < 0.0 {
    0.0
  } else if rawPercent > 100.0 {
    100.0
  } else {
    rawPercent
  }

  {
    score,
    isLowQuality,
    colorClass: isLowQuality ? "bg-danger" : "bg-success",
    progressPercent,
  }
}

let formatBytes = (size: float) => {
  if size > 0.0 {
    let mb = size /. (1024.0 *. 1024.0)
    if mb >= 1.0 {
      Float.toFixed(mb, ~digits=1) ++ "MB"
    } else {
      let kb = size /. 1024.0
      Float.toFixed(kb, ~digits=0) ++ "KB"
    }
  } else {
    ""
  }
}

let formatBadge = format => {
  switch format {
  | "WEBP" => ("text-orange-600 bg-orange-50", "WEBP")
  | "PNG" => ("text-indigo-600 bg-indigo-50", "PNG")
  | "JPEG" | "JPG" => ("text-blue-600 bg-blue-50", "JPG")
  | other => ("text-slate-600 bg-slate-50", other)
  }
}

let describeFileMeta = (scene: Types.scene): fileMetaDisplay => {
  let (format, size) = switch scene.file {
  | Url(url) =>
    let cleanUrl = UrlUtils.stripQueryAndFragment(url)
    let pieces = cleanUrl->String.split(".")
    let ext = pieces->Belt.Array.get(Belt.Array.length(pieces) - 1)->Option.getOr("JPG")
    (ext->String.toUpperCase, 0.0)
  | Blob(b) =>
    let mime = BrowserBindings.Blob.type_(b)
    let ext = mime->String.split("/")->Belt.Array.get(1)->Option.getOr("JPG")
    (ext->String.toUpperCase, BrowserBindings.Blob.size(b))
  | File(f) =>
    let mime = BrowserBindings.File.type_(f)
    let ext = mime->String.split("/")->Belt.Array.get(1)->Option.getOr("JPG")
    (ext->String.toUpperCase, BrowserBindings.File.size(f))
  }

  let (badgeColor, formatLabel) = formatBadge(format)
  {
    badgeColor,
    formatLabel,
    formattedSize: formatBytes(size),
  }
}

let fallbackSceneFileName = (scene: Types.scene) => {
  switch scene.file {
  | Url(url) => UrlUtils.getFileNameFromUrl(url)
  | _ => ""
  }
}

let resolveTooltipName = (scene: Types.scene) => {
  let fallbackName = fallbackSceneFileName(scene)
  let candidate = switch scene.originalFile {
  | Some(File(f)) => BrowserBindings.File.name(f)
  | Some(Url(url)) =>
    let name = UrlUtils.getFileNameFromUrl(url)
    if name != "" {
      name
    } else {
      fallbackName
    }
  | _ => fallbackName
  }

  if candidate == "" {
    if fallbackName == "" {
      scene.name
    } else {
      fallbackName
    }
  } else {
    candidate
  }
}

let describe = (scene: Types.scene): displayInfo => {
  {
    tooltipName: resolveTooltipName(scene),
    quality: describeQuality(scene),
    fileMeta: describeFileMeta(scene),
  }
}
