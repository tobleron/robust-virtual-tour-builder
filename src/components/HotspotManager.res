/* src/components/HotspotManager.res */

open ReBindings
open Types

module Event = {
  type t
  @send external stopPropagation: t => unit = "stopPropagation"
  @send external preventDefault: t => unit = "preventDefault"
  @get external target: t => Dom.element = "target"
}

module ElementExt = {
  @send external closest: (Dom.element, string) => Nullable.t<Dom.element> = "closest"
  @set external setOnClick: (Dom.element, Event.t => unit) => unit = "onclick"
}

let createHotspotConfig = (
  ~hotspot: hotspot,
  ~index: int,
  ~state: state,
  ~scene as _scene: scene,
  ~dispatch: Actions.action => unit,
) => {
  let isSimulationMode = state.simulation.status != Idle
  let incomingLink = state.incomingLink
  let targetSceneOpt = Belt.Array.getBy(state.scenes, s => s.name == hotspot.target)

  // NAVIGATION LOGIC
  let isReturnLink = switch incomingLink {
  | Some(inc) =>
    switch Belt.Array.get(state.scenes, inc.sceneIndex) {
    | Some(prevScene) => prevScene.name == hotspot.target
    | None => false
    }
  | None => false
  }

  let isTargetAutoForward = switch targetSceneOpt {
  | Some(ts) => ts.isAutoForward
  | None => false
  }

  // Determine if this specific hotspot is the one we are currently navigating towards
  let isTargetOfActiveNav = switch state.navigation {
  | Navigating(data) => data.hotspotIndex == index
  | _ => false
  }

  // CSS Class (Always Gold, only 3rd chevron changes)
  let cssClass = ref("pnlm-hotspot flat-arrow arrow-gold")
  if isTargetAutoForward {
    cssClass := cssClass.contents ++ " auto-forward"
  }
  if isReturnLink {
    cssClass := cssClass.contents ++ " return-link"
  }
  if isSimulationMode {
    cssClass := cssClass.contents ++ " in-simulation"
  }
  if isTargetOfActiveNav {
    cssClass := cssClass.contents ++ " active-sim-target"
  }

  {
    "id": if hotspot.linkId != "" {
      hotspot.linkId
    } else {
      "hs_" ++ Belt.Int.toString(index)
    },
    "pitch": switch hotspot.displayPitch {
    | Some(p) => p
    | None => hotspot.pitch
    },
    "yaw": hotspot.yaw,
    "type": "info",
    "text": " " /* Ensure trigger */,
    "cssClass": cssClass.contents,
    "createTooltipFunc": (div: Dom.element) => {
      // Create Container - APPEND classes, don't overwrite to preserve Pannellum positioning
      Dom.classList(div)->Dom.ClassList.add("pnlm-hotspot-base")
      Dom.classList(div)->Dom.ClassList.add("group")
      Dom.classList(div)->Dom.ClassList.add("relative")
      Dom.classList(div)->Dom.ClassList.add("flex")
      Dom.classList(div)->Dom.ClassList.add("items-center")
      Dom.classList(div)->Dom.ClassList.add("justify-center")
      // We render it as a 0x0 size anchor, effectively checking center.
      // But the children are absolute/fixed relative to it?
      // No, children are absolute. Let's give it w-12 h-12 to match click area if needed
      // Actually, Pannellum hotspots are usually 0x0 div with visible overflow.
      // Let's stick to overflow-visible.
      Dom.setPointerEvents(div, "auto")
      Dom.setCursor(div, "default")

      // Use React 18 createRoot to render the PreviewArrow component into the div
      // We rely on Pannellum to manage the DIV lifecycle (removing it when scene changes)
      // Note: In a perfect world we would unmount the root, but Pannellum just nukes the DOM.
      // Garbage collection should handle the detached nodes.

      let root = ReBindings.ReactDOMClient.createRoot(div)

      // We pass a dummy elementId because we're not using the HotspotLine loop anymore
      // Pannellum handles the positioning of 'div' automatically.
      let elementId = "hs-react-" ++ Belt.Int.toString(index)

      ReBindings.ReactDOMClient.Root.render(
        root,
        <PreviewArrow
          sceneIndex={state.activeIndex}
          hotspotIndex={index}
          dispatch={dispatch}
          elementId={elementId}
          isTargetAutoForward={isTargetAutoForward}
          scenes={state.scenes}
          state={state}
        />,
      )
    },
  }
}

