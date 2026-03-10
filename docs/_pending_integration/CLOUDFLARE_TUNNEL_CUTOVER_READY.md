# Cloudflare Tunnel Cutover Readiness

This runbook prepares `robust-vtb.com` to expose the current single-origin app through a named Cloudflare Tunnel once the domain zone becomes active in Cloudflare.

## Chosen Public Shape

- Public origin: `https://robust-vtb.com`
- Optional alias: `https://www.robust-vtb.com`
- Local origin service behind the tunnel: `http://localhost:8080`

Why this shape:

- The app already serves the marketing/account pages and builder from the same origin.
- Frontend routing already supports `/`, `/pricing`, `/signin`, `/signup`, `/dashboard`, `/account`, and `/builder`.
- The backend already serves the built frontend from `dist/` and handles API routes on the same process.

Relevant files:

- [src/site/PageFramework.js](src/site/PageFramework.js)
- [src/index.js](src/index.js)
- [backend/src/main.rs](backend/src/main.rs)
- [backend/src/api/auth.rs](backend/src/api/auth.rs)
- [backend/.env.example](backend/.env.example)

## Required Runtime Environment

At tunnel cutover time, the backend runtime should have these values:

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

Notes:

- `APP_BASE_URL` controls auth email links.
- `CORS_ALLOWED_ORIGINS` matters in production mode.
- `BYPASS_AUTH` and `ALLOW_DEV_AUTH_BOOTSTRAP` must stay `false`.
- Google auth is optional, but if enabled the redirect URL must use the production hostname.

## Named Tunnel Config

Cloudflare expects the runtime config in `~/.cloudflared/config.yml`.

Example:

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

## Cutover Commands

Run these after Cloudflare marks the zone active and tunnel authorization succeeds:

```bash
cloudflared tunnel create robust-vtb
cloudflared tunnel route dns robust-vtb robust-vtb.com
cloudflared tunnel route dns robust-vtb www.robust-vtb.com
```

Then place the config above in `~/.cloudflared/config.yml` and run:

```bash
cloudflared tunnel run robust-vtb
```

## Optional macOS Service Mode

After named tunnel verification is complete, Cloudflare documents running `cloudflared` as a macOS service:

```bash
cloudflared service install
```

This is only useful if the Mac itself is the long-running origin.

## App-Specific Readiness Checks

Before public cutover:

1. `npm run build`
2. Start backend in production mode with real env values.
3. Verify `http://localhost:8080/health`
4. Verify `http://localhost:8080/`
5. Verify `http://localhost:8080/builder`
6. Verify signup sends links using `https://robust-vtb.com/...`
7. Verify `https://robust-vtb.com/api/auth/google/callback` is registered in Google console if Google auth is enabled

## What Is Still Not Solved By Tunnel Alone

Cloudflare Tunnel only exposes your running origin. It does not replace hosting architecture.

These remain separate concerns:

- persistent storage strategy
- database durability and backups
- media storage outside local disk
- multi-user concurrency scaling
- long-running export/teaser job isolation

For testing and early staging, the tunnel is enough. For serious production, the origin architecture still matters.
