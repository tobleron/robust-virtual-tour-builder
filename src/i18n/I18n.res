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
  let value: Nullable.t<string> = %raw(`
    function(json, path) {
      return path.split('.').reduce((obj, key) => (obj && obj[key] !== undefined) ? obj[key] : null, json)
    }
  `)(json, path)
  value->Nullable.toOption
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
