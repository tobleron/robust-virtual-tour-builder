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
    '/images/icon-192.png',
    '/images/icon-512.png',
];

// Install event - cache static assets
self.addEventListener('install', event => {
    console.log('[Service Worker] Installing...');
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('[Service Worker] Caching static assets');
                return cache.addAll(STATIC_ASSETS);
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

    // Skip API requests (let them go to network)
    if (event.request.url.includes('/api/')) {
        return;
    }

    event.respondWith(
        caches.match(event.request)
            .then(cached => {
                if (cached) {
                    console.log('[Service Worker] Serving from cache:', event.request.url);
                    return cached;
                }

                console.log('[Service Worker] Fetching from network:', event.request.url);
                return fetch(event.request).then(response => {
                    // Cache successful responses
                    if (response && response.status === 200) {
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
                // Could return a custom offline page here
                throw error;
            })
    );
});
