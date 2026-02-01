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
  // Helper to santize messages that might be raw JSON
  let cleanMessage = (msg: string) => {
    if msg->Js.String2.startsWith("{") && msg->Js.String2.endsWith("}") {
      switch JsonCombinators.Json.parse(msg) {
      | Ok(json) =>
        // Try to decode common error fields
        let decoder = JsonCombinators.Json.Decode.oneOf(list{
          JsonCombinators.Json.Decode.field("message", JsonCombinators.Json.Decode.string),
          JsonCombinators.Json.Decode.field("error", JsonCombinators.Json.Decode.string),
          JsonCombinators.Json.Decode.field("detail", JsonCombinators.Json.Decode.string),
        })
        
        switch JsonCombinators.Json.decode(json, decoder) {
        | Ok(clean) => clean
        | Error(_) => "An error occurred (details in console)"
        }
      | Error(_) => msg
      }
    } else {
      msg
    }
  }
  React.useEffect0(() => {
    let unsubscribe = EventBus.subscribe(event => {
      switch event {
      | ShowNotification(msg, type_, data) =>
        ignore(data)
        let cleanMsg = cleanMessage(msg)
        switch type_ {
        | #Success => Shadcn.Sonner.success(cleanMsg)
        | #Error => Shadcn.Sonner.error(cleanMsg)
        | #Warning => Shadcn.Sonner.warning(cleanMsg)
        | #Info => Shadcn.Sonner.info(cleanMsg)
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
