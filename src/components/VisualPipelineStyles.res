open ReBindings

module Styles = VisualPipelineLogic.Styles

let inject = () => {
  let existing = Dom.getElementById("visual-pipeline-styles")
  let style = switch Nullable.toOption(existing) {
  | Some(el) => el
  | None =>
    let el = Dom.createElement("style")
    Dom.setId(el, "visual-pipeline-styles")
    Dom.appendChild(Dom.head, el)
    el
  }
  Dom.setTextContent(style, Styles.styles)
}
