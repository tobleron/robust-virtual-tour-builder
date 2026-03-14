# T1875 Troubleshoot Portal Tour Upload 403

- [ ] Hypothesis (Ordered Expected Solutions)
  - [x] Reverse proxy or request-size handling is interfering with multipart upload before the request reaches the portal handler.
  - [ ] Upload request is missing or losing admin auth/session on the multipart endpoint, causing AuthMiddleware to reject it.
  - [ ] The upload endpoint is behind a stricter middleware/path configuration on VPS than the rest of the portal admin routes.
  - [ ] The frontend upload request shape differs from what the backend multipart handler expects, leading to a misleading forbidden response.

- [ ] Activity Log
  - [x] Read portal upload frontend/backend route wiring.
  - [x] Inspect live VPS service logs during/after failed upload.
  - [x] Reproduce or simulate the failing upload request path against the live service.
  - [x] Patch the actual rejection point and re-verify upload.

- [ ] Code Change Ledger
  - [x] Remote-only infra change: updated `/etc/nginx/sites-enabled/robust-vtb` on the VPS to set `client_max_body_size 100m;` for `www.robust-vtb.com`, then validated with `nginx -t` and reloaded nginx. No repository source files changed.

- [ ] Rollback Check
  - [ ] Confirmed CLEAN or REVERTED non-working changes.

- [ ] Context Handoff
  - [ ] Upload route exists at `/api/portal/admin/tours/upload` and is protected by `AuthMiddleware`.
  - [ ] Frontend uses multipart `FormData` through `PortalApi.uploadTour`, with auth header injection handled in the shared request helper.
  - [x] Live VPS logs showed `413` from nginx, with `client intended to send too large body`, so the issue was proxy-side rejection rather than portal auth.
  - [x] Nginx on the VPS now allows request bodies up to `100m`; if uploads still fail, the next check is app-side handler/log behavior after the request reaches Actix.
