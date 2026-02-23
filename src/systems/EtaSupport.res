/* src/systems/EtaSupport.res */

let clampFloat = (~value: float, ~minValue: float, ~maxValue: float): float =>
  if value < minValue {
    minValue
  } else if value > maxValue {
    maxValue
  } else {
    value
  }

let rec combineEtaCandidates = (
  ~a: option<float>,
  ~b: option<float>,
  ~c: option<float>,
  ~d: option<float>=?,
) => {
  switch d {
  | Some(dv) =>
    switch (a, b, c) {
    | (Some(av), Some(bv), Some(cv)) =>
      let values = [av, bv, cv, dv]->Belt.Array.keep(v => v > 0.0)
      switch Belt.Array.length(values) {
      | 4 =>
        let sorted = Belt.Array.copy(values)
        Belt.SortArray.stableSortInPlaceBy(sorted, (x, y) => compare(x, y))
        Some((Belt.Array.getExn(sorted, 1) +. Belt.Array.getExn(sorted, 2)) /. 2.0)
      | _ => combineEtaCandidates(~a, ~b, ~c)
      }
    | _ => combineEtaCandidates(~a, ~b, ~c)
    }
  | None =>
    switch (a, b, c) {
    | (Some(x), Some(y), Some(z)) =>
      let minV = Math.min(x, Math.min(y, z))
      let maxV = Math.max(x, Math.max(y, z))
      Some(x +. y +. z -. minV -. maxV) // median-of-three
    | (Some(x), Some(y), None) | (Some(x), None, Some(y)) | (None, Some(x), Some(y)) =>
      Some((x +. y) /. 2.0)
    | (Some(x), None, None) | (None, Some(x), None) | (None, None, Some(x)) => Some(x)
    | _ => None
    }
  }
}

let formatEta = (etaSeconds: int): string => {
  let clamped = if etaSeconds > 0 {
    etaSeconds
  } else {
    0
  }
  let hours = clamped / 3600
  let remainderAfterHours = clamped - hours * 3600
  let minutes = remainderAfterHours / 60
  let seconds = remainderAfterHours - minutes * 60

  if hours > 0 {
    Belt.Int.toString(hours) ++ "h " ++ Belt.Int.toString(minutes) ++ "m"
  } else if minutes > 0 {
    Belt.Int.toString(minutes) ++ "m " ++ Belt.Int.toString(seconds) ++ "s"
  } else {
    Belt.Int.toString(seconds) ++ "s"
  }
}

let parseEtaTokenSeconds = (token: string, suffix: string): option<int> => {
  if !String.endsWith(token, suffix) {
    None
  } else {
    let suffixLen = String.length(suffix)
    let raw = String.slice(token, ~start=0, ~end=String.length(token) - suffixLen)->String.trim
    Belt.Int.fromString(raw)
  }
}

let parseEtaTextSeconds = (text: string): option<int> => {
  let normalized = text->String.trim->String.toLowerCase
  let raw = if String.startsWith(normalized, "eta ") {
    String.slice(normalized, ~start=4, ~end=String.length(normalized))
  } else {
    normalized
  }

  if raw == "" {
    None
  } else {
    let tokens = raw->String.split(" ")->Belt.Array.keep(t => t != "")
    let hours = ref(0)
    let minutes = ref(0)
    let seconds = ref(0)

    tokens->Belt.Array.forEach(token => {
      switch (
        parseEtaTokenSeconds(token, "h"),
        parseEtaTokenSeconds(token, "m"),
        parseEtaTokenSeconds(token, "s"),
      ) {
      | (Some(h), _, _) => hours := h
      | (_, Some(m), _) => minutes := m
      | (_, _, Some(s)) => seconds := s
      | _ => ()
      }
    })

    let total = hours.contents * 3600 + minutes.contents * 60 + seconds.contents
    if total > 0 {
      Some(total)
    } else {
      None
    }
  }
}

let dispatchEtaToast = (
  ~id: string,
  ~contextOperation: string,
  ~prefix: string,
  ~etaSeconds: int,
  ~details: option<string>=None,
  ~createdAt: float=Date.now(),
  (),
): unit => {
  NotificationManager.dispatch({
    id,
    importance: NotificationTypes.Warning,
    context: NotificationTypes.Operation(contextOperation),
    message: prefix ++ ": ETA " ++ formatEta(etaSeconds),
    details,
    action: None,
    duration: 0,
    dismissible: true,
    createdAt,
  })
}

let dispatchCalculatingEtaToast = (
  ~id: string,
  ~contextOperation: string,
  ~prefix: string,
  ~details: option<string>=None,
  ~createdAt: float=Date.now(),
  (),
): unit => {
  NotificationManager.dispatch({
    id,
    importance: NotificationTypes.Warning,
    context: NotificationTypes.Operation(contextOperation),
    message: prefix ++ ": Calculating ETA...",
    details,
    action: None,
    duration: 0,
    dismissible: true,
    createdAt,
  })
}

let dismissEtaToast = (id: string): unit => NotificationManager.dismiss(id)
