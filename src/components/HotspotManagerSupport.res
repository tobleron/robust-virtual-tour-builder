open ReBindings
open Types

let isReturnLink = (~hotspot: hotspot, ~state: state): bool =>
  switch state.navigationState.incomingLink {
  | Some(inc) =>
    let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    switch Belt.Array.get(scenes, inc.sceneIndex) {
    | Some(prevScene) => HotspotTarget.pointsToScene(hotspot, prevScene)
    | None => false
    }
  | None => false
  }

let hotspotCssClass = (
  ~hotspot: hotspot,
  ~index: int,
  ~state: state,
  ~isAutoForward: bool,
): string => {
  let isSimulationMode = state.simulation.status != Idle
  let isTargetOfActiveNav = switch state.navigationState.navigation {
  | Navigating(data) => data.hotspotIndex == index
  | _ => false
  }

  let cssClass = ref("pnlm-hotspot flat-arrow arrow-gold")
  if isAutoForward {
    cssClass := cssClass.contents ++ " auto-forward"
  }
  if isReturnLink(~hotspot, ~state) {
    cssClass := cssClass.contents ++ " return-link"
  }
  if isSimulationMode {
    cssClass := cssClass.contents ++ " in-simulation"
  }
  if isTargetOfActiveNav {
    cssClass := cssClass.contents ++ " active-sim-target"
  }
  if hotspot.displayPitch == None {
    cssClass := cssClass.contents ++ " freely-placed"
  }
  cssClass.contents
}

let renderPreviewArrow = (
  ~div: Dom.element,
  ~index: int,
  ~state: state,
  ~dispatch: Actions.action => unit,
  ~isAutoForward: bool,
) => {
  Logger.debug(~module_="HotspotManager", ~message="CREATE_TOOLTIP_FUNC_CALLED", ())
  Dom.classList(div)->Dom.ClassList.add("pnlm-hotspot-base")
  Dom.classList(div)->Dom.ClassList.add("group")
  Dom.classList(div)->Dom.ClassList.add("relative")
  Dom.classList(div)->Dom.ClassList.add("flex")
  Dom.classList(div)->Dom.ClassList.add("items-center")
  Dom.classList(div)->Dom.ClassList.add("justify-center")
  Dom.setPointerEvents(div, "auto")
  Dom.setCursor(div, "default")

  try {
    let root = ReBindings.ReactDOMClient.createRoot(div)
    let elementId = "hs-react-" ++ Belt.Int.toString(index)

    ReBindings.ReactDOMClient.Root.render(
      root,
      <PreviewArrow
        sceneIndex={state.activeIndex}
        hotspotIndex={index}
        dispatch={dispatch}
        elementId={elementId}
        isTargetAutoForward={isAutoForward}
        sequenceLabel={None}
        isReturnNode={false}
        scenes={SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)}
        state={state}
      />,
    )
  } catch {
  | _ => ()
  }
}
