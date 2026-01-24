open Vitest

describe("ServiceWorkerMain", () => {
  test("cacheName is defined", t => {
    t->expect(ServiceWorkerMain.cacheName->String.includes("vtb-cache-v"))->Expect.toBe(true)
  })

  test("manualAssets contains core files", t => {
    let assets = ServiceWorkerMain.manualAssets
    t->expect(assets->Array.includes("/"))->Expect.toBe(true)
    t->expect(assets->Array.includes("/index.html"))->Expect.toBe(true)
    t->expect(assets->Array.includes("/manifest.json"))->Expect.toBe(true)
  })

  test("Bindings are accessible", _ => {
    /* This just ensures the compiler sees these as valid modules and externals */
    let _ = (
      ServiceWorkerMain.Response.clone,
      ServiceWorkerMain.Request.method,
      ServiceWorkerMain.Cache.match,
      ServiceWorkerMain.CacheStorage.open_,
      ServiceWorkerMain.Clients.claim,
      ServiceWorkerMain.FetchEvent.request,
      ServiceWorkerMain.ExtendableEvent.waitUntil,
    )
  })
})
