/* src/systems/TeaserPathfinder.res */

open Types

type transitionTarget = {
  yaw: float,
  pitch: float,
  targetName: string,
  timelineItemId: option<string>,
}

type arrivalView = {
  yaw: float,
  pitch: float,
}

type step = {
  idx: int,
  mutable transitionTarget: option<transitionTarget>,
  arrivalView: arrivalView,
}

/* Helper to find scene index by name */
let findSceneIndex = (scenes: array<Types.scene>, name: string) => {
  Belt.Array.getIndexBy(scenes, s => s.name == name)
}
let findSceneIndexById = (scenes: array<Types.scene>, id: string) => {
  Belt.Array.getIndexBy(scenes, s => s.id == id)
}

/* Helper to check if a scene is auto-forward */
let isAutoForward = (scene: Types.scene) => {
  scene.isAutoForward
}

/*
 * Helper to resolve the final destination if skipping auto-forward scenes.
 * Returns: (finalIndex, accumulatedArrivalView)
 * Note: The JS logic resets arrival view to 0,0 on skips, so we'll match that.
 */
let resolveAutoForwardChain = (scenes: array<Types.scene>, startIdx: int): int => {
  let currentIdx = ref(startIdx)
  let visited = ref(Belt.Set.Int.empty)
  let continue = ref(true)
  let loopCount = ref(0) // Safety break

  while continue.contents && loopCount.contents < 10 {
    loopCount := loopCount.contents + 1

    switch Belt.Array.get(scenes, currentIdx.contents) {
    | Some(scene) =>
      if isAutoForward(scene) {
        /* Mark as visited (conceptually for this chain) */
        visited := Belt.Set.Int.add(visited.contents, currentIdx.contents)

        /* Find next link to jump to */
        /* Priority: Unvisited non-return link? The JS logic just finds ANY link for auto-forward skipping?
            Actually JS says: "Find the next link from THIS auto-forward scene (Same priority: unvisited, non-return)"
            But for "Return Phase" it looks for RETURN links.
            
            Let's keep it simple: The walker logic below handles the *next* step. 
            This helper is specifically for "I have arrived at X, but X is auto-forward, where do I end up?"
 */

        /* JS Logic for Forward Phase Skip:
            const jumpLink = nextScene.hotspots.find(h => {
                const tIdx ... return tIdx !== -1 && !visited.has(tIdx);
            });
 */

        /* This implies the implementation needs to know if we are in forward or return phase 
            to pick the right kind of link to skip through.
            
            Actually, the JS logic inlines this inside the main loop. 
            I will replicate that structure closer rather than abstracting too early.
 */
        continue := false // Placeholder
      } else {
        continue := false
      }
    | None => continue := false
    }
  }
  currentIdx.contents
}

let getDefaultView = () => {yaw: 0.0, pitch: 0.0}

let getHotspotView = (hotspot: Types.hotspot): (float, float) => {
  switch hotspot.viewFrame {
  | Some(vf) => (vf.yaw, vf.pitch)
  | None => (hotspot.yaw, hotspot.pitch)
  }
}

let getArrivalView = (hotspot: Types.hotspot): arrivalView => {
  /* Priority: viewFrame > targetYaw/Pitch */
  switch hotspot.viewFrame {
  | Some(vf) => {yaw: vf.yaw, pitch: vf.pitch}
  | None =>
    switch (hotspot.targetYaw, hotspot.targetPitch) {
    | (Some(ty), Some(tp)) => {yaw: ty, pitch: tp}
    | _ => {yaw: 0.0, pitch: 0.0}
    }
  }
}

