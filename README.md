# Robust Virtual Tour Builder

![CI](https://github.com/tobleron/robust-virtual-tour-builder/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/badge/License-AGPL_v3-blue.svg)
![GitHub Stars](https://img.shields.io/github/stars/tobleron/robust-virtual-tour-builder)

<!-- METADATA_START -->
**Version:** 5.3.6 (Build 68)  
**Release Date:** March 20, 2026  
**Status:** Stable `main` ships the local-first builder runtime  
**License:** AGPL v3 + optional commercial license
<!-- METADATA_END -->

Robust Virtual Tour Builder is an open source virtual-tour authoring platform built with ReScript and Rust.

It now ships in two practical shapes:
- a **local-first builder** for creating and editing tours on your own machine
- a **portal/customer delivery surface** for published tours and broker-facing sharing workflows

The `main` branch is the stable adopter path.

## Stable Setup

Use this if you want the repo to behave like the product, not like a dev sandbox.

### First Run

Clone the repo and stay on `main`, then run the setup script for your OS.

macOS / Linux:

```bash
./scripts/setup-local-builder.sh
```

Windows PowerShell:

```powershell
./scripts/setup-local-builder.ps1
```

What this does:
- installs missing local prerequisites through the supported package manager when possible
- generates `config/builder.runtime.toml` with ready-to-run defaults
- generates `backend/.env.local-builder` with local secrets if needed
- builds the frontend and backend for production
- starts the builder as a **single server** on one host and port

Open:

```text
http://127.0.0.1:8080
```

### Daily Start

After first setup:

```bash
npm run start
```

Stable launcher behavior:
- expects the repo to run from `main`
- auto-switches to `main` only when the worktree is clean
- stops with guidance if branch switching would affect uncommitted work
- preserves incremental backend release builds
- serves both the UI and API from the same origin

### Runtime Config

Stable runtime settings live in:
- `config/builder.runtime.toml`
- `backend/.env.local-builder`

Default generated runtime config:

```toml
[app]
surface = "builder"
profile = "local"

[server]
host = "127.0.0.1"
port = 8080

[public]
base_url = "http://127.0.0.1:8080"
```

For VPS-oriented builder hosting, edit:
- `profile`
- `host`
- `port`
- `base_url`

When `profile = "vps"` and no owner account exists yet, the launcher prints a one-time setup URL for the first admin.

### Local Recovery

On local installs:
- visit `/local-reset` to restart first-time setup
- auth-only reset preserves local projects by default
- full reset is opt-in and wipes local project data

Full setup details: [docs/operations/local-builder-setup.md](docs/operations/local-builder-setup.md)

## What The App Does

### Builder
- imports panoramic scenes and project packages
- manages scenes, floors, labels, hotspots, traversal, and tagging
- exports self-contained tours
- supports teaser/video workflows and publish-ready packaging

### Portal
- hosts published tours for customer-facing delivery
- includes portal admin workflows for tour management and recipient/customer assignment
- includes portal customer/gallery surfaces for delivered tours

### Reliability
- operation lifecycle tracking for long-running workflows
- debounced persistence and recovery-oriented local state handling
- navigation supervision with structured cancellation and retry semantics
- recovery flows for interrupted operations and local auth reset

## Current Feature Areas

- **Scene authoring:** floor-aware scene organization, hotspot editing, linking, labeling, and traversal logic
- **Viewer runtime:** dual-viewer transition architecture, hotspot overlays, navigation feedback, and simulation support
- **Project IO:** local persistence, dashboard reopen flows, package import/export, and resumable upload pathways
- **Publishing:** portal library workflows, customer delivery, and export packaging
- **Media tooling:** image processing, EXIF analysis, thumbnails, geocoding support, FFmpeg-backed teaser/video paths
- **Ops/security:** auth flows, rate limiting, session handling, release guards, and health endpoints

## Architecture Snapshot

Core stack:
- **Frontend:** ReScript v12, React 19, Rsbuild, Tailwind CSS 4
- **Backend:** Rust, Actix-web, SQLx, SQLite
- **Testing:** Vitest and Playwright

Core patterns:
- centralized reducer architecture on the frontend
- FSM-driven navigation and application lifecycle
- dual-viewer scene transition system
- local-first persistence and recovery layers
- service-oriented Rust backend with portal, project, media, and auth boundaries

Key references:
- [MAP.md](MAP.md)
- [DATA_FLOW.md](DATA_FLOW.md)
- [docs/architecture/overview.md](docs/architecture/overview.md)
- [docs/project/mechanics.md](docs/project/mechanics.md)

## Documentation Map

Start here depending on intent:
- **Stable setup / hosting:** [docs/operations/local-builder-setup.md](docs/operations/local-builder-setup.md), [docs/operations/deployment.md](docs/operations/deployment.md)
- **Architecture:** [docs/architecture/INDEX.md](docs/architecture/INDEX.md)
- **Project behavior:** [docs/project/INDEX.md](docs/project/INDEX.md)
- **Security / auth / licensing:** [docs/security/INDEX.md](docs/security/INDEX.md)
- **API reference:** [docs/api/INDEX.md](docs/api/INDEX.md)
- **Docs root:** [docs/INDEX.md](docs/INDEX.md)

## Development Workflow

Use this only if you are actively developing the app itself.

Setup:

```bash
./scripts/setup.sh
```

Start the full dev stack:

```bash
npm run dev
```

Open:

```text
http://localhost:3000
```

Useful commands:

```bash
npm run dev:frontend
npm run dev:backend
npm run res:watch
npm run sw:watch
npm run build
npm test
```

## License

This project uses a dual-license model:
- **AGPL v3** for users comfortable with AGPL compliance
- **Commercial terms** for proprietary or separately contracted use

Start here:
- [docs/security/licensing.md](docs/security/licensing.md)
- [LICENSE](LICENSE)
- [LICENSE_COMMERCIAL](LICENSE_COMMERCIAL)

## Contact

Maintained by **Arto Kalishian**, the original developer of Robust Virtual Tour Builder.

- Email: `arto.eg@gmail.com`
- Website: `https://www.robust-vtb.com`
- GitHub Issues: use the repo issue tracker for bugs and setup problems
- Commercial / implementation inquiries: contact directly by email
