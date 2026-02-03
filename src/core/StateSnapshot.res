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
  Math.random()->Float.toString ++ "_" ++ Date.now()->Float.toString
}

let capture = (state: Types.state, action: Actions.action): string => {
  let id = generateId()
  let snapshot = {
    id: id,
    timestamp: Date.now(),
    state: state,
    action: action,
  }

  // Prepend to history
  history := Belt.Array.concat([snapshot], history.contents)

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
      let snapshot = Belt.Array.getExn(history.contents, i)
      // Remove this snapshot and any newer ones (indices 0 to i)
      let newHistory = Belt.Array.slice(history.contents, ~offset=i + 1, ~len=Belt.Array.length(history.contents) - (i + 1))
      history := newHistory
      Some(snapshot.state)
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
