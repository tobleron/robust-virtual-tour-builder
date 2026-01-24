/* src/utils/RequestQueue.res */

let maxConcurrent = 6
let activeCount = ref(0)
let queue: array<unit => Promise.t<unit>> = []

let rec process = () => {
  if activeCount.contents < maxConcurrent && Array.length(queue) > 0 {
    switch Array.shift(queue) {
    | Some(run) =>
      activeCount := activeCount.contents + 1
      run()
      ->Promise.then(_ => {
        activeCount := activeCount.contents - 1
        process()
        Promise.resolve()
      })
      ->Promise.catch(_ => {
        activeCount := activeCount.contents - 1
        process()
        Promise.resolve()
      })
      ->ignore

      /* Try to start another one in parallel if slots remain */
      process()
    | None => ()
    }
  }
}

let schedule = (task: unit => Promise.t<'a>): Promise.t<'a> => {
  Promise.make((resolve, reject) => {
    let run = () => {
      task()
      ->Promise.then(result => {
        resolve(result)
        Promise.resolve()
      })
      ->Promise.catch(err => {
        reject(err)
        Promise.resolve()
      })
    }

    Array.push(queue, run)
    process()
  })
}
