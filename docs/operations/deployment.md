# Deployment Guide

**Last Updated:** March 19, 2026  
**Scope:** Cloudflare Tunnel deployment for `robust-vtb.com`  
**Prerequisites:** Cloudflare account, domain zone active in Cloudflare

---

## 1. Overview

This guide covers deploying the Robust Virtual Tour Builder through a Cloudflare Tunnel to expose the application at `https://robust-vtb.com`.

### Public Shape

- **Public origin:** `https://robust-vtb.com`
- **Optional alias:** `https://www.robust-vtb.com`
- **Local origin:** `http://localhost:8080`

### Why This Architecture

The app already serves marketing/account pages and builder from the same origin:
- Frontend routing supports: `/`, `/pricing`, `/signin`, `/signup`, `/dashboard`, `/account`, `/builder`
- Backend serves built frontend from `dist/` and handles API routes on same process

**Relevant Files:**
- `src/site/PageFramework.js` - Marketing page routing
- `src/index.js` - Frontend entry point
- `backend/src/main.rs` - Backend server
- `backend/src/api/auth.rs` - Authentication endpoints
- `backend/.env.example` - Environment configuration

---

## 2. Prerequisites

### 2.1 Cloudflare Setup

1. **Domain Zone:** Add `robust-vtb.com` to Cloudflare
2. **Wait for Activation:** Cloudflare must mark the zone as active
3. **Cloudflared Installed:** Install Cloudflare Tunnel daemon

```bash
# macOS (Homebrew)
brew install cloudflared

# Or download from: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/
```

### 2.2 Application Build

Ensure the application builds successfully:

```bash
npm run build
```

---

## 3. Runtime Environment Configuration

### 3.1 Environment Variables

Create `.env` file for production:

```env
NODE_ENV=production
PORT=8080
DATABASE_URL=sqlite://data/database.db
APP_BASE_URL=https://robust-vtb.com
CORS_ALLOWED_ORIGINS=https://robust-vtb.com,https://www.robust-vtb.com
JWT_SECRET=<strong random secret>
SESSION_KEY=<64+ byte random secret>
BYPASS_AUTH=false
ALLOW_DEV_AUTH_BOOTSTRAP=false
RESEND_API_KEY=<resend key>
EMAIL_FROM=no-reply@robust-vtb.com
GOOGLE_REDIRECT_URL=https://robust-vtb.com/api/auth/google/callback
```

### 3.2 Critical Configuration Notes

| Variable | Purpose | Production Requirement |
|---|---|---|
| `APP_BASE_URL` | Controls auth email links | Must be `https://robust-vtb.com` |
| `CORS_ALLOWED_ORIGINS` | CORS validation in production | Must include production domain |
| `BYPASS_AUTH` | Development auth bypass | **Must be `false`** |
| `ALLOW_DEV_AUTH_BOOTSTRAP` | Dev auth bootstrap | **Must be `false`** |
| `JWT_SECRET` | JWT signing | Use strong random secret (32+ chars) |
| `SESSION_KEY` | Session encryption | Use strong random secret (64+ bytes) |

### 3.3 Generate Secure Secrets

```bash
# Generate JWT_SECRET (32 chars)
openssl rand -base64 32

# Generate SESSION_KEY (64 bytes)
openssl rand -base64 64
```

---

## 4. Cloudflare Tunnel Configuration

### 4.1 Create Named Tunnel

```bash
# Create tunnel (one-time setup)
cloudflared tunnel create robust-vtb
```

This outputs:
- Tunnel UUID (e.g., `f1a2b3c4-d5e6-7f8g-9h0i-j1k2l3m4n5o6`)
- Credentials file path (e.g., `/Users/<user>/.cloudflared/<UUID>.json`)

### 4.2 Configure Tunnel

Create/edit `~/.cloudflared/config.yml`:

```yaml
tunnel: <TUNNEL-UUID>
credentials-file: /Users/<your-user>/.cloudflared/<TUNNEL-UUID>.json

ingress:
  - hostname: robust-vtb.com
    service: http://localhost:8080
  - hostname: www.robust-vtb.com
    service: http://localhost:8080
  - service: http_status:404
```

