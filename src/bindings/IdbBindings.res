@module("idb-keyval")
external set: (string, 'a) => Promise.t<unit> = "set"

@module("idb-keyval")
external get: string => Promise.t<Nullable.t<'a>> = "get"

@module("idb-keyval")
external del: string => Promise.t<unit> = "del"

@module("idb-keyval")
external clear: unit => Promise.t<unit> = "clear"
