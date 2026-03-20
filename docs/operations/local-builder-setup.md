# Local Builder Setup

The stable local-builder flow is designed for adopters who run the builder from the `main` branch.

## Fresh Install

### macOS / Linux
```bash
./scripts/setup-local-builder.sh
```

### Windows PowerShell
```powershell
./scripts/setup-local-builder.ps1
```

What this does:
- installs missing local prerequisites through the supported package manager when possible
- creates `config/builder.runtime.toml` from the example defaults
- creates `backend/.env.local-builder` with generated secrets if it does not exist
- builds the frontend and backend for production
- starts the single-server builder runtime

## Daily Start

After the first setup, use:

```bash
npm run start
```

This stable launcher:
- requires `main`
- auto-switches from another branch only when the worktree is clean
- stops with guidance if uncommitted work would be affected
- preserves `backend/target` for incremental release builds
- serves both the UI and API from the same host and port

## Runtime Config

The stable runtime reads:

- `config/builder.runtime.toml`
- `backend/.env.local-builder`

`config/builder.runtime.toml` controls non-secret runtime settings:

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

Defaults are generated automatically, so local installs do not require edits.

## VPS-Oriented Use

If you want the builder to bind on a VPS:

1. Edit `config/builder.runtime.toml`
2. Set:
   - `profile = "vps"`
   - `host = "0.0.0.0"` or the desired bind host
   - `base_url` to the public builder URL
3. Start with `npm run start`

When `profile = "vps"` and the builder has not been configured yet, the launcher prints a one-time setup URL for creating the first owner account safely.
