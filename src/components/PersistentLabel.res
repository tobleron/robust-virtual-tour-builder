/* src/components/PersistentLabel.res */
open Types

let deriveSceneNumberBySceneId = (scenes: array<scene>): Belt.Map.String.t<int> =>
  if scenes->Belt.Array.length == 0 {
    Belt.Map.String.empty
  } else {
    let stateForSequence: state = {
      ...State.initialState,
      inventory: scenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, scene) =>
        acc->Belt.Map.String.set(scene.id, {scene, status: Active})
      ),
      sceneOrder: scenes->Belt.Array.map(scene => scene.id),
      activeIndex: 0,
    }
    HotspotSequence.deriveSceneNumberBySceneId(~state=stateForSequence)
  }

@react.component
let make = React.memo((~activeIndex: int, ~scenes: array<scene>) => {
  let sceneNumberBySceneId = React.useMemo1(() => deriveSceneNumberBySceneId(scenes), [scenes])

  let (currentLabel, currentSeq, isVisible) = if activeIndex >= 0 {
    switch Belt.Array.get(scenes, activeIndex) {
    | Some(s) =>
      let trimmed = s.label->String.trim
      if trimmed == "" || trimmed->String.toLowerCase->String.includes("untagged") {
        ("unlabeled", None, false)
      } else {
        (s.label, sceneNumberBySceneId->Belt.Map.String.get(s.id), true)
      }
    | None => ("", None, false)
    }
  } else {
    ("", None, false)
  }

  let sequenceText = switch currentSeq {
  | Some(seqNo) => "# " ++ Int.toString(seqNo)
  | None => "# -"
  }

  <div
    id="v-scene-persistent-label"
    className={"viewer-persistent-label " ++ if isVisible {
      "state-visible"
    } else {
      "state-hidden"
    }}
  >
    <span className="viewer-persistent-label-seq"> {React.string(sequenceText)} </span>
    <span className="viewer-persistent-label-name"> {React.string(currentLabel)} </span>
  </div>
})
