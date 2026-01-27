/* src/components/PersistentLabel.res */
open Types

@react.component
let make = React.memo((~activeIndex: int, ~scenes: array<scene>) => {
  let currentLabel = if activeIndex >= 0 {
    switch Belt.Array.get(scenes, activeIndex) {
    | Some(s) => s.label
    | None => ""
    }
  } else {
    ""
  }

  <div
    id="v-scene-persistent-label"
    className={"viewer-persistent-label " ++ if currentLabel != "" {
      "state-visible"
    } else {
      "state-hidden"
    }}
  >
    {React.string("# " ++ currentLabel)}
  </div>
})
