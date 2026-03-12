# 1854 Deprecate Fly.io Deployment And Remove Local CLI

## Objective

Remove Fly.io-specific deployment artifacts from the repository and uninstall the local `flyctl` CLI, since Fly.io is no longer part of the deployment path.

## Checklist

- [x] Confirm all Fly.io-related repo artifacts and references.
- [x] Remove the Fly.io GitHub Actions deployment workflow.
- [x] Remove the root Fly.io app configuration file.
- [x] Uninstall the local `flyctl` CLI.
- [x] Run a build-equivalent verification after cleanup.

## Completion Notes

- Removed `.github/workflows/deploy-fly.yml`.
- Removed `fly.toml`.
- Uninstalled Homebrew `flyctl` from `/opt/homebrew/bin/flyctl`.
- Verified `flyctl` is no longer present in `PATH`.
- Verified repo build still succeeds with `npm run build`.

## Notes

- There is a separate non-Fly GitHub CI failure under investigation in `T1853_troubleshoot_github_actions_ci_and_deploy_workflow_failures.md`.
