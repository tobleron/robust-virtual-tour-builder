# Task 116: Update Service Worker Cache Paths

## Priority: MEDIUM

## Context
The current `service-worker.js` caches paths that were valid before the Rsbuild migration:
```javascript
const STATIC_ASSETS = [
    '/',
    '/index.html',
    '/css/output.css',        // ❌ Old path
    '/css/style.css',          // ❌ Old path
    '/src/Main.bs.js',         // ❌ Old path - now bundled
    '/src/libs/pannellum.js',
    // ...
];
```

After Rsbuild migration, assets are now in `dist/static/`:
- `dist/static/js/index.*.js`
- `dist/static/css/index.*.css`

This mismatch means the service worker **fails silently** during installation and doesn't cache production assets.

## Objective
Update the service worker to correctly cache Rsbuild production output.

## Acceptance Criteria
- [ ] Service worker caches files from `dist/static/` directory
- [ ] Dynamic filename handling for hashed assets (or use manifest)
- [ ] Cache version bumped to invalidate old caches
- [ ] PWA still installable and works offline
- [ ] `/api/*` routes are NOT cached (remain network-only)

## Implementation Options

### Option A: Manual Path Update (Simple)
```javascript
const CACHE_NAME = 'vtb-cache-v2';
const STATIC_ASSETS = [
    '/',
    '/index.html',
    '/static/css/index.e0f2d19c.css',  // Update on each build
    '/static/js/index.869e1e2e.js',
    '/static/js/lib-react.2f17fd6e.js',
    '/src/libs/pannellum.js',
    '/src/libs/pannellum.css',
    '/images/logo.png',
    '/images/icon-192.png',
    '/images/icon-512.png',
];
```
⚠️ Downside: Must update manually after each build

### Option B: Precache Manifest (Recommended)
Generate a manifest during build and import it:

1. **Add to `rsbuild.config.mjs`:**
```javascript
export default defineConfig({
  // ...
  output: {
    manifest: true, // Generates asset-manifest.json
  },
});
```

2. **Service worker reads manifest:**
```javascript
self.addEventListener('install', async event => {
    const manifest = await fetch('/asset-manifest.json').then(r => r.json());
    const urls = Object.values(manifest).map(v => v.file || v);
    await caches.open(CACHE_NAME).addAll(['/', ...urls]);
});
```

### Option C: Workbox (Most Robust)
Use Google's Workbox library for production-grade service worker:
```bash
npm install --save-dev workbox-cli
npx workbox generateSW workbox-config.js
```

## Recommended Approach
**Option B** - It's simple, doesn't require new dependencies, and handles hash changes automatically.

## Verification
1. Build production: `npm run build`
2. Serve from backend: `cd backend && cargo run --release`
3. Open DevTools → Application → Service Workers
4. Verify "Cached Storage" contains correct assets
5. Go offline (DevTools → Network → Offline)
6. Refresh page → App should load from cache

## Estimated Effort
2 hours
