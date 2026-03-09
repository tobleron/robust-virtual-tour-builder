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
  let isAutoForward = switch hotspot.isAutoForward {
  | Some(b) => b
  | None => false
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
    "cssClass": HotspotManagerSupport.hotspotCssClass(~hotspot, ~index, ~state, ~isAutoForward),
    "tooltipAlwaysVisible": true,
    "createTooltipFunc": (div: Dom.element) => {
      HotspotManagerSupport.renderPreviewArrow(~div, ~index, ~state, ~dispatch, ~isAutoForward)
    },
  }
}

let syncHotspots = (
  v: Viewer.t,
  _state: state,
  _scene: scene,
  _dispatch: Actions.action => unit,
) => {
  if !ViewerSystem.isViewerReady(v) {
    Logger.debug(~module_="HotspotManager", ~message="SYNC_SKIPPED_VIEWER_NOT_READY", ())
  } else {
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
        "adding": Belt.Array.length(_scene.hotspots),
      }),
      (),
    )

    // Add ALL new hotspots
    /*
       DEPRECATED: Hotspots are now managed by ReactHotspotLayer.res
       for better layering and performance.
 */
    /*
    if !state.isTeasing {
      Belt.Array.forEachWithIndex(scene.hotspots, (i, h) => {
        let conf = createHotspotConfig(~hotspot=h, ~index=i, ~state, ~scene, ~dispatch)
        Viewer.addHotSpot(v, conf)
      })
    }
 */
  }
}

let handleAddHotspot = async (sceneIndex: int, hotspot: Types.hotspot) => {
  let _ = await OptimisticAction.execute(
    ~action=Actions.AddHotspot(sceneIndex, hotspot),
    ~apiCall=state => {
      switch state.sessionId {
      | Some(sid) =>
        let projectData = ProjectSystem.encodeProjectFromState(state)
        Api.ProjectApi.saveProject(sid, projectData)
      | None => Promise.resolve(Ok())
      }
    },
  )
}

let handleDeleteHotspot = async (sceneIndex: int, hotspotIndex: int) => {
  let _ = await OptimisticAction.execute(
    ~action=Actions.RemoveHotspot(sceneIndex, hotspotIndex),
    ~apiCall=state => {
      switch state.sessionId {
      | Some(sid) =>
        let projectData = ProjectSystem.encodeProjectFromState(state)
        Api.ProjectApi.saveProject(sid, projectData)
      | None => Promise.resolve(Ok())
      }
    },
  )
}

let handleUpdateSceneMetadata = async (sceneIndex: int, metadata: JSON.t) => {
  let _ = await OptimisticAction.execute(
    ~action=Actions.UpdateSceneMetadata(sceneIndex, metadata),
    ~apiCall=state => {
      switch state.sessionId {
      | Some(sid) =>
        let projectData = ProjectSystem.encodeProjectFromState(state)
        Api.ProjectApi.saveProject(sid, projectData)
      | None => Promise.resolve(Ok())
      }
    },
  )
}
let handleUpdateHotspotMetadata = async (sceneIndex: int, hotspotIndex: int, metadata: JSON.t) => {
  let _ = await OptimisticAction.execute(
    ~action=Actions.UpdateHotspotMetadata(sceneIndex, hotspotIndex, metadata),
    ~apiCall=state => {
      switch state.sessionId {
      | Some(sid) =>
        let projectData = ProjectSystem.encodeProjectFromState(state)
        Api.ProjectApi.saveProject(sid, projectData)
      | None => Promise.resolve(Ok())
      }
    },
  )
}

let findIndicesByIds = (state: state, ~sceneId: string, ~hotspotLinkId: string): option<(
  int,
  int,
)> => {
  state.sceneOrder
  ->Belt.Array.getIndexBy(id => id == sceneId)
  ->Option.flatMap(sIdx => {
    state.inventory
    ->Belt.Map.String.get(sceneId)
    ->Option.flatMap(entry => {
      entry.scene.hotspots
      ->Belt.Array.getIndexBy(h => h.linkId == hotspotLinkId)
      ->Option.map(hIdx => (sIdx, hIdx))
    })
  })
}

let handleUpdateHotspotTarget = async (
  ~sceneIndex=?,
  ~hotspotIndex=?,
  ~sceneId=?,
  ~hotspotLinkId=?,
  targetName: string,
  targetSceneId: option<string>,
) => {
  let state = AppContext.getBridgeState()

  // Resolve indices: either use provided ones or lookup by stable IDs
  let resolvedIndices = switch (sceneId, hotspotLinkId) {
  | (Some(sid), Some(hId)) => findIndicesByIds(state, ~sceneId=sid, ~hotspotLinkId=hId)
  | _ =>
    switch (sceneIndex, hotspotIndex) {
    | (Some(sIdx), Some(hIdx)) => Some((sIdx, hIdx))
    | _ => None
    }
  }

  switch resolvedIndices {
  | Some((sIdx, hIdx)) =>
    let _ = await OptimisticAction.execute(
      ~action=Actions.UpdateHotspotMetadata(
        sIdx,
        hIdx,
        Logger.castToJson({
          "target": targetName,
          "targetSceneId": targetSceneId,
        }),
      ),
      ~apiCall=state => {
        switch state.sessionId {
        | Some(sid) =>
          let projectData = ProjectSystem.encodeProjectFromState(state)
          Api.ProjectApi.saveProject(sid, projectData)
        | None => Promise.resolve(Ok())
        }
      },
    )
  | None => Logger.error(~module_="HotspotManager", ~message="RETARGET_LOOKUP_FAILED", ())
  }
}

let handleCommitHotspotMove = async (
  sceneIndex: int,
  hotspotIndex: int,
  yaw: float,
  pitch: float,
) => {
  let _ = await OptimisticAction.execute(
    ~action=Actions.CommitHotspotMove(sceneIndex, hotspotIndex, yaw, pitch),
    ~apiCall=state => {
      switch state.sessionId {
      | Some(sid) =>
        let projectData = ProjectSystem.encodeProjectFromState(state)
        Api.ProjectApi.saveProject(sid, projectData)
      | None => Promise.resolve(Ok())
      }
    },
  )
  let _ = setTimeout(() => EventBus.dispatch(ForceHotspotSync), 0)
}
