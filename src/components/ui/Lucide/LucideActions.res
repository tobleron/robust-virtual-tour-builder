/* src/components/ui/Lucide/LucideActions.res */

module FilePlus = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "FilePlus"
}

module Save = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "Save"
}

module FolderOpen = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "FolderOpen"
}

module Info = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "Info"
}

module Share2 = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "Share2"
}

module Trash2 = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "Trash2"
}

module Unlink = {
  @module("lucide-react") @react.component
  external make: (
    ~className: string=?,
    ~size: int=?,
    ~strokeWidth: float=?,
    ~fill: string=?,
  ) => React.element = "Unlink"
}
