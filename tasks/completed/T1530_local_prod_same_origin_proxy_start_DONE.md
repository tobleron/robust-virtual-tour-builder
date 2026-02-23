# T1530 - Local production same-origin startup via preview proxy

## Objective
Make local production startup behave like deployed production by serving built frontend through a server that forwards `/api` routes to backend, preventing Pannellum/project file load failures caused by missing proxy behavior.

## Scope
- Update `scripts/start-prod.sh` runtime orchestration.
- Keep backend in optimized mode (`cargo run --release`).
- Replace static server path with proxy-capable preview runtime.
- Verify build and runtime health.

## Acceptance Criteria
- `npm run start` builds frontend and starts backend release mode.
- Frontend runtime provides `/api/*` passthrough to backend on local prod start.
- `http://localhost:3000/api/health` returns `200` while start runtime is active.
- No regressions in startup branch switch + cleanup behavior.

## Verification
- `npm run build`
- `npm run start`
- Curl checks for `http://localhost:8080/api/health` and `http://localhost:3000/api/health`.
