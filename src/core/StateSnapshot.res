/* src/core/StateSnapshot.res */

open JsonCombinators.Json

type snapshot = {
  id: string,
  timestamp: float,
  state: Types.state,
  action: Actions.action,
}

let history: ref<array<snapshot>> = ref([])
let maxSnapshots = 10

let snapshotEncoder = (snapshot: snapshot) => {
  Encode.object([
    ("id", Encode.string(snapshot.id)),
    ("timestamp", Encode.float(snapshot.timestamp)),
    ("state", JsonParsers.Encoders.state(snapshot.state)),
    ("action", Encode.string(Actions.actionToString(snapshot.action))),
  ])
}

let generateId = () => {
  try {
    ReBindings.Crypto.randomUUID()
  } catch {
  | _ => "snap_" ++ Float.toString(Date.now()) ++ "_" ++ Float.toString(Math.random())
  }
}

let capture = (state: Types.state, action: Actions.action): string => {
  let id = generateId()
  let snapshot = {
    id,
    timestamp: Date.now(),
    state,
    action,
  }

  // Prepend to history
  history := Belt.Array.concat([snapshot], history.contents)

  Logger.debug(
    ~module_="StateSnapshot",
    ~message="CAPTURE",
    ~data=Some(
      Logger.castToJson({
        "id": id,
        "action": Actions.actionToString(action),
        "historySize": Belt.Array.length(history.contents),
      }),
    ),
    (),
  )

  // Trim if needed
  if Belt.Array.length(history.contents) > maxSnapshots {
    history := Belt.Array.slice(history.contents, ~offset=0, ~len=maxSnapshots)
  }

  id
}

let rollback = (id: string): option<Types.state> => {
  let indexOpt = Belt.Array.getIndexBy(history.contents, s => s.id == id)
  switch indexOpt {
  | Some(i) =>
    switch Belt.Array.get(history.contents, i) {
    | Some(snapshot) =>
      // Remove this snapshot and any newer ones (indices 0 to i)
      let newHistory = Belt.Array.slice(
        history.contents,
        ~offset=i + 1,
        ~len=Belt.Array.length(history.contents) - (i + 1),
      )
      history := newHistory
      Some(snapshot.state)
    | None => None
    }
  | None => None
  }
}

let commit = (id: string): unit => {
  history := Belt.Array.keep(history.contents, s => s.id != id)
}

let getLatest = (): option<snapshot> => {
  Belt.Array.get(history.contents, 0)
}

let clear = (): unit => {
  history := []
}
