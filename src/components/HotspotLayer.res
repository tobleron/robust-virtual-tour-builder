/* src/components/HotspotLayer.res */

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
  <>
    <MemoStaticDiv.make
      id="viewer-center-indicator"
      className="absolute top-1/2 left-1/2 w-3 h-3 -translate-x-1/2 -translate-y-1/2 border-2 border-brand-gold rounded-full z-[5001] pointer-events-none hidden"
    />

    <MemoStaticSvg.make
      id="viewer-hotspot-lines"
      className="absolute inset-0 w-full h-full z-[5000] pointer-events-none"
    />
  </>
})
