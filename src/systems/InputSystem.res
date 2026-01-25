/* src/systems/InputSystem.res */

open ReBindings
open EventBus

/* Navigation module should be available globally or imported */
/* We can use the NavigationSystem bindings in ReBindings if needed, but they are limited */
/* Better to bind to Navigation.res if possible, or assume it's available as module `Navigation` */
/* But Navigation.res might not expose cancelNavigation if it's internal? */
/* NavigationSystem.js exposed it. */
/* Let's assume Navigation module has it */

/* Local Binding to Navigation.res functionality if not exposed directly */
/* Actually, since Navigation.res is a file module, `Navigation` should be available. */

let handleGlobalEscape = (e: Dom.event) => {
  /* Priority 1: Sidebar / UI Modals */
  let modals = ["style-modal", "new-project-modal", "about-modal", "modal-container"]
  let handled = ref(false)

  Belt.Array.forEach(modals, modalId => {
    if !handled.contents {
      switch Dom.getElementById(modalId)->Nullable.toOption {
      | Some(modal) =>
        let style = Window.getComputedStyle(modal)
        let display = Dom.getPropertyValue(style, "display")
        let hasOverlay =
          Dom.querySelector(modal, ".modal-overlay")->Nullable.toOption->Belt.Option.isSome

        if display == "flex" || hasOverlay {
          Logger.debug(
            ~module_="InputSystem",
            ~message="MODAL_CLOSE",
            ~data=Some({"modalId": modalId}),
            (),
          )

          if modalId == "modal-container" {
            switch Dom.querySelector(modal, "#cancel-link")->Nullable.toOption {
            | Some(btn) =>
              Dom.click(btn)
              Dom.preventDefault(e)
              handled := true
            | None => ()
            }
          }

          if !handled.contents {
            /* Try finding close buttons */
            let selector = "#btn-close-style, #btn-new-cancel, #btn-close-about"
            switch Dom.querySelector(modal, selector)->Nullable.toOption {
            | Some(btn) =>
              Dom.click(btn)
              Dom.preventDefault(e)
              handled := true
            | None =>
              /* Fallback */
              let overlay = Dom.querySelector(modal, ".modal-overlay")->Nullable.toOption
              if Belt.Option.isSome(overlay) {
                let anyCancel = Dom.querySelector(
                  modal,
                  "button[id*='cancel'], button[id*='close'], .btn-secondary",
                )
                switch anyCancel->Nullable.toOption {
                | Some(btn) =>
                  Dom.click(btn)
                  Dom.preventDefault(e)
                  handled := true
                | None => ()
                }
              }
            }
          }
        }
      | None => ()
      }
    }
  })

  if !handled.contents {
    /* Priority 2: Context Menus */
    switch Dom.getElementById("context-menu")->Nullable.toOption {
    | Some(menu) =>
      if !Dom.contains(menu, "hidden") {
        Logger.debug(~module_="InputSystem", ~message="CONTEXT_MENU_CLOSE", ())
        Dom.add(menu, "hidden")
        Dom.remove(menu, "flex")
        Dom.preventDefault(e)
        handled := true
      }
    | None => ()
    }
  }

  if !handled.contents {
    let state = GlobalStateBridge.getState()

    /* Priority 3: Linking Mode */
    if state.isLinking {
      Logger.info(~module_="InputSystem", ~message="LINKING_CANCELLED", ())
      GlobalStateBridge.dispatch(Actions.StopLinking)
      EventBus.dispatch(ShowNotification("Linking cancelled", #Info))
      Dom.preventDefault(e)
    } else {
      /* Priority 4: Simulation */
      if state.simulation.status == Running {
        Logger.info(~module_="InputSystem", ~message="SIMULATION_STOPPED_ESC", ())
        Navigation.cancelNavigation()
        GlobalStateBridge.dispatch(Actions.StopAutoPilot)
        GlobalStateBridge.dispatch(Actions.SetActiveScene(0, 0.0, 0.0, None))

        // Force hide snapshot overlay and release locks for maximum robustness
        switch Dom.getElementById("viewer-snapshot-overlay")->Nullable.toOption {
        | Some(el) => Dom.ClassList.remove(Dom.classList(el), "snapshot-visible")
        | None => ()
        }
        ViewerState.state.isSwapping = false
        ViewerState.state.isSceneLoading = false

        EventBus.dispatch(ShowNotification("Simulation Stopped", #Info))
        Dom.preventDefault(e)
        handled := true
      }

      if !handled.contents {
        /* Priority 5: Navigation */

        Navigation.cancelNavigation()
      }
    }
  }
}

let initInputSystem = () => {
  Logger.initialized(~module_="InputSystem")
  Dom.addEventListener(Dom.documentBody, "keydown", e => {
    let key = Dom.key(e)
    let ctrlKey = Dom.ctrlKey(e)
    let shiftKey = Dom.shiftKey(e)

    if key == "Escape" {
      handleGlobalEscape(e)
    } else if key == "Enter" {
      let state = GlobalStateBridge.getState()
      if state.isLinking {
        Dom.preventDefault(e)
        Dom.stopPropagation(e)

        switch state.linkDraft {
        | Some(draft) =>
          let intermediate = switch draft.intermediatePoints {
          | Some(pts) => pts
          | None => []
          }

          let (y, p, cy, cp, ch) = switch Belt.Array.get(
            intermediate,
            Array.length(intermediate) - 1,
          ) {
          | Some(last) => (last.yaw, last.pitch, last.camYaw, last.camPitch, last.camHfov)
          | None => (draft.yaw, draft.pitch, draft.camYaw, draft.camPitch, draft.camHfov)
          }

          let draftNull = Nullable.make(draft)

          LinkModal.showLinkModal(
            ~pitch=p,
            ~yaw=y,
            ~camPitch=cp,
            ~camYaw=cy,
            ~camHfov=ch,
            ~linkDraft=draftNull,
            (),
          )
        | None =>
          // Use current viewer
          switch Nullable.toOption(ReBindings.Viewer.instance) {
          | Some(v) =>
            let y = ReBindings.Viewer.getYaw(v)
            let p = ReBindings.Viewer.getPitch(v)
            let h = ReBindings.Viewer.getHfov(v)

            LinkModal.showLinkModal(
              ~pitch=p,
              ~yaw=y,
              ~camPitch=p,
              ~camYaw=y,
              ~camHfov=h,
              ~linkDraft=Nullable.null,
              (),
            )
          | None => ()
          }
        }
      }
    } else if ctrlKey && shiftKey && (key == "D" || key == "d") {
      let newStateResult = %raw(`(window.DEBUG && window.DEBUG.toggle) ? window.DEBUG.toggle() : false`)
      Logger.info(
        ~module_="InputSystem",
        ~message="DEBUG_TOGGLE",
        ~data=Some({"newState": newStateResult ? "enabled" : "disabled"}),
        (),
      )
      EventBus.dispatch(
        ShowNotification(newStateResult ? "Debug mode: ON" : "Debug mode: OFF", #Info),
      )
    } else if ctrlKey && shiftKey {
      switch key {
      | "1" => {
          Logger.setLevel(Logger.Trace)
          EventBus.dispatch(ShowNotification("Level: TRACE", #Info))
        }
      | "2" => {
          Logger.setLevel(Logger.Debug)
          EventBus.dispatch(ShowNotification("Level: DEBUG", #Info))
        }
      | "3" => {
          Logger.setLevel(Logger.Info)
          EventBus.dispatch(ShowNotification("Level: INFO", #Info))
        }
      | _ => ()
      }
    }
  })
}
