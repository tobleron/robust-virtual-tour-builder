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
  // Ruthless helper to sanitize messages from any potential JSON or technical syntax
  let cleanMessage = (msg: string) => {
    Logger.debug(
      ~module_="Notification",
      ~message="RAW_NOTIFICATION",
      ~data=JsonCombinators.Json.Encode.object([("raw", JsonCombinators.Json.Encode.string(msg))]),
      (),
    )

    let trimmed = msg->String.trim

    // Recursive extraction to handle nested JSON or prefixed JSON
    let rec extractClean = (input: string) => {
      let s = input->String.indexOf("{")
      let e = input->String.lastIndexOf("}")

      if s != -1 && e != -1 && e > s {
        let jsonPart = input->String.substring(~start=s, ~end=e + 1)
        switch JsonCombinators.Json.parse(jsonPart) {
        | Ok(json) =>
          let decoder = JsonCombinators.Json.Decode.oneOf([
            JsonCombinators.Json.Decode.field("message", JsonCombinators.Json.Decode.string),
            JsonCombinators.Json.Decode.field("error", JsonCombinators.Json.Decode.string),
            JsonCombinators.Json.Decode.field("detail", JsonCombinators.Json.Decode.string),
            JsonCombinators.Json.Decode.field("details", JsonCombinators.Json.Decode.string),
            JsonCombinators.Json.Decode.field("msg", JsonCombinators.Json.Decode.string),
            JsonCombinators.Json.Decode.field("reason", JsonCombinators.Json.Decode.string),
          ])

          switch JsonCombinators.Json.decode(json, decoder) {
          | Ok(clean) => extractClean(clean) // Check if the extracted part is also JSON
          | Error(_) =>
            if s > 0 {
              input->String.substring(~start=0, ~end=s)->String.trim ++ " (Technical Error)"
            } else {
              "A technical error occurred"
            }
          }
        | Error(_) => input // Not valid JSON, return as is (will be checked by desperation filter)
        }
      } else {
        input
      }
    }

    let result = extractClean(trimmed)

    // Secondary strip: common technical prefixes and patterns
    let stripped =
      result
      ->String.replaceRegExp(/^Backend error: \d+\s+/, "")
      ->String.replaceRegExp(/^Error:\s+/i, "")
      ->String.replaceRegExp(/^Uncaught\s+/i, "")
      ->String.replaceRegExp(/^Exception:\s+/i, "")
      ->String.trim

    // Final Desperation check: If it STILL contains JSON syntax elements, kill it
    let final = if (
      stripped->String.includes("{") ||
      stripped->String.includes("}") ||
      stripped->String.includes("[") ||
      stripped->String.includes("]") ||
      stripped->String.includes("\":")
    ) {
      "An unexpected server error occurred"
    } else {
      stripped
    }

    Logger.debug(
      ~module_="Notification",
      ~message="CLEAN_NOTIFICATION",
      ~data=JsonCombinators.Json.Encode.object([
        ("clean", JsonCombinators.Json.Encode.string(final)),
      ]),
      (),
    )
    final
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
