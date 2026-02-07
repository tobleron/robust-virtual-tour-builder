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
  | SlidingWindow(int, int) // maxCalls, windowMs

// Standard Policies
let sceneNavigation = Throttle(300, Leading)
let projectMutation = SlidingWindow(5, 10000)
let heavyCompute = Debounce(100)
