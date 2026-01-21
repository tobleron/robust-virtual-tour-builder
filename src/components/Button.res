/* src/components/Button.res */

type variant =
  | Primary
  | Yellow
  | Danger
  | Success
  | SidebarSquare
  | SidebarWide
  | ModalPremium
  | ViewerUtil

type size = Small | Medium | Large

@react.component
let make = (
  ~children: React.element,
  ~onClick: option<ReactEvent.Mouse.t => unit>=?,
  ~variant: variant=Primary,
  ~disabled: bool=false,
  ~className: string="",
  ~ariaLabel: option<string>=?,
  ~icon: option<string>=?,
  ~type_: string="button",
) => {
  let baseClass = switch variant {
  | Primary => "btn btn-primary"
  | Yellow => "btn btn-yellow"
  | Danger => "btn btn-danger-red"
  | Success => "btn btn-success-green"
  | SidebarSquare => "sidebar-action-btn-square hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50"
  | SidebarWide => "sidebar-action-btn-wide hover-lift active-push group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/50"
  | ModalPremium => "modal-btn-premium"
  | ViewerUtil => "v-util-btn"
  }

  let combinedClass = baseClass ++ " " ++ className

  <button
    type_
    className={combinedClass}
    onClick={switch onClick {
    | Some(fn) => fn
    | None => _ => ()
    }}
    disabled
    ?ariaLabel
  >
    {switch icon {
    | Some(iconName) =>
      <span className="material-icons" ariaHidden=true> {React.string(iconName)} </span>
    | None => React.null
    }}
    {children}
  </button>
}
