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
  let (notifications, setNotifications) = React.useState(_ => [])

  React.useEffect0(() => {
    let unsubscribe = EventBus.subscribe(event => {
      switch event {
      | ShowNotification(msg, type_) =>
        let id = Math.random()->Float.toString
        let newNotif = {id, msg, type_, visible: true}
        setNotifications(prev => Belt.Array.concat(prev, [newNotif]))

        let _ = setTimeout(
          () => {
            // Cleanup
            setNotifications(prev => Belt.Array.keep(prev, n => n.id !== id))
          },
          3500,
        )
      | _ => ()
      }
    })
    Some(unsubscribe)
  })

  // Render
  <>
    {notifications
    ->Belt.Array.map(n => {
      let typeClass = switch n.type_ {
      | #Info => ""
      | #Success => "success"
      | #Error => "error"
      | #Warning => "warning"
      }

      <div key={n.id} className={`toast show ${typeClass}`} role="status" ariaLive=#polite>
        <span className="material-icons" style={makeStyle({"fontSize": "20px"})} ariaHidden=true>
          {React.string(
            switch n.type_ {
            | #Error => "error_outline"
            | #Success => "check_circle"
            | #Warning => "warning_amber"
            | _ => "info_outline"
            },
          )}
        </span>
        <span> {React.string(n.msg)} </span>
      </div>
    })
    ->React.array}
  </>
}

let notify = (msg, type_) => {
  EventBus.dispatch(ShowNotification(msg, type_))
}
