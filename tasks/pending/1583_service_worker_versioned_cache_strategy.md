# Task: Service Worker Versioned Cache Strategy with Runtime Asset Prioritization

## Objective
Upgrade `ServiceWorkerMain.res` from monolithic cache-first to a tiered caching strategy with content-hash-aware versioning, runtime prioritization, and stale-content purging for enterprise reliability.

## Problem Statement
The current service worker caches **all** assets including non-critical images (multiple logo variants, old logos) at install time. The `fetchWithTimeout` uses fixed timeouts (10s/15s/30s) without adaptive behavior. There is no cache size budgeting — over multiple deploys, stale assets accumulate in IndexedDB. The de-duplication logic uses `Array.indexOf` which is O(n²) for the full asset list.

## Acceptance Criteria
- [ ] Implement tiered cache strategy: `immutable` (hashed assets like JS chunks), `network-first` (API/data), `stale-while-revalidate` (HTML, manifest)
- [ ] Hashed assets (e.g., `index-a1b2c3.js`) should never be re-fetched or revalidated — permanent cache
- [ ] Add cache storage budget: automatically evict assets not accessed in 7 days during `activate` event
- [ ] Replace O(n²) de-duplication with `Set`-based approach
- [ ] Add adaptive timeout: start with 5s, extend to 15s if first attempt times out (progressive)
- [ ] Add `Cache-Control` header inspection before caching responses
- [ ] Remove unnecessary assets from manual list (e.g., `logo.png~`, `logo_old.png`)
- [ ] Add navigation preload hint for index.html on activate

## Technical Notes
- **Files**: `src/ServiceWorkerMain.res`
- **Pattern**: URL pattern matching with hash detection (`/assets/[name]-[hash].js`)
- **Risk**: Medium — incorrect caching strategy can serve stale content; must test deploy-and-reload cycle
- **Measurement**: Install event duration should decrease; cache storage size should plateau instead of growing
