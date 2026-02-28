type t<'v> = {
  maxEntries: int,
  map: Belt.MutableMap.String.t<'v>,
  orderRef: ref<array<string>>,
  onEvict: option<(string, 'v) => unit>,
}

let make = (~maxEntries: int, ~onEvict: option<(string, 'v) => unit>=?): t<'v> => {
  maxEntries: if maxEntries > 0 {
    maxEntries
  } else {
    1
  },
  map: Belt.MutableMap.String.make(),
  orderRef: ref([]),
  onEvict,
}

let size = (cache: t<'v>) => Belt.MutableMap.String.size(cache.map)

let touch = (cache: t<'v>, key: string) => {
  let withoutKey = cache.orderRef.contents->Belt.Array.keep(k => k != key)
  cache.orderRef := Belt.Array.concat(withoutKey, [key])
}

let evictOne = (cache: t<'v>) => {
  switch Belt.Array.get(cache.orderRef.contents, 0) {
  | Some(oldestKey) =>
    switch Belt.MutableMap.String.get(cache.map, oldestKey) {
    | Some(value) =>
      Belt.MutableMap.String.remove(cache.map, oldestKey)
      cache.orderRef := cache.orderRef.contents->Belt.Array.keep(k => k != oldestKey)
      cache.onEvict->Option.forEach(cb => cb(oldestKey, value))
    | None => cache.orderRef := cache.orderRef.contents->Belt.Array.keep(k => k != oldestKey)
    }
  | None => ()
  }
}

let enforceMax = (cache: t<'v>) => {
  while Belt.MutableMap.String.size(cache.map) > cache.maxEntries {
    evictOne(cache)
  }
}

let get = (cache: t<'v>, key: string): option<'v> => {
  let value = Belt.MutableMap.String.get(cache.map, key)
  value->Option.forEach(_ => touch(cache, key))
  value
}

let set = (cache: t<'v>, key: string, value: 'v) => {
  Belt.MutableMap.String.set(cache.map, key, value)
  touch(cache, key)
  enforceMax(cache)
}

let remove = (cache: t<'v>, key: string) => {
  switch Belt.MutableMap.String.get(cache.map, key) {
  | Some(value) => cache.onEvict->Option.forEach(cb => cb(key, value))
  | None => ()
  }
  Belt.MutableMap.String.remove(cache.map, key)
  cache.orderRef := cache.orderRef.contents->Belt.Array.keep(k => k != key)
}

let clear = (cache: t<'v>) => {
  Belt.MutableMap.String.forEach(cache.map, (key, value) => {
    cache.onEvict->Option.forEach(cb => cb(key, value))
  })
  Belt.MutableMap.String.clear(cache.map)
  cache.orderRef := []
}

let shrinkTo = (cache: t<'v>, targetMax: int) => {
  let bounded = if targetMax > 0 {
    targetMax
  } else {
    1
  }
  while Belt.MutableMap.String.size(cache.map) > bounded {
    evictOne(cache)
  }
}
