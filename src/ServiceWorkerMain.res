/* src/ServiceWorkerMain.res */

/* Standalone Bindings for Service Worker */
module Response = {
  type t
  @send external clone: t => t = "clone"
  @get external status: t => int = "status"
  @get external type_: t => string = "type"
  @send external json: t => Promise.t<'a> = "json"
  @get external headers: t => {..} = "headers"
}

module Request = {
  type t
  @get external method: t => string = "method"
  @get external url: t => string = "url"
  @get external mode: t => string = "mode"
}

module Cache = {
  type t
  @send external match: (t, Request.t) => Promise.t<Nullable.t<Response.t>> = "match"
  @send external put: (t, Request.t, Response.t) => Promise.t<unit> = "put"
  @send external addAll: (t, array<string>) => Promise.t<unit> = "addAll"
  @send external keys: (t, unit) => Promise.t<array<Request.t>> = "keys"
  @send external deleteReq: (t, Request.t) => Promise.t<bool> = "delete"
}

module CacheStorage = {
  type t
  @send external open_: (t, string) => Promise.t<Cache.t> = "open"
  @send external keys: (t, unit) => Promise.t<array<string>> = "keys"
  @send external delete: (t, string) => Promise.t<bool> = "delete"
  @send external match: (t, Request.t) => Promise.t<Nullable.t<Response.t>> = "match"
  @send external matchUrl: (t, string) => Promise.t<Nullable.t<Response.t>> = "match"
}

module Clients = {
  type t
  @send external claim: (t, unit) => Promise.t<unit> = "claim"
}

