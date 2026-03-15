# 1877 Portal HTTPS and VPS Hardening - COMPLETED ✅

**Completed:** March 15, 2026

## Objective
Finish the production-facing hardening pass for the live portal on the DigitalOcean VPS after the successful HTTP bring-up. The portal is already reachable and functional over plain HTTP; this task covers HTTPS issuance, canonical redirect cleanup, cookie/security posture alignment, and basic VPS hardening suitable for the portal-only deployment model.

## Completed Changes

### ✅ HTTPS Certificate
- Issued Let's Encrypt certificate for `robust-vtb.com` and `www.robust-vtb.com`
- Certificate expires: June 13, 2026
- Auto-renewal configured via certbot

### ✅ Nginx Redirects
- `http://robust-vtb.com` → `https://www.robust-vtb.com`
- `http://www.robust-vtb.com` → `https://www.robust-vtb.com`
- `https://robust-vtb.com` → `https://www.robust-vtb.com`

### ✅ Production Cookie Posture
- Backend: Session cookie `SameSite=None` for mobile compatibility
- Frontend: Added `credentials: 'include'` to customer API requests
- `Secure` flag works correctly with HTTPS
- Access links now work on both PC and mobile browsers

### ✅ Backend Fixes
- SQL-based expiry check (avoids DateTime parsing issues with SQLite)
- Access link validation now done in SQL query

### ✅ Build/Deploy Improvements
- Fixed incremental compilation (removed `backend/target` deletion from build script)
- Created `/root/scripts/robust-vtb-portal-build.sh` for incremental builds
- Build times: 5min → <30s for incremental changes

## Verification Results
- ✅ `curl -I http://robust-vtb.com` returns redirect to HTTPS www
- ✅ `curl -I https://www.robust-vtb.com` returns 200 OK
- ✅ Portal admin sign-in works under HTTPS
- ✅ Customer portal/gallery routes work under HTTPS
- ✅ Session cookies sent correctly with API requests
- ✅ Tour upload works through portal UI
- ✅ Access links work on mobile browsers (tested with iPhone user-agent)

## Test URL
```
https://www.robust-vtb.com/u/ak84/fmM6njo
```

## Remaining Items (Moved to T1881)
- [ ] VPS hardening (ufw, SSH config, fail2ban)
- [ ] Automatic security updates
- [ ] Backup strategy
- [ ] Monitoring setup

## Related Tasks
- T1881: VPS Security Hardening (follow-up task)
- T1869: Portal admin refresh and access link discoverability
- T1865: Portal access link rewrite and export simplification
