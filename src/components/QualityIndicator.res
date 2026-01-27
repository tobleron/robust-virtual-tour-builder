/* src/components/QualityIndicator.res */
open Types

@react.component
let make = React.memo((~activeIndex, ~scenes) => {
  let quality = if activeIndex >= 0 {
    switch Belt.Array.get(scenes, activeIndex) {
    | Some(s) => s.quality
    | None => None
    }
  } else {
    None
  }

  let badges = switch quality {
  | Some(qJson) =>
    let q = Schemas.castToQualityAnalysis(qJson)
    let b = []
    if q.isBlurry {
      let _ = Array.push(b, {"text": "BLURRY", "cls": "q-blurry"})
    } else if q.isSoft {
      let _ = Array.push(b, {"text": "SOFT", "cls": "q-soft"})
    }
    if q.isSeverelyDark {
      let _ = Array.push(b, {"text": "DARK", "cls": "q-dark"})
    } else if q.isDim {
      let _ = Array.push(b, {"text": "DIM", "cls": "q-dim"})
    }
    b
  | None => []
  }

  <div
    id="v-scene-quality-indicator"
    className={"absolute top-6 right-6 z-[6005] flex items-center gap-2 pointer-events-none transition-all duration-300 " ++ if (
      Array.length(badges) > 0
    ) {
      "opacity-100 translate-x-2 scale-95"
    } else {
      "opacity-0 translate-x-4 scale-90 hidden"
    }}
  >
    {badges
    ->Belt.Array.map(b => {
      <span key={b["text"]} className={`quality-badge ${b["cls"]}`}>
        {React.string(b["text"])}
      </span>
    })
    ->React.array}
  </div>
})
