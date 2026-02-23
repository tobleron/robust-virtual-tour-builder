/* src/utils/TourLogic.res */

let padStart = (str, targetLength, padString) => {
  let len = String.length(str)
  if len >= targetLength {
    str
  } else {
    let padding = ref("")
    let needed = targetLength - len
    for _ in 1 to needed {
      padding.contents = padding.contents ++ padString
    }
    padding.contents ++ str
  }
}

/**
 * Sanitize scene/tour names to prevent filesystem issues
 */
let sanitizeName = (name, ~maxLength=255) => {
  if name == "" {
    "Untitled"
  } else {
    let sanitized =
      name
      ->String.trim
      // Remove control characters and invalid filesystem characters
      ->String.replaceRegExp(/[\x00-\x1F\x7F<>:\"\/\\|?*]/g, "_")
      // Replace multiple spaces/underscores with single underscore
      ->String.replaceRegExp(/[\s_]+/g, "_")
      // Remove leading/trailing underscores
      ->String.replaceRegExp(/^_+|_+$/g, "")
      ->String.substring(~start=0, ~end=maxLength)

    if sanitized == "" {
      "Untitled"
    } else {
      sanitized
    }
  }
}

/**
 * Check if a name is a placeholder/unknown name
 */
let isUnknownName = name => {
  let n = String.toLowerCase(name)
  n == "" ||
  String.includes(n, "unknown") ||
  n == "untitled" ||
  n == "untitled tour" ||
  n == "imported tour" ||
  n == "tour" ||
  n == "tour name" ||
  n == "virtual_tour" ||
  n == "virtual tour" ||
  n == "new tour" ||
  n == "new tour..." ||
  RegExp.test(/^tour_\d{4,6}_\d{4}$/i, name) ||
  // Matches Tour_DDMM_HHMM or Tour_DDMMYY_HHMM
  RegExp.test(/^saved_rmx_/i, name)
}

/**
 * Generate a concise, unique Link ID (e.g., A01, B99)
 */
let generateLinkId = (usedIds: Belt.Set.String.t) => {
  let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  let result = ref(None)

  for l in 0 to String.length(letters) - 1 {
    if Belt.Option.isNone(result.contents) {
      let charStr = String.substring(letters, ~start=l, ~end=l + 1)
      for n in 0 to 99 {
        if Belt.Option.isNone(result.contents) {
          let num = Belt.Int.toString(n)->padStart(2, "0")
          let candidate = charStr ++ num
          if !Belt.Set.String.has(usedIds, candidate) {
            result.contents = Some(candidate)
          }
        }
      }
    }
  }

  switch result.contents {
  | Some(id) => id
  | None => "Z" ++ Belt.Int.toString(Math.Int.floor(Math.random() *. 99.0))->padStart(2, "0")
  }
}

/**
 * Calculate the standardized filename for a scene based on its index and label.
 */
let toSlug = (label, maxLength) => {
  let initial = sanitizeName(label, ~maxLength)->String.replaceRegExp(/[\s-]+/g, "_")
  // Use a Unicode-aware regex to preserve letters and numbers from any script while stripping dangerous symbols.
  // \p{L} matches any Unicode letter, \p{N} any Unicode number.
  let slug = %raw(`(str) => {
    try {
      return str.normalize('NFKC').replace(/[^\p{L}\p{N}_]/gu, '');
    } catch (e) {
      // Fallback for environments without Unicode property escape support (extremely rare in modern browsers)
      return str.replace(/[^a-zA-Z0-9_]/g, '');
    }
  }`)(initial)

  if slug == "" {
    "Untagged"
  } else {
    slug
  }
}

/**
 * Attempts to extract the ORIGINAL base name from a potentially computed filename.
 * If the current name matches the pattern "Index_Label_BaseName", it returns BaseName.
 * Otherwise, it returns the current name (stripped of extension).
 */
let recoverBaseName = (currentName, currentLabel) => {
  let nameWithoutExt = UrlUtils.stripExtension(currentName)

  if currentLabel == "" {
    nameWithoutExt ++ ".webp"
  } else {
    let slug = toSlug(currentLabel, 200)

    // Try matching new format: Slug_Prefix_Base (e.g. "living_room_01_DSC001")
    let patternNew = "^" ++ slug ++ "_\\d{2}_(.+)$"
    let matchNew = %raw(`(str, p) => {
        try {
            const m = str.match(new RegExp(p));
            return m ? m[1] : null;
        } catch (e) { return null; }
    }`)(nameWithoutExt, patternNew)

    switch Nullable.toOption(matchNew) {
    | Some(base) => base
    | None =>
      // Try matching old format: Prefix_Slug_Base (e.g. "01_living_room_DSC001")
      let patternOld = "^\\d{2}_" ++ slug ++ "_(.+)$"
      let matchOld = %raw(`(str, p) => {
          try {
              const m = str.match(new RegExp(p));
              return m ? m[1] : null;
          } catch (e) { return null; }
      }`)(nameWithoutExt, patternOld)

      switch Nullable.toOption(matchOld) {
      | Some(base) => base
      | None => nameWithoutExt
      }
    }
  }
}

// Helper to extract base name from ID (centralized logic)
let getBaseNameFromId = id => {
  let raw = if String.startsWith(id, "legacy_") {
    String.substring(id, ~start=7, ~end=String.length(id))
  } else {
    id
  }
  UrlUtils.stripExtension(raw)
}

/**
 * Calculate the standardized filename for a scene based on its index, label, and original base name.
 */
let sequencePrefix = seq => Belt.Int.toString(seq)->padStart(3, "0")

let extractSequenceId = name => {
  switch String.split(name, "_")->Belt.Array.get(0) {
  | Some(prefix) if prefix != "" =>
    let chars = Js.String.split("", prefix)
    if chars->Belt.Array.every(c => c >= "0" && c <= "9") {
      Belt.Int.fromString(prefix)
    } else {
      None
    }
  | _ => None
  }
}

let normalizeSequenceId = seq =>
  if seq > 0 {
    seq
  } else {
    1
  }

let formatDisplayLabel = (scene: Types.scene) => {
  let label =
    if scene.label != "" {
      scene.label
    } else {
      UrlUtils.stripExtension(scene.name)
    }
  if scene.label != "" {
    let seq = normalizeSequenceId(scene.sequenceId)
    sequencePrefix(seq) ++ "_" ++ label
  } else {
    label
  }
}

let computeSceneFilename = (sequenceId, label, _baseName) => {
  let seq = normalizeSequenceId(sequenceId)
  let prefix = sequencePrefix(seq)
  if label == "" {
    prefix ++ "_Untagged.webp"
  } else {
    let slug = toSlug(label, 200)
    prefix ++ "_" ++ slug ++ ".webp"
  }
}

// Types for validation
type hotspot = {target: string}
type scene = {
  name: string,
  hotspots: array<hotspot>,
}
type integrityResult = {
  totalHotspots: int,
  orphanedLinks: int,
  details: array<{"sourceScene": string, "targetMissing": string}>,
}

/**
 * Perform a structural integrity check on a tour scene list.
 */
let validateTourIntegrity = (scenes: array<scene>) => {
  let sceneNames = scenes->Belt.Array.map(s => s.name)->Belt.Set.String.fromArray
  let totalHotspots = ref(0)
  let orphanedLinks = ref(0)
  let details = []

  scenes->Belt.Array.forEach(scene => {
    scene.hotspots->Belt.Array.forEach(hs => {
      totalHotspots.contents = totalHotspots.contents + 1
      if !Belt.Set.String.has(sceneNames, hs.target) {
        orphanedLinks.contents = orphanedLinks.contents + 1
        let _ = Array.push(details, {"sourceScene": scene.name, "targetMissing": hs.target})
      }
    })
  })

  {
    totalHotspots: totalHotspots.contents,
    orphanedLinks: orphanedLinks.contents,
    details,
  }
}
