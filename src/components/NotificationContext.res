// Helper for styles
external makeStyle: {..} => ReactDOM.Style.t = "%identity"

type notification = {
  id: string,
  msg: string,
  type_: [#Info | #Success | #Error | #Warning],
  visible: bool,
}

@react.component
let make = () => {
  React.useEffect0(() => {
    let unsubscribe = EventBus.subscribe(event => {
      switch event {
      | ShowNotification(msg, type_, data) =>
        ignore(data)
        switch type_ {
        | #Success => Shadcn.Sonner.success(msg)
        | #Error => Shadcn.Sonner.error(msg)
        | #Warning => Shadcn.Sonner.warning(msg)
        | #Info => Shadcn.Sonner.info(msg)
        }
      | _ => ()
      }
    })
    Some(unsubscribe)
  })

  <div id="vtb-notification-bridge" dataTestId="notification-context" />
}

let notify = (msg, type_, ~data=?) => {
  EventBus.dispatch(ShowNotification(msg, type_, data))
}
