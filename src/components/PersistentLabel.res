/* src/components/PersistentLabel.res */
open Types

let deriveSceneSequenceBySceneId = (scenes: array<scene>): Belt.Map.String.t<int> => {
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

    let sequenceBySceneId = ref(Belt.Map.String.empty)

    scenes
    ->Belt.Array.get(0)
    ->Option.forEach(scene =>
      sequenceBySceneId :=
        sequenceBySceneId.contents->Belt.Map.String.set(
          scene.id,
          Constants.Scene.Sequence.startSceneNumber,
        )
    )

    HotspotSequence.deriveOrderedHotspots(~state=stateForSequence)->Belt.Array.forEach(link => {
      switch sequenceBySceneId.contents->Belt.Map.String.get(link.sceneId) {
      | Some(existing) =>
        if link.sequence < existing {
          sequenceBySceneId :=
            sequenceBySceneId.contents->Belt.Map.String.set(link.sceneId, link.sequence)
        }
      | None =>
        sequenceBySceneId :=
          sequenceBySceneId.contents->Belt.Map.String.set(link.sceneId, link.sequence)
      }

      let targetSeq = link.sequence + 1
      switch sequenceBySceneId.contents->Belt.Map.String.get(link.targetSceneId) {
      | Some(existing) =>
        if targetSeq < existing {
          sequenceBySceneId :=
            sequenceBySceneId.contents->Belt.Map.String.set(link.targetSceneId, targetSeq)
        }
      | None =>
        sequenceBySceneId :=
          sequenceBySceneId.contents->Belt.Map.String.set(link.targetSceneId, targetSeq)
      }
    })

    sequenceBySceneId.contents
  }
}

@react.component
let make = React.memo((~activeIndex: int, ~scenes: array<scene>) => {
  let sequenceBySceneId = React.useMemo1(() => deriveSceneSequenceBySceneId(scenes), [scenes])

  let (currentLabel, currentSeq, isVisible) = if activeIndex >= 0 {
    switch Belt.Array.get(scenes, activeIndex) {
    | Some(s) =>
      let trimmed = s.label->String.trim
      if trimmed == "" || trimmed->String.toLowerCase->String.includes("untagged") {
        ("unlabeled", None, false)
      } else {
        (s.label, sequenceBySceneId->Belt.Map.String.get(s.id), true)
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
