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
      ->String.replaceRegExp(%re("/[\\x00-\\x1F\\x7F<>:\"\\/\\\\|?*]/g"), "_")
      // Replace multiple spaces/underscores with single underscore
      ->String.replaceRegExp(%re("/[\\s_]+/g"), "_")
      // Remove leading/trailing underscores
      ->String.replaceRegExp(%re("/^_+|_+$/g"), "")
      ->String.substring(~start=0, ~end=maxLength)

    if sanitized == "" {
      "Untitled"
    } else {
      sanitized
    }
  }
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
let computeSceneFilename = (index, label) => {
  let prefix = Belt.Int.toString(index + 1)->padStart(2, "0")
  if label == "" {
    prefix ++ "_unnamed.webp"
  } else {
    let sanitizedLabel = sanitizeName(label, ~maxLength=200)
    let baseSlug =
      sanitizedLabel
      ->String.replaceRegExp(%re("/[\\s-]+/g"), "_")
      ->String.replaceRegExp(%re("/[^a-z0-9_]/gi"), "")
      ->String.toLowerCase

    prefix ++ "_" ++ baseSlug ++ ".webp"
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
        let _ = Array.push(
          details,
          {"sourceScene": scene.name, "targetMissing": hs.target},
        )
      }
    })
  })

  {
    totalHotspots: totalHotspots.contents,
    orphanedLinks: orphanedLinks.contents,
    details: details,
  }
}
