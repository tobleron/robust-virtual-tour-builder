# 1876 DigitalOcean Portal VPS Cutover and Cleanup

## Objective
Bring the portal onto the new DigitalOcean VPS at `164.90.242.73` using the existing portal-only deployment model, while keeping the builder local. The server must be fully updated first, package caches cleaned, the portal deployed with full release optimization, and build caches cleaned again after successful cutover.

## Required Changes
- Update the new Ubuntu server to the latest packages before deploying the portal.
- Remove package download caches after the OS update.
- Adjust deployment scripts or runtime config as needed for the new DigitalOcean host and key-based SSH workflow.
- Deploy the current portal source to the new VPS.
- Build the portal frontend and the portal-only Rust release binary on the VPS.
- Configure runtime dependencies and service management needed for the portal.
- Verify the portal service is healthy locally on the VPS and publicly through the domain/IP as applicable.
- After a successful optimized build and start, remove disposable build caches that are no longer needed for the running portal.

## Verification
- SSH access works with the generated key.
- `apt` upgrade completes cleanly on the VPS.
- Portal-only release build completes on the VPS.
- `systemctl status` shows the portal service healthy.
- `curl http://127.0.0.1:8080/api/health` succeeds on the VPS.
- Public HTTP access works against the new host or mapped domain.
- Post-build cleanup reclaims space without breaking the running service.

## Activity Log
- Updated `scripts/update-portal.sh` to target the new DigitalOcean host by default.
- Hardened `scripts/deploy-portal-vps.sh` for the new remote workflow:
  - key-based SSH support
  - cleaner rsync exclusions
  - better preflight/error reporting
  - restart health retries
- Updated the DigitalOcean VPS:
  - `apt-get update`
  - full upgrade
  - autoremove
  - cache cleanup
- Installed runtime/build dependencies on the VPS:
  - `nginx`
  - `certbot`
  - `python3-certbot-nginx`
  - `build-essential`
  - `pkg-config`
  - `libssl-dev`
  - `sqlite3`
  - `rsync`
  - Node 20
  - Rust stable
- Added 4 GB swap to make the full release build viable on the 1 GB VPS.
- Created portal runtime directories, system user, env file, nginx site config, systemd unit, and remote build script.
- Synced the portal source to `/opt/robust-vtb/current` and ran the full portal-only optimized build on the VPS.
- Verified the build script removed `backend/target` after installing `/opt/robust-vtb/bin/portal`.
- Diagnosed and fixed three startup blockers on the new VPS:
  - unquoted `DEV_AUTH_NAME` in `/etc/robust-vtb/portal.env`
  - missing writable `LOG_DIR`
  - missing writable `PORTAL_STORAGE_ROOT`
- Bootstrapped and verified the admin account on the new VPS:
  - `admin@robust.local`
  - `PortalAdmin!2026`

## Final Runtime State
- Host: `164.90.242.73`
- Domain DNS now resolves to the new host for both:
  - `robust-vtb.com`
  - `www.robust-vtb.com`
- Portal health:
  - `curl http://127.0.0.1:8080/api/health` returns `200 OK`
- Public HTTP:
  - `http://164.90.242.73`
  - `http://www.robust-vtb.com/portal-admin/signin`
- Disk state after cleanup:
  - `/` at about `41%` used
  - `/opt/robust-vtb/current` about `894M`
  - `/var/lib/robust-vtb` about `376K`
  - `/root/.cargo/registry` about `408M`

## Notes
- Do not touch local builder workflows beyond what is needed to point deployment scripts at the new VPS.
- Preserve the portal-only backend split; no builder/media-export runtime should be deployed.
- Keep this task active until the user confirms the new VPS setup is satisfactory.
