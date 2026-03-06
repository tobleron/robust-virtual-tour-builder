type opaquePromise

external toOpaquePromise: promise<'a> => opaquePromise = "%identity"
external fromOpaquePromise: opaquePromise => promise<'a> = "%identity"

let inFlight: Dict.t<opaquePromise> = Dict.make()

let clear = () => {
  Belt.Array.forEach(Dict.toArray(inFlight), ((key, _value)) => Dict.delete(inFlight, key))
}

let run = (~key: string, ~task: unit => promise<'a>): promise<'a> => {
  switch Dict.get(inFlight, key)->Option.map(fromOpaquePromise) {
  | Some(existing) => existing
  | None =>
    let wrapped = task()
    ->Promise.then(result => {
      Dict.delete(inFlight, key)
      Promise.resolve(result)
    })
    ->Promise.catch(err => {
      Dict.delete(inFlight, key)
      Promise.reject(err)
    })
    Dict.set(inFlight, key, toOpaquePromise(wrapped))
    wrapped
  }
}
