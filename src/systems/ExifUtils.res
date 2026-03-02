/* src/systems/ExifUtils.res */

open ReBindings

let maxInt = (a, b) =>
  if a > b {
    a
  } else {
    b
  }

external castToDict: JSON.t => dict<JSON.t> = "%identity"
external castToJson: 'a => JSON.t = "%identity"

let cleanLocationWord = (w: string): string => {
  let clean = String.replaceRegExp(w, /[^\p{L}\p{N}]/gu, "")
  if String.length(clean) == 0 {
    ""
  } else {
    let first = String.charAt(clean, 0)->String.toUpperCase
    let rest = String.slice(clean, ~start=1, ~end=String.length(clean))->String.toLowerCase
    first ++ rest
  }
}

let extractLocationName = (addr: string): option<string> => {
  let words =
    String.split(addr, " ")
    ->Belt.Array.flatMap(w => String.split(w, ","))
    ->Belt.Array.keep(w => String.length(String.trim(w)) > 0)

  // Skip leading numeric words (like house numbers) to get to the actual location name
  let rec skipNumeric = (arr: array<string>) => {
    switch Belt.Array.get(arr, 0) {
    | Some(w) if RegExp.test(/^\d+$/, w) => skipNumeric(Belt.Array.sliceToEnd(arr, 1))
    | _ => arr
    }
  }

  let locationWords = skipNumeric(words)

  let selectedWords =
    Belt.Array.slice(locationWords, ~offset=0, ~len=3)
    ->Belt.Array.map(cleanLocationWord)
    ->Belt.Array.keep(w => String.length(w) > 0)

  if Array.length(selectedWords) > 0 {
    Some(Array.join(selectedWords, "_"))
  } else {
    None
  }
}

let generateProjectName = (address: option<string>, dateTime: option<string>): option<string> => {
  let locationPart = switch address {
  | Some(addr) => extractLocationName(addr)
  | None => None
  }

  let timestampPart = switch dateTime {
  | Some(dt) if String.length(dt) >= 16 => {
      // Input: YYYY:MM:DD HH:MM...
      let year = String.slice(dt, ~start=0, ~end=4)
      let month = String.slice(dt, ~start=5, ~end=7)
      let day = String.slice(dt, ~start=8, ~end=10)
      let hour = String.slice(dt, ~start=11, ~end=13)
      let minute = String.slice(dt, ~start=14, ~end=16)
      let shortYear = String.slice(year, ~start=2, ~end=4)
      Some(`${day}${month}${shortYear}_${hour}${minute}`)
    }
  | _ => None
  }

  let timestamp = switch timestampPart {
  | Some(ts) => ts
  | None => {
      let now = Date.make()
      let day = String.padStart(Belt.Int.toString(Date.getDate(now)), 2, "0")
      let month = String.padStart(Belt.Int.toString(Date.getMonth(now) + 1), 2, "0")
      let year = String.slice(Belt.Int.toString(Date.getFullYear(now)), ~start=2, ~end=4)
      let hour = String.padStart(Belt.Int.toString(Date.getHours(now)), 2, "0")
      let minute = String.padStart(Belt.Int.toString(Date.getMinutes(now)), 2, "0")
      `${day}${month}${year}_${hour}${minute}`
    }
  }

  let loc = switch locationPart {
  | Some(l) => l
  | None => "Tour"
  }

  Some(`${loc}_${timestamp}`)
}

let downloadExifReport = (content: string): string => {
  let timestamp =
    Date.toISOString(Date.make())
    ->String.replaceRegExp(/[:.]/g, "-")
    ->String.slice(~start=0, ~end=19)

  let filename = `EXIF_METADATA_${timestamp}.txt`
  let blob = Blob.newBlob([content], {"type": "text/plain;charset=utf-8"})
  let url = UrlUtils.safeCreateObjectURL(blob)

  let a = Dom.createElement("a")
  Dom.setAttribute(a, "href", url)
  Dom.setAttribute(a, "download", filename)
  Dom.appendChild(Dom.documentBody, a)
  Dom.click(a)
  Dom.removeElement(a)

  let _ = Window.setTimeout(() => URL.revokeObjectURL(url), 10000)
  filename
}