let syncHotspots = (v: Viewer.t, state: state, scene: scene, dispatch: Actions.action => unit) => {
  let config = Viewer.getConfig(v)
  let hs = config["hotSpots"]

  // Safe Nuke: Remove ALL existing hotspots to prevent zombie states
  // We iterate a copy of IDs (currentIds) so we don't modify the array we are reading from indirectly
  let currentIds = Belt.Array.map(hs, h => h["id"])
  Belt.Array.forEach(currentIds, id => {
    if id != "" {
      Viewer.removeHotSpot(v, id)
    }
  })

  Logger.debug(
    ~module_="HotspotManager",
    ~message="SYNC_HOTSPOTS_NUKE",
    ~data=Some({
      "removed": Belt.Array.length(currentIds),
      "adding": Belt.Array.length(scene.hotspots),
    }),
    (),
  )

  // Add ALL new hotspots
  Belt.Array.forEachWithIndex(scene.hotspots, (i, h) => {
    let conf = createHotspotConfig(~hotspot=h, ~index=i, ~state, ~scene, ~dispatch)
    Viewer.addHotSpot(v, conf)
  })
}

let getProjectData = (state: Types.state) => {
  let project: Types.project = {
    tourName: state.tourName,
    scenes: state.scenes,
    lastUsedCategory: state.lastUsedCategory,
    exifReport: state.exifReport,
    sessionId: state.sessionId,
    deletedSceneIds: state.deletedSceneIds,
    timeline: state.timeline,
  }
  JsonParsers.Encoders.project(project)
}

let handleAddHotspot = (sceneIndex: int, hotspot: Types.hotspot) => {
  InteractionQueue.enqueue(Thunk(async () => {
    let _ = await OptimisticAction.execute(
      ~action=Actions.AddHotspot(sceneIndex, hotspot),
      ~apiCall=() => {
        let state = GlobalStateBridge.getState()
        switch state.sessionId {
        | Some(sid) =>
          let projectData = getProjectData(state)
          Api.ProjectApi.saveProject(sid, projectData)
        | None => Promise.resolve(Error("No active session"))
        }
      },
    )
  }))
}

let handleDeleteHotspot = (sceneIndex: int, hotspotIndex: int) => {
  InteractionQueue.enqueue(Thunk(async () => {
    let _ = await OptimisticAction.execute(
      ~action=Actions.RemoveHotspot(sceneIndex, hotspotIndex),
      ~apiCall=() => {
        let state = GlobalStateBridge.getState()
        switch state.sessionId {
        | Some(sid) =>
          let projectData = getProjectData(state)
          Api.ProjectApi.saveProject(sid, projectData)
        | None => Promise.resolve(Error("No active session"))
        }
      },
    )
  }))
}

let handleUpdateSceneMetadata = (sceneIndex: int, metadata: JSON.t) => {
  InteractionQueue.enqueue(Thunk(async () => {
    let _ = await OptimisticAction.execute(
      ~action=Actions.UpdateSceneMetadata(sceneIndex, metadata),
      ~apiCall=() => {
        let state = GlobalStateBridge.getState()
        switch state.sessionId {
        | Some(sid) =>
          let projectData = getProjectData(state)
          Api.ProjectApi.saveProject(sid, projectData)
        | None => Promise.resolve(Error("No active session"))
        }
      },
    )
  }))
}
