/* src/systems/ExifReportGeneratorLogicGroups.res */

open ReBindings
open SharedTypes
open ExifReportGeneratorTypes
open ExifReportGeneratorUtils

let analyzeGroups = (exifResults, lines) => {
  // Group by camera signature
  let groups = Dict.make()
  Belt.Array.forEach(exifResults, r => {
    let sig = ExifParser.getCameraSignature(r.exifData)
    switch Dict.get(groups, sig) {
    | Some(files) => {
        let _ = Array.push(files, r)
      }
    | None => Dict.set(groups, sig, [r])
    }
  })

  Belt.Array.forEach(Dict.toArray(groups), ((signature, files)) => {
    let firstExif = switch Belt.Array.get(files, 0) {
    | Some(r) => r.exifData
    | None => defaultExif // Should not happen
    }

    let dashCount = maxInt(0, 60 - String.length(signature))
    let dashes = String.repeat("─", dashCount)
    let _ = Array.push(lines, `  ┌─ ${signature} ─${dashes}`)
    let _ = Array.push(lines, `  │  Images: ${Belt.Int.toString(Array.length(files))}`)

    switch firstExif.focalLength->Nullable.toOption {
    | Some(fl) => {
        let _ = Array.push(lines, `  │  Focal Length: ${Float.toFixed(fl, ~digits=1)}mm`)
      }
    | None => ()
    }

    switch firstExif.aperture->Nullable.toOption {
    | Some(ap) => {
        let _ = Array.push(lines, `  │  Aperture: f/${Float.toFixed(ap, ~digits=1)}`)
      }
    | None => ()
    }

    switch firstExif.iso->Nullable.toOption {
    | Some(iso) => {
        let _ = Array.push(lines, `  │  ISO: ${Belt.Int.toString(iso)}`)
      }
    | None => ()
    }

    switch firstExif.dateTime->Nullable.toOption {
    | Some(dt) => {
        let _ = Array.push(lines, `  │  Capture Period: ${dt}`)
      }
    | None => ()
    }

    let _ = Array.push(lines, `  │`)
    let _ = Array.push(lines, `  │  Files:`)
    Belt.Array.forEach(files, r => {
      let _ = Array.push(lines, `  │    • ${r.filename}`)
    })
    let _ = Array.push(lines, `  └${String.repeat("─", 76)}`)
    let _ = Array.push(lines, "")
  })
}

let listIndividualFiles = (exifResults, lines) => {
  Belt.Array.forEach(exifResults, r => {
    let hasGPS = switch r.exifData.gps->Nullable.toOption {
    | Some(_) => "✓ GPS"
    | None => "✗ No GPS"
    }

    let hasCamera = {
      let make = switch r.exifData.make->Nullable.toOption {
      | Some(m) => m
      | None => ""
      }
      let model = switch r.exifData.model->Nullable.toOption {
      | Some(m) => m
      | None => ""
      }
      let combined = String.trim(make ++ " " ++ model)
      if combined == "" {
        "Unknown Device"
      } else {
        combined
      }
    }

    let qScore = `| Quality: ${Float.toFixed(r.qualityData.score, ~digits=1)}/10`

    let _ = Array.push(lines, `  ${r.filename}`)
    let _ = Array.push(lines, `    └─ ${hasCamera} | ${hasGPS} ${qScore}`)

    switch r.qualityData.analysis->Nullable.toOption {
    | Some(analysis) => {
        let _ = Array.push(lines, `       Note: ${analysis}`)
      }
    | None => ()
    }
  })
}
