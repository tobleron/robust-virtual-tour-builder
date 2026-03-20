# 1898 README Main Repo Refresh

## Objective
Rewrite the GitHub-facing `README.md` so it accurately reflects the current `main` branch product shape, especially the stable local-builder setup flow, single-server runtime, VPS-oriented runtime config, portal/public surfaces, and the reorganized documentation tree.

## Requirements
- Make the stable setup path the primary README entrypoint.
- Remove stale or misleading product copy, metadata, and workflow details.
- Update app overview and feature summaries to match the latest docs and current architecture.
- Point readers clearly to the current docs structure for operations, architecture, security, and project mechanics.
- Keep the README useful for both adopters and contributors without mixing the stable and dev workflows confusingly.

## Verification
- `node --check` not applicable
- Visual review of `README.md`
- `git diff -- README.md`
