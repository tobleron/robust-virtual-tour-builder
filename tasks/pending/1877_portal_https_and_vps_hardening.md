# 1877 Portal HTTPS and VPS Hardening

## Objective
Finish the production-facing hardening pass for the live portal on the DigitalOcean VPS after the successful HTTP bring-up. The portal is already reachable and functional over plain HTTP; this task covers HTTPS issuance, canonical redirect cleanup, cookie/security posture alignment, and basic VPS hardening suitable for the portal-only deployment model.

## Required Changes
- Issue a valid Let's Encrypt certificate for:
  - `robust-vtb.com`
  - `www.robust-vtb.com`
- Update nginx so the canonical public host is:
  - `https://www.robust-vtb.com`
- Redirect:
  - `http://robust-vtb.com` -> `https://www.robust-vtb.com`
  - `http://www.robust-vtb.com` -> `https://www.robust-vtb.com`
  - `https://robust-vtb.com` -> `https://www.robust-vtb.com`
- Switch the portal runtime env to HTTPS-aware public URLs:
  - `PORTAL_PUBLIC_BASE_URL=https://www.robust-vtb.com`
  - `APP_BASE_URL=https://www.robust-vtb.com`
- Re-evaluate `NODE_ENV` / production cookie posture after HTTPS is live so secure cookies work correctly without breaking portal auth.
- Review and remove temporary development-only auth/bootstrap settings that should not remain enabled on the public portal once a real admin flow is confirmed.
- Confirm nginx request/body/timeouts remain appropriate for portal uploads after the SSL cutover.
- Apply basic VPS hardening appropriate for the current portal-only scope:
  - verify `ufw` only exposes `OpenSSH` and `Nginx Full`
  - confirm SSH key auth is working for operations
  - review whether password SSH/root password login should be disabled after key-based access is confirmed
  - verify file ownership for runtime paths:
    - `/var/lib/robust-vtb`
    - `/var/log/robust-vtb`
    - `/opt/robust-vtb/bin`
    - `/opt/robust-vtb/current/cache`

## Verification
- `certbot` completes successfully and certificates renew non-interactively.
- `curl -I http://robust-vtb.com` returns the expected redirect chain to HTTPS `www`.
- `curl -I https://www.robust-vtb.com` returns `200 OK`.
- Portal admin sign-in still works under HTTPS.
- Customer portal/gallery routes still work under HTTPS.
- Cookies/session auth behave correctly with the HTTPS/public production config.
- Firewall and SSH configuration still allow intended admin access while blocking unnecessary exposure.

## Notes
- Keep the builder local. This task applies only to the portal VPS.
- Do not introduce builder/media-export runtime features on the VPS.
- Preserve the current portal-only release workflow and deployment scripts.
