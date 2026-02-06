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

// Standard Policies
let sceneNavigation = Throttle(300, Leading)
let projectMutation = Mutex(Global)
let heavyCompute = Debounce(100)
