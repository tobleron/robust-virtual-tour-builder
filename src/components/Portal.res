/* src/components/Portal.res */
open ReBindings

@react.component
let make = (~children: React.element, ~id: string="portal-root") => {
  let portalNode = React.useMemo1(() => {
    let existing = Dom.getElementById(id)
    switch Nullable.toOption(existing) {
    | Some(node) => node
    | None =>
      let node = Dom.createElement("div")
      Dom.setId(node, id)
      Dom.appendChild(Dom.documentBody, node)
      node
    }
  }, [id])

  ReactDOMPortal.createPortal(children, portalNode)
}
