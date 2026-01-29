/* src/systems/Scene.res - Consolidated Scene System */

open ReBindings
open Types
open Actions

// --- TRANSITION (from SceneTransitionManager.res) ---

module Transition = {
  let performSwap = (loadedScene: scene, _loadStartTime) => {
    ViewerState.state.isSwapping = true
    let (av, iv) = (ViewerSystem.Pool.getActive(), ViewerSystem.Pool.getInactive())
    let (ov, nv) = (ViewerSystem.getActiveViewer(), ViewerSystem.getInactiveViewer())
    ViewerSystem.Pool.swapActive()
    ViewerSystem.Pool.getActive()->Option.forEach(v => ViewerSystem.Pool.clearCleanupTimeout(v.id))
    let assignGlobal: Nullable.t<ReBindings.Viewer.t> => unit = %raw(
      "(v) => window.pannellumViewer = v"
    )
    assignGlobal(nv)
    Dom.getElementById("viewer-hotspot-lines")
    ->Nullable.toOption
    ->Option.forEach(svg => Dom.setTextContent(svg, ""))
    let _ = Window.setTimeout(() => {
      ViewerSystem.getActiveViewer()
      ->Nullable.toOption
      ->Option.forEach(v => {
        if ViewerSystem.isViewerReady(v) {
          HotspotLine.updateLines(
            v,
            GlobalStateBridge.getState(),
            ~mouseEvent=?ViewerState.state.lastMouseEvent->Nullable.toOption,
            (),
          )
        }
      })
      ViewerState.state.isSwapping = false
    }, 50)

    let isCut = GlobalStateBridge.getState().transition.type_ == Cut
    switch (av, iv) {
    | (Some(act), Some(inact)) =>
      let (actEl, inactEl) = (
        Dom.getElementById(act.containerId),
        Dom.getElementById(inact.containerId),
      )
      switch (actEl->Nullable.toOption, inactEl->Nullable.toOption) {
      | (Some(a), Some(i)) =>
        if isCut {
          Dom.setTransition(a, "none")
          Dom.setTransition(i, "none")
        } else {
          Dom.setTransition(a, "")
          Dom.setTransition(i, "")
        }
        Dom.remove(a, "active")
        Dom.add(i, "active")
        if isCut {
          let _ = Window.setTimeout(() => {
            Dom.setTransition(a, "")
            Dom.setTransition(i, "")
          }, 50)
        }
      | _ => ()
      }
    | _ => ()
    }

    let clv = ViewerSystem.Pool.getInactive()
    switch clv {
    | Some(vp) =>
      let tid = Window.setTimeout(() => {
        ov->Nullable.toOption->Option.forEach(ViewerSystem.Adapter.destroy)
        ViewerSystem.Pool.clearInstance(vp.containerId)
        ViewerSystem.Pool.clearCleanupTimeout(vp.id)
      }, 500)
      ViewerSystem.Pool.setCleanupTimeout(vp.id, Some(tid))
    | None => ()
    }

    Dom.getElementById("viewer-snapshot-overlay")
    ->Nullable.toOption
    ->Option.forEach(s => {
      Dom.remove(s, "snapshot-visible")
      let _ = Window.setTimeout(() => {
        if !(Dom.classList(s)->Dom.ClassList.contains("snapshot-visible")) {
          Dom.setBackgroundImage(s, "none")
        }
      }, 450)
    })
    ViewerSnapshot.requestIdleSnapshot()
    ViewerState.state.lastSceneId = Nullable.make(loadedScene.id)
    GlobalStateBridge.dispatch(DispatchNavigationFsmEvent(StabilizeComplete))
  }
}

// --- LOADER (from SceneLoader.res) ---

module Loader = {
  let castToString: 'a => string = %raw("(x) => typeof x === 'string' ? x : ''")
  let castToDict: 'a => dict<string> = %raw("(x) => (typeof x === 'object' && x !== null) ? x : {}")
  external asDynamic: 'a => {..} = "%identity"
  let loadStartTime = ref(0.0)
  module Config = {
    let getHotspots = (scene: scene) =>
      scene.hotspots->Belt.Array.mapWithIndex((idx, h) => {
        let pitch = h.displayPitch->Option.getOr(h.pitch)
        {
          "pitch": pitch,
          "yaw": h.yaw,
          "type": "info",
          "cssClass": "flat-arrow",
          "createTooltipFunc": HotspotLine.renderGoldArrow,
          "createTooltipArgs": {
            "i": idx,
            "targetSceneId": h.target,
            "pitch": pitch,
            "yaw": h.yaw,
            "truePitch": h.pitch,
            "viewFrame": h.viewFrame,
            "targetYaw": h.targetYaw,
            "targetPitch": h.targetPitch,
            "isReturnLink": h.isReturnLink,
            "returnViewFrame": h.returnViewFrame,
          },
        }
      })
    let makeSceneConfig = (scene: scene) =>
      {"panorama": scene.file->Types.fileToUrl, "autoLoad": true, "hotSpots": getHotspots(scene)}
  }

