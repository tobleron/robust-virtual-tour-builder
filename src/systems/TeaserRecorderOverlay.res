/* src/systems/TeaserRecorderOverlay.res */

open ReBindings

let getOrCreate = () => {
  let id = "teaser-overlay"
  switch Dom.getElementById(id)->Nullable.toOption {
  | Some(d) => d
  | None =>
    let div = Dom.createElement("div")
    Dom.setId(div, id)
    Dom.setAttribute(
      div,
      "style",
      "position:fixed;top:0;left:0;right:0;bottom:0;pointer-events:none;z-index:9999;background:black;opacity:0;transition:opacity 0.1s linear;",
    )
    Dom.appendChild(Dom.documentBody, div)
    div
  }
}

let setOpacity = (opacity: float) => {
  switch Dom.getElementById("teaser-overlay")->Nullable.toOption {
  | Some(d) =>
    Dom.setAttribute(
      d,
      "style",
      "position:fixed;top:0;left:0;right:0;bottom:0;pointer-events:none;z-index:9999;background:black;opacity:" ++
      Float.toString(opacity) ++ ";transition:opacity 0.1s linear;",
    )
  | None => ()
  }
}
