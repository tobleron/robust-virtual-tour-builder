# 1896 Local Builder Setup And Reset Productization

## Objective
Implement a production-safe local-builder onboarding and recovery flow so adopters running the stable branch locally can set up their first account without dev-login shortcuts, recover access by resetting local auth, and keep local project state safe and easy to understand.

## Requirements
- Add a local-only first-run setup flow that creates the initial admin account and then disables itself.
- Add a local-only reset flow that can reset auth state without deleting projects by default, while also offering an explicit full factory reset.
- Keep project state local-first and preserve projects/assets during auth-only reset.
- Thread the setup/reset pages through the existing site shell so README-driven local usage feels coherent.
- Keep the portal-oriented email password recovery flow intact.
- Make the stable local-builder path compatible with `main` branch productization and remove dependence on dev bootstrap login for normal use.

## Implementation Notes
- Backend should expose setup status/bootstrap/reset endpoints guarded to localhost-style requests only.
- Frontend should add `/setup` and `/local-reset` surfaces and redirect appropriately based on setup state.
- Sign-in UX on local installs should surface the local reset path clearly.
- README/start-path alignment work should be limited to the stable local-builder experience rather than portal deployment changes.
- Stable `npm run start` should become a single-server builder runtime on `main`, not a builder+preview dual-process launcher.
- Runtime host/port/base URL should come from a generated TOML config with safe local defaults and a VPS-oriented profile option.
- First-time remote/VPS bootstrap must use a one-time setup token instead of an always-open remote setup page.

## Verification
- `cargo build`
- `npm run build`
- Manual local auth flow verification: first-run setup, normal sign-in, auth-only reset, and preserved project state
