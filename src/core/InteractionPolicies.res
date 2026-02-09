type mode =
  | Leading
  | Trailing

type scope =
  | Global
  | Keyed(string)

type policy =
  | Throttle(int, mode)
  | Debounce(int)
  | Mutex(scope)
  | SlidingWindow(int, int, int) // maxCalls, windowMs, minIntervalMs

// Standard Policies
let sceneNavigation = Throttle(200, Leading)
let projectMutation = SlidingWindow(5, 20000, 500)
let heavyCompute = Debounce(100)
