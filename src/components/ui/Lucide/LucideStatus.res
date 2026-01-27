/* src/components/ui/Lucide/LucideStatus.res */

module CircleAlert = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
    ~stroke: string=?,
  ) => React.element = "CircleAlert"
}

module CircleCheck = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
    ~stroke: string=?,
  ) => React.element = "CircleCheck"
}

module TriangleAlert = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
    ~stroke: string=?,
  ) => React.element = "TriangleAlert"
}

module Flag = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "Flag"
}
