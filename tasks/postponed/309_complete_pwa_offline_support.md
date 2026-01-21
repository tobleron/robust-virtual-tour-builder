# Task 309: Complete PWA Offline Support

**Priority**: Low  
**Effort**: Medium (2-3 days)  
**Impact**: Low  
**Category**: Progressive Web App / User Experience

## Objective

Complete the Progressive Web App (PWA) implementation by adding full offline support, enabling users to continue working when internet connectivity is lost.

## Current Status

**PWA Coverage**: 80%  
**What's Implemented**:
- ✅ Web App Manifest (`public/manifest.json`)
- ✅ Service Worker (`src/ServiceWorkerMain.res`)
- ✅ iOS PWA meta tags
- ✅ Icons (192px, 512px)
- ✅ Theme color
- ✅ Standalone display mode
- ✅ Asset caching (basic)

**What's Missing**:
- ⚠️ Full offline functionality
- ⚠️ Offline fallback pages
- ⚠️ Background sync
- ⚠️ Push notifications (optional)

## Offline Capabilities Needed

### 1. Core Functionality (Must Work Offline):
- ✅ View existing project
- ✅ Navigate between scenes
- ✅ View hotspots
- ⚠️ Edit scene names (local only)
- ⚠️ Create/edit hotspots (local only)
- ⚠️ Save project (local storage)

### 2. Limited Functionality (Requires Online):
- ❌ Upload new images (requires backend)
- ❌ Process images (requires backend)
- ❌ Generate teaser videos (requires backend)
- ❌ Geocoding (requires API)

## Implementation Steps

### Phase 1: Enhanced Service Worker Caching (1 day)

Update `src/ServiceWorkerMain.res`:

```rescript
// Cache strategies
let CACHE_VERSION = "v4.3.7"
let STATIC_CACHE = "static-" ++ CACHE_VERSION
let DYNAMIC_CACHE = "dynamic-" ++ CACHE_VERSION
let IMAGE_CACHE = "images-" ++ CACHE_VERSION

// Assets to cache immediately
let STATIC_ASSETS = [
  "/",
  "/index.html",
  "/main.js",
  "/style.css",
  "/libs/pannellum.js",
  "/libs/pannellum.css",
  "/libs/jszip.min.js",
  "/manifest.json",
  "/images/icon-192.png",
  "/images/icon-512.png",
]

// Install event - cache static assets
self->addEventListener("install", event => {
  event->waitUntil(
    caches->open(STATIC_CACHE)->then(cache => {
      Logger.info(~module_="ServiceWorker", ~message="CACHE_STATIC_ASSETS", ())
      cache->addAll(STATIC_ASSETS)
    })
  )
  self->skipWaiting() // Activate immediately
})

// Fetch event - network first, then cache
self->addEventListener("fetch", event => {
  let request = event->request
  
  // API requests - network only (with offline fallback)
  if String.includes(request->url, "/api/") {
    event->respondWith(
      fetch(request)->catch(_ => {
        // Return offline fallback for API
        Response.make(
          ~body=JSON.stringify({"error": "Offline", "offline": true}),
          ~init={"status": 503, "headers": {"Content-Type": "application/json"}}
        )
      })
    )
  }
  // Images - cache first, then network
  else if String.includes(request->url, ".webp") || String.includes(request->url, ".jpg") {
    event->respondWith(
      caches->match(request)->then(response => {
        switch Nullable.toOption(response) {
        | Some(cached) => Promise.resolve(cached)
        | None => 
          fetch(request)->then(networkResponse => {
            caches->open(IMAGE_CACHE)->then(cache => {
              cache->put(request, networkResponse->clone())
              networkResponse
            })
          })
        }
      })
    )
  }
  // Static assets - cache first
  else {
    event->respondWith(
      caches->match(request)->then(response => {
        switch Nullable.toOption(response) {
        | Some(cached) => Promise.resolve(cached)
        | None => fetch(request)
        }
      })
    )
  }
})
```

### Phase 2: Offline Detection UI (4-6 hours)

Create `src/components/OfflineIndicator.res`:

```rescript
@react.component
let make = () => {
  let (isOnline, setIsOnline) = React.useState(() => true)
  
  React.useEffect0(() => {
    let handleOnline = _ => setIsOnline(_ => true)
    let handleOffline = _ => setIsOnline(_ => false)
    
    Window.addEventListener("online", handleOnline)
    Window.addEventListener("offline", handleOffline)
    
    // Initial check
    setIsOnline(_ => Navigator.onLine)
    
    Some(() => {
      Window.removeEventListener("online", handleOnline)
      Window.removeEventListener("offline", handleOffline)
    })
  })
  
  if !isOnline {
    <div className="offline-banner">
      <span className="offline-icon">{"⚠️"->React.string}</span>
      <span>{"You are offline. Some features are unavailable."->React.string}</span>
    </div>
  } else {
    React.null
  }
}
```

