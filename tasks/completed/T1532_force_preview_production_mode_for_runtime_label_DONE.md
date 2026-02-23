# T1532 - Force preview runtime to production mode

## Objective
Ensure `npm run start` always exposes production runtime env values so sidebar build label resolves to stable.

## Scope
- Update `scripts/start-prod.sh` preview launch command.
- Verify prod start health and runtime env behavior.

## Acceptance Criteria
- `npm run start` launches preview in production mode.
- Sidebar build info resolves to stable in local prod runtime.
- API proxy behavior remains functional.

## Verification
- `npm run start`
- `curl http://localhost:3000/api/health` returns 200.
