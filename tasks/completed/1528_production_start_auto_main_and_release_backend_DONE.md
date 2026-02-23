# 1528 - Production start auto-main and release backend

## Objective
Ensure `npm run start` launches a true production runtime by automatically switching to `main` branch, building production assets, serving frontend output, and running backend in fully optimized Rust release mode.

## Scope
- Add a stable production launcher script under `scripts/`.
- Wire `package.json` `start` script to this launcher.
- Enforce branch switch behavior (`git checkout main`) before startup.
- Run backend with `cargo run --release`.
- Keep workflow deterministic and non-interactive.

## Functional Requirements
- [ ] `npm run start` exists in `package.json`.
- [ ] Start flow checks out `main` automatically.
- [ ] Start flow runs frontend production build before serving.
- [ ] Backend starts with `cargo run --release`.
- [ ] Frontend and backend are launched together for runtime use.

## Non-Functional Requirements
- [ ] Script fails fast with clear error if prerequisites are missing.
- [ ] No destructive git operations.
- [ ] Startup logs clearly indicate branch and run modes.

## Files Expected
- `package.json`
- `scripts/start-prod.sh`

## Validation
- [ ] `npm run start` executes successfully from non-main branch and lands on `main`.
- [ ] Backend process command uses Rust release mode.
- [ ] `npm run build` passes after changes.