module FetchEvent = {
  type t
  @get external request: t => Request.t = "request"
  @send external respondWith: (t, Promise.t<Response.t>) => unit = "respondWith"
  @send external waitUntil: (t, Promise.t<'a>) => unit = "waitUntil"
}

module ExtendableEvent = {
  type t
  @send external waitUntil: (t, Promise.t<'a>) => unit = "waitUntil"
}

@val external self: {..} = "self"
@val @scope("self") external caches: CacheStorage.t = "caches"
@val @scope("self") external clients: Clients.t = "clients"
@val @scope("self") external registration: {..} = "registration"
@val @scope("self") external addEventListener: (string, 'event => unit) => unit = "addEventListener"
@val @scope("self") external skipWaiting: unit => Promise.t<unit> = "skipWaiting"

@val external fetch: Request.t => Promise.t<Response.t> = "fetch"
@val external fetchUrl: string => Promise.t<Response.t> = "fetch"

@val external setTimeout: (unit => unit, int) => int = "setTimeout"
@val external clearTimeout: int => unit = "clearTimeout"
@new external makeError: string => exn = "Error"

/* Promise helpers */
@val @scope("Promise") external race: array<Promise.t<'a>> => Promise.t<'a> = "race"

module URL = {
  type t
  @new external make: string => t = "URL"
  @get external pathname: t => string = "pathname"
}

/* Constants - Updated by scripts/sync-sw.cjs */
let cacheName = "vtb-cache-v5.3.5"
let manualAssets = [
  "/",
  "/index.html",
  "/early-boot.js",
  "/images/blank-panorama.svg",
  "/images/icon-192.png",
  "/images/icon-512.png",
  "/images/logo.jpeg",
  "/images/logo.webp",
  "/images/logo_.png",
  "/images/logo_on_leather.png",
  "/images/og-preview.png",
  "/images/robust_logo_new.png",
  "/libs/FileSaver.min.js",
  "/libs/jszip.min.js",
  "/libs/pannellum.css",
  "/libs/pannellum.js",
  "/manifest.json",
  "/robots.txt",
  "/sounds/click.wav",
  "/workers/image-worker.js"
]

let runtimeStaleMaxAgeMs = 7.0 *. 24.0 *. 60.0 *. 60.0 *. 1000.0

let hasHashedAssetName = (_pathname: string): bool =>
  ServiceWorkerMainSupport.hasHashedAssetName(_pathname)

let shouldCacheResponse = (_response: Response.t): bool => {
  ServiceWorkerMainSupport.shouldCacheResponse(_response)
}

let isResponseOlderThan = (_response: Response.t, _maxAgeMs: float): bool =>
  ServiceWorkerMainSupport.isResponseOlderThan(_response, _maxAgeMs)

let fetchWithTimeout = (request, timeoutMs) => {
  let timeoutPromise = Promise.make((_, reject) => {
    let _ = setTimeout(() => {
      reject(makeError("ServiceWorkerFetchTimeout"))
    }, timeoutMs)
  })

  race([fetch(request), timeoutPromise])
}

let fetchWithAdaptiveTimeout = (request: Request.t): Promise.t<Response.t> =>
  fetchWithTimeout(request, 5000)->Promise.catch(_ => fetchWithTimeout(request, 15000))

let dedupeAssets = (_assets: array<string>): array<string> =>
  ServiceWorkerMainSupport.dedupeAssets(_assets)

addEventListener("install", (event: ExtendableEvent.t) => {
  Logger.info(~module_="ServiceWorker", ~message="INSTALL_START", ())

  let installPromise = ServiceWorkerMainSupport.installPromise(
    ~cacheName,
    ~manualAssets,
    ~openCache=name => caches->CacheStorage.open_(name),
    ~addAll=(cache, assets) => cache->Cache.addAll(assets),
    ~skipWaiting,
    ~fetchManifest=() => {
      let load = async () => {
        let response = await fetchUrl("/asset-manifest.json")
        let manifest: {"allFiles": Nullable.t<array<string>>} = await response->Response.json
        let allFiles = manifest["allFiles"]
        if allFiles->Nullable.toOption->Belt.Option.isSome {
          allFiles
          ->Nullable.toOption
          ->Option.getOr([])
          ->Array.filter(file => !(file->String.endsWith(".map")))
        } else {
          []
        }
      }
      load()
    },
  )

  event->ExtendableEvent.waitUntil(installPromise)
})

addEventListener("activate", (event: ExtendableEvent.t) => {
  Logger.info(~module_="ServiceWorker", ~message="ACTIVATE_START", ())

  let activatePromise = ServiceWorkerMainSupport.activatePromise(
    ~cacheName,
    ~runtimeStaleMaxAgeMs,
    ~cacheKeys=() => caches->CacheStorage.keys(),
    ~deleteCache=name => caches->CacheStorage.delete(name),
    ~openCache=name => caches->CacheStorage.open_(name),
    ~cacheRequests=cache => cache->Cache.keys(),
    ~matchRequest=(cache, req) =>
      cache->Cache.match(req)->Promise.then(found => Promise.resolve(found->Nullable.toOption)),
    ~deleteRequest=(cache, req) => cache->Cache.deleteReq(req),
    ~requestUrl=req => req->Request.url,
    ~pathnameForUrl=url => URL.pathname(URL.make(url)),
    ~enableNavigationPreload=() =>
      %raw(`(function(reg){
          try {
            if (reg && reg.navigationPreload && typeof reg.navigationPreload.enable === 'function') {
              return reg.navigationPreload.enable();
            }
          } catch (_) {}
          return Promise.resolve();
        })(registration)`),
    ~claimClients=() => clients->Clients.claim(),
  )

  event->ExtendableEvent.waitUntil(activatePromise)
})

addEventListener("fetch", (event: FetchEvent.t) => {
  let request = event->FetchEvent.request

  if request->Request.method == "GET" {
    let url = URL.make(request->Request.url)
    let pathname = URL.pathname(url)
    let mode = request->Request.mode

    let isApi = pathname->String.startsWith("/api/") || pathname == "/health"
    let isNavigation = mode == "navigate"

    let performFetch = () =>
      if isApi {
        fetchWithTimeout(request, 30000)
      } else {
        fetchWithAdaptiveTimeout(request)
      }

    if isApi {
      // API requests: network-first and no SW cache.
      event->FetchEvent.respondWith(performFetch())
    } else {
      let isImmutable = hasHashedAssetName(pathname)
      let isStaleWhileRevalidate =
        isNavigation || pathname == "/index.html" || pathname == "/manifest.json"

      let fetchAndCache =
        performFetch()
        ->Promise.then(response => {
          if (
            response->Response.status == 200 &&
            response->Response.type_ == "basic" &&
            shouldCacheResponse(response)
          ) {
            let responseToCache = response->Response.clone
            let _ =
              caches
              ->CacheStorage.open_(cacheName)
              ->Promise.then(
                cache => {
                  cache->Cache.put(request, responseToCache)
                },
              )
          }
          Promise.resolve(response)
        })
        ->Promise.catch(error => {
          Logger.warn(~module_="ServiceWorker", ~message="BG_FETCH_FAILED", ~data=error, ())
          Promise.reject(error)
        })

      event->FetchEvent.respondWith(
        caches
        ->CacheStorage.match(request)
        ->Promise.then(cachedResponse => {
          switch cachedResponse->Nullable.toOption {
          | Some(res) =>
            if isImmutable {
              Promise.resolve(res)
            } else if isStaleWhileRevalidate {
              event->FetchEvent.waitUntil(fetchAndCache)
              Promise.resolve(res)
            } else {
              Promise.resolve(res)
            }
          | None =>
            // Cache miss: try network
            fetchAndCache->Promise.catch(
              err => {
                if isNavigation {
                  // Navigation fallback
                  caches
                  ->CacheStorage.matchUrl("/index.html")
                  ->Promise.then(
                    fallback => {
                      switch fallback->Nullable.toOption {
                      | Some(res) => Promise.resolve(res)
                      | None => Promise.reject(err)
                      }
                    },
                  )
                } else {
                  Promise.reject(err)
                }
              },
            )
          }
        }),
      )
    }
  }
})
