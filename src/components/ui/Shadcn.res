/* src/components/ui/Shadcn.res */

module Button = {
  @module("./button.jsx") @react.component
  external make: (
    ~className: string=?,
    ~variant: string=?,
    ~size: string=?,
    ~onClick: JsxEvent.Mouse.t => unit=?,
    ~children: React.element=?,
  ) => React.element = "Button"
}

module Popover = {
  @module("./popover.jsx") @react.component
  external make: (
    ~children: React.element,
    @as("open") ~open_: bool=?,
    ~onOpenChange: bool => unit=?,
  ) => React.element = "Popover"

  module Trigger = {
    @module("./popover.jsx") @react.component
    external make: (~children: React.element, ~asChild: bool=?) => React.element = "PopoverTrigger"
  }

  module Anchor = {
    @module("./popover.jsx") @react.component
    external make: (~children: React.element=?, ~virtualRef: 'a=?) => React.element =
      "PopoverAnchor"
  }

  module Content = {
    @module("./popover.jsx") @react.component
    external make: (
      ~children: React.element,
      ~className: string=?,
      ~align: string=?,
      ~side: string=?,
      ~sideOffset: int=?,
    ) => React.element = "PopoverContent"
  }
}

module Tooltip = {
  module Provider = {
    @module("./tooltip.jsx") @react.component
    external make: (~children: React.element) => React.element = "TooltipProvider"
  }

  @module("./tooltip.jsx") @react.component
  external make: (~children: React.element) => React.element = "Tooltip"

  module Trigger = {
    @module("./tooltip.jsx") @react.component
    external make: (~children: React.element, ~asChild: bool=?) => React.element = "TooltipTrigger"
  }

  module Content = {
    @module("./tooltip.jsx") @react.component
    external make: (
      ~children: React.element,
      ~className: string=?,
      ~sideOffset: int=?,
      ~side: string=?,
      ~align: string=?,
    ) => React.element = "TooltipContent"
  }
}

module DropdownMenu = {
  @module("./dropdown-menu.jsx") @react.component
  external make: (~children: React.element) => React.element = "DropdownMenu"

  module Trigger = {
    @module("./dropdown-menu.jsx") @react.component
    external make: (~children: React.element, ~asChild: bool=?) => React.element =
      "DropdownMenuTrigger"
  }

  module Content = {
    @module("./dropdown-menu.jsx") @react.component
    external make: (
      ~children: React.element,
      ~className: string=?,
      ~align: string=?,
      ~side: string=?,
      ~sideOffset: int=?,
    ) => React.element = "DropdownMenuContent"
  }

  module Item = {
    @module("./dropdown-menu.jsx") @react.component
    external make: (
      ~children: React.element,
      ~className: string=?,
      ~onClick: JsxEvent.Mouse.t => unit=?,
    ) => React.element = "DropdownMenuItem"
  }

  module Separator = {
    @module("./dropdown-menu.jsx") @react.component
    external make: unit => React.element = "DropdownMenuSeparator"
  }
}

module ContextMenu = {
  @module("./context-menu.jsx") @react.component
  external make: (~children: React.element) => React.element = "ContextMenu"

  module Trigger = {
    @module("./context-menu.jsx") @react.component
    external make: (~children: React.element, ~asChild: bool=?) => React.element =
      "ContextMenuTrigger"
  }

  module Content = {
    @module("./context-menu.jsx") @react.component
    external make: (~children: React.element, ~className: string=?) => React.element =
      "ContextMenuContent"
  }

  module Item = {
    @module("./context-menu.jsx") @react.component
    external make: (
      ~children: React.element,
      ~className: string=?,
      ~onClick: JsxEvent.Mouse.t => unit=?,
    ) => React.element = "ContextMenuItem"
  }

  module Separator = {
    @module("./context-menu.jsx") @react.component
    external make: unit => React.element = "ContextMenuSeparator"
  }
}
