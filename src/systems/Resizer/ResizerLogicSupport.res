// @efficiency-role: domain-logic

open ReBindings

let computeNewName = (~suggestedName: option<string>, ~originalName: string): string =>
  switch suggestedName {
  | Some(name) => name
  | None =>
    let baseName = String.replaceRegExp(originalName, /\.[^/.]+$/, "")
    switch String.match(originalName, /IMG_\d{8}_(\d{6})_\d{2}_(\d{3})/) {
    | Some(captures) =>
      let hhmmss = switch Belt.Array.get(captures, 1) {
      | Some(Some(v)) => v
      | _ => ""
      }
      let sss = switch Belt.Array.get(captures, 2) {
      | Some(Some(v)) => v
      | _ => ""
      }
      if hhmmss != "" && sss != "" {
        let mmss = String.slice(hhmmss, ~start=2, ~end=6)
        "IMG_" ++ mmss ++ "_" ++ sss
      } else {
        baseName
      }
    | None =>
      switch String.match(originalName, /_(\d{6})_\d{2}_(\d{3})/) {
      | Some(captures) =>
        let p1 = switch Belt.Array.get(captures, 1) {
        | Some(Some(v)) => v
        | _ => ""
        }
        let p2 = switch Belt.Array.get(captures, 2) {
        | Some(Some(v)) => v
        | _ => ""
        }
        if p1 != "" && p2 != "" {
          p1 ++ "_" ++ p2
        } else {
          baseName
        }
      | None => baseName
      }
    }
  }

let extractResolutionFiles = zip => {
  let files = [("4k", "4k.webp"), ("2k", "2k.webp"), ("hd", "hd.webp")]
  let promises = Belt.Array.map(files, ((key, name)) => {
    let zipFile = JSZip.file(zip, name)
    switch Nullable.toOption(zipFile) {
    | Some(z) => JSZip.async(z, "blob")->Promise.then(b => Promise.resolve((key, Some(b))))
    | None => Promise.resolve((key, None))
    }
  })
  Promise.all(promises)
}

let buildResolutionBlobDict = results => {
  let d = Dict.make()
  Belt.Array.forEach(results, ((key, blobOpt)) => {
    switch blobOpt {
    | Some(b) => Dict.set(d, key, b)
    | None => ()
    }
  })
  d
}
