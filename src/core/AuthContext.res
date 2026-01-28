type user = {
  id: string,
  email: string,
  name: string,
}

type authState =
  | Unauthenticated
  | Authenticated({user: user, token: string})

type contextValue = {
  state: authState,
  login: (string, user) => unit,
  logout: unit => unit,
  isAuthenticated: bool,
}

let defaultContext = {
  state: Unauthenticated,
  login: (_, _) => (),
  logout: () => (),
  isAuthenticated: false,
}

let context = React.createContext(defaultContext)

module ContextProvider = {
  let make = React.Context.provider(context)
}

module Provider = {
  @react.component
  let make = (~children) => {
    let (state, setState) = React.useState(() => Unauthenticated)

    React.useEffect0(() => {
      let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")
      let userStr = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_user")

      switch (token, userStr) {
      | (Some(t), Some(u)) =>
        try {
          let parsedUser: user = %raw(`function(str) { return JSON.parse(str) }`)(u)
          setState(_ => Authenticated({user: parsedUser, token: t}))
        } catch {
        | _ => ()
        }
      | _ => ()
      }
      None
    })

    let login = (token: string, user: user) => {
      Dom.Storage2.localStorage->Dom.Storage2.setItem("auth_token", token)
      let userStr: string = %raw(`function(u) { return JSON.stringify(u) }`)(user)
      Dom.Storage2.localStorage->Dom.Storage2.setItem("auth_user", userStr)
      setState(_ => Authenticated({user: user, token: token}))
    }

    let logout = React.useCallback0(() => {
      Dom.Storage2.localStorage->Dom.Storage2.removeItem("auth_token")
      Dom.Storage2.localStorage->Dom.Storage2.removeItem("auth_user")
      setState(_ => Unauthenticated)
    })

    React.useEffect1(() => {
      let handleLogout = _ => logout()
      let _ = %raw(`function(handler) { window.addEventListener('auth:logout', handler) }`)(handleLogout)
      Some(() => {
        let _ = %raw(`function(handler) { window.removeEventListener('auth:logout', handler) }`)(handleLogout)
      })
    }, [logout])

    let isAuthenticated = switch state {
    | Authenticated(_) => true
    | Unauthenticated => false
    }

    let value = {state, login, logout, isAuthenticated}

    <ContextProvider value> children </ContextProvider>
  }
}

let useAuth = () => React.useContext(context)
