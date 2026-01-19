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

  // CSS Class
  let cssClass = ref("flat-arrow")
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

  if isTargetAutoForward {
    cssClass := cssClass.contents ++ " arrow-green"
  } else {
    cssClass := cssClass.contents ++ " arrow-gold"
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
    "cssClass": cssClass.contents,
    "createTooltipFunc": (div: Dom.element) => {
      let isAutoForward = isTargetAutoForward
      let isReturn = switch hotspot.isReturnLink {
      | Some(b) => b
      | None => false
      }

      let html = `
        <div class="hotspot-delete-btn" title="Delete Link" role="button" tabindex="0" aria-label="Delete Link">✕</div>
        <div class="hotspot-controls">
          <div class="hotspot-forward-btn ${if isAutoForward {
          "active"
        } else {
          ""
        }}" title="Toggle Auto-Forward" role="button" tabindex="0" aria-label="Toggle Auto-Forward">A</div>
          <div class="hotspot-return-btn ${if isReturn {
          "active"
        } else {
          ""
        }}" title="Toggle Return Link" role="button" tabindex="0" aria-label="Toggle Return Link">R</div>
        </div>
      `
      Dom.setInnerHTML(div, html)
      Dom.setPointerEvents(div, "auto")
      Dom.setCursor(div, "default")

      // Accessibility for the main hotspot container
      Dom.setAttribute(div, "role", "button")
      Dom.setAttribute(div, "tabindex", "0")
      Dom.setAttribute(div, "aria-label", "Navigate to " ++ hotspot.target)

      // Keyboard support
      let handleKey = (e: Dom.event) => {
        let key = Dom.key(e)
        if key == "Enter" || key == " " {
          Dom.preventDefault(e)
          Dom.stopPropagation(e)
          // Trigger the click logic by manually calling the click handler or dispatching a click
          Dom.click(div)
        }
      }
      Dom.addEventListener(div, "keydown", handleKey)

      // Logic for click
      ElementExt.setOnClick(div, e => {
        Logger.info(
          ~module_="Hotspot",
          ~message="HOTSPOT_CLICK",
          ~data=Some({
            "type": hotspot.target != "" ? "navigation" : "info",
            "id": "hs_" ++ Belt.Int.toString(index),
            "target": hotspot.target,
          }),
          (),
        )

        let target = Event.target(e)
        let deleteBtn = ElementExt.closest(target, ".hotspot-delete-btn")
        let forwardBtn = ElementExt.closest(target, ".hotspot-forward-btn")
        let returnBtn = ElementExt.closest(target, ".hotspot-return-btn")

        // 1. Delete
        if !Nullable.isNullable(deleteBtn) {
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
        } // 2. Forward
        else if !Nullable.isNullable(forwardBtn) {
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
        } // 3. Return
        else if !Nullable.isNullable(returnBtn) {
          Event.stopPropagation(e)
          Event.preventDefault(e)

          dispatch(Actions.ToggleHotspotReturnLink(state.activeIndex, index))

          EventBus.dispatch(ShowNotification("Return link status updated", #Success))
        } else {
          // 4. Navigation

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
            | None =>
              Logger.warn(
                ~module_="Hotspot",
                ~message="TARGET_INDEX_NOT_FOUND",
                ~data=Some({
                  "targetScene": targetSceneOpt->Belt.Option.mapWithDefault("unknown", s => s.name),
                }),
                (),
              )
            }
          | None =>
            Logger.warn(
              ~module_="Hotspot",
              ~message="TARGET_NOT_FOUND",
              ~data=Some({"targetId": hotspot.target}),
              (),
            )
          }
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

  Logger.info(
    ~module_="HotspotManager",
    ~message="SYNC_HOTSPOTS_EXEC",
    ~data=Some({
      "scene": scene.name,
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
