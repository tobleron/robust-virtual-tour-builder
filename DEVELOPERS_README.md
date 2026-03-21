# Developer Guide

This repository uses a dual-reader model: `README.md` is now exclusively for end-users, while this `DEVELOPERS_README.md` is the reference for contributors and maintainers working on the code.

## Before You Touch Code
1. Read `MAP.md` and `DATA_FLOW.md` to understand the topology and primary data flows.
2. Review `AGENTS.md` plus the relevant workflow guide under `.agent/workflows/` before editing the matching language (`rescript-standards.md` for `.res`, `rust-standards.md` for `.rs`, `testing-standards.md` for tests, etc.).
3. Consult `tasks/TASKS.md` before creating or modifying official tasks.
4. Understand the `_dev-system` analyzer in `_dev-system/README.md`, especially how it synthesizes `tasks/pending/dev_tasks/` guidance.

## Local Setup (Stable Builder Mode)
Run the bundled setup that installs prerequisites, generates runtime files, builds the release assets, and launches the single-server local builder.

macOS / Linux:

```bash
./scripts/setup-local-builder.sh
```

Windows PowerShell:

```powershell
./scripts/setup-local-builder.ps1
```

The script:
- validates tools (`node`, `npm`, `rustup/cargo`, `ffmpeg`, `git`)
- generates `config/builder.runtime.toml` and `backend/.env.local-builder` with safe defaults
- builds frontend/backend for release and preserves `backend/target`
- starts the server that hosts both UI and API on one origin
- auto-selects the next free local port if the configured local port is already in use

Once the first-run setup completes, use:

```bash
npm run start
```

`npm run start` targets the `main` branch, refuses to switch if the worktree is dirty, and keeps incremental release builds intact.

If you need the hot-reloading dev stack instead, use the legacy commands:

```bash
npm run dev
npm run dev:frontend
npm run dev:backend
npm run res:watch
npm run sw:watch
```

The dev stack exposes frontend assets on `http://localhost:3000` and proxies backend requests.

## Testing & Quality
- `npm test` (frontend + backend) runs the full suite.
- `npm run test:frontend` runs Vitest.
- `npm run test:watch` / `npm run test:ui` provide interactive Vitest sessions.
- `npm run build` produces the release bundles.
- `cd backend && cargo test` covers backend unit tests.
- Use `./scripts/fast-commit.sh` or `./scripts/commit.sh "msg"` only when you have explicit permission to snapshot or push.

## `_dev-system` Analyzer
The `_dev-system` directory hosts the analyzer that scans the codebase, computes drag, and generates guidance tasks under `tasks/pending/dev_tasks/`. Read `_dev-system/README.md` to understand:
- what drag is and how thresholds behave
- how configuration lives under `_dev-system/config/efficiency.json`
- how to rerun the analyzer when you touch high-drag modules
- how to interpret the dev tasks before editing large files

Use `_dev-system/README.md` as the reference; this developer guide summarizes only the high-level intent.

## Stability Notes
- `main` carries the production-ready, local-first builder runtime with guards against dev-only shortcuts.
- The portal and builder share release guard scripts accessible under `scripts/guard-main-release.sh`.
- Keep new commits tidy: do not commit generated files like `dist/`, `backend/target/`, or `cache/geocoding.json` unless explicitly requested.

## Additional Resources
- [MAP.md](MAP.md) & [DATA_FLOW.md](DATA_FLOW.md)
- [AGENTS.md](AGENTS.md) overview of workflow constraints
- [docs/operations/local-builder-setup.md](docs/operations/local-builder-setup.md) for setup/runtimes
- [docs/operations/deployment.md](docs/operations/deployment.md) for VPS hosting
- [tasks/TASKS.md](tasks/TASKS.md) for task workflow
