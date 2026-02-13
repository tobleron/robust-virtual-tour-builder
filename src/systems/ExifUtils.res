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

  let selectedWords =
    Belt.Array.slice(words, ~offset=0, ~len=3)
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
  | Some(dt) => {
      let regex = RegExp.fromString("(\\d{4}):(\\d{2}):(\\d{2})\\s+(\\d{2}):(\\d{2})")
      switch RegExp.exec(regex, dt) {
      | Some(result) => {
          let captures = RegExp.Result.matches(result)
          let get = i => {
            switch Belt.Array.get(captures, i) {
            | Some(n) => n->Belt.Option.getWithDefault("")
            | None => ""
            }
          }
          if Array.length(captures) >= 5 {
            let year = get(0)
            let month = get(1)
            let day = get(2)
            let hour = get(3)
            let minute = get(4)
            // Short format DDMM_HHMM as per requirements
            let _ = year // Unused but captured
            Some(`${day}${month}_${hour}${minute}`)
          } else {
            None
          }
        }
      | None => None
      }
    }
  | None => None
  }

  let timestamp = switch timestampPart {
  | Some(ts) => ts
  | None => {
      let now = Date.make()
      let day = String.padStart(Belt.Int.toString(Date.getDate(now)), 2, "0")
      let month = String.padStart(Belt.Int.toString(Date.getMonth(now) + 1), 2, "0")
      // Short format DDMM_HHMM
      let hour = String.padStart(Belt.Int.toString(Date.getHours(now)), 2, "0")
      let minute = String.padStart(Belt.Int.toString(Date.getMinutes(now)), 2, "0")
      `${day}${month}_${hour}${minute}`
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