**Replace:**
- `<TUNNEL-UUID>` with your actual tunnel UUID
- `<your-user>` with your macOS username

### 4.3 Route DNS

```bash
# Route main domain
cloudflared tunnel route dns robust-vtb robust-vtb.com

# Route www alias
cloudflared tunnel route dns robust-vtb www.robust-vtb.com
```

---

## 5. Running the Tunnel

### 5.1 Manual Mode (Testing)

```bash
# Start tunnel (foreground)
cloudflared tunnel run robust-vtb
```

**Expected Output:**
```
INF Starting Cloudflare tunnel
INF Tunnel connection established
INF Route configured for robust-vtb.com
INF Route configured for www.robust-vtb.com
```

### 5.2 macOS Service Mode (Production)

After verifying tunnel works:

```bash
# Install as macOS service (runs on boot)
cloudflared service install
```

**Service Management:**
```bash
# Check status
cloudflared service status

# Uninstall service
cloudflared service uninstall
```

---

## 6. Application Readiness Checks

Before public cutover, verify all endpoints:

### 6.1 Health Check

```bash
curl http://localhost:8080/health
# Expected: {"status": "ok"}
```

### 6.2 Static Pages

```bash
# Homepage
curl http://localhost:8080/

# Builder
curl http://localhost:8080/builder

# Pricing (if exists)
curl http://localhost:8080/pricing
```

### 6.3 Authentication Flow

1. **Signup Link Verification:**
   - Create test account
   - Verify email links use `https://robust-vtb.com/...`

2. **Google OAuth (if enabled):**
   - Verify redirect URL registered in Google Console:
     `https://robust-vtb.com/api/auth/google/callback`

### 6.4 API Endpoints

```bash
# Test CORS with production origin
curl -H "Origin: https://robust-vtb.com" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     http://localhost:8080/api/health
```

---

## 7. Cutover Procedure

### 7.1 Pre-Cutover Checklist

- [ ] Domain zone active in Cloudflare
- [ ] Tunnel created and configured
- [ ] DNS routes configured
- [ ] Application built in production mode
- [ ] Environment variables set
- [ ] Health checks passing
- [ ] Auth flow verified
- [ ] Google OAuth redirect URL updated (if applicable)

### 7.2 Cutover Steps

1. **Start Backend (Production Mode):**
   ```bash
   # From project root
   npm run build
   cd backend
   cargo run --release
   ```

2. **Start Cloudflare Tunnel:**
   ```bash
   cloudflared tunnel run robust-vtb
   ```

3. **Verify Public Access:**
   ```bash
   curl https://robust-vtb.com/health
   ```

4. **Monitor Logs:**
   - Watch for tunnel connection errors
   - Monitor application logs for errors
   - Check Cloudflare dashboard for traffic

### 7.3 Post-Cutover Verification

- [ ] Homepage loads over HTTPS
- [ ] Builder accessible
- [ ] Signup/login functional
- [ ] Email links use production domain
- [ ] CORS errors absent from console
- [ ] Cloudflare dashboard shows traffic

---

## 8. Troubleshooting

### Issue: Tunnel Won't Connect

**Symptoms:** `ERR Tunnel connection failed`

**Solutions:**
1. Verify credentials file exists: `ls ~/.cloudflared/<UUID>.json`
2. Check tunnel status in Cloudflare dashboard
3. Ensure tunnel not running elsewhere (port conflict)
4. Verify firewall allows outbound connections

### Issue: 502 Bad Gateway

**Symptoms:** Cloudflare returns 502

**Solutions:**
1. Verify backend is running: `curl http://localhost:8080/health`
2. Check backend listening on correct port (8080)
3. Verify ingress config points to correct localhost port
4. Check backend logs for startup errors

### Issue: CORS Errors

**Symptoms:** Browser console shows CORS policy errors

**Solutions:**
1. Verify `CORS_ALLOWED_ORIGINS` includes production domain
2. Ensure backend running in production mode (`NODE_ENV=production`)
3. Check Cloudflare not stripping Origin header

