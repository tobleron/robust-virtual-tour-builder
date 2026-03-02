/* src/components/PersistentLabel.res */
open Types

@react.component
let make = React.memo((~activeIndex: int, ~scenes: array<scene>) => {
  let (currentLabel, isVisible) = if activeIndex >= 0 {
    switch Belt.Array.get(scenes, activeIndex) {
    | Some(s) =>
      let trimmed = s.label->String.trim
      if trimmed == "" || trimmed->String.toLowerCase->String.includes("untagged") {
        ("unlabeled", false)
      } else {
        (s.label, true)
      }
    | None => ("", false)
    }
  } else {
    ("", false)
  }

  <div
    id="v-scene-persistent-label"
    className={"viewer-persistent-label " ++ if isVisible {
      "state-visible"
    } else {
      "state-hidden"
    }}
  >
    {React.string("# " ++ currentLabel)}
  </div>
})
