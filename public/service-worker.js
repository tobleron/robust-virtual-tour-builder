const CACHE_NAME = 'vtb-cache-v4.2.112';

// Assets that aren't managed by Rsbuild but should still be cached
const MANUAL_ASSETS = [
    "/",
    "/index.html",
    "/early-boot.js",
    "/images/icon-192.png",
    "/images/icon-512.png",
    "/images/logo.png",
    "/images/og-preview.png",
    "/libs/FileSaver.min.js",
    "/libs/jszip.min.js",
    "/libs/pannellum.css",
    "/libs/pannellum.js",
    "/manifest.json"
];

// Install event - cache static assets using manifest + manual list
self.addEventListener('install', event => {
    console.log('[Service Worker] Installing...');
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(async cache => {
                console.log('[Service Worker] Fetching asset manifest...');
                let manifestUrls = [];
                try {
                    const response = await fetch('/asset-manifest.json');
                    const manifest = await response.json();

                    // Filter out source maps and handle potential missing allFiles
                    if (manifest.allFiles) {
                        manifestUrls = manifest.allFiles.filter(file => !file.endsWith('.map'));
                    }
                } catch (err) {
                    console.warn('[Service Worker] Could not load asset-manifest.json, falling back to manual assets only', err);
                }

                const allAssets = [...new Set([...MANUAL_ASSETS, ...manifestUrls])];
                console.log('[Service Worker] Caching assets:', allAssets);
                return cache.addAll(allAssets);
            })
            .then(() => self.skipWaiting())
    );
});

// Activate event - clean up old caches
self.addEventListener('activate', event => {
    console.log('[Service Worker] Activating...');
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames
                    .filter(cacheName => cacheName !== CACHE_NAME)
                    .map(cacheName => {
                        console.log('[Service Worker] Deleting old cache:', cacheName);
                        return caches.delete(cacheName);
                    })
            );
        }).then(() => self.clients.claim())
    );
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', event => {
    // Skip non-GET requests
    if (event.request.method !== 'GET') {
        return;
    }

    const url = new URL(event.request.url);

    // Skip API requests, health check, and session files (let them go to network)
    if (url.pathname.startsWith('/api/') || url.pathname === '/health') {
        return;
    }

    event.respondWith(
        caches.match(event.request)
            .then(cached => {
                if (cached) {
                    // console.log('[Service Worker] Serving from cache:', event.request.url);
                    return cached;
                }

                return fetch(event.request).then(response => {
                    // Cache successful responses for GET requests that aren't API calls
                    if (response && response.status === 200 && response.type === 'basic') {
                        const responseToCache = response.clone();
                        caches.open(CACHE_NAME).then(cache => {
                            cache.put(event.request, responseToCache);
                        });
                    }
                    return response;
                });
            })
            .catch(error => {
                console.error('[Service Worker] Fetch failed:', error);
                throw error;
            })
    );
});
