/* src/components/HotspotMenuLayer.res */
open EventBus

type hotspotMenuInfo = {
  anchor: Dom.element,
  hotspot: Types.hotspot,
  index: int,
}

@react.component
let make = React.memo(() => {
  let uiSlice = AppContext.useUiSlice()
  let isTeasing = uiSlice.isTeasing
  let (hotspotMenu, setHotspotMenu) = React.useState(_ => None)

  // Force close menu if teaser starts
  React.useEffect1(() => {
    if isTeasing {
      setHotspotMenu(_ => None)
    }
    None
  }, [isTeasing])

  // Subscribe to hotspot menu events
  React.useEffect1(() => {
    let unsubscribe = EventBus.subscribe(
      event => {
        switch event {
        | OpenHotspotMenu(payload) if !isTeasing =>
          setHotspotMenu(
            _ => Some({
              anchor: payload["anchor"],
              hotspot: payload["hotspot"],
              index: payload["index"],
            }),
          )
        | _ => ()
        }
      },
    )

    Some(() => unsubscribe())
  }, [isTeasing])

  {
    switch hotspotMenu {
    | Some(menu) =>
      <Shadcn.Popover
        open_={true}
        onOpenChange={isOpen =>
          if !isOpen {
            setHotspotMenu(_ => None)
          }}
      >
        <Shadcn.Popover.Anchor virtualRef={menu.anchor} />
        <Shadcn.Popover.Content
          side="top" sideOffset=12 className="p-0 border-none shadow-none z-[30000]"
        >
          <HotspotActionMenu
            hotspot={menu.hotspot} index={menu.index} onClose={() => setHotspotMenu(_ => None)}
          />
        </Shadcn.Popover.Content>
      </Shadcn.Popover>
    | None => React.null
    }
  }
})
