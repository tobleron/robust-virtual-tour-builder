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
}

module Clients = {
  type t
  @send external claim: (t, unit) => Promise.t<unit> = "claim"
}

module FetchEvent = {
  type t
  @get external request: t => Request.t = "request"
  @send external respondWith: (t, Promise.t<Response.t>) => unit = "respondWith"
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

@new external newURL: string => {..} = "URL"

/* Constants - Updated by scripts/sync-sw.cjs */
let cacheName = "vtb-cache-v4.3.5"
let manualAssets = [
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
  "/manifest.json",
  "/sounds/click.wav"
]

addEventListener("install", (event: ExtendableEvent.t) => {
  Console.log("[Service Worker] Installing...")

  let installPromise =
    caches
    ->CacheStorage.open_(cacheName)
    ->Promise.then(async cache => {
      Console.log("[Service Worker] Fetching asset manifest...")
      let manifestUrls = try {
        let response = await fetchUrl("/asset-manifest.json")
        let manifest = await response->Response.json

        let allFiles = (manifest->Obj.magic)["allFiles"]
        if allFiles->Nullable.toOption->Belt.Option.isSome {
          allFiles->Array.filter(file => !(file->String.endsWith(".map")))
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

      Console.log2("[Service Worker] Caching assets:", uniqueAssets)
      await cache->Cache.addAll(uniqueAssets)
    })
    ->Promise.then(_ => skipWaiting())

  event->ExtendableEvent.waitUntil(installPromise)
})

addEventListener("activate", (event: ExtendableEvent.t) => {
  Console.log("[Service Worker] Activating...")

  let activatePromise =
    caches
    ->CacheStorage.keys()
    ->Promise.then(cacheNames => {
      cacheNames
      ->Array.filter(name => name != cacheName)
      ->Array.map(
        name => {
          Console.log2("[Service Worker] Deleting old cache:", name)
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
    let url = newURL(request->Request.url)
    let pathname = (url->Obj.magic)["pathname"]

    let isApi = pathname->String.startsWith("/api/") || pathname == "/health"

    if !isApi {
      event->FetchEvent.respondWith(
        caches
        ->CacheStorage.match(request)
        ->Promise.then(cachedResponse => {
          switch cachedResponse->Nullable.toOption {
          | Some(res) => Promise.resolve(res)
          | None =>
            fetch(request)->Promise.then(
              response => {
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
              },
            )
          }
        })
        ->Promise.catch(error => {
          Console.error2("[Service Worker] Fetch failed:", error)
          Promise.reject(error)
        }),
      )
    }
  }
})
