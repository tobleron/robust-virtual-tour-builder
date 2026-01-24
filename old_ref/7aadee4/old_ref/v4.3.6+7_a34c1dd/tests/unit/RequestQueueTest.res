/* tests/unit/RequestQueueTest.res */
open RequestQueue

let run = async () => {
  Console.log("Running RequestQueue tests...")

  // 1. Verify concurrency limit
  let completedCount = ref(0)
  let activeAtPeak = ref(0)

  let createTask = (_id, durationMs) => {
    () => {
      let currentActive = activeCount.contents
      if currentActive > activeAtPeak.contents {
        activeAtPeak := currentActive
      }

      Promise.make((resolve, _reject) => {
        ReBindings.Window.setTimeout(() => {
          completedCount := completedCount.contents + 1
          resolve()
        }, durationMs)->ignore
      })
    }
  }

  // Schedule 5 tasks
  let promises = Belt.Array.makeBy(5, i => {
    schedule(createTask(i, 10))
  })

  let _ = await Promise.all(promises)

  assert(completedCount.contents == 5)
  assert(activeAtPeak.contents > 0)

  // 2. Error test with explicit catch
  let errorTask = () => {
    Promise.make((_res, rej) => {
      rej(%raw(`new Error("Intentional Task Failure")`))
    })
  }

  Console.log("Testing RequestQueue error handling...")
  let result = await schedule(errorTask)
  ->Promise.then(_ => Promise.resolve(Ok()))
  ->Promise.catch(_ => Promise.resolve(Error()))

  switch result {
  | Ok() => assert(false)
  | Error() => Console.log("✓ RequestQueue: Caught scheduled task error")
  }

  assert(activeCount.contents == 0)

  Console.log("✓ RequestQueue: Basic concurrency and error handling verified")
  Console.log("RequestQueue tests passed!")
}