### Issue: Auth Links Wrong Domain

**Symptoms:** Email links use `localhost` instead of production domain

**Solutions:**
1. Set `APP_BASE_URL=https://robust-vtb.com`
2. Restart backend after env change
3. Clear any cached email templates

---

## 9. What Tunnel Does NOT Solve

Cloudflare Tunnel only exposes your running origin. These remain separate concerns:

### 9.1 Infrastructure Concerns

| Concern | Tunnel Provides | Additional Need |
|---|---|---|
| **Storage** | ❌ | Persistent volume / object storage |
| **Database** | ❌ | SQLite file persistence + backups |
| **Media Storage** | ❌ | S3 or external storage |
| **Concurrency** | ❌ | Worker scaling (see Async Processing) |
| **Job Isolation** | ❌ | Separate worker infrastructure |
| **Backups** | ❌ | Automated backup strategy |
| **Monitoring** | ❌ | External monitoring service |

### 9.2 For Testing and Early Staging

**Tunnel is sufficient for:**
- Development testing
- Demo environments
- Early user testing
- Proof of concept

### 9.3 For Serious Production

**Additional architecture needed:**
- Persistent storage strategy (database durability, backups)
- Media storage outside local disk (S3, Cloudflare R2)
- Multi-user concurrency scaling (async processing platform)
- Long-running export/teaser job isolation (worker nodes)
- Load balancing (multiple origins)
- CDN for static assets

---

## 10. Security Considerations

### 10.1 Tunnel Security

- Tunnel traffic encrypted end-to-end
- No inbound ports opened on firewall
- Cloudflare handles DDoS mitigation
- Tunnel credentials must be protected

### 10.2 Application Security

- Keep `BYPASS_AUTH=false` in production
- Keep `ALLOW_DEV_AUTH_BOOTSTRAP=false` in production
- Use strong, unique secrets for JWT and session
- Enable HTTPS-only cookies
- Implement rate limiting (already in place)

### 10.3 Cloudflare Security Features

Consider enabling:
- **WAF (Web Application Firewall):** Block common attacks
- **Bot Fight Mode:** Reduce automated abuse
- **SSL/TLS:** Set to "Full (Strict)"
- **HSTS:** Enforce HTTPS
- **Security Headers:** CSP, X-Frame-Options, etc.

---

## 11. Monitoring & Maintenance

### 11.1 Cloudflare Dashboard

Monitor:
- Traffic analytics
- Security events
- Tunnel health
- DNS queries

### 11.2 Application Monitoring

Recommended:
- Uptime monitoring (UptimeRobot, Pingdom)
- Error tracking (Sentry, LogRocket)
- Performance monitoring (Cloudflare Web Analytics)
- Log aggregation (self-hosted or SaaS)

### 11.3 Regular Maintenance

- **Weekly:** Review error logs, check tunnel health
- **Monthly:** Review traffic patterns, update dependencies
- **Quarterly:** Security audit, backup verification

---

## 12. Related Documents

- [Async Processing Platform](../architecture/async_processing.md) - For scaling heavy operations
- [Authentication](../security/authentication.md) - Auth system details
- [Rate Limits](../security/rate_limits.md) - Rate limiting configuration
- [Runbook & Audits](../project/runbook_and_audits.md) - Operational procedures

---

## 13. Appendix: Quick Reference Commands

```bash
# Create tunnel
cloudflared tunnel create robust-vtb

# Route DNS
cloudflared tunnel route dns robust-vtb robust-vtb.com
cloudflared tunnel route dns robust-vtb www.robust-vtb.com

# Run tunnel (manual)
cloudflared tunnel run robust-vtb

# Install as service
cloudflared service install

# Check service status
cloudflared service status

# Uninstall service
cloudflared service uninstall

# List tunnels
cloudflared tunnel list

# Show tunnel info
cloudflared tunnel info <TUNNEL-UUID>
```

---

**Document History:**
- March 19, 2026: Initial deployment guide from Cloudflare Tunnel cutover documentation
