/* src/ServiceWorkerMain.res */

/* Standalone Bindings for Service Worker */
module Response = {
  type t
  @send external clone: t => t = "clone"
  @get external status: t => int = "status"
  @get external type_: t => string = "type"
  @send external json: t => Promise.t<'a> = "json"
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
let cacheName = "vtb-cache-v4.10.0"
let manualAssets = [
  "/",
  "/index.html",
  "/early-boot.js",
  "/images/icon-192.png",
  "/images/icon-512.png",
  "/images/logo.jpeg",
  "/images/logo.png",
  "/images/logo.png~",
  "/images/logo_old.png",
  "/images/logo_on_leather.png",
  "/images/og-preview.png",
  "/libs/FileSaver.min.js",
  "/libs/jszip.min.js",
  "/libs/pannellum.css",
  "/libs/pannellum.js",
  "/manifest.json",
  "/robots.txt",
  "/sounds/click.wav"
]

let fetchWithTimeout = (request, timeoutMs) => {
  let timeoutPromise = Promise.make((_, reject) => {
    let _ = setTimeout(() => {
      reject(makeError("ServiceWorkerFetchTimeout"))
    }, timeoutMs)
  })

  race([fetch(request), timeoutPromise])
}

addEventListener("install", (event: ExtendableEvent.t) => {
  Logger.info(~module_="ServiceWorker", ~message="INSTALL_START", ())

  let installPromise =
    caches
    ->CacheStorage.open_(cacheName)
    ->Promise.then(async cache => {
      Logger.info(~module_="ServiceWorker", ~message="FETCH_MANIFEST_START", ())
      let manifestUrls = try {
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
      } catch {
      | _ => []
      }

      let allAssets = manualAssets->Array.concat(manifestUrls)
      /* Remove duplicates */
      let uniqueAssets = allAssets->Array.filterWithIndex(
        (item, index) => {
          allAssets->Array.indexOf(item) == index
        },
      )

      Logger.info(~module_="ServiceWorker", ~message="CACHING_ASSETS", ~data=uniqueAssets, ())
      await cache->Cache.addAll(uniqueAssets)
    })
    ->Promise.then(_ => skipWaiting())

  event->ExtendableEvent.waitUntil(installPromise)
})

addEventListener("activate", (event: ExtendableEvent.t) => {
  Logger.info(~module_="ServiceWorker", ~message="ACTIVATE_START", ())

  let activatePromise =
    caches
    ->CacheStorage.keys()
    ->Promise.then(cacheNames => {
      cacheNames
      ->Array.filter(name => name != cacheName)
      ->Array.map(
        name => {
          Logger.info(~module_="ServiceWorker", ~message="DELETE_OLD_CACHE", ~data=name, ())
          caches->CacheStorage.delete(name)
        },
      )
      ->Promise.all
    })
    ->Promise.then(_ => clients->Clients.claim())

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

    let timeoutMs = if isNavigation {
      10000
    } else if isApi {
      30000
    } else {
      15000
    }

    let performFetch = () => fetchWithTimeout(request, timeoutMs)

    if isApi {
      // API requests: enforce timeout, no caching
      event->FetchEvent.respondWith(performFetch())
    } else {
      // Assets & Navigation: Cache first, then stale-while-revalidate with timeout

      let fetchAndCache =
        performFetch()
        ->Promise.then(response => {
          if response->Response.status == 200 && response->Response.type_ == "basic" {
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

      event->FetchEvent.waitUntil(fetchAndCache)

      event->FetchEvent.respondWith(
        caches
        ->CacheStorage.match(request)
        ->Promise.then(cachedResponse => {
          switch cachedResponse->Nullable.toOption {
          | Some(res) => Promise.resolve(res)
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
