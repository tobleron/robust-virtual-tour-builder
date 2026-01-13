/* src/components/HotspotManager.res */

open ReBindings
open Store

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
  ~incomingLink: option<Navigation.linkInfo>,
  ~isSimulationMode: bool
) => {
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
    if isTargetAutoForward { cssClass := cssClass.contents ++ " auto-forward" }
    if isReturnLink { cssClass := cssClass.contents ++ " return-link" }
    if isSimulationMode { cssClass := cssClass.contents ++ " in-simulation" }
    if isSimulationMode && isCurrentSceneAutoForward { cssClass := cssClass.contents ++ " hidden-in-sim" }

    {
        "id": "hs_" ++ Belt.Int.toString(index),
        "pitch": switch Nullable.toOption(hotspot.displayPitch) { | Some(p) => p | None => hotspot.pitch },
        "yaw": hotspot.yaw,
        "type": "info",
        "cssClass": cssClass.contents,
        "createTooltipFunc": (div: Dom.element) => {
            let isAutoForward = isTargetAutoForward
            let isReturn = switch Nullable.toOption(hotspot.isReturnLink) { | Some(b) => b | None => false }

            let iStr = Belt.Int.toString(index)
            let fillUrl = if isTargetAutoForward { "url(#autoForwardGradient)" } else { "url(#hsG_" ++ iStr ++ ")" }
            
            let html = `
        <div class="hotspot-delete-btn" title="Delete Link">✕</div>
        <svg class="custom-arrow-svg" viewBox="0 0 100 100">
          <defs>
            <linearGradient id="hsG_${iStr}" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" style="stop-color:#FFD700"/><stop offset="100%" style="stop-color:#FDB931"/></linearGradient>
            <linearGradient id="autoForwardGradient" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" style="stop-color:#0d9488"/><stop offset="100%" style="stop-color:#0f766e"/></linearGradient>
          </defs>
          <path d="M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z" fill="${fillUrl}" />
          <path class="glow-unit glow-top" d="M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z" />
          <path class="glow-unit glow-bottom" d="M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z" />
        </svg>
        <div class="hotspot-controls">
          <div class="hotspot-forward-btn ${if isAutoForward {"active"} else {""}}" title="Toggle Auto-Forward">A</div>
          <div class="hotspot-return-btn ${if isReturn {"active"} else {""}}" title="Toggle Return Link">R</div>
        </div>
      `
            Dom.setInnerHTML(div, html)
            Dom.setPointerEvents(div, "auto")
            Dom.setCursor(div, "default")
            
            // Logic for click
            ElementExt.setOnClick(div, (e) => {
                 Debug.debug("Hotspot", "Click received on hotspot " ++ iStr, ~data=Some({"target": hotspot.target}), ())
                 
                 let target = Event.target(e)
                 let deleteBtn = ElementExt.closest(target, ".hotspot-delete-btn")
                 let forwardBtn = ElementExt.closest(target, ".hotspot-forward-btn")
                 let returnBtn = ElementExt.closest(target, ".hotspot-return-btn")
                 
                 // 1. Delete
                 if !(Nullable.isNullable(deleteBtn)) {
                     Event.stopPropagation(e)
                     Event.preventDefault(e)
                     Store.store.removeHotspot(state.activeIndex, index)
                     Notification.notify("Link deleted", "info")
                 } 
                 // 2. Forward
                 else if !(Nullable.isNullable(forwardBtn)) {
                     Event.stopPropagation(e)
                     Event.preventDefault(e)
                     switch targetSceneOpt {
                     | Some(ts) =>
                         let targetIdx = Belt.Array.getIndexBy(state.scenes, s => s.name == hotspot.target)
                         switch targetIdx {
                         | Some(idx) => 
                             let currentVal = ts.isAutoForward
                             Store.store.updateSceneMetadata(idx, Obj.magic({"isAutoForward": !currentVal}))
                             Notification.notify(
                                 if !currentVal { "Auto-forward: ENABLED" } else { "Auto-forward: DISABLED" },
                                 "success"
                             )
                         | None => ()
                         }
                     | None => ()
                     }
                 }
                 // 3. Return
                 else if !(Nullable.isNullable(returnBtn)) {
                     Event.stopPropagation(e)
                     Event.preventDefault(e)
                     let currentVal = switch Nullable.toOption(hotspot.isReturnLink) { | Some(b) => b | None => false }
                     hotspot.isReturnLink = Nullable.fromOption(Some(!currentVal))
                     
                     if !currentVal { // Enabled
                         if Nullable.isNullable(hotspot.returnViewFrame) {
                             // Initialize return view frame
                             let vf = switch Nullable.toOption(hotspot.viewFrame) {
                             | Some(v) => v
                             | None => {yaw: 0.0, pitch: 0.0, hfov: 90.0}
                             }
                             hotspot.returnViewFrame = Nullable.fromOption(Some({
                                 yaw: vf.yaw, pitch: vf.pitch, hfov: vf.hfov
                             }))
                         }
                     }
                     
                     Store.store.notify()
                     Notification.notify(
                         if !currentVal { "Return Link: ENABLED" } else { "Return Link: DISABLED" },
                         "success"
                     )
                 }
                 // 4. Navigation
                 else {
                     switch targetSceneOpt {
                     | Some(_ts) =>
                         let targetIdx = Belt.Array.getIndexBy(state.scenes, s => s.name == hotspot.target)
                         switch targetIdx {
                         | Some(idx) =>
                            let navYaw = ref(0.0)
                            let navPitch = ref(0.0)
                            let navHfov = ref(90.0)
                            
                            let isRet = switch Nullable.toOption(hotspot.isReturnLink) { | Some(b) => b | None => false }
                            
                            if isRet && !Nullable.isNullable(hotspot.returnViewFrame) {
                                let rvf = Nullable.toOption(hotspot.returnViewFrame)
                                switch rvf {
                                | Some(r) => 
                                    navYaw := r.yaw
                                    navPitch := r.pitch
                                    navHfov := r.hfov
                                | None => ()
                                }
                            } else {
                                // Logic for targetYaw vs viewFrame
                                switch Nullable.toOption(hotspot.targetYaw) {
                                | Some(ty) =>
                                    navYaw := ty
                                    navPitch := switch Nullable.toOption(hotspot.targetPitch) { | Some(p) => p | None => 0.0 }
                                    navHfov := switch Nullable.toOption(hotspot.targetHfov) { | Some(h) => h | None => 90.0 }
                                | None =>
                                    switch Nullable.toOption(hotspot.viewFrame) {
                                    | Some(vf) =>
                                        navYaw := vf.yaw
                                        navPitch := vf.pitch
                                        navHfov := vf.hfov
                                    | None => ()
                                    }
                                }
                            }
                            
                            Debug.info("Hotspot", "Navigating to " ++ hotspot.target, ())
                            Navigation.navigateToScene(
                                idx, 
                                state.activeIndex, 
                                index, 
                                ~targetYaw=navYaw.contents, 
                                ~targetPitch=navPitch.contents, 
                                ~targetHfov=navHfov.contents, 
                                ()
                            )
                         | None => Debug.warn("Hotspot", "Target index not found", ())
                         }
                     | None => Debug.warn("Hotspot", "Target scene not found", ())
                     }
                 }
            })
        }
    }
}

let syncHotspots = (
    v: Viewer.t, 
    state: state, 
    scene: scene, 
    incomingLink: option<Navigation.linkInfo>, 
    isSimulationMode: bool
) => {
    
    let config = Viewer.getConfig(v)
    let hs = try {
        (Obj.magic(config)["hotSpots"]: array<{..}>)
    } catch {
    | _ => []
    }
    
    // Remove existing
    Belt.Array.forEach(hs, h => {
        let idVal = (Obj.magic(h)["id"])
        
        // Handle if ID is string or other; JS binding usually gives string
        // We need to cast carefully.
        let id: string = Obj.magic(idVal)
        if id != "" {
            Viewer.removeHotSpot(v, id)
        }
    })
    
    // Add new
    Belt.Array.forEachWithIndex(scene.hotspots, (i, h) => {
        let conf = createHotspotConfig(~hotspot=h, ~index=i, ~state=state, ~scene=scene, ~incomingLink=incomingLink, ~isSimulationMode=isSimulationMode)
        Viewer.addHotSpot(v, conf)
    })
}
