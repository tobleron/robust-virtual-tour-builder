/* src/components/ui/Lucide/LucideMedia.res */

module ImageIcon = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
    ~stroke: string=?,
  ) => React.element = "Image"
}

module FileImage = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
    ~stroke: string=?,
  ) => React.element = "FileImage"
}

module Images = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
    ~stroke: string=?,
  ) => React.element = "Images"
}

module Film = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "Film"
}

module Camera = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "Camera"
}

module Sparkles = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "Sparkles"
}

module BarChart3 = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "BarChart3"
}

module Download = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "Download"
}

module Copy = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "Copy"
}
