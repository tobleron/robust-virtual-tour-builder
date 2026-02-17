/* src/utils/AsyncQueue.res */
// @efficiency-role: utility

open Logger

type queueResult<'result> =
  | Success('result)
  | Failed(int, string)

let computeStatus = (activeStatuses, completedCount, total) => {
  let counts = Dict.make()
  Dict.toArray(activeStatuses)->Belt.Array.forEach(((_k, status)) => {
    let current = Dict.get(counts, status)->Option.getOr(0)
    Dict.set(counts, status, current + 1)
  })

  let parts = []
  Dict.toArray(counts)->Belt.Array.forEach(((status, count)) => {
    if status != "__DONE__" && count > 0 {
      let _ = Array.push(parts, status ++ ": " ++ Belt.Int.toString(count))
    }
  })

  let baseMsg =
    "Processing " ++ Belt.Int.toString(completedCount) ++ "/" ++ Belt.Int.toString(total)
  if Array.length(parts) > 0 {
    baseMsg ++ "|" ++ Array.join(parts, " \u2022 ")
  } else {
    baseMsg
  }
}

let execute = (
  items: array<'item>,
  maxConcurrency: int,
  worker: (int, 'item, string => unit) => Promise.t<'result>,
  onProgress: (float, string) => unit,
) => {
  let total = Array.length(items)
  let results = Belt.Array.make(total, None)
  let currentIndex = ref(0)
  let completedCount = ref(0)
  let activeStatuses = Dict.make()

  let report = () => {
    let msg = computeStatus(activeStatuses, completedCount.contents, total)
    let pct = if total > 0 {
      Float.fromInt(completedCount.contents) /. Float.fromInt(total)
    } else {
      1.0
    }
    onProgress(pct, msg)
  }

  let (resolve, _) = (ref(ignore), ref(ignore))
  let promise = Promise.make((res, _rej) => {
    resolve := res
    // No reject handling needed for now
  })

  let rec next = () => {
    if currentIndex.contents >= total {
      if completedCount.contents == total {
        resolve.contents(Belt.Array.keepMap(results, x => x))
      }
    } else {
      let i = currentIndex.contents
      currentIndex := i + 1
      switch Belt.Array.get(items, i) {
      | Some(item) =>
        Dict.set(activeStatuses, Belt.Int.toString(i), "Pending")
        report()

        let _ =
          worker(i, item, status => {
            Dict.set(activeStatuses, Belt.Int.toString(i), status)
            report()
          })
          ->Promise.then(res => {
            let _ = Belt.Array.set(results, i, Some(Success(res)))
            completedCount := completedCount.contents + 1
            Dict.set(activeStatuses, Belt.Int.toString(i), "__DONE__")
            report()
            next()
            Promise.resolve()
          })
          ->Promise.catch(err => {
            let (msg, _) = getErrorDetails(err)
            error(
              ~module_="AsyncQueue",
              ~message="WORKER_UNHANDLED_ERROR",
              ~data=castToJson({"index": i, "error": msg}),
              (),
            )
            let _ = Belt.Array.set(results, i, Some(Failed(i, msg)))
            completedCount := completedCount.contents + 1
            Dict.set(activeStatuses, Belt.Int.toString(i), "__Error__")
            report()
            next()
            Promise.resolve()
          })
      | None => ()
      }
    }
  }

  let initialWorkers = Math.Int.min(maxConcurrency, total)
  if total == 0 {
    resolve.contents([])
  } else {
    for _ in 1 to initialWorkers {
      next()
    }
  }
  promise
}
