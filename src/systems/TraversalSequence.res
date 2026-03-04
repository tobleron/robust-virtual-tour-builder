open Types
open Actions

let moduleName = "TraversalSequence"

let addVisitedLink = (visited: array<string>, linkId: string): array<string> =>
  if visited->Belt.Array.some(existing => existing == linkId) {
    visited
  } else {
    Belt.Array.concat(visited, [linkId])
  }

let applyVisitedActions = (visited: array<string>, actions: array<action>): array<string> =>
  actions->Belt.Array.reduce(visited, (acc, action) =>
    switch action {
    | AddVisitedLink(linkId) => addVisitedLink(acc, linkId)
    | _ => acc
    }
  )

let firstNewLinkId = (~visited: array<string>, ~actions: array<action>): option<string> =>
  actions->Belt.Array.reduce(None, (acc, action) =>
    switch (acc, action) {
    | (Some(_), _) => acc
    | (None, AddVisitedLink(linkId)) =>
      if visited->Belt.Array.some(existing => existing == linkId) {
        None
      } else {
        Some(linkId)
      }
    | _ => None
    }
  )

let deriveLinkSequence = (~state: state, ~maxSteps: int=400): Belt.Map.String.t<int> => {
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  switch Belt.Array.get(activeScenes, 0) {
  | None => Belt.Map.String.empty
  | Some(_) =>
    let sequenceByLinkId = ref(Belt.Map.String.empty)
    let nextSequence = ref(Constants.Scene.Sequence.startSceneNumber)
    let stepCount = ref(0)
    let continueLoop = ref(true)

    let currentStateRef = ref({
      ...state,
      activeIndex: Constants.Scene.Sequence.startSceneIndex,
      simulation: {
        ...state.simulation,
        status: Running,
        visitedLinkIds: [],
      },
    })

    while continueLoop.contents && stepCount.contents < maxSteps {
      let currentState = currentStateRef.contents
      switch Belt.Array.get(activeScenes, currentState.activeIndex) {
      | Some(_) =>
        switch SimulationMainLogic.getNextMove(currentState) {
        | SimulationMainLogic.Move({
            targetIndex,
            triggerActions,
            hotspotIndex: _,
            yaw: _,
            pitch: _,
            hfov: _,
          }) =>
          let maybeLinkId = firstNewLinkId(
            ~visited=currentState.simulation.visitedLinkIds,
            ~actions=triggerActions,
          )

          maybeLinkId->Option.forEach(linkId => {
            if sequenceByLinkId.contents->Belt.Map.String.get(linkId)->Option.isNone {
              sequenceByLinkId :=
                sequenceByLinkId.contents->Belt.Map.String.set(linkId, nextSequence.contents)
              nextSequence := nextSequence.contents + 1
            }
          })

          let visitedAfterMove = applyVisitedActions(
            currentState.simulation.visitedLinkIds,
            triggerActions,
          )
          currentStateRef := {
              ...currentState,
              activeIndex: targetIndex,
              simulation: {
                ...currentState.simulation,
                visitedLinkIds: visitedAfterMove,
              },
            }
          stepCount := stepCount.contents + 1
        | SimulationMainLogic.Complete(_) | SimulationMainLogic.None => continueLoop := false
        }
      | None => continueLoop := false
      }
    }

    if stepCount.contents >= maxSteps {
      Logger.warn(
        ~module_=moduleName,
        ~message="HOTSPOT_SEQUENCE_MAX_STEPS_REACHED",
        ~data=Some({"maxSteps": maxSteps}),
        (),
      )
    }

    sequenceByLinkId.contents
  }
}
