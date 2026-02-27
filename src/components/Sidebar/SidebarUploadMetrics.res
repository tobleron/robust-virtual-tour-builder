type etaRuntimeMetrics = {
  completed: int,
  total: int,
  inFlightUtilization: option<float>,
}

type exportRuntimeMetrics = {
  packagedScene: option<(int, int)>,
  uploadedMb: option<(float, float)>,
}

let primarySegment = (msg: string): string =>
  msg
  ->String.split("|")
  ->Belt.Array.get(0)
  ->Option.getOr("")
  ->String.trim

let parseSceneProgress = (primary: string): option<(int, int)> => {
  if !String.startsWith(primary, "Packaging scene ") {
    None
  } else {
    let sceneWord = primary->String.split("scene ")->Belt.Array.get(1)->Option.getOr("")
    let pair = sceneWord->String.split(" of ")
    switch (
      pair->Belt.Array.get(0)->Option.flatMap(Belt.Int.fromString),
      pair
      ->Belt.Array.get(1)
      ->Option.flatMap(raw =>
        raw
        ->String.split(".")
        ->Belt.Array.get(0)
        ->Option.getOr(raw)
        ->Belt.Int.fromString
      ),
    ) {
    | (Some(completed), Some(total)) if total > 0 => Some((completed, total))
    | _ => None
    }
  }
}

let parseUploadProgressMb = (primary: string): option<(float, float)> => {
  if !String.startsWith(primary, "Uploading: ") {
    None
  } else {
    let sentWord = primary->String.split("Uploading: ")->Belt.Array.get(1)->Option.getOr("")
    let pair = sentWord->String.split(" of ")
    switch (
      pair->Belt.Array.get(0)->Option.flatMap(Belt.Float.fromString),
      pair
      ->Belt.Array.get(1)
      ->Option.flatMap(raw =>
        raw
        ->String.split(" ")
        ->Belt.Array.get(0)
        ->Option.getOr(raw)
        ->Belt.Float.fromString
      ),
    ) {
    | (Some(sent), Some(total)) if total > 0.0 => Some((sent, total))
    | _ => None
    }
  }
}

let parseProcessingMetrics = (msg: string): option<etaRuntimeMetrics> => {
  let primary = primarySegment(msg)

  if !String.startsWith(primary, "Processing ") {
    None
  } else {
    let countToken = primary->String.split(" ")->Belt.Array.get(1)->Option.getOr("")
    let countParts = countToken->String.split("/")

    switch (
      countParts->Belt.Array.get(0)->Option.flatMap(Belt.Int.fromString),
      countParts->Belt.Array.get(1)->Option.flatMap(Belt.Int.fromString),
    ) {
    | (Some(completed), Some(total)) if total > 0 =>
      let inFlightUtilization =
        msg
        ->String.split("In-flight:")
        ->Belt.Array.get(1)
        ->Option.flatMap(raw => {
          let pair =
            raw
            ->String.split("MB")
            ->Belt.Array.get(0)
            ->Option.getOr("")
            ->String.trim
          let vals = pair->String.split("/")
          switch (
            vals->Belt.Array.get(0)->Option.flatMap(Belt.Float.fromString),
            vals->Belt.Array.get(1)->Option.flatMap(Belt.Float.fromString),
          ) {
          | (Some(current), Some(max)) if max > 0.0 => Some(current /. max)
          | _ => None
          }
        })
      Some({completed, total, inFlightUtilization})
    | _ => None
    }
  }
}

let parseExportMetrics = (msg: string): exportRuntimeMetrics => {
  let primary = primarySegment(msg)
  {packagedScene: parseSceneProgress(primary), uploadedMb: parseUploadProgressMb(primary)}
}
