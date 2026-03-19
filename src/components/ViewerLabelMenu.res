/* src/components/ViewerLabelMenu.res */

@react.component
let make = React.memo((
  ~scenesLoaded,
  ~isLinking,
  ~simActive=false,
  ~isSystemLocked=false,
  ~isTeasing=false,
) => {
  let state = AppContext.useAppState()
  let canMutateProject = Capability.useCapability(CanMutateProject)
  let (isLabelMenuOpen, setIsLabelMenuOpen) = React.useState(_ => false)
  let (tooltipCooldown, setTooltipCooldown) = React.useState(_ => false)
  let isMovingHotspot = switch state.movingHotspot {
  | Some(_) => true
  | None => false
  }
  let isDisabled =
    !scenesLoaded ||
    !canMutateProject ||
    isLinking ||
    simActive ||
    isSystemLocked ||
    isTeasing ||
    isMovingHotspot

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
          variant="ghost"
          className="viewer-control viewer-control--orb viewer-control--utility viewer-control--label viewer-control--danger"
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
