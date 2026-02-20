// @efficiency-role: ui-component

external makeStyle: {..} => ReactDOM.Style.t = "%identity"

module Logic = {
  let getThumbUrl = (scene: Types.scene) => {
    switch scene.tinyFile {
    | Some(tiny) =>
      let url = SceneCache.getThumbUrl(scene.id ++ "_tiny", tiny)
      if url == "" {
        SceneCache.getThumbUrl(scene.id, scene.file)
      } else {
        url
      }
    | None => SceneCache.getThumbUrl(scene.id, scene.file)
    }
  }
}

@react.component
let make = React.memo((
  ~scene: Types.scene,
  ~index,
  ~isActive,
  ~onItemClick: int => unit,
  ~onItemDragStart: (int, JsxEvent.Mouse.t) => unit,
  ~onItemDragOver: (int, JsxEvent.Mouse.t) => unit,
  ~onItemDrop: (int, JsxEvent.Mouse.t) => unit,
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

  let thumbUrl = React.useMemo1(() => Logic.getThumbUrl(scene), [scene])

  let (isMenuOpen, setMenuOpen) = React.useState(_ => false)
  let (flickerState, setFlickerState) = React.useState(_ => #None)
  React.useEffect1(() => {
    if wasThrottled {
      setFlickerState(_ => #Throttled)
      let timeoutId = ReBindings.Window.setTimeout(
        () => {
          setFlickerState(_ => #None)
        },
        600,
      )
      Some(
        () => {
          ReBindings.Window.clearTimeout(timeoutId)
        },
      )
    } else {
      None
    }
  }, [wasThrottled])

  let handleClearClick = e => {
    JsxEvent.Mouse.preventDefault(e)
    setFlickerState(_ => #Clear)
    let _ = ReBindings.Window.setTimeout(() => {
      setFlickerState(_ => #None)
      setMenuOpen(_ => false)
      onItemClearLinks(index)
    }, 800)
  }

  let handleDeleteClick = e => {
    JsxEvent.Mouse.preventDefault(e)
    setFlickerState(_ => #Delete)
    let _ = ReBindings.Window.setTimeout(() => {
      setFlickerState(_ => #None)
      setMenuOpen(_ => false)
      onItemDelete(index)
    }, 800)
  }

  let activeClasses = if isActive {
    "active border-slate-200 ring-0 bg-slate-50/50"
  } else {
    "border-slate-100 hover:border-slate-200 bg-white"
  }

  let qualityScore = switch scene.quality {
  | Some(q) =>
    switch JsonCombinators.Json.decode(q, JsonParsers.Shared.qualityAnalysis) {
    | Ok(qObj) => qObj.score
    | Error(_) => 10.0
    }
  | None => 10.0
  }
  let isLowQuality = qualityScore < 6.5
  let qualityColor = if isLowQuality {
    "bg-danger"
  } else {
    "bg-success"
  }
  let progressPercent = {
    let raw = qualityScore *. 10.0
    if raw < 0.0 {
      0.0
    } else if raw > 100.0 {
      100.0
    } else {
      raw
    }
  }

  let groupColorClass = ColorPalette.getGroupClass(scene.colorGroup)

  let throttleClasses = switch flickerState {
  | #Throttled => "ring-2 ring-primary/40 opacity-80 cursor-wait"
  | _ => ""
  }
  let isBusy = flickerState == #Throttled
  let fallbackSceneFileName = switch scene.file {
  | Url(url) => UrlUtils.getFileNameFromUrl(url)
  | _ => ""
  }

  let tooltipNameCandidate = switch scene.originalFile {
  | Some(File(f)) => BrowserBindings.File.name(f)
  | Some(Url(url)) =>
    let name = UrlUtils.getFileNameFromUrl(url)
    if name != "" {
      name
    } else {
      fallbackSceneFileName
    }
  | _ => fallbackSceneFileName
  }

  let tooltipName = if tooltipNameCandidate == "" {
    if fallbackSceneFileName == "" {
      scene.name
    } else {
      fallbackSceneFileName
    }
  } else {
    tooltipNameCandidate
  }

  <div
    key={scene.id}
    className={`scene-item group relative flex items-center border rounded-lg mb-2 overflow-hidden transition-all duration-200 select-none touch-pan-y active-push h-16 focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 focus-visible:outline-none ${activeClasses} ${throttleClasses}`}
    draggable=true
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
            className="w-full h-full object-cover transition-all duration-700 group-hover:scale-110 opacity-100 group-hover:brightness-[1.3]"
            loading=#lazy
          />
        } else {
          React.null
        }}
        <div className="absolute inset-0 bg-transparent" />

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

    <Tooltip content={tooltipName} delayDuration=Constants.tooltipDelayDuration>
      <div className="flex-1 min-w-0 py-1.5 px-2 flex flex-col justify-center cursor-pointer">
        <div className="flex items-center justify-between gap-2 overflow-hidden">
          <h4
            className={`text-[12px] font-medium truncate tracking-tight ${if isActive {
                "text-primary"
              } else {
                "text-slate-700"
              }}`}
          >
            {React.string(UrlUtils.stripExtension(scene.name))}
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
            let (format, size) = switch scene.file {
            | Url(url) =>
              let cleanUrl = UrlUtils.stripQueryAndFragment(url)
              let pieces = cleanUrl->String.split(".")
              let ext = pieces->Belt.Array.get(Belt.Array.length(pieces) - 1)->Option.getOr("JPG")
              (ext->String.toUpperCase, 0.0)
            | Blob(b) =>
              let mime = BrowserBindings.Blob.type_(b)
              let ext = mime->String.split("/")->Belt.Array.get(1)->Option.getOr("JPG")
              (ext->String.toUpperCase, BrowserBindings.Blob.size(b))
            | File(f) =>
              let mime = BrowserBindings.File.type_(f)
              let ext = mime->String.split("/")->Belt.Array.get(1)->Option.getOr("JPG")
              (ext->String.toUpperCase, BrowserBindings.File.size(f))
            }

            let (badgeColor, formatLabel) = switch format {
            | "WEBP" => ("text-orange-600 bg-orange-50", "WEBP")
            | "PNG" => ("text-indigo-600 bg-indigo-50", "PNG")
            | "JPEG" | "JPG" => ("text-blue-600 bg-blue-50", "JPG")
            | f => ("text-slate-600 bg-slate-50", f)
            }

            let formattedSize = if size > 0.0 {
              let mb = size /. (1024.0 *. 1024.0)
              if mb >= 1.0 {
                Float.toFixed(mb, ~digits=1) ++ "MB"
              } else {
                let kb = size /. 1024.0
                Float.toFixed(kb, ~digits=0) ++ "KB"
              }
            } else {
              ""
            }

            <div className="flex items-center gap-1.5 shrink-0">
              <span
                className={`px-1 py-0.5 rounded-[3px] text-[8px] font-bold tracking-tight border border-current/10 ${badgeColor}`}
              >
                {React.string(formatLabel)}
              </span>
              {if formattedSize != "" {
                <span className="text-[9px] font-medium text-slate-400">
                  {React.string(formattedSize)}
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
                className={`h-full transition-all duration-1000 ease-out rounded-full ${qualityColor}`}
                style={makeStyle({"width": Float.toString(progressPercent) ++ "%"})}
              />
            </div>
            <span
              className={`absolute -top-4 text-[9px] font-bold uppercase tracking-wider whitespace-nowrap pointer-events-none ${if (
                  isLowQuality
                ) {
                  "text-danger"
                } else {
                  "text-slate-400"
                }}`}
              style={makeStyle({
                "left": Float.toString(progressPercent) ++ "%",
                "transform": "translateX(-50%)",
              })}
            >
              {React.string(Float.toFixed(qualityScore, ~digits=1))}
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
