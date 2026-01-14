# Task 84: Implement Service Worker for Offline Capability

## Priority: 🟢 LOW (Future Enhancement)

## Context
A Service Worker would enable:
1. **Instant repeat loads** - Cache static assets
2. **Offline capability** - Work without network
3. **Background sync** - Queue operations when offline

Per `docs/ARCHITECTURE_DIAGRAM.md`, this is a recommended optimization strategy.

## Implementation Plan

### Phase 1: Basic Asset Caching

**Create service-worker.js:**
```javascript
const CACHE_NAME = 'vtb-cache-v1';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/css/output.css',
  '/css/style.css',
  '/src/Main.bs.js',
  '/src/libs/pannellum.js',
  '/src/libs/pannellum.css',
  '/src/libs/jszip.min.js',
  '/images/logo.png',
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(STATIC_ASSETS))
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  );
});
```

**Register in Main.res:**
```rescript
let registerServiceWorker = () => {
  if Js.typeof(ReBindings.Window.navigator["serviceWorker"]) != "undefined" {
    ReBindings.Window.navigator["serviceWorker"]
      ->ServiceWorker.register("/service-worker.js")
      ->Promise.then(_ => Promise.resolve())
      ->ignore
  }
}
```

### Phase 2: Cache-First with Network Fallback
```javascript
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(cached => {
        // Return cached version immediately
        // Also fetch fresh version for next time
        const networkFetch = fetch(event.request)
          .then(response => {
            caches.open(CACHE_NAME)
              .then(cache => cache.put(event.request, response.clone()));
            return response;
          });
        
        return cached || networkFetch;
      })
  );
});
```

### Phase 3: Offline Queue for API Calls
When offline, queue save/export operations:
```javascript
self.addEventListener('sync', event => {
  if (event.tag === 'sync-project') {
    event.waitUntil(syncProject());
  }
});
```

## Scope Considerations

### What to Cache
- [x] HTML, CSS, JS (static assets)
- [x] Images (logo, icons)
- [x] Fonts (Google Fonts)
- [ ] API responses (not for this phase)
- [ ] User-uploaded images (stored in IndexedDB, not SW)

### What NOT to Cache
- Backend API endpoints (dynamic)
- Large panorama images (use IndexedDB)
- Session data

## PWA Manifest (Optional Enhancement)
```json
// manifest.json
{
  "name": "Remax Virtual Tour Builder",
  "short_name": "VTB",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0f172a",
  "theme_color": "#003da5",
  "icons": [
    { "src": "/images/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/images/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

## Acceptance Criteria
- [ ] Service Worker registered on app load
- [ ] Static assets cached after first visit
- [ ] Subsequent loads use cache (faster)
- [ ] Cache invalidation on version change
- [ ] Works offline for viewing (if images cached)
- [ ] No interference with API calls

## Files to Create
- `service-worker.js` (root directory)
- `manifest.json` (root directory)
- `images/icon-192.png`
- `images/icon-512.png`

## Files to Modify
- `index.html` - link manifest, register SW
- `src/Main.res` - register service worker

## Testing
1. Load app with DevTools open
2. Go to Application → Service Workers
3. Verify "Activated and running"
4. Go to Application → Cache Storage
5. Verify assets are cached
6. Toggle "Offline" in Network tab
7. Reload - app should still load
8. Change version, reload - old cache cleared
