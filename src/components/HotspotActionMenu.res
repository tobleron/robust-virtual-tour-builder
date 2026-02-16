/* src/components/HotspotActionMenu.res */
open Types

@react.component
let make = (~hotspot: hotspot, ~index: int, ~onClose: unit => unit) => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  let targetSceneOpt = Belt.Array.getBy(state.scenes, s => s.name == hotspot.target)
  let isAutoForward = switch targetSceneOpt {
  | Some(ts) => ts.isAutoForward
  | None => false
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
    let currentState = AppContext.getBridgeState()
    let currentTargetSceneOpt = Belt.Array.getBy(currentState.scenes, s => s.name == hotspot.target)
    switch currentTargetSceneOpt {
    | Some(ts) =>
      switch Belt.Array.getIndexBy(currentState.scenes, s => s.name == hotspot.target) {
      | Some(idx) =>
        let newVal = !ts.isAutoForward
        HotspotManager.handleUpdateSceneMetadata(
          idx,
          Logger.castToJson({"isAutoForward": newVal}),
        )->ignore
        EventBus.dispatch(ForceHotspotSync)
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
      | None => ()
      }
    | None => ()
    }
  }

  let handleNavigate = () => {
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
            ? "bg-accent/10 border-accent/20 text-accent-light"
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
