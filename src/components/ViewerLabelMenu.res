/* src/components/ViewerLabelMenu.res */

@react.component
let make = React.memo((~scenesLoaded, ~isLinking) => {
  let (isLabelMenuOpen, setIsLabelMenuOpen) = React.useState(_ => false)
  let (tooltipCooldown, setTooltipCooldown) = React.useState(_ => false)

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
      disabled={isLinking || (isLabelMenuOpen || tooltipCooldown)}
    >
      <Shadcn.DropdownMenu.Trigger asChild=true>
        <Shadcn.Button
          size="icon"
          variant={if !scenesLoaded {
            "secondary"
          } else {
            "destructive"
          }}
          className="w-[32px] h-[32px] rounded-full text-[18px] font-bold border border-transparent hover:border-[#0e2d52]"
          disabled={isLinking}
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
      <LabelMenu onClose={() => handleMenuOpenChange(false)} />
    </Shadcn.DropdownMenu.Content>
  </Shadcn.DropdownMenu>
})
