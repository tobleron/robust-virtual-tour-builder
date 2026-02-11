# 1329: [NAV-SUP 2/6] Add AbortController/AbortSignal Bindings

## Parent Task
[1306_ARCH_Navigation_Supervisor_Pattern](./1306_ARCH_Navigation_Supervisor_Pattern.md)

## Objective
Add proper ReScript bindings for `AbortController` and `AbortSignal` to enable structured concurrency in the navigation pipeline. These bindings allow `SceneLoader` and `SceneTransition` to respond to cancellation requests.

## Context
The Supervisor pattern requires the ability to **cancel in-flight async work**. The browser-native `AbortController` + `AbortSignal` API is the standard mechanism. We currently have a partial binding in `BrowserBindings.res` — this task ensures it's complete and usable.

## Implementation

### [MODIFY] `src/bindings/BrowserBindings.res`

Check if `AbortController` and `AbortSignal` are already bound. If partial or missing, add:

```rescript
module AbortController = {
  type t

  @new external make: unit => t = "AbortController"
  @get external signal: t => AbortSignal.t = "signal"
  @send external abort: t => unit = "abort"
}

module AbortSignal = {
  type t

  @get external aborted: t => bool = "aborted"
  @send external addEventListener: (t, string, unit => unit) => unit = "addEventListener"
  @send external removeEventListener: (t, string, unit => unit) => unit = "removeEventListener"
}
```

**Note on ordering:** `AbortSignal` must be defined before `AbortController` (or use `and` for mutual recursion) because `AbortController.signal` returns `AbortSignal.t`.

### [MODIFY] `src/systems/Navigation/NavigationSupervisor.res`
- Import and use the new `AbortController` binding in `requestNavigation`:
  ```rescript
  let controller = BrowserBindings.AbortController.make()
  let newTask = {
    id: taskId,
    targetSceneId,
    abort: () => BrowserBindings.AbortController.abort(controller),
    startedAt: Date.now(),
  }
  ```
- Store the `AbortSignal.t` so it can be passed to `SceneLoader` in task 1330.

## Verification
- [ ] `AbortController.make()` compiles and produces a valid JS `new AbortController()`
- [ ] `AbortSignal.aborted` correctly reads the boolean property
- [ ] `AbortController.abort()` correctly calls the `abort()` method
- [ ] No `Obj.magic` used in bindings
- [ ] Build passes cleanly

## Does NOT include
- Passing `AbortSignal` into `SceneLoader` or `SceneTransition` (Task 1330)
