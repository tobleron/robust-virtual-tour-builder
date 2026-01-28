open Vitest

/* Minimal bindings for act */
@module("react") external act: (unit => unit) => unit = "act"
@module("react") external actAsync: (unit => Promise.t<unit>) => Promise.t<unit> = "act"

module TestComponent = {
  @react.component
  let make = () => {
    let {isAuthenticated, login, logout, state} = AuthContext.useAuth()

    <div>
      <div id="auth-status">
        {React.string(isAuthenticated ? "Authenticated" : "Unauthenticated")}
      </div>
      <button
        id="login-btn"
        onClick={_ => login("fake-token", {id: "1", name: "Test", email: "test@test.com"})}
      >
        {React.string("Login")}
      </button>
      <button id="logout-btn" onClick={_ => logout()}> {React.string("Logout")} </button>
      <div id="user-email">
        {switch state {
        | Authenticated({user}) => React.string(user.email)
        | Unauthenticated => React.string("None")
        }}
      </div>
    </div>
  }
}

describe("AuthContext", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = %raw(`function(res, ms){setTimeout(res, ms)}`)(resolve, ms)
    })

  beforeEach(() => {
    Dom.Storage2.localStorage->Dom.Storage2.clear
    ignore(Promise.resolve())
  })

  testAsync("starts unauthenticated", async t => {
    let container = %raw("document.createElement('div')")
    let _ = %raw("document.body.appendChild(container)")
    let root = ReactDOM.Client.createRoot(container)

    await actAsync(
      async () => {
        ReactDOM.Client.Root.render(
          root,
          <AuthContext.Provider>
            <TestComponent />
          </AuthContext.Provider>,
        )
      },
    )

    let _ = await wait(50)

    let status = %raw("container.querySelector('#auth-status').textContent")
    t->expect(status)->Expect.toBe("Unauthenticated")

    ReactDOM.Client.Root.unmount(root, ())
    let _ = %raw("document.body.removeChild(container)")
  })

  testAsync("login updates state", async t => {
    let container = %raw("document.createElement('div')")
    let _ = %raw("document.body.appendChild(container)")
    let root = ReactDOM.Client.createRoot(container)

    await actAsync(
      async () => {
        ReactDOM.Client.Root.render(
          root,
          <AuthContext.Provider>
            <TestComponent />
          </AuthContext.Provider>,
        )
      },
    )

    let _ = await wait(50)

    await actAsync(
      async () => {
        let _ = %raw("container.querySelector('#login-btn').click()")
      },
    )

    let _ = await wait(50)

    let status = %raw("container.querySelector('#auth-status').textContent")
    t->expect(status)->Expect.toBe("Authenticated")

    let email = %raw("container.querySelector('#user-email').textContent")
    t->expect(email)->Expect.toBe("test@test.com")

    ReactDOM.Client.Root.unmount(root, ())
    let _ = %raw("document.body.removeChild(container)")
  })
})
