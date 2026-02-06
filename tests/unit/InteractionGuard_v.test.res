open Vitest
open InteractionGuard
open InteractionPolicies
open ReBindings

let wait = ms =>
  Promise.make((resolve, _) => {
    let _ = Window.setTimeout(() => resolve(Obj.magic()), ms)
  })

testAsync("Throttle (Leading) - only one executes per window", async t => {
  let counter = ref(0)
  let action = async () => {
    counter := counter.contents + 1
  }

  // Call 1: Success
  let r1 = attempt("throttle_test", Throttle(100, Leading), action)
  switch r1 {
  | Ok(_) => t->expect(counter.contents)->Expect.toBe(1)
  | Error(_) => t->expect("First call failed")->Expect.toBe("First call should succeed")
  }

  // Call 2: Blocked
  let r2 = attempt("throttle_test", Throttle(100, Leading), action)
  switch r2 {
  | Ok(_) => t->expect("Second call succeeded")->Expect.toBe("Second call should be throttled")
  | Error(msg) => t->expect(msg)->Expect.toBe("Throttled")
  }

  // Wait > 100ms
  let _ = await wait(150)

  // Call 3: Success
  let r3 = attempt("throttle_test", Throttle(100, Leading), action)
  switch r3 {
  | Ok(_) => t->expect(counter.contents)->Expect.toBe(2)
  | Error(_) => t->expect("Third call failed")->Expect.toBe("Third call should succeed")
  }
})

testAsync("Mutex (Global) - only one executes at a time", async t => {
  let finished = ref(false)

  let resolveRef = ref(_ => ())
  let p = Promise.make((resolve, _) => {
    resolveRef := resolve
  })

  let action = async () => {
    await p
    finished := true
  }

  // Start Action 1
  let r1 = attempt("mutex_test", Mutex(Global), action)

  // Start Action 2 (should be blocked)
  let r2 = attempt("mutex_test", Mutex(Global), async () => ())

  switch r1 {
  | Ok(_) => ()
  | Error(_) => t->expect("First mutex call failed")->Expect.toBe("Should succeed")
  }

  switch r2 {
  | Ok(_) => t->expect("Second mutex call succeeded")->Expect.toBe("Should be locked")
  | Error(msg) => t->expect(msg)->Expect.toBe("Locked")
  }

  // Finish Action 1
  resolveRef.contents(Obj.magic())
  // Wait for promise chain
  let _ = await wait(10)

  // Start Action 3 (should succeed)
  let r3 = attempt("mutex_test", Mutex(Global), async () => ())
  switch r3 {
  | Ok(_) => ()
  | Error(msg) => t->expect("Third mutex call failed: " ++ msg)->Expect.toBe("Should succeed")
  }

  t->expect(finished.contents)->Expect.toBe(true)
})

testAsync("SlidingWindow - limits calls in window", async t => {
  let counter = ref(0)
  let action = async () => {
    counter := counter.contents + 1
  }

  // 2 calls allowed per 50ms
  let policy = SlidingWindow(2, 50)

  // Call 1: OK
  let _ = attempt("sliding_test", policy, action)
  // Call 2: OK
  let _ = attempt("sliding_test", policy, action)
  // Call 3: Blocked
  let r3 = attempt("sliding_test", policy, action)

  t->expect(counter.contents)->Expect.toBe(2)
  switch r3 {
  | Ok(_) => t->expect("Third call succeeded")->Expect.toBe("Should be rate limited")
  | Error(msg) => t->expect(msg)->Expect.toBe("Rate limited")
  }

  // Wait > 50ms
  let _ = await wait(60)

  // Call 4: OK
  let _ = attempt("sliding_test", policy, action)
  t->expect(counter.contents)->Expect.toBe(3)
})
