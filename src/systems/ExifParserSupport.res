open ReBindings
open SharedTypes
open Types

let loadTags = async (~loadFile, ~loadBlob, file: Types.file) => {
  switch file {
  | File(f) => await loadFile(f)
  | Blob(b) => await loadBlob(b)
  | Url(url) =>
    let res = await Fetch.fetchSimple(url)
    let blob = await Fetch.blob(res)
    await loadBlob(blob)
  }
}

let normalizeLookupKey = key => String.toLowerCase(String.replaceRegExp(key, /\s/g, ""))

let getValue = (~keys, ~lookupDescription, key) => {
  switch lookupDescription(key) {
  | Some(description) => description
  | None => {
      let normalizedSearch = normalizeLookupKey(key)
      let foundKey = keys->Belt.Array.getBy(k => {
        let normalizedK = normalizeLookupKey(k)
        normalizedK == normalizedSearch || String.includes(normalizedK, normalizedSearch)
      })

      switch foundKey {
      | Some(foundKey) => lookupDescription(foundKey)->Option.getOr("")
      | None => ""
      }
    }
  }
}

let getFloat = (~getValue, key) => {
  let v = getValue(key)
  let step1 = v->String.replaceRegExp(/,/g, ".")
  let cleaned = step1->String.replaceRegExp(/[^0-9.\-]/g, "")
  Belt.Float.fromString(cleaned)
}

let getInt = (~getValue, key) => {
  let v = getValue(key)
  let cleaned = v->String.replaceRegExp(/[^0-9-]/g, "")
  switch Belt.Int.fromString(cleaned) {
  | Some(i) => i
  | None => 0
  }
}

let buildPano = (~getValue, ~getFloat, ~getInt): gPanoMetadata => {
  let usePano = getValue("UsePanoramaViewer") == "True"

  {
    usePanoramaViewer: usePano,
    projectionType: getValue("ProjectionType"),
    poseHeadingDegrees: getFloat("PoseHeadingDegrees")->Option.getOr(0.0),
    posePitchDegrees: getFloat("PosePitchDegrees")->Option.getOr(0.0),
    poseRollDegrees: getFloat("PoseRollDegrees")->Option.getOr(0.0),
    croppedAreaImageWidthPixels: getInt("CroppedAreaImageWidthPixels"),
    croppedAreaImageHeightPixels: getInt("CroppedAreaImageHeightPixels"),
    fullPanoWidthPixels: getInt("FullPanoWidthPixels"),
    fullPanoHeightPixels: getInt("FullPanoHeightPixels"),
    croppedAreaLeftPixels: getInt("CroppedAreaLeftPixels"),
    croppedAreaTopPixels: getInt("CroppedAreaTopPixels"),
    initialViewHeadingDegrees: getInt("InitialViewHeadingDegrees"),
  }
}

let parseGpsCoordinate = (~getValue, valKey, refKey, xmpKey) => {
  let rawValues = [
    getValue(valKey),
    getValue(valKey->String.replaceRegExp(/([a-z])([A-Z])/g, "$1 $2")),
    getValue(xmpKey),
    getValue(String.toLowerCase(valKey)),
    getValue(String.replaceRegExp(valKey, /GPS/, "")),
  ]
  let rawVal = rawValues->Belt.Array.getBy(v => v != "")->Option.getOr("")

  let refValues = [
    getValue(refKey),
    getValue(refKey->String.replaceRegExp(/([a-z])([A-Z])/g, "$1 $2")),
  ]
  let ref = refValues->Belt.Array.getBy(v => v != "")->Option.getOr("")->String.toUpperCase

  if rawVal == "" {
    None
  } else {
    let parts =
      rawVal
      ->String.replaceRegExp(/[deg°'"\s]/g, " ")
      ->String.replaceRegExp(/,/g, " ")
      ->String.split(" ")
      ->Belt.Array.keep(s => String.length(String.trim(s)) > 0)

    let decimalDegrees = if Array.length(parts) >= 3 {
      let d = Belt.Float.fromString(parts[0]->Option.getOr("0"))->Option.getOr(0.0)
      let m = Belt.Float.fromString(parts[1]->Option.getOr("0"))->Option.getOr(0.0)
      let s = Belt.Float.fromString(parts[2]->Option.getOr("0"))->Option.getOr(0.0)
      Some(d +. m /. 60.0 +. s /. 3600.0)
    } else {
      let cleaned = rawVal->String.replaceRegExp(/[^0-9.\-]/g, "")
      Belt.Float.fromString(cleaned)
    }

    switch decimalDegrees {
    | Some(deg) =>
      let factor = if (
        ref == "S" || ref == "W" || String.includes(rawVal, "S") || String.includes(rawVal, "W")
      ) {
        -1.0
      } else {
        1.0
      }
      let finalVal = deg *. factor

      if finalVal >= -180.0 && finalVal <= 180.0 {
        Some(finalVal)
      } else {
        None
      }
    | None => None
    }
  }
}

let buildExif = (~getValue, ~getFloat, ~getInt, ~gps): exifMetadata => {
  {
    make: Nullable.fromOption(Some(getValue("Make"))),
    model: Nullable.fromOption(Some(getValue("Model"))),
    dateTime: Nullable.fromOption(Some(getValue("DateTime"))),
    gps,
    width: getInt("ImageWidth"),
    height: getInt("ImageHeight"),
    focalLength: Nullable.fromOption(getFloat("FocalLength")),
    aperture: Nullable.fromOption(getFloat("FNumber")),
    iso: Nullable.fromOption(Some(getInt("ISOSpeedRatings"))),
  }
}
