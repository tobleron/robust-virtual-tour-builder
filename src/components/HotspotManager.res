/* src/components/HotspotManager.res */

open ReBindings
open Types
open EventBus

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
  ~scene: scene,
  ~dispatch: Actions.action => unit,
) => {
  let isSimulationMode = state.simulation.status == Running
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

  let isCurrentSceneAutoForward = scene.isAutoForward

  let isTargetAutoForward = switch targetSceneOpt {
  | Some(ts) => ts.isAutoForward
  | None => false
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
  if isSimulationMode && isCurrentSceneAutoForward {
    cssClass := cssClass.contents ++ " hidden-in-sim"
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
      let isAutoForward = isTargetAutoForward

      /* Manually create elements to ensure they exist in DOM */
      let deleteBtn = Dom.createElement("div")
      Dom.setAttribute(deleteBtn, "class", "hotspot-delete-btn")
      Dom.setAttribute(deleteBtn, "title", "Delete Link")
      Dom.setAttribute(deleteBtn, "role", "button")
      Dom.setAttribute(deleteBtn, "tabindex", "0")
      Dom.setAttribute(deleteBtn, "aria-label", "Delete Link")
      Dom.setTextContent(deleteBtn, "✕")

      /* Navigation Arrow (Double Chevron) */
      let navBtn = Dom.createElement("div")
      Dom.setAttribute(navBtn, "class", "hotspot-nav-btn")
      Dom.setAttribute(navBtn, "title", "Navigate to " ++ hotspot.target)
      Dom.setAttribute(navBtn, "role", "button")
      Dom.setAttribute(navBtn, "tabindex", "0")

      let controls = Dom.createElement("div")
      Dom.setAttribute(controls, "class", "hotspot-controls")

      /* Forward Btn */
      let fwdBtn = Dom.createElement("div")
      let fwdClass = "hotspot-forward-btn" ++ (isAutoForward ? " active" : "")
      Dom.setAttribute(fwdBtn, "class", fwdClass)
      Dom.setAttribute(fwdBtn, "title", "Toggle Auto-Forward")

      /* Append all to container */
      Dom.appendChild(controls, navBtn)
      Dom.appendChild(controls, fwdBtn)

      Dom.appendChild(div, deleteBtn)
      Dom.appendChild(div, controls)

      /* v4.4.1: Critical - Disable events on the root div to prevent accidental mis-clicks */
      Dom.setPointerEvents(div, "none")
      Dom.setCursor(div, "default")

      // Accessibility for the main hotspot container
      Dom.setAttribute(div, "role", "presentation")

      // 1. Delete Logic
      ElementExt.setOnClick(deleteBtn, e => {
        Event.stopPropagation(e)
        Event.preventDefault(e)
        Logger.info(
          ~module_="Hotspot",
          ~message="LINK_DELETE",
          ~data=Some({"hotspotId": "hs_" ++ Belt.Int.toString(index)}),
          (),
        )
        dispatch(Actions.RemoveHotspot(state.activeIndex, index))
        EventBus.dispatch(ShowNotification("Link deleted", #Info))
      })

      // 2. Forward Logic
      ElementExt.setOnClick(fwdBtn, e => {
        Event.stopPropagation(e)
        Event.preventDefault(e)
        switch targetSceneOpt {
        | Some(ts) =>
          let targetIdx = Belt.Array.getIndexBy(state.scenes, s => s.name == hotspot.target)
          switch targetIdx {
          | Some(idx) =>
            let currentVal = ts.isAutoForward
            dispatch(
              Actions.UpdateSceneMetadata(idx, Logger.castToJson({"isAutoForward": !currentVal})),
            )
            EventBus.dispatch(
              ShowNotification(
                if !currentVal {
                  "Auto-forward: ENABLED"
                } else {
                  "Auto-forward: DISABLED"
                },
                #Success,
              ),
            )
          | None => ()
          }
        | None => ()
        }
      })

      // 3. Navigation Logic
      ElementExt.setOnClick(navBtn, e => {
        Event.stopPropagation(e)
        Event.preventDefault(e)

        switch targetSceneOpt {
        | Some(_ts) =>
          let targetIdx = Belt.Array.getIndexBy(state.scenes, s => s.name == hotspot.target)
          switch targetIdx {
          | Some(idx) =>
            let navYaw = ref(0.0)
            let navPitch = ref(0.0)
            let navHfov = ref(90.0)

            let isRet = switch hotspot.isReturnLink {
            | Some(b) => b
            | None => false
            }

            if isRet && hotspot.returnViewFrame != None {
              let rvf = hotspot.returnViewFrame
              switch rvf {
              | Some(r) =>
                navYaw := r.yaw
                navPitch := r.pitch
                navHfov := r.hfov
              | None => ()
              }
            } else {
              // Logic for targetYaw vs viewFrame
              switch hotspot.targetYaw {
              | Some(ty) =>
                navYaw := ty
                navPitch :=
                  switch hotspot.targetPitch {
                  | Some(p) => p
                  | None => 0.0
                  }
                navHfov :=
                  switch hotspot.targetHfov {
                  | Some(h) => h
                  | None => 90.0
                  }
              | None =>
                switch hotspot.viewFrame {
                | Some(vf) =>
                  navYaw := vf.yaw
                  navPitch := vf.pitch
                  navHfov := vf.hfov
                | None => ()
                }
              }
            }

            Logger.info(
              ~module_="Hotspot",
              ~message="NAV_TRIGGERED",
              ~data=Some({"target": hotspot.target, "fromScene": scene.name}),
              (),
            )
            Navigation.navigateToScene(
              dispatch,
              state,
              idx,
              state.activeIndex,
              index,
              ~targetYaw=navYaw.contents,
              ~targetPitch=navPitch.contents,
              ~targetHfov=navHfov.contents,
              (),
            )
          | None => ()
          }
        | None => ()
        }
      })
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
