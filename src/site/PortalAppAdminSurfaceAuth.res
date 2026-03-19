// @efficiency-role: ui-component
open PortalAppUI

@react.component
let make = (~flash, ~onSignIn) => {
  let (email, setEmail) = React.useState(() => "")
  let (password, setPassword) = React.useState(() => "")
  let (showPassword, setShowPassword) = React.useState(() => false)

  let submit = event => {
    ReactEvent.Form.preventDefault(event)
    ignore(onSignIn(email, password))
  }

  <div className="portal-shell">
    <main className="portal-main portal-auth-main">
      <section className="portal-hero portal-auth-card">
        {brandLockup()}
        <h1 className="portal-title"> {React.string("Portal Administration")} </h1>
        <p className="portal-subtitle">
          {React.string(
            "Sign in with your internal Robust account to manage portal recipients and tours.",
          )}
        </p>
        {messageNode(~flash)}
        <form className="portal-form" onSubmit={submit}>
          <div className="portal-form-grid">
            <label>
              {React.string("Email")}
              <input
                value={email}
                autoComplete="username"
                onChange={e => setEmail(_ => ReactEvent.Form.target(e)["value"])}
              />
            </label>
            <label>
              {React.string("Password")}
              <div className="portal-password-input">
                <input
                  type_={showPassword ? "text" : "password"}
                  value={password}
                  autoComplete="current-password"
                  onChange={e => setPassword(_ => ReactEvent.Form.target(e)["value"])}
                />
                <button
                  type_="button"
                  className="portal-password-toggle"
                  ariaLabel={showPassword ? "Hide password" : "Show password"}
                  title={showPassword ? "Hide password" : "Show password"}
                  onClick={_ => setShowPassword(isVisible => !isVisible)}
                >
                  {React.string(showPassword ? "Hide" : "Show")}
                </button>
              </div>
            </label>
          </div>
          <div className="portal-form-actions">
            <button className="site-btn site-btn-primary" type_="submit">
              {React.string("Sign In")}
            </button>
            <a className="site-btn site-btn-ghost" href="/forgot-password">
              {React.string("Reset Password")}
            </a>
          </div>
        </form>
      </section>
    </main>
  </div>
}
