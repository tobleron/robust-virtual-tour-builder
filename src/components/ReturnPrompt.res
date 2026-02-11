/* src/components/ReturnPrompt.res */
open Types

@react.component
let make = React.memo((~incomingLink, ~scenes) => {
  let dispatch = AppContext.useAppDispatch()

  let processReturnPrompt = () => {
    let v = Nullable.toOption(ReBindings.Viewer.instance)

    switch (v, incomingLink) {
    | (Some(viewer), Some(inc)) =>
      let prevScene = Belt.Array.get(scenes, inc.sceneIndex)
      switch prevScene {
      | Some(scene) =>
        let currentYaw = ReBindings.Viewer.getYaw(viewer)
        ReBindings.Viewer.setYawWithDuration(viewer, currentYaw +. 180.0, 1000)
        dispatch(Actions.SetPendingReturnSceneName(Some(scene.name)))
        NotificationManager.dispatch({
          id: "",
          importance: Success,
          context: Operation("return_prompt"),
          message: "Turned around! NOW click '+' to place the link.",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Success),
          dismissible: true,
          createdAt: Date.now(),
        })

        // Use ReBindings.Dom for manipulation
        switch ReBindings.Dom.getElementById("return-link-prompt") {
        | Nullable.Value(el) =>
          ReBindings.Dom.classList(el)->ReBindings.Dom.ClassList.remove("visible")
        | _ => ()
        }
      | None => ()
      }
    | _ => ()
    }
  }

  let handleReturnPromptClick = React.useMemo2(() =>
    e => {
      JsxEvent.Mouse.stopPropagation(e)
      processReturnPrompt()
    }
  , (incomingLink, scenes))

  let handleReturnPromptKeyDown = React.useMemo2(() =>
    e => {
      if JsxEvent.Keyboard.key(e) == "Enter" {
        JsxEvent.Keyboard.stopPropagation(e)
        processReturnPrompt()
      }
    }
  , (incomingLink, scenes))

  <div
    id="return-link-prompt"
    className="hidden absolute bottom-24 left-1/2 -translate-x-1/2 glass-panel rounded-full px-5 py-2.5 items-center gap-3 shadow-2xl z-[4000] border border-brand-gold/20 cursor-pointer transition-all hover:scale-105 active:scale-95 animate-fade-in-centered"
    onClick={handleReturnPromptClick}
    role="button"
    tabIndex=0
    onKeyDown={handleReturnPromptKeyDown}
  >
    <div
      className="w-6 h-6 bg-brand-gold rounded-full flex items-center justify-center text-black font-semibold text-xs shadow-sm"
    >
      {React.string("↩")}
    </div>
    <div className="return-link-text font-ui text-[13px] font-semibold text-white">
      {React.string("Add Return Link")}
    </div>
  </div>
})
