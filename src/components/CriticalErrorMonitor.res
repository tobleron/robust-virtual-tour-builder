open Types
open Actions

@react.component
let make = () => {
  let {appMode} = AppContext.useUiSlice()
  let hasShown = React.useRef(false)

  React.useEffect1(() => {
    switch appMode {
    | SystemBlocking(CriticalError(msg)) =>
      if !hasShown.current {
        hasShown.current = true

        let handleReset = () => {
          hasShown.current = false
          GlobalStateBridge.dispatch(DispatchAppFsmEvent(Reset))
          EventBus.dispatch(CloseModal)
        }

        EventBus.dispatch(
          ShowModal({
            title: "Critical Error",
            description: Some(msg),
            icon: Some("alert-triangle"),
            content: None,
            buttons: [
              {
                label: "Reload Application",
                class_: "btn-danger",
                onClick: handleReset,
                autoClose: Some(true),
              },
            ],
            onClose: None,
            allowClose: Some(false),
            className: Some("modal-red"),
          }),
        )
      }
    | _ =>
      if hasShown.current {
        hasShown.current = false
      }
    }
    None
  }, [appMode])

  React.null
}
