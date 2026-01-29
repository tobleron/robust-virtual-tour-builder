/* src/utils/ProgressBar.res */

open ReBindings

let progressAutoHideTimeout = ref(None)

let setTextContent = (el: Dom.element, text: string) => {
  Dom.setTextContent(el, text)
}

let setStyleProperty = (el: Dom.element, prop: string, val: string) => {
  Dom.setProperty(el, prop, val)
}

let handleAutoHide = (ui: Dom.element, uploadLabel: option<Dom.element>) => {
  let id = Window.setTimeout(() => {
    Dom.setOpacity(ui, "0")
    setStyleProperty(ui, "transform", "translateY(-10px)")

    let _ = Window.setTimeout(() => {
      Dom.setDisplay(ui, "none")
      Dom.setOpacity(ui, "1")
      setStyleProperty(ui, "transform", "translateY(0)")
      uploadLabel->Belt.Option.forEach(l => Dom.setDisplay(l, "flex"))
    }, 300)
    progressAutoHideTimeout := None
  }, Constants.progressBarAutoHideDelay)
  progressAutoHideTimeout := Some(id)
}

let updateProgressBar = (
  percent: float,
  text: string,
  ~visible: bool=true,
  ~title: option<string>=?,
  (),
) => {
  /* Clear timeout */
  switch progressAutoHideTimeout.contents {
  | Some(id) =>
    Window.clearTimeout(id)
    progressAutoHideTimeout := None
  | None => ()
  }

  let processingUi = Dom.getElementById("processing-ui")->Nullable.toOption
  let progressBar = Dom.getElementById("progress-bar")->Nullable.toOption
  let progressTitle = Dom.getElementById("progress-title")->Nullable.toOption
  let progressPercentage = Dom.getElementById("progress-percentage")->Nullable.toOption
  let progressTextContent = Dom.getElementById("progress-text-content")->Nullable.toOption
  let progressSpinner = Dom.getElementById("progress-spinner")->Nullable.toOption
  let uploadLabel = Dom.getElementById("upload-label")->Nullable.toOption

  switch (processingUi, progressBar) {
  | (Some(ui), Some(bar)) =>
    if !visible {
      Dom.setOpacity(ui, "0")
      setStyleProperty(ui, "transform", "translateY(-10px)")

      let _ = Window.setTimeout(() => {
        Dom.setDisplay(ui, "none")
        Dom.setOpacity(ui, "1")
        setStyleProperty(ui, "transform", "translateY(0)")
      }, 300)

      uploadLabel->Belt.Option.forEach(l => Dom.setDisplay(l, "flex"))
    } else {
      Dom.setDisplay(ui, "block")
      Dom.setTransition(ui, "opacity 0.3s ease, transform 0.3s ease")
      uploadLabel->Belt.Option.forEach(l => Dom.setDisplay(l, "none"))

      let clampedPercent = Math.max(0.0, Math.min(100.0, percent))
      setStyleProperty(bar, "width", Float.toString(clampedPercent) ++ "%")

      Logger.trace(
        ~module_="ProgressBar",
        ~message="PROGRESS_UPDATE",
        ~data=Logger.castToJson({"percent": clampedPercent, "text": text}),
        (),
      )

      progressPercentage->Belt.Option.forEach(el => {
        setTextContent(el, Float.toString(Math.round(clampedPercent)) ++ "%")
      })

      /* Update Text */
      if text != "" {
        progressTextContent->Belt.Option.forEach(el => setTextContent(el, text))
      }

      switch title {
      | Some(t) => progressTitle->Belt.Option.forEach(el => setTextContent(el, t))
      | None => ()
      }

      /* Spinner */
      progressSpinner->Belt.Option.forEach(el => {
        Dom.setOpacity(
          el,
          if clampedPercent >= 100.0 {
            "0"
          } else {
            "1"
          },
        )
      })

      /* Scroll sidebar */
      switch Dom.querySelector(Dom.documentBody, ".sidebar-content")->Nullable.toOption {
      | Some(sidebar) =>
        Dom.scrollTo(
          sidebar,
          {
            "top": 0,
            "behavior": "smooth",
          },
        )
      | None => ()
      }

      /* Auto Hide */
      if clampedPercent >= 100.0 {
        handleAutoHide(ui, uploadLabel)
      }
    }
  | _ => () /* Elements missing */
  }
}
