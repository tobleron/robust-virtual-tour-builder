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
// Helper to generate consistent slugs
let toSlug = (label, maxLength) => {
  sanitizeName(label, ~maxLength)
    ->String.replaceRegExp(/[\s-]+/g, "_")
    ->String.replaceRegExp(/[^a-z0-9_]/gi, "")
    ->String.toLowerCase
}

/**
 * Attempts to extract the ORIGINAL base name from a potentially computed filename.
 * If the current name matches the pattern "Index_Label_BaseName", it returns BaseName.
 * Otherwise, it returns the current name (stripped of extension).
 */
let recoverBaseName = (currentName, currentLabel) => {
  let nameWithoutExt = UrlUtils.stripExtension(currentName)

  if currentLabel == "" {
    nameWithoutExt
  } else {
    let slug = toSlug(currentLabel, 200)
    // Match pattern: XX_slug_BASENAME
    // usage of %raw for regex capture which is simpler than ReBindings here
    let pattern = "^\\d{2}_" ++ slug ++ "_(.+)$"
    let match = %raw(`(str, p) => {
        try {
            const m = str.match(new RegExp(p));
            return m ? m[1] : null;
        } catch (e) { return null; }
    }`)(nameWithoutExt, pattern)

    switch Nullable.toOption(match) {
    | Some(base) => base
    | None => nameWithoutExt
    }
  }
}

// Helper to extract base name from ID (centralized logic)
let getBaseNameFromId = (id) => {
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
let computeSceneFilename = (index, label, baseName) => {
  let prefix = Belt.Int.toString(index + 1)->padStart(2, "0")
  if label == "" {
    prefix ++ "_" ++ baseName ++ ".webp"
  } else {
    let baseSlug = toSlug(label, 200)
    let sanitizedBase = toSlug(baseName, 200)

    // Avoid duplication if label already contains the base name (e.g. "Kitchen_123" + "123")
    if baseSlug == sanitizedBase || String.endsWith(baseSlug, "_" ++ sanitizedBase) {
      prefix ++ "_" ++ baseSlug ++ ".webp"
    } else {
      prefix ++ "_" ++ baseSlug ++ "_" ++ baseName ++ ".webp"
    }
  }
}

// Types for validation
type hotspot = {target: string}
type scene = {
  name: string,
  hotspots: array<hotspot>,
}
type state = {scenes: array<scene>}

type integrityResult = {
  totalHotspots: int,
  orphanedLinks: int,
  details: array<{"sourceScene": string, "targetMissing": string}>,
}

/**
 * Perform a structural integrity check on a tour state.
 */
let validateTourIntegrity = (state: state) => {
  let sceneNames = state.scenes->Belt.Array.map(s => s.name)->Belt.Set.String.fromArray
  let totalHotspots = ref(0)
  let orphanedLinks = ref(0)
  let details = []

  state.scenes->Belt.Array.forEach(scene => {
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