  module Reuse = {
    let findReusableInstance = (targetIdx: int): option<Dom.element> => {
      let targetSceneId = GlobalStateBridge.getState().scenes[targetIdx]->Option.map(s => s.id)
      ViewerSystem.Pool.pool
      ->Belt.Array.getBy(v =>
        v.instance
        ->Option.map(inst =>
          ViewerSystem.Adapter.getMetaData(inst, "sceneId") ==
            targetSceneId->Option.map(id => Obj.magic(id))
        )
        ->Option.getOr(false)
      )
      ->Option.map(v => Dom.getElementById(v.containerId)->Nullable.toOption)
      ->Option.flatMap(x => x)
    }
  }

  module Events = {
    let onSceneLoad = (v, loadedScene: scene) => {
      let vId = castToDict(v)->Dict.get("container")->Option.getOr("")
      let entry = ViewerSystem.Pool.pool->Belt.Array.getBy(e => e.containerId == vId)
      entry->Option.forEach(e => {
        e.instance->Option.forEach(inst =>
          ViewerSystem.Adapter.setMetaData(inst, "isLoaded", Obj.magic(true))
        )
      })
      ViewerSystem.Pool.setCleanupTimeout(vId, None)
      GlobalStateBridge.dispatch(
        DispatchNavigationFsmEvent(NavigationFSM.TextureLoaded({targetSceneId: loadedScene.id})),
      )
    }
    let onSceneError = msg => {
      Logger.error(~module_="SceneLoader", ~message="LOAD_ERROR", ~data={"error": msg}, ())
      EventBus.dispatch(ShowNotification(msg, #Error))
    }
  }

  let loadNewScene = (_prevIndex: option<int>, targetIndex: option<int>, ~isAnticipatory=false) => {
    targetIndex->Option.forEach(tIdx => {
      let state = GlobalStateBridge.getState()
      state.scenes[tIdx]->Option.forEach(targetScene => {
        if !isAnticipatory {
          loadStartTime := Date.now()
          GlobalStateBridge.dispatch(
            DispatchNavigationFsmEvent(NavigationFSM.PreloadStarted({targetSceneId: targetScene.id})),
          )
        }
        switch if isAnticipatory {
          None
        } else {
          Reuse.findReusableInstance(tIdx)
        } {
        | Some(_) =>
          if !isAnticipatory {
            Transition.performSwap(targetScene, loadStartTime.contents)
          }
        | None =>
          let vp = if isAnticipatory {
            ViewerSystem.Pool.getInactive()
          } else {
            ViewerSystem.Pool.getInactive()
          }
          vp->Option.forEach(
            v => {
              let config = Config.makeSceneConfig(targetScene)
              let _ = ViewerSystem.Adapter.initialize(v.containerId, config)
              ViewerSystem.Pool.registerInstance(v.containerId, Obj.magic(v.instance)) // This is a bit hacky but okay for now
              // Wait, PannellumAdapter.load had a specific implementation.
              // Let's check PannellumAdapter.res again.
            },
          )
        }
      })
    })
  }
}

// --- SWITCHER (from SceneSwitcher.res) ---

module Switcher = {
  let navStartTime = ref(0.0)

