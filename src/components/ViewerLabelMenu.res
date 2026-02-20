/* src/components/ViewerLabelMenu.res */

@react.component
let make = React.memo((~scenesLoaded, ~isLinking, ~simActive=false) => {
  let (isLabelMenuOpen, setIsLabelMenuOpen) = React.useState(_ => false)
  let (tooltipCooldown, setTooltipCooldown) = React.useState(_ => false)
  let isDisabled = !scenesLoaded || isLinking || simActive

  let handleMenuOpenChange = React.useMemo0(() =>
    isOpen => {
      setIsLabelMenuOpen(_ => isOpen)
      if !isOpen {
        setTooltipCooldown(_ => true)
        let _ = setTimeout(
          () => {
            setTooltipCooldown(_ => false)
          },
          500,
        )
      }
    }
  )

  <Shadcn.DropdownMenu open_=isLabelMenuOpen onOpenChange={handleMenuOpenChange}>
    <Tooltip
      content="Set scene label"
      alignment=#Right
      disabled={isDisabled || isLabelMenuOpen || tooltipCooldown}
    >
      <Shadcn.DropdownMenu.Trigger asChild=true>
        <Shadcn.Button
          size="icon"
          variant={if !scenesLoaded {
            "secondary"
          } else {
            "destructive"
          }}
          className={"w-8 h-8 min-w-8 min-h-8 rounded-full cursor-pointer font-semibold border border-transparent hover:border-[#0e2d52]" ++ if (
            !scenesLoaded
          ) {
            " disabled:opacity-100"
          } else {
            ""
          }}
          disabled=isDisabled
        >
          <LucideIcons.Hash size=18 strokeWidth=3.0 />
        </Shadcn.Button>
      </Shadcn.DropdownMenu.Trigger>
    </Tooltip>
    <Shadcn.DropdownMenu.Content
      side="right"
      align="start"
      sideOffset=12
      className="p-0 bg-white rounded-2xl shadow-2xl border border-slate-200 z-[30000]"
    >
      <LabelMenu
        onClose={() => handleMenuOpenChange(false)}
        sceneIndex={AppContext.useSceneSlice().activeIndex}
      />
    </Shadcn.DropdownMenu.Content>
  </Shadcn.DropdownMenu>
})
