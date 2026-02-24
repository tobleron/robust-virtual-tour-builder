/* src/components/HotspotActionMenu.res */
open Types

@react.component
let make = (~hotspot: hotspot, ~index: int, ~onClose: unit => unit) => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  let currentHotspot = switch Belt.Array.get(
    SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
    state.activeIndex,
  ) {
  | Some(scene) => Belt.Array.get(scene.hotspots, index)
  | None => None
  }

  let isAutoForward = switch currentHotspot {
  | Some(h) =>
    switch h.isAutoForward {
    | Some(b) => b
    | None => false
    }
  | None =>
    switch hotspot.isAutoForward {
    | Some(b) => b
    | None => false
    }
  }

  let handleDelete = () => {
    EventBus.dispatch(
      ShowModal({
        title: "Delete Link",
        description: Some("Are you sure you want to delete this link?"),
        content: None,
        icon: Some("warning"),
        className: Some("modal-blue"),
        allowClose: Some(true),
        onClose: None,
        buttons: [
          {
            label: "Cancel",
            class_: "bg-slate-100/10 text-white hover:bg-white/20",
            onClick: () => (),
            autoClose: Some(true),
          },
          {
            label: "Delete",
            class_: "bg-red-500/20 text-white hover:bg-red-500/40",
            onClick: () => {
              HotspotManager.handleDeleteHotspot(state.activeIndex, index, ~getState=() =>
                state
              )->ignore
              NotificationManager.dispatch({
                id: "",
                importance: Success,
                context: Operation("hotspot_action"),
                message: "Link deleted",
                details: None,
                action: None,
                duration: NotificationTypes.defaultTimeoutMs(Success),
                dismissible: true,
                createdAt: Date.now(),
              })
            },
            autoClose: Some(true),
          },
        ],
      }),
    )
    onClose()
  }

  let handleToggleAutoForward = () => {
    // Get current scene's hotspots
    let sceneHotspotsOpt = Belt.Array.get(
      SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
      state.activeIndex,
    )
    let currentSceneHotspots = switch sceneHotspotsOpt {
    | Some(scene) => scene.hotspots
    | None => let empty: array<hotspot> = []; empty
    }

    // Count existing auto-forward hotspots (excluding current one)
    let existingAutoForwardCount = Belt.Array.keep(
      currentSceneHotspots,
      h => switch h.isAutoForward {
      | Some(true) => true
      | _ => false
      },
    )->Belt.Array.length

    let isCurrentAutoForward = switch currentHotspot {
      | Some(h) => switch h.isAutoForward {
        | Some(true) => true
        | _ => false
        }
      | None => false
      }

    let alreadyHasAutoForward = existingAutoForwardCount > 0 && !isCurrentAutoForward

    // Validation 1: Only ONE auto-forward link per scene
    if alreadyHasAutoForward && !isAutoForward {
      // User is trying to ENABLE auto-forward on a second link
      NotificationManager.dispatch({
        id: "autoforward-validation-error",
        importance: Error,
        context: Operation("hotspot_action"),
        message: "Only one auto-forward link per scene",
        details: Some("Auto-forward link must be the LAST link in the scene (the exit path). Disable auto-forward on the existing link first."),
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Error),
        dismissible: true,
        createdAt: Date.now(),
      })
      onClose()
    } else {
      // Validation 2: Auto-forward link must be the LAST link (highest index)
      // When enabling, check if this is the last hotspot
      let isLastHotspot = index >= Belt.Array.length(currentSceneHotspots) - 1

      if !isAutoForward && !isLastHotspot {
        // User is trying to enable auto-forward on a non-last link
        NotificationManager.dispatch({
          id: "autoforward-order-error",
          importance: Error,
          context: Operation("hotspot_action"),
          message: "Auto-forward link must be last",
          details: Some("The auto-forward link should be the last link created in this scene (the exit path). Create your other links first, then set the last one as auto-forward."),
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
        onClose()
      } else {
        // Validation passed - toggle auto-forward
        let newVal = !isAutoForward
        HotspotManager.handleUpdateHotspotMetadata(
          state.activeIndex,
          index,
          Logger.castToJson({"isAutoForward": newVal}),
        )->ignore
        let _ = setTimeout(() => EventBus.dispatch(ForceHotspotSync), 0)
        NotificationManager.dispatch({
          id: "",
          importance: Success,
          context: Operation("hotspot_action"),
          message: "Auto-forward: " ++ if newVal {
            "ENABLED"
          } else {
            "DISABLED"
          },
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Success),
          dismissible: true,
          createdAt: Date.now(),
        })
      }
    }
  }

  let handleNavigate = () => {
    let targetIdx = HotspotTarget.resolveSceneIndex(
      SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
      hotspot,
    )
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

      Scene.Switcher.navigateToScene(
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
    onClose()
  }

  <div className="flex flex-col p-1.5 gap-1.5 min-w-[160px]">
    /* Nav Button */
    <button
      onClick={_ => handleNavigate()}
      className="flex items-center gap-3 px-3 py-2.5 rounded-xl bg-primary/10 text-primary hover:bg-primary hover:text-white transition-all group"
    >
      <LucideIcons.Navigation className="text-lg" />
      <span className="text-[11px] font-semibold uppercase tracking-widest">
        {React.string("GO")}
      </span>
    </button>

    <div className="flex gap-1.5">
      /* Auto-Forward Toggle */
      <button
        onClick={_ => handleToggleAutoForward()}
        className={`flex-1 flex items-center justify-center gap-2 px-3 py-2.5 rounded-xl transition-all border
          ${isAutoForward
            ? "bg-[#4B0082]/20 border-[#4B0082]/30 text-[#a78bfa]"
            : "bg-white/10 border-white/5 text-slate-400 hover:text-slate-200"}`}
        title="Toggle Auto-Forward"
      >
        {if isAutoForward {
          <LucideIcons.FastForward className="text-[16px]" />
        } else {
          <LucideIcons.ChevronRight className="text-[16px]" />
        }}
        <span className="text-[10px] font-semibold uppercase tracking-tighter">
          {React.string(
            if isAutoForward {
              "AUTO"
            } else {
              "MANUAL"
            },
          )}
        </span>
      </button>

      /* Delete Button */
      <button
        onClick={_ => handleDelete()}
        className="w-10 flex items-center justify-center rounded-xl bg-danger/10 text-danger hover:bg-danger hover:text-white transition-all border border-danger/20"
        title="Delete Link"
      >
        <LucideIcons.Trash2 className="text-lg" />
      </button>
    </div>
  </div>
}