/* MAIN PATHFINDER */
let getWalkPath = (scenes: array<Types.scene>, skipAutoForward: bool) => {
  if Belt.Array.length(scenes) == 0 {
    []
  } else {
    let visited = Belt.MutableSet.Int.make()
    let path = []

    /* 0. Start at index 0 */
    let currentIdx = ref(0)
    Belt.MutableSet.Int.add(visited, 0)

    /* Determine initial view (matching JS logic) */
    let initialView = switch Belt.Array.get(scenes, 0) {
    | Some(firstScene) =>
      if Array.length(firstScene.hotspots) > 0 {
        let hOpt = Belt.Array.get(firstScene.hotspots, 0)
        switch hOpt {
        | Some(h) =>
          switch h.viewFrame {
          | Some(vf) => {yaw: vf.yaw, pitch: vf.pitch}
          | None => {yaw: 0.0, pitch: 0.0}
          }
        | None => {yaw: 0.0, pitch: 0.0}
        }
      } else {
        {yaw: 0.0, pitch: 0.0}
      }
    | None => {yaw: 0.0, pitch: 0.0}
    }

    let _ = Js.Array.push(
      {
        idx: 0,
        transitionTarget: None,
        arrivalView: initialView,
      },
      path,
    )

    /* PHASE 1: FORWARD */
    let continueForward = ref(true)
    let forwardSteps = ref(0)

    while continueForward.contents && forwardSteps.contents < 12 {
      forwardSteps := forwardSteps.contents + 1

      switch Belt.Array.get(scenes, currentIdx.contents) {
      | Some(currentScene) =>
        /* Find Forward Link */
        let forwardLinkOpt = Js.Array.find(h => {
          let isReturn = switch h.isReturnLink {
          | Some(v) => v
          | None => false
          }
          if isReturn {
            false
          } else {
            let tIdx = findSceneIndex(scenes, h.target)
            switch tIdx {
            | Some(idx) => !Belt.MutableSet.Int.has(visited, idx)
            | None => false
            }
          }
        }, currentScene.hotspots)

        switch forwardLinkOpt {
        | Some(link) =>
          let nextIdxRef = ref(findSceneIndex(scenes, link.target)->Belt.Option.getWithDefault(-1))
          if nextIdxRef.contents != -1 {
            /* Update previous step transition target */
            let lastStepOpt = Belt.Array.get(path, Array.length(path) - 1)
            switch lastStepOpt {
            | Some(lastStep) =>
              let (transYaw, transPitch) = getHotspotView(link)
              lastStep.transitionTarget = Some({
                yaw: transYaw,
                pitch: transPitch,
                targetName: link.target,
                timelineItemId: None,
              })
            | None => ()
            }

            /* Handle Skip Auto Forward */
            if skipAutoForward {
              let chainCounter = ref(0)
              let searching = ref(true)

              while searching.contents && chainCounter.contents < 10 {
                switch Belt.Array.get(scenes, nextIdxRef.contents) {
                | Some(nextScene) =>
                  if isAutoForward(nextScene) {
                    Belt.MutableSet.Int.add(visited, nextIdxRef.contents)
                    /* Find jump link */
                    let jumpLinkOpt = Js.Array.find(h => {
                      let tIdx = findSceneIndex(scenes, h.target)
                      switch tIdx {
                      | Some(idx) => !Belt.MutableSet.Int.has(visited, idx)
                      | None => false
                      }
                    }, nextScene.hotspots)

                    switch jumpLinkOpt {
                    | Some(jLink) =>
                      nextIdxRef :=
                        findSceneIndex(scenes, jLink.target)->Belt.Option.getWithDefault(-1)
                    | None => searching := false /* Dead end */
                    }
                  } else {
                    searching := false /* Found stable scene */
                  }
                | None => searching := false
                }
                chainCounter := chainCounter.contents + 1
              }
            }

            /* Determine Arrival View */
            /* JS: If skipped, default to 0. If direct, use link data. */
            let originalTargetIdx =
              findSceneIndex(scenes, link.target)->Belt.Option.getWithDefault(-2)
            let arrView = if nextIdxRef.contents == originalTargetIdx {
              getArrivalView(link)
            } else {
              getDefaultView()
            }

            let _ = Js.Array.push(
              {
                idx: nextIdxRef.contents,
                transitionTarget: None,
                arrivalView: arrView,
              },
              path,
            )

            Belt.MutableSet.Int.add(visited, nextIdxRef.contents)
            currentIdx := nextIdxRef.contents
          } else {
            continueForward := false
          }
        | None => continueForward := false
        }
      | None => continueForward := false
      }
    }

    /* PHASE 2: RETURN */
    let continueReturn = ref(true)
    let returnSteps = ref(0)

    while continueReturn.contents && returnSteps.contents < 12 {
      returnSteps := returnSteps.contents + 1

      switch Belt.Array.get(scenes, currentIdx.contents) {
      | Some(currentScene) =>
        let returnLinkOpt = Js.Array.find(h => {
          switch h.isReturnLink {
          | Some(true) => true
          | _ => false
          }
        }, currentScene.hotspots)

        switch returnLinkOpt {
        | Some(link) =>
          let nextIdxRef = ref(findSceneIndex(scenes, link.target)->Belt.Option.getWithDefault(-1))
          if nextIdxRef.contents != -1 {
            let lastStepOpt = Belt.Array.get(path, Array.length(path) - 1)
            switch lastStepOpt {
            | Some(lastStep) =>
              let (transYaw, transPitch) = getHotspotView(link)
              lastStep.transitionTarget = Some({
                yaw: transYaw,
                pitch: transPitch,
                targetName: link.target,
                timelineItemId: None,
              })
            | None => ()
            }

            let originalTargetIdx = nextIdxRef.contents

            /* Handle Skip Auto Forward (Return flavor) */
            if skipAutoForward {
              let chainCounter = ref(0)
              let searching = ref(true)

              let visitedInChain = Belt.MutableSet.Int.make()
              Belt.MutableSet.Int.add(visitedInChain, nextIdxRef.contents)

              while searching.contents && chainCounter.contents < 10 {
                switch Belt.Array.get(scenes, nextIdxRef.contents) {
                | Some(nextScene) =>
                  if isAutoForward(nextScene) {
                    /* Find RETURN jump link */
                    let jumpLinkOpt = Js.Array.find(h => {
                      let isRet = switch h.isReturnLink {
                      | Some(true) => true
                      | _ => false
                      }
                      if isRet {
                        let tIdx = findSceneIndex(scenes, h.target)
                        switch tIdx {
                        | Some(idx) => !Belt.MutableSet.Int.has(visitedInChain, idx)
                        | None => false
                        }
                      } else {
                        false
                      }
                    }, nextScene.hotspots)

                    switch jumpLinkOpt {
                    | Some(jLink) =>
                      let jIdx =
                        findSceneIndex(scenes, jLink.target)->Belt.Option.getWithDefault(-1)
                      if jIdx != -1 {
                        nextIdxRef := jIdx
                        Belt.MutableSet.Int.add(visitedInChain, jIdx)
                      } else {
                        searching := false
                      }
                    | None => searching := false
                    }
                  } else {
                    searching := false
                  }
                | None => searching := false
                }
                chainCounter := chainCounter.contents + 1
              }
            }

            let arrView = if nextIdxRef.contents == originalTargetIdx {
              /* For return links, JS logic says Priority: viewFrame > targetYaw */
              getArrivalView(link)
            } else {
              getDefaultView()
            }

            let _ = Js.Array.push(
              {
                idx: nextIdxRef.contents,
                transitionTarget: None,
                arrivalView: arrView,
              },
              path,
            )

            currentIdx := nextIdxRef.contents

            if currentIdx.contents == 0 {
              continueReturn := false
            }
          } else {
            continueReturn := false
          }
        | None => continueReturn := false
        }
      | None => continueReturn := false
      }
    }

    /* Cleanup Logic */
    /* 1. Filter remaining auto-forward if skipping */
    let finalPath = if skipAutoForward {
      Belt.Array.keep(path, step => {
        switch Belt.Array.get(scenes, step.idx) {
        | Some(s) => !isAutoForward(s)
        | None => false
        }
      })
    } else {
      path
    }

    /* 2. Dedupe adjacent */
    let deduped = Belt.Array.keepWithIndex(finalPath, (step, i) => {
      if i == 0 {
        true
      } else {
        switch Belt.Array.get(finalPath, i - 1) {
        | Some(prev) => step.idx != prev.idx
        | None => true
        }
      }
    })

    deduped
  }
}