Add to `App.res`:
```rescript
<OfflineIndicator />
```

### Phase 3: Offline Fallback Pages (2-4 hours)

Create `public/offline.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Offline - Virtual Tour Builder</title>
  <style>
    body {
      font-family: 'Inter', sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
      color: white;
    }
    .offline-container {
      text-align: center;
      max-width: 500px;
      padding: 2rem;
    }
    .offline-icon {
      font-size: 4rem;
      margin-bottom: 1rem;
    }
  </style>
</head>
<body>
  <div class="offline-container">
    <div class="offline-icon">📡</div>
    <h1>You're Offline</h1>
    <p>It looks like you've lost your internet connection. Some features require an active connection to work.</p>
    <p>You can still:</p>
    <ul style="text-align: left;">
      <li>View your existing project</li>
      <li>Navigate between scenes</li>
      <li>Edit scene names and hotspots</li>
    </ul>
    <button onclick="location.reload()" style="margin-top: 1rem; padding: 0.75rem 1.5rem; background: #dc3545; border: none; border-radius: 0.5rem; color: white; cursor: pointer;">
      Try Again
    </button>
  </div>
</body>
</html>
```

Cache offline.html in service worker:
```rescript
let STATIC_ASSETS = [
  // ...
  "/offline.html",
]
```

### Phase 4: Background Sync (Optional, 4-6 hours)

For queuing actions when offline:

```rescript
// Register background sync
if "sync" in registration {
  registration->sync->register("upload-queue")
}

// In service worker
self->addEventListener("sync", event => {
  if event->tag == "upload-queue" {
    event->waitUntil(processUploadQueue())
  }
})

let processUploadQueue = async () => {
  // Get queued uploads from IndexedDB
  let queue = await getUploadQueue()
  
  // Process each
  for upload in queue {
    try {
      await fetch("/api/media/process-full", {
        method: "POST",
        body: upload.formData
      })
      await removeFromQueue(upload.id)
    } catch {
    | _ => () // Will retry on next sync
    }
  }
}
```

### Phase 5: Offline Storage Strategy (4-6 hours)

Use IndexedDB for offline data:

```rescript
// Store project data offline
let saveProjectOffline = async (projectData) => {
  let db = await openDB("vtb-offline", 1)
  let tx = db->transaction("projects", "readwrite")
  let store = tx->objectStore("projects")
  await store->put(projectData, "current-project")
}

// Load project data offline
let loadProjectOffline = async () => {
  let db = await openDB("vtb-offline", 1)
  let tx = db->transaction("projects", "readonly")
  let store = tx->objectStore("projects")
  await store->get("current-project")
}
```

## Verification

### Manual Testing:

1. **Install PWA**:
   - Open in Chrome
   - Click "Install" prompt
   - Verify app installs

2. **Test Offline Mode**:
   - Open DevTools → Network tab
   - Check "Offline"
   - Reload page
   - Verify app still works

3. **Test Offline Features**:
   - Navigate between scenes ✅
   - Edit scene names ✅
   - Create hotspots ✅
   - Try to upload (should show offline message) ✅

4. **Test Online Recovery**:
   - Uncheck "Offline"
   - Verify sync happens
   - Verify queued actions process

### Automated Testing:

```javascript
// tests/e2e/offline.spec.ts
test('should work offline', async ({ page, context }) => {
  await page.goto('/');
  
  // Go offline
  await context.setOffline(true);
  
  // Verify offline banner appears
  await expect(page.locator('.offline-banner')).toBeVisible();
  
  // Verify can still navigate
  await page.click('.scene-item');
  await expect(page.locator('#panorama-a')).toBeVisible();
  
  // Go back online
  await context.setOffline(false);
  
  // Verify banner disappears
  await expect(page.locator('.offline-banner')).not.toBeVisible();
});
```

## Success Criteria

- [ ] Enhanced service worker caching implemented
- [ ] Offline indicator UI added
- [ ] Offline fallback page created
- [ ] Core features work offline (view, navigate, edit)
- [ ] Graceful degradation for online-only features
- [ ] Background sync implemented (optional)
- [ ] IndexedDB storage for offline data
- [ ] PWA installs correctly
- [ ] Offline mode tested manually
- [ ] E2E tests for offline scenarios

## Benefits

- ✅ Work continues during connectivity loss
- ✅ Better user experience
- ✅ True Progressive Web App
- ✅ Competitive advantage
- ✅ Mobile-friendly (spotty connections)
- ✅ Professional PWA implementation

## Resources

- PWA Offline Guide: https://web.dev/offline-cookbook/
- Service Worker API: https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API
- Background Sync: https://web.dev/periodic-background-sync/
- IndexedDB: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API
