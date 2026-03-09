/* src/systems/Api/MediaApiProcessFull.res */

let clamp = (~value: float, ~minValue: float, ~maxValue: float) =>
  if value < minValue {
    minValue
  } else if value > maxValue {
    maxValue
  } else {
    value
  }

let updateSpacing = (
  ~nextSpacingMs: float,
  ~reason: string,
  ~spacingRef: ref<float>,
  ~latencyRef: ref<float>,
) => {
  let bounded = clamp(
    ~value=nextSpacingMs,
    ~minValue=Constants.Media.processFullSpacingMinMs,
    ~maxValue=Constants.Media.processFullSpacingMaxMs,
  )
  let previous = spacingRef.contents
  if bounded != previous {
    spacingRef := bounded
    Logger.info(
      ~module_="MediaApi",
      ~message="PROCESS_FULL_AUTOTUNE_SPACING_UPDATED",
      ~data=Some({
        "reason": reason,
        "fromMs": Float.toFixed(previous, ~digits=0),
        "toMs": Float.toFixed(bounded, ~digits=0),
        "emaLatencyMs": Float.toFixed(latencyRef.contents, ~digits=0),
      }),
      (),
    )
  }
}

let updateLatencyEma = (~sampleMs: float, ~latencyRef: ref<float>) => {
  if latencyRef.contents <= 0.0 {
    latencyRef := sampleMs
  } else {
    let alpha = Constants.Media.processFullLatencyEmaAlpha
    latencyRef := (1.0 -. alpha) *. latencyRef.contents +. alpha *. sampleMs
  }
}

let noteProcessFullSuccess = (
  ~durationMs: float,
  ~attempts: int,
  ~spacingRef: ref<float>,
  ~latencyRef: ref<float>,
  ~stableSuccessRef: ref<int>,
) => {
  updateLatencyEma(~sampleMs=durationMs, ~latencyRef)

  if attempts > 1 {
    stableSuccessRef := 0
    updateSpacing(
      ~nextSpacingMs=spacingRef.contents +. Constants.Media.processFullSpacingStepUpMs,
      ~reason="retry-success",
      ~spacingRef,
      ~latencyRef,
    )
  } else {
    stableSuccessRef := stableSuccessRef.contents + 1
    let reachedWindow =
      stableSuccessRef.contents >= Constants.Media.processFullAutotuneSuccessWindow
    if reachedWindow {
      stableSuccessRef := 0
      updateSpacing(
        ~nextSpacingMs=spacingRef.contents -. Constants.Media.processFullSpacingStepDownMs,
        ~reason="stable-success-window",
        ~spacingRef,
        ~latencyRef,
      )
    }
  }
}

let reserveProcessFullSlot = async (
  ~nextAllowedAtRef: ref<float>,
  ~spacingRef: ref<float>,
  ~sleepMs: int => Promise.t<unit>,
) => {
  let now = Date.now()
  let slotAt = if nextAllowedAtRef.contents > now {
    nextAllowedAtRef.contents
  } else {
    now
  }
  nextAllowedAtRef := slotAt +. spacingRef.contents
  let waitMs = slotAt -. now
  if waitMs > 1.0 {
    let _ = await sleepMs(Belt.Float.toInt(waitMs))
  } else {
    ()
  }
}

let parseRateLimitedSeconds = (msg: string): option<int> => {
  if String.startsWith(msg, "RateLimited: ") {
    let parts = String.split(msg, ": ")
    if Array.length(parts) == 2 {
      parts[1]->Option.flatMap(Belt.Int.fromString)
    } else {
      None
    }
  } else {
    None
  }
}

let applyProcessFullBackoff = (
  ~seconds: int,
  ~nextAllowedAtRef: ref<float>,
  ~spacingRef: ref<float>,
  ~latencyRef: ref<float>,
  ~stableSuccessRef: ref<int>,
) => {
  let resumeAt = Date.now() +. Belt.Int.toFloat(seconds * 1000)
  if resumeAt > nextAllowedAtRef.contents {
    nextAllowedAtRef := resumeAt
  }
  stableSuccessRef := 0
  updateSpacing(
    ~nextSpacingMs=spacingRef.contents +. Constants.Media.processFullSpacingStepUpMs,
    ~reason="rate-limited",
    ~spacingRef,
    ~latencyRef,
  )
}