let getTimelinePath = (
  timeline: array<Types.timelineItem>,
  scenes: array<Types.scene>,
  skipAutoForward: bool,
) => {
  let path = []

  Belt.Array.forEach(timeline, item => {
    let startIdxOpt = findSceneIndexById(scenes, item.sceneId)
    switch startIdxOpt {
    | Some(startSceneIdx) =>
      let scene = Belt.Array.getExn(scenes, startSceneIdx)

      /* Skip AutoForward (Start) logic */
      if !(skipAutoForward && isAutoForward(scene)) {
        /* Find Hotspot */
        let hotspotOpt = if item.linkId != "" {
          Belt.Array.getBy(scene.hotspots, h => h.linkId == item.linkId)
        } else {
          /* Fallback target matching */
          Belt.Array.getBy(scene.hotspots, h => h.target == item.targetScene)
        }

        let (transYaw, transPitch) = switch hotspotOpt {
        | Some(h) => getHotspotView(h)
        | None => (0.0, 0.0)
        }

        /* Add or Merge Step */
        let pushNew = ref(true)
        let pathLen = Array.length(path)
        if pathLen > 0 {
          /* Safe access last step */
          switch Belt.Array.get(path, pathLen - 1) {
          | Some(last) =>
            if last.idx == startSceneIdx && Belt.Option.isNone(last.transitionTarget) {
              /* Merge into existing step */
              last.transitionTarget = Some({
                yaw: transYaw,
                pitch: transPitch,
                targetName: item.targetScene,
                timelineItemId: Some(item.id),
              })
              pushNew := false
            }
          | None => () /* Should not happen if len > 0 */
          }
        }

        if pushNew.contents {
          let _ = Js.Array.push(
            {
              idx: startSceneIdx,
              transitionTarget: Some({
                yaw: transYaw,
                pitch: transPitch,
                targetName: item.targetScene,
                timelineItemId: Some(item.id),
              }),
              arrivalView: getDefaultView() /* Start of jump defaults to 0,0 */,
            },
            path,
          )
        }

        /* Calculate Arrival (End Scene) */
        let targetIdxRef = ref(
          findSceneIndex(scenes, item.targetScene)->Belt.Option.getWithDefault(-1),
        )
        let arrivalViewRef = ref(getDefaultView())

        if targetIdxRef.contents != -1 {
          /* Initial arrival from link data if direct */
          switch hotspotOpt {
          | Some(h) =>
            switch (h.targetYaw, h.targetPitch) {
            | (Some(ty), Some(tp)) => arrivalViewRef := {yaw: ty, pitch: tp}
            | _ => ()
            }
          | None => ()
          }

          /* Handle Skip Auto Forward (End) */
          if skipAutoForward {
            let chainCounter = ref(0)
            let searching = ref(true)
            let visitedInChain = Belt.MutableSet.Int.make()
            Belt.MutableSet.Int.add(visitedInChain, targetIdxRef.contents)

            while searching.contents && chainCounter.contents < 10 {
              switch Belt.Array.get(scenes, targetIdxRef.contents) {
              | Some(nextScene) =>
                if isAutoForward(nextScene) {
                  /* Find ANY forward link to jump */
                  let jumpLinkOpt = Js.Array.find(h => {
                    let tIdx = findSceneIndex(scenes, h.target)
                    switch tIdx {
                    | Some(idx) => !Belt.MutableSet.Int.has(visitedInChain, idx)
                    | None => false
                    }
                  }, nextScene.hotspots)

                  switch jumpLinkOpt {
                  | Some(jLink) =>
                    let jIdx = findSceneIndex(scenes, jLink.target)->Belt.Option.getWithDefault(-1)
                    targetIdxRef := jIdx
                    Belt.MutableSet.Int.add(visitedInChain, jIdx)
                    arrivalViewRef := getDefaultView() /* Reset for jump */
                  | None => searching := false
                  }
                } else {
                  searching := false
                }
              | None => searching := false
              }
              chainCounter := chainCounter.contents + 1
            }
          }

          /* Push Arrival Step */
          let _ = Js.Array.push(
            {
              idx: targetIdxRef.contents,
              transitionTarget: None,
              arrivalView: arrivalViewRef.contents,
            },
            path,
          )
        }
      }
    | None => ()
    }
  })

  /* Cleanup Logic */
  /* 1. Filter remaining auto-forward if skipping */
  let finalPath = if skipAutoForward {
    Belt.Array.keep(path, step => {
      switch Belt.Array.get(scenes, step.idx) {
      | Some(s) => !isAutoForward(s)
      | None => false
      }
    })
  } else {
    path
  }

  /* 2. Dedupe adjacent */
  let deduped = Belt.Array.keepWithIndex(finalPath, (step, i) => {
    if i == 0 {
      true
    } else {
      switch Belt.Array.get(finalPath, i - 1) {
      | Some(prev) => step.idx != prev.idx
      | None => true
      }
    }
  })
  deduped
}