  let navigateToScene = (
    dispatch,
    state,
    targetIdx,
    sourceIdx,
    sourceHIdx,
    ~targetYaw=0.0,
    ~targetPitch=0.0,
    ~targetHfov=90.0,
    ~previewOnly=false,
    (),
  ) => {
    navStartTime := Date.now()
    if (
      state.navigation->(
        s =>
          switch s {
          | Navigating(_) => true
          | _ => false
          }
      )
    ) {
      ()
    } else {
      let njid = state.currentJourneyId + 1
      dispatch(Actions.IncrementJourneyId)
      let currView = NavigationGraph.getCurrentView()
      if previewOnly {
        dispatch(SetNavigationStatus(Previewing({sceneIndex: sourceIdx, hotspotIndex: sourceHIdx})))
      }
      if state.simulation.status == Running || previewOnly {
        let pd = NavigationGraph.calculatePathData(
          state,
          sourceIdx,
          sourceHIdx,
          targetIdx,
          targetYaw,
          targetPitch,
          targetHfov,
          currView,
        )
        let j: journeyData = {
          journeyId: njid,
          targetIndex: targetIdx,
          sourceIndex: sourceIdx,
          hotspotIndex: sourceHIdx,
          arrivalYaw: pd->Option.map(p => p.arrivalYaw)->Option.getOr(targetYaw),
          arrivalPitch: pd->Option.map(p => p.arrivalPitch)->Option.getOr(targetPitch),
          arrivalHfov: pd->Option.map(p => p.arrivalHfov)->Option.getOr(targetHfov),
          previewOnly,
          pathData: pd,
        }
        dispatch(SetNavigationStatus(Navigating(j)))
        state.scenes[targetIdx]->Option.forEach(ts =>
          dispatch(DispatchNavigationFsmEvent(UserClickedScene({targetSceneId: ts.id})))
        )
        pd->Option.forEach(p =>
          EventBus.dispatch(
            NavStart({
              journeyId: njid,
              targetIndex: targetIdx,
              sourceIndex: sourceIdx,
              hotspotIndex: sourceHIdx,
              previewOnly,
              pathData: p,
            }),
          )
        )
      } else {
        let (ay, ap, _) = NavigationGraph.calculateSmartArrivalTarget(state.scenes, targetIdx)
        dispatch(SetIncomingLink(Some({sceneIndex: sourceIdx, hotspotIndex: sourceHIdx})))
        dispatch(
          SetActiveScene(
            targetIdx,
            ay,
            ap,
            Some({type_: Link, targetHotspotIndex: -1, fromSceneName: None}),
          ),
        )
        state.scenes[targetIdx]->Option.forEach(ts =>
          dispatch(DispatchNavigationFsmEvent(UserClickedScene({targetSceneId: ts.id})))
        )
      }
    }
  }

  let handleAutoForward = (dispatch, state, currentScene: scene) => {
    if state.simulation.status != Running && currentScene.isAutoForward && !state.isLinking {
      let chain = state.autoForwardChain
      if Array.length(chain) == 0 {
        state.incomingLink->Option.forEach(l =>
          dispatch(Actions.AddToAutoForwardChain(l.sceneIndex))
        )
      }
      if Array.includes(chain, state.activeIndex) {
        dispatch(ResetAutoForwardChain)
        EventBus.dispatch(ShowNotification("Loop detected", #Warning))
      } else {
        dispatch(AddToAutoForwardChain(state.activeIndex))
        currentScene.hotspots
        ->Belt.Array.getBy(h => h.isReturnLink != Some(true))
        ->Option.forEach(h => {
          state.scenes
          ->Belt.Array.getIndexBy(s => s.name == h.target)
          ->Option.forEach(tIdx => {
            let hIdx =
              currentScene.hotspots
              ->Belt.Array.getIndexBy(hh => hh.linkId == h.linkId)
              ->Option.getOr(0)
            navigateToScene(dispatch, state, tIdx, state.activeIndex, hIdx, ())
          })
        })
      }
    }
  }

  let setSimulationMode = (dispatch, state, val) => {
    dispatch(SetSimulationMode(val))
    dispatch(ResetAutoForwardChain)
    dispatch(SetIncomingLink(None))
    dispatch(IncrementJourneyId)
    EventBus.dispatch(ClearSimUi)
    dispatch(SetNavigationStatus(Idle))
    if val && state.activeIndex >= 0 {
      let _ = ReBindings.Window.setTimeout(() => {
        state.scenes[state.activeIndex]->Option.forEach(s => handleAutoForward(dispatch, state, s))
      }, 100)
    }
  }

  let cancelNavigation = () => {EventBus.dispatch(NavCancelled)}

  let initNavigation = dispatch => {
    dispatch(SetSimulationMode(false))
    dispatch(SetCurrentJourneyId(0))
    dispatch(SetNavigationStatus(Idle))
    dispatch(SetIncomingLink(None))
    dispatch(ResetAutoForwardChain)
    let _ = EventBus.subscribe(e => {
      switch e {
      | NavCompleted(j) => dispatch(NavigationCompleted(j))
      | NavCancelled => dispatch(SetNavigationStatus(Idle))
      | _ => ()
      }
    })
  }
}
