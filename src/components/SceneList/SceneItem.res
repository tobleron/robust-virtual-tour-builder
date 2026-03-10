// @efficiency-role: ui-component

external makeStyle: {..} => ReactDOM.Style.t = "%identity"

module Logic = {
  let getThumbUrl = (scene: Types.scene) => {
    SceneItemDisplay.getThumbUrl(scene)
  }
}

@react.component
let make = React.memo((
  ~scene: Types.scene,
  ~index,
  ~isActive,
  ~interactionLocked=false,
  ~onItemClick: int => unit,
  ~onItemDragStart: (int, JsxEvent.Mouse.t) => unit,
  ~onItemDragOver: (int, JsxEvent.Mouse.t) => unit,
  ~onItemDrop: (int, JsxEvent.Mouse.t) => unit,
  ~onItemRequestReorder: int => unit,
  ~onItemDelete: int => unit,
  ~onItemClearLinks: int => unit,
) => {
  let (handleSceneClick, _, wasThrottled) = UseInteraction.useInteraction(
    ~id="scene_navigation",
    ~policy=InteractionPolicies.sceneNavigation,
    ~action=async () => onItemClick(index),
  )

  React.useEffect0(() => {
    Logger.initialized(~module_="SceneItem")
    None
  })

  let sceneItemRef = SceneItemHooks.useSceneItemRef(scene.id)

  let thumbUrl = React.useMemo1(() => Logic.getThumbUrl(scene), [scene])
  let displayInfo = React.useMemo1(() => SceneItemDisplay.describe(scene), [scene])
  let (
    isMenuOpen,
    setMenuOpen,
    flickerState,
    handleClearClick,
    handleDeleteClick,
    throttleClasses,
    isBusy,
  ) = SceneItemHooks.useMenuFeedback(~wasThrottled, ~index, ~onItemClearLinks, ~onItemDelete)

  let activeClasses = isActive
    ? "active border-slate-200 ring-0 bg-slate-50/50"
    : "border-slate-100 hover:border-slate-200 bg-white"
  let lockClasses = interactionLocked ? "opacity-80 pointer-events-none" : ""

  <div
    key={scene.id}
    ref={ReactDOM.Ref.domRef(sceneItemRef)}
    className={`scene-item group relative flex items-center border rounded-lg mb-2 overflow-hidden transition-all duration-200 select-none touch-pan-y active-push h-16 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 focus-visible:outline-none ${activeClasses} ${throttleClasses} ${lockClasses}`}
    draggable={!interactionLocked}
    onDragStart={e => onItemDragStart(index, e)}
    onDragOver={e => onItemDragOver(index, e)}
    onDrop={e => onItemDrop(index, e)}
    onClick={_ => {
      if !isActive {
        handleSceneClick()->Promise.catch(_ => Promise.resolve())->ignore
      }
    }}
    tabIndex=0
    onKeyDown={e => {
      if JsxEvent.Keyboard.key(e) == "Enter" || JsxEvent.Keyboard.key(e) == " " {
        JsxEvent.Keyboard.preventDefault(e)
        if !isActive {
          handleSceneClick()->Promise.catch(_ => Promise.resolve())->ignore
        }
      }
    }}
    role="button"
    ariaLabel={`Select scene ${scene.name}`}
    ariaBusy=isBusy
  >
    <div
      className="scene-item-dragger flex flex-col items-center justify-center gap-1 w-8 text-slate-300 hover:text-slate-500 cursor-grab active:cursor-grabbing transition-colors self-stretch"
      onDoubleClick={e => {
        JsxEvent.Mouse.preventDefault(e)
        JsxEvent.Mouse.stopPropagation(e)
        onItemRequestReorder(index)
      }}
      title="Drag to reorder. Double-click to choose a position."
    >
      <span className="scene-item-order-chip text-[10px] font-semibold text-slate-500 leading-none">
        {React.int(index + 1)}
      </span>
      <LucideIcons.GripVertical size=14 />
    </div>

    <div className="flex flex-col gap-0 h-full p-1">
      <div className="w-20 h-full relative bg-slate-900 overflow-hidden cursor-pointer rounded-md">
        {if thumbUrl != "" {
          <img
            src={thumbUrl}
            alt={`Thumbnail of ${scene.name}`}
            className="w-full h-full object-cover transition-all duration-700 group-hover:scale-110 opacity-100 group-hover:brightness-[1.3]"
            loading=#lazy
          />
        } else {
          React.null
        }}
        <div className="absolute inset-0 bg-transparent" />
      </div>
    </div>

    <Tooltip content={displayInfo.tooltipName} delayDuration=Constants.tooltipDelayDuration>
      <div className="flex-1 min-w-0 py-1.5 px-2 flex flex-col justify-center cursor-pointer">
        <div className="flex items-center justify-between gap-2 overflow-hidden">
          <h4
            className={`text-[12px] font-medium truncate tracking-tight ${if isActive {
                "text-primary"
              } else {
                "text-slate-700"
              }}`}
          >
            {React.string(TourLogic.formatDisplayLabel(scene))}
          </h4>
          {if Array.length(scene.hotspots) > 0 {
            <div
              className="flex items-center gap-1 text-slate-400 group-hover:text-primary transition-colors shrink-0"
            >
              <LucideIcons.Link size=10 />
              <span className="text-[10px] font-semibold">
                {React.int(Array.length(scene.hotspots))}
              </span>
            </div>
          } else {
            React.null
          }}
        </div>

        <div className="flex items-center gap-2 mt-1">
          /* Format & Technical Meta */
          {
            <div className="flex items-center gap-1.5 shrink-0">
              <span
                className={`px-1 py-0.5 rounded-[3px] text-[8px] font-bold tracking-tight border border-current/10 ${displayInfo.fileMeta.badgeColor}`}
              >
                {React.string(displayInfo.fileMeta.formatLabel)}
              </span>
              {if displayInfo.fileMeta.formattedSize != "" {
                <span className="text-[9px] font-medium text-slate-400">
                  {React.string(displayInfo.fileMeta.formattedSize)}
                </span>
              } else {
                React.null
              }}
            </div>
          }
        </div>
        <div className="flex items-center mt-2">
          <div className="flex-1 relative">
            <div className="w-full bg-slate-100 h-0.5 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all duration-1000 ease-out rounded-full ${displayInfo.quality.colorClass}`}
                style={makeStyle({"width": Float.toString(displayInfo.quality.progressPercent) ++ "%"})}
              />
            </div>
            <span
              className={`absolute -top-4 text-[9px] font-bold uppercase tracking-wider whitespace-nowrap pointer-events-none ${if (
                  displayInfo.quality.isLowQuality
                ) {
                  "text-danger"
                } else {
                  "text-slate-400"
                }}`}
              style={makeStyle({
                "left": Float.toString(displayInfo.quality.progressPercent) ++ "%",
                "transform": "translateX(-50%)",
              })}
            >
              {React.string(Float.toFixed(displayInfo.quality.score, ~digits=1))}
            </span>
          </div>
        </div>
      </div>
    </Tooltip>

    <div
      className="w-8 flex flex-col items-center justify-center gap-0 border-l border-slate-50 bg-slate-50/50 group-hover:bg-slate-100 transition-colors self-stretch"
    >
      <Shadcn.DropdownMenu open_={isMenuOpen} onOpenChange={isOpen => setMenuOpen(_ => isOpen)}>
        <Shadcn.DropdownMenu.Trigger asChild=true>
          <button
            className="w-6 h-6 rounded flex items-center justify-center hover:bg-white hover:shadow-sm transition-all text-slate-400 hover:text-primary active:scale-90 focus-visible:ring-2 focus-visible:ring-primary focus-visible:outline-none"
            ariaLabel={`Actions for ${scene.name}`}
            disabled=interactionLocked
            onClick={e => JsxEvent.Mouse.stopPropagation(e)}
          >
            <LucideIcons.MoreVertical size=14 />
          </button>
        </Shadcn.DropdownMenu.Trigger>
        <Shadcn.DropdownMenu.Content side="right" sideOffset=10 className="w-48 p-1.5 z-[30000]">
          <Shadcn.DropdownMenu.Label
            className="text-[10px] font-semibold uppercase tracking-widest text-slate-500 py-2 px-3"
          >
            {React.string("Scene Actions")}
          </Shadcn.DropdownMenu.Label>

          <Shadcn.DropdownMenu.Item
            onClick={handleClearClick}
            className={`px-2 py-1.5 text-[10px] font-semibold uppercase tracking-wide cursor-pointer text-slate-600 ${flickerState ==
                #Clear
                ? "animate-flicker-orange-flat"
                : ""}`}
          >
            <LucideIcons.Unlink className="text-lg mr-2 text-primary" />
            <span> {React.string("Clear Links")} </span>
          </Shadcn.DropdownMenu.Item>

          <Shadcn.DropdownMenu.Separator />

          <Shadcn.DropdownMenu.Item
            onClick={handleDeleteClick}
            className={`px-2 py-1.5 text-[10px] font-semibold uppercase tracking-wide cursor-pointer text-danger hover:bg-danger/10 ${flickerState ==
                #Delete
                ? "animate-flicker-red-light"
                : ""}`}
          >
            <LucideIcons.Trash2 className="text-lg mr-2 text-danger" />
            <span> {React.string("Remove Scene")} </span>
          </Shadcn.DropdownMenu.Item>
        </Shadcn.DropdownMenu.Content>
      </Shadcn.DropdownMenu>
    </div>
  </div>
})
