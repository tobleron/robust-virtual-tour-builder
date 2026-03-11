// @efficiency-role: service-orchestrator

let hasHashedAssetName = (_pathname: string): bool =>
  %raw(`(function(pathname){
    return /-[a-f0-9]{6,}\.(js|css|mjs|png|jpg|jpeg|webp|svg)$/.test(pathname);
  })(_pathname)`)

let shouldCacheResponse = (_response): bool => {
  let cc = %raw(`(function(response){
    const headers = response && response.headers ? response.headers : null;
    const value = headers && typeof headers.get === "function" ? headers.get("Cache-Control") : null;
    return value == null ? "" : String(value);
  })(_response)`)
  !(cc->String.includes("no-store") || cc->String.includes("private"))
}

let isResponseOlderThan = (_response, _maxAgeMs: float): bool =>
  %raw(`(function(response, maxAgeMs){
    try {
      const dateVal = response && response.headers ? response.headers.get("Date") : null;
      if (!dateVal) return false;
      const ts = Date.parse(dateVal);
      if (!Number.isFinite(ts)) return false;
      return (Date.now() - ts) > maxAgeMs;
    } catch (_) {
      return false;
    }
  })(_response, _maxAgeMs)`)

let dedupeAssets = (_assets: array<string>): array<string> =>
  %raw(`(function(assets){ return Array.from(new Set(assets)); })(assets)`)

let loadManifestUrls = (~fetchManifest: unit => Promise.t<array<string>>): Promise.t<
  array<string>,
> => fetchManifest()->Promise.catch(_ => Promise.resolve([]))

let installPromise = (
  ~cacheName: string,
  ~manualAssets: array<string>,
  ~openCache: string => Promise.t<'cache>,
  ~addAll: ('cache, array<string>) => Promise.t<unit>,
  ~skipWaiting: unit => Promise.t<unit>,
  ~fetchManifest: unit => Promise.t<array<string>>,
) =>
  openCache(cacheName)
  ->Promise.then(async cache => {
    Logger.info(~module_="ServiceWorker", ~message="FETCH_MANIFEST_START", ())
    let manifestUrls = await loadManifestUrls(~fetchManifest)
    let allAssets = manualAssets->Array.concat(manifestUrls)
    let uniqueAssets = dedupeAssets(allAssets)

    Logger.info(~module_="ServiceWorker", ~message="CACHING_ASSETS", ~data=uniqueAssets, ())
    await addAll(cache, uniqueAssets)
  })
  ->Promise.then(_ => skipWaiting())

let pruneCacheEntries = (
  ~requests: array<'request>,
  ~matchRequest: 'request => Promise.t<option<'response>>,
  ~deleteRequest: 'request => Promise.t<bool>,
  ~requestUrl: 'request => string,
  ~pathnameForUrl: string => string,
  ~runtimeStaleMaxAgeMs: float,
) =>
  requests
  ->Array.map(req =>
    matchRequest(req)->Promise.then(found => {
      switch found {
      | Some(response) =>
        let path = pathnameForUrl(requestUrl(req))
        if !hasHashedAssetName(path) && isResponseOlderThan(response, runtimeStaleMaxAgeMs) {
          deleteRequest(req)
        } else {
          Promise.resolve(false)
        }
      | None => Promise.resolve(false)
      }
    })
  )
  ->Promise.all
  ->Promise.then(_ => Promise.resolve())

let activatePromise = (
  ~cacheName: string,
  ~runtimeStaleMaxAgeMs: float,
  ~cacheKeys: unit => Promise.t<array<string>>,
  ~deleteCache: string => Promise.t<bool>,
  ~openCache: string => Promise.t<'cache>,
  ~cacheRequests: 'cache => Promise.t<array<'request>>,
  ~matchRequest: ('cache, 'request) => Promise.t<option<'response>>,
  ~deleteRequest: ('cache, 'request) => Promise.t<bool>,
  ~requestUrl: 'request => string,
  ~pathnameForUrl: string => string,
  ~enableNavigationPreload: unit => Promise.t<unit>,
  ~claimClients: unit => Promise.t<unit>,
) =>
  cacheKeys()
  ->Promise.then(cacheNames => {
    cacheNames
    ->Array.filter(name => name != cacheName)
    ->Array.map(name => {
      Logger.info(~module_="ServiceWorker", ~message="DELETE_OLD_CACHE", ~data=name, ())
      deleteCache(name)
    })
    ->Promise.all
  })
  ->Promise.then(_ =>
    openCache(cacheName)->Promise.then(cache =>
      cacheRequests(cache)->Promise.then(
        requests =>
          pruneCacheEntries(
            ~requests,
            ~matchRequest=req => matchRequest(cache, req),
            ~deleteRequest=req => deleteRequest(cache, req),
            ~requestUrl,
            ~pathnameForUrl,
            ~runtimeStaleMaxAgeMs,
          ),
      )
    )
  )
  ->Promise.then(_ => enableNavigationPreload())
  ->Promise.then(_ => claimClients())
