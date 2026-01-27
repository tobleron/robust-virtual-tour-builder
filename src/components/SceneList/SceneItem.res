/* src/components/SceneList/SceneItem.res */

external makeStyle: {..} => ReactDOM.Style.t = "%identity"

@react.component
let make = React.memo((
  ~scene: Types.scene,
  ~index,
  ~isActive,
  ~onClick,
  ~onDragStart,
  ~onDragOver,
  ~onDrop,
  ~onDelete,
  ~onClearLinks,
) => {
  React.useEffect0(() => {
    Logger.initialized(~module_="SceneItem")
    None
  })

  let thumbUrl = React.useMemo1(() => {
    switch scene.tinyFile {
    | Some(tiny) => UrlUtils.fileToUrl(tiny)
    | None => UrlUtils.fileToUrl(scene.file)
    }
  }, [scene.id])

  let (isMenuOpen, setMenuOpen) = React.useState(_ => false)
  let (flickerState, setFlickerState) = React.useState(_ => #None)

  let handleClearClick = e => {
    JsxEvent.Mouse.preventDefault(e)
    setFlickerState(_ => #Clear)
    let _ = ReBindings.Window.setTimeout(() => {
      setFlickerState(_ => #None)
      setMenuOpen(_ => false)
      onClearLinks()
    }, 800)
  }

  let handleDeleteClick = e => {
    JsxEvent.Mouse.preventDefault(e)
    setFlickerState(_ => #Delete)
    let _ = ReBindings.Window.setTimeout(() => {
      setFlickerState(_ => #None)
      setMenuOpen(_ => false)
      onDelete()
    }, 800)
  }

  let activeClasses = if isActive {
    "border-slate-200 ring-0 bg-slate-50/50"
  } else {
    "border-slate-100 hover:border-slate-200 bg-white"
  }

  let qualityScore = switch scene.quality {
  | Some(q) =>
    let qObj = Schemas.castToQualityAnalysis(q)
    qObj.score
  | None => 10.0
  }
  let isLowQuality = qualityScore < 6.5
  let qualityColor = if isLowQuality {
    "bg-danger"
  } else {
    "bg-success"
  }

  let groupColorClass = ColorPalette.getGroupClass(scene.colorGroup)

  <div
    key={scene.id}
    className={`scene-item group relative flex items-center border rounded-lg mb-2 overflow-hidden transition-all duration-200 select-none touch-pan-y active-push h-16 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 focus-visible:outline-none ${activeClasses}`}
    draggable=true
    onDragStart={onDragStart}
    onDragOver={onDragOver}
    onDrop={onDrop}
    onClick={_ => onClick()}
    tabIndex=0
    onKeyDown={e => {
      if JsxEvent.Keyboard.key(e) == "Enter" || JsxEvent.Keyboard.key(e) == " " {
        JsxEvent.Keyboard.preventDefault(e)
        onClick()
      }
    }}
    role="button"
    ariaLabel={`Select scene ${scene.name}`}
  >
    <div
      className="flex items-center justify-center w-5 text-slate-300 hover:text-slate-500 cursor-grab active:cursor-grabbing transition-colors self-stretch"
    >
      <LucideIcons.GripVertical size=14 />
    </div>

    <div className="flex flex-col gap-0 h-full p-1">
      <div className="w-20 h-full relative bg-slate-900 overflow-hidden cursor-pointer rounded-md">
        {if thumbUrl != "" {
          <img
            src={thumbUrl}
            alt={`Thumbnail of ${scene.name}`}
            className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110 opacity-80 group-hover:opacity-100"
            loading=#lazy
          />
        } else {
          React.null
        }}
        <div className="absolute inset-0 bg-gradient-to-r from-slate-950/40 to-transparent" />

        <div
          className="absolute top-1 left-1 px-1 py-0.5 rounded bg-slate-950/70 backdrop-blur-md text-[10px] font-semibold text-white border border-white/10 z-10"
        >
          {React.int(index + 1)}
        </div>

        <div
          className={`absolute top-0 right-0 h-full z-20 transition-all duration-500 w-1 ${groupColorClass}`}
        />
      </div>
    </div>

    <div className="flex-1 min-w-0 py-1.5 px-2 flex flex-col justify-center cursor-pointer">
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center justify-between gap-2">
          <h4
            className={`text-[12px] font-medium truncate tracking-tight ${if isActive {
                "text-primary"
              } else {
                "text-slate-700"
              }}`}
          >
            {React.string(scene.name)}
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

        <div className="flex items-center gap-1.5 mt-1">
          <div className="flex-1">
            <div className="w-full bg-slate-100 h-0.5 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all duration-1000 ease-out rounded-full ${qualityColor}`}
                style={makeStyle({"width": Float.toString(qualityScore *. 10.0) ++ "%"})}
              />
            </div>
          </div>
          <span
            className={`text-[10px] font-semibold uppercase tracking-wide leading-none ${if (
                isLowQuality
              ) {
                "text-danger"
              } else {
                "text-slate-400"
              }}`}
          >
            {React.string(Float.toFixed(qualityScore, ~digits=1))}
          </span>
        </div>
      </div>
    </div>

    <div
      className="w-8 flex flex-col items-center justify-center gap-0 border-l border-slate-50 bg-slate-50/50 group-hover:bg-slate-100 transition-colors self-stretch"
    >
      <Shadcn.DropdownMenu open_={isMenuOpen} onOpenChange={isOpen => setMenuOpen(_ => isOpen)}>
        <Shadcn.DropdownMenu.Trigger asChild=true>
          <button
            className="w-6 h-6 rounded flex items-center justify-center hover:bg-white hover:shadow-sm transition-all text-slate-400 hover:text-primary active:scale-90 focus-visible:ring-2 focus-visible:ring-primary focus-visible:outline-none"
            ariaLabel={`Actions for ${scene.name}`}
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
