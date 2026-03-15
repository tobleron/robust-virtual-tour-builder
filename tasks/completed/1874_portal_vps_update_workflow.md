# 1874 Portal VPS Update Workflow

## Objective
Create a reliable one-command deployment workflow for the portal VPS so source changes can be synced, built, restarted, and verified without manual guesswork.

## Required Changes
- Improve the existing portal VPS deploy script.
- Add a simple wrapper command for the current production VPS.
- Include post-deploy service and health verification.
- Keep the workflow portal-only.

## Verification
- Run the new wrapper in dry form or inspect generated commands.
- Verify `npm run build`, `cargo check`, and portal-only runtime assumptions remain valid.
- `bash -n scripts/deploy-portal-vps.sh`
- `bash -n scripts/update-portal.sh`

## Notes
- Do not embed SSH passwords in repo scripts.
- Assume SSH key or normal interactive SSH usage.
- Deploy script now performs an explicit SSH preflight check before syncing, retries health probes after restart, and repairs remote `cache/` ownership for the `robustvtb` runtime user to prevent post-deploy degraded health.
- Current blocker to end-to-end rerun is infrastructure-side: `ssh root@5.249.151.59` is returning `Connection refused` while the public portal remains reachable over HTTP.
