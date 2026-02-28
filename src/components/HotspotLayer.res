/* src/components/HotspotLayer.res */
open ReBindings

module StaticDiv = {
  @react.component
  let make = (~id, ~className=?, ~style=?, ~children=?) => {
    <div id ?className ?style> {children->Option.getOr(React.null)} </div>
  }
}

@module("react")
external memoCustom: (
  React.component<'props>,
  ('props, 'props) => bool,
) => React.component<'props> = "memo"

// Memoize with 'true' to never re-render after mount
let staticDivComp = memoCustom(StaticDiv.make, (_, _) => true)
module MemoStaticDiv = {
  let make = staticDivComp
}

module StaticSvg = {
  @react.component
  let make = (~id, ~className=?, ~style=?, ~children=?) => {
    <svg id ?className ?style> {children->Option.getOr(React.null)} </svg>
  }
}
let staticSvgComp = memoCustom(StaticSvg.make, (_, _) => true)
module MemoStaticSvg = {
  let make = staticSvgComp
}

@react.component
let make = React.memo(() => {
  let uiSlice = AppContext.useUiSlice()
  let isTeasing = uiSlice.isTeasing

  React.useEffect0(() => {
    Logger.info(~module_="HotspotLayer", ~message="INITIALIZING_CLICK_LISTENER", ())
    let container = Dom.getElementById("viewer-hotspot-lines")
    switch Nullable.toOption(container) {
    | Some(svg) =>
      let handleContainerClick = ev => {
        let target = Dom.target(ev)
        let id = switch Nullable.toOption(Dom.getAttribute(target, "id")) {
        | Some(id) => Some(id)
        | None =>
          // Resolve nested SVG targets by climbing to the nearest arrow node.
          Dom.closest(target, "[id^='arrow_']")
          ->Nullable.toOption
          ->Option.flatMap(el => Dom.getAttribute(el, "id")->Nullable.toOption)
        }

        switch id {
        | Some(idString) if idString->String.startsWith("arrow_") =>
          Dom.stopPropagation(ev)
          let linkId = idString->String.slice(~start=6)
          Logger.info(
            ~module_="HotspotLayer",
            ~message="ARROW_CLICKED",
            ~data=Some({"linkId": linkId}),
            (),
          )
          EventBus.dispatch(PreviewLinkId(linkId))
        | _ => ()
        }
      }
      Dom.addEventListener(svg, "click", handleContainerClick)
      Some(() => Dom.removeEventListener(svg, "click", handleContainerClick))
    | None => None
    }
  })

  if isTeasing {
    React.null
  } else {
    <>
      <MemoStaticDiv.make
        id="viewer-center-indicator"
        className="absolute top-1/2 left-1/2 w-3 h-3 -translate-x-1/2 -translate-y-1/2 border-2 border-brand-gold rounded-full z-[5001] pointer-events-none hidden"
      />

      <MemoStaticSvg.make
        id="viewer-hotspot-lines"
        className="absolute inset-0 w-full h-full z-[5000] pointer-events-none"
      />

      <ReactHotspotLayer />
    </>
  }
})
