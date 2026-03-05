// @efficiency-role: ignored
// @efficiency: infra-adapter
type locale = En | Es

type contextValue = {
  locale: locale,
  setLocale: locale => unit,
  t: string => string,
}

let defaultContext = {
  locale: En,
  setLocale: _ => (),
  t: key => key,
}

let context = React.createContext(defaultContext)

module ContextProvider = {
  let make = React.Context.provider(context)
}

@module("./locales/en.json") external en: JSON.t = "default"
@module("./locales/es.json") external es: JSON.t = "default"

let getNestedString = (json: JSON.t, path: string): option<string> => {
  let keys = String.split(path, ".")
  let keyCount = Belt.Array.length(keys)

  let rec walk = (current: JSON.t, index: int): option<string> => {
    if index >= keyCount {
      switch JsonCombinators.Json.decode(current, JsonCombinators.Json.Decode.string) {
      | Ok(value) => Some(value)
      | Error(_) => None
      }
    } else {
      let key = keys->Belt.Array.get(index)->Option.getOr("")
      switch JsonCombinators.Json.decode(
        current,
        JsonCombinators.Json.Decode.object(field =>
          field.optional(key, JsonCombinators.Json.Decode.id)
        ),
      ) {
      | Ok(Some(next)) => walk(next, index + 1)
      | _ => None
      }
    }
  }

  walk(json, 0)
}

module Provider = {
  @react.component
  let make = (~children) => {
    let (locale, setLocale) = React.useState(() => En)

    let currentDict = switch locale {
    | En => en
    | Es => es
    }

    let t = (key: string) => {
      switch getNestedString(currentDict, key) {
      | Some(s) => s
      | None => key
      }
    }

    let value = {locale, setLocale: l => setLocale(_ => l), t}

    <ContextProvider value> children </ContextProvider>
  }
}

let useTranslation = () => React.useContext(context)
