/* src/components/LabelMenu.res */

open Types
open ReBindings

let labelMenuTimeout = ref(None)

let closeLabelMenu = () => {
  let menu = Dom.getElementById("v-scene-label-menu")
  switch Nullable.toOption(menu) {
  | Some(m) =>
    if !Dom.contains(m, "hidden") {
      switch labelMenuTimeout.contents {
      | Some(id) =>
        Window.clearTimeout(id)
        labelMenuTimeout := None
      | None => ()
      }

      Dom.add(m, "scale-95")
      Dom.add(m, "opacity-0")
      Dom.remove(m, "scale-100")
      Dom.remove(m, "opacity-100")

      let _ = Window.setTimeout(() => {
        Dom.add(m, "hidden")
        Logger.debug(~module_="LabelMenu", ~message="MENU_CLOSE", ())
      }, 300)
    }
  | None => ()
  }
}

let scheduleMenuClose = () => {
  switch labelMenuTimeout.contents {
  | Some(id) => Window.clearTimeout(id)
  | None => ()
  }

  labelMenuTimeout := Some(Window.setTimeout(() => {
        closeLabelMenu()
        labelMenuTimeout := None
      }, 1900))
}

let toggleLabelMenu = (labelButton: Dom.element) => {
  let menu = Dom.getElementById("v-scene-label-menu")
  switch Nullable.toOption(menu) {
  | Some(m) =>
    // Clear pending auto-close
    switch labelMenuTimeout.contents {
    | Some(id) =>
      Window.clearTimeout(id)
      labelMenuTimeout := None
    | None => ()
    }

    let isHidden = Dom.contains(m, "hidden")

    if isHidden {
      let rect = Dom.getBoundingClientRect(labelButton)
      let menuHeight = 500.0
      let spaceBelow = Belt.Int.toFloat(Window.innerHeight) -. rect.top

      Dom.setPointerEvents(m, "auto")
      let top = if spaceBelow < menuHeight {
        Math.max(20.0, rect.bottom -. menuHeight)
      } else {
        rect.top
      }

      Dom.setTop(m, Float.toString(top) ++ "px")
      Dom.setLeft(m, Float.toString(rect.right +. 12.0) ++ "px")

      Dom.remove(m, "hidden")

      let _ = Window.setTimeout(() => {
        Dom.remove(m, "scale-95")
        Dom.remove(m, "opacity-0")
        Dom.add(m, "scale-100")
        Dom.add(m, "opacity-100")
        Logger.debug(~module_="LabelMenu", ~message="MENU_OPEN", ())
      }, 10)
    } else {
      closeLabelMenu()
    }
  | None => ()
  }
}

let syncLabelMenu = (scene: Types.scene) => {
  let labelPills = JsHelpers.from(Dom.querySelectorAllDoc(".label-pill"))
  let labelSections = JsHelpers.from(Dom.querySelectorAllDoc(".label-section"))
  let inp = Dom.getElementById("v-scene-label-custom")

  let currentLabel = scene.label
  let currentCategory = scene.category

  // Filter Sections
  Belt.Array.forEach(labelSections, section => {
    let cat = Dict.get(Dom.dataset(section), "category")
    if cat == Some(currentCategory) {
      Dom.setDisplay(section, "flex")
    } else {
      Dom.setDisplay(section, "none")
    }
  })

  // Update Pills
  Belt.Array.forEach(labelPills, pill => {
    let val = Dict.get(Dom.dataset(pill), "val")
    let isActive = val == Some(currentLabel)
    if isActive {
      Dom.add(pill, "bg-remax-blue")
      Dom.add(pill, "text-white")
      Dom.add(pill, "border-remax-blue")
      Dom.remove(pill, "bg-slate-50")
      Dom.remove(pill, "text-slate-600")
      Dom.remove(pill, "border-slate-100")
    } else {
      Dom.remove(pill, "bg-remax-blue")
      Dom.remove(pill, "text-white")
      Dom.remove(pill, "border-remax-blue")
      Dom.add(pill, "bg-slate-50")
      Dom.add(pill, "text-slate-600")
      Dom.add(pill, "border-slate-100")
    }
  })

  // Update Input
  switch Nullable.toOption(inp) {
  | Some(i) => Dom.setValue(i, currentLabel)
  | None => ()
  }
}

let createLabelMenu = (_viewerStage: Dom.element, labelButton: Dom.element) => {
  // Remove existing
  let existing = Dom.getElementById("v-scene-label-menu")
  switch Nullable.toOption(existing) {
  | Some(e) => Dom.removeElement(e)
  | None => ()
  }

  let lblMenu = Dom.createElement("div")
  Dom.setId(lblMenu, "v-scene-label-menu")

  Dom.setClassName(
    lblMenu,
    "hidden fixed flex flex-col gap-4 z-[9999] pointer-events-auto transition-all duration-300 ease-out scale-95 opacity-0 overflow-hidden modal-box",
  )
  Dom.setPosition(lblMenu, "fixed")
  Dom.setMargin(lblMenu, "0")
  Dom.setStyleWidth(lblMenu, "95%")
  Dom.setMaxWidth(lblMenu, "360px")
  Dom.setPadding(lblMenu, "24px")
  Dom.setOverflow(lblMenu, "hidden")

  // Cross-browser scrollbar nuclear option
  let styleEl = Dom.createElement("style")
  Dom.setTextContent(
    styleEl,
    "
    #v-scene-label-menu ::-webkit-scrollbar { width: 4px; }
    #v-scene-label-menu ::-webkit-scrollbar-track { background: transparent; }
    #v-scene-label-menu ::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 10px; }
    #v-scene-label-menu ::-webkit-scrollbar-thumb:hover { background: #cbd5e1; }
    .scroll-indicator-bottom {
      content: \"\"; position: absolute; bottom: 84px; left: 24px; right: 24px; height: 30px;
      background: linear-gradient(to top, rgba(255,255,255,0.95), transparent);
      pointer-events: none; z-index: 10; transition: opacity 0.3s;
    }
  ",
  )
  Dom.appendChild(lblMenu, styleEl)

  // Scroll Fade
  let scrollFade = Dom.createElement("div")
  Dom.setClassName(scrollFade, "scroll-indicator-bottom")
  Dom.appendChild(lblMenu, scrollFade)

  // Presets Wrapper
  let presetsWrapper = Dom.createElement("div")
  Dom.setId(presetsWrapper, "label-presets-scroll")
  Dom.setClassName(presetsWrapper, "flex-1 flex flex-col gap-4 overflow-y-auto pr-1 relative")
  Dom.setMaxHeight(presetsWrapper, "360px")

  Dom.setOnScroll(presetsWrapper, () => {
    let remaining =
      Dom.getScrollHeight(presetsWrapper) -
      Dom.getScrollTop(presetsWrapper) -
      Dom.getClientHeight(presetsWrapper)
    Dom.setOpacity(
      scrollFade,
      if remaining > 10 {
        "1"
      } else {
        "0"
      },
    )
  })

  // Categories
  let categories = Dict.toArray(Constants.roomLabelPresets)
  Belt.Array.forEach(categories, ((category, labels)) => {
    let section = Dom.createElement("div")
    Dom.setClassName(section, "label-section flex flex-col gap-2.5")
    Dict.set(Dom.dataset(section), "category", category)

    let header = Dom.createElement("div")
    Dom.setClassName(header, "flex items-center gap-2")
    Dom.setInnerHTML(
      header,
      "
      <span class=\"text-[9px] font-black text-slate-600 uppercase tracking-[2px]\">" ++
      category ++ "</span>
      <div class=\"h-[1px] flex-1 bg-slate-100\"></div>
    ",
    )
    Dom.appendChild(section, header)

    let grid = Dom.createElement("div")
    Dom.setClassName(grid, "grid grid-cols-2 gap-1.5")

    Belt.Array.forEach(labels, label => {
      let chip = Dom.createElement("button")
      Dom.setClassName(
        chip,
        "label-pill px-3 py-2 font-ui text-[10px] font-bold uppercase text-slate-600 bg-slate-50 border border-slate-100 rounded-lg cursor-pointer transition-all hover:bg-remax-blue hover:text-white hover:border-remax-blue hover:shadow-md active:scale-95 text-left focus-visible:ring-2 focus-visible:ring-remax-blue focus-visible:outline-none",
      )
      Dom.setTextContent(chip, label)
      Dom.setAttribute(chip, "aria-label", "Set label to " ++ label)
      Dict.set(Dom.dataset(chip), "val", label)
      Dict.set(Dom.dataset(chip), "category", category)

      Dom.setOnClick(
        chip,
        e => {
          Dom.stopPropagation(e)
          let state = GlobalStateBridge.getState()
          GlobalStateBridge.dispatch(
            UpdateSceneMetadata(state.activeIndex, Obj.magic({"label": label})),
          )
          Logger.info(~module_="LabelMenu", ~message="LABEL_SET", ~data=Some({"label": label}), ())
          EventBus.dispatch(ShowNotification("Label Set: " ++ label, #Success))
          scheduleMenuClose()
        },
      )
      Dom.appendChild(grid, chip)
    })

    Dom.appendChild(section, grid)
    Dom.appendChild(presetsWrapper, section)
  })

  Dom.appendChild(lblMenu, presetsWrapper)

  // Custom Section
  let customSection = Dom.createElement("div")
  Dom.setClassName(
    customSection,
    "flex flex-col gap-2 pt-4 mt-1 border-t border-slate-100 bg-white/50 backdrop-blur-sm sticky bottom-0",
  )
  Dom.setBackgroundColor(customSection, "white") // approximate sticky background

  let customTitle = Dom.createElement("div")
  Dom.setClassName(customTitle, "text-[9px] font-black text-slate-500 uppercase tracking-[1px]")
  Dom.setTextContent(customTitle, "Custom Label Entry")
  Dom.appendChild(customSection, customTitle)

  let inputWrapper = Dom.createElement("div")
  Dom.setClassName(inputWrapper, "flex gap-2 items-center")

  let inp = Dom.createElement("input")
  Dom.setId(inp, "v-scene-label-custom")
  Dom.setAttribute(inp, "type", "text")
  Dom.setAttribute(inp, "placeholder", "Enter custom name...")
  Dom.setClassName(
    inp,
    "flex-1 px-4 py-2 bg-slate-50 border border-slate-200 text-slate-700 rounded-xl text-xs font-bold outline-none focus:ring-4 focus:ring-remax-blue/5 focus:border-remax-blue placeholder:text-slate-400 transition-all focus-visible:ring-remax-blue",
  )
  Dom.setOnClick(inp, e => Dom.stopPropagation(e))

  let setBtn = Dom.createElement("button")
  Dom.setInnerHTML(setBtn, "SET")
  Dom.setClassName(
    setBtn,
    "shrink-0 px-3 py-2 text-white text-[10px] font-black rounded-xl transition-all active:scale-95 shadow-sm focus-visible:ring-2 focus-visible:ring-primary focus-visible:outline-none",
  )
  Dom.setBackgroundColor(setBtn, "#007BA7")
  Dom.setAttribute(setBtn, "aria-label", "Apply custom label")

  let clearBtn = Dom.createElement("button")
  Dom.setInnerHTML(clearBtn, "CLEAR")
  Dom.setClassName(
    clearBtn,
    "shrink-0 px-3 py-2 bg-slate-200 text-slate-600 text-[10px] font-black rounded-xl hover:bg-slate-300 transition-all active:scale-95 focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:outline-none",
  )
  Dom.setAttribute(clearBtn, "aria-label", "Clear current label")

  let applyCustom = () => {
    let val = Dom.getValue(inp)->String.trim
    if val != "" {
      let state = GlobalStateBridge.getState()
      GlobalStateBridge.dispatch(UpdateSceneMetadata(state.activeIndex, Obj.magic({"label": val})))
      Logger.info(~module_="LabelMenu", ~message="LABEL_SET_CUSTOM", ~data=Some({"label": val}), ())
      EventBus.dispatch(ShowNotification("Label Set: " ++ val, #Success))
      scheduleMenuClose()
    }
  }

  let clearLabel = () => {
    let state = GlobalStateBridge.getState()
    GlobalStateBridge.dispatch(UpdateSceneMetadata(state.activeIndex, Obj.magic({"label": ""})))
    Dom.setValue(inp, "")
    EventBus.dispatch(ShowNotification("Label Cleared", #Warning))
    scheduleMenuClose()
  }

  Dom.setOnClick(setBtn, e => {
    Dom.stopPropagation(e)
    applyCustom()
  })

  Dom.setOnClick(clearBtn, e => {
    Dom.stopPropagation(e)
    clearLabel()
  })

  Dom.setOnKeyDown(inp, e => {
    if Dom.key(e) == "Enter" {
      Dom.stopPropagation(e)
      applyCustom()
    }
  })

  Dom.appendChild(inputWrapper, inp)
  Dom.appendChild(inputWrapper, setBtn)
  Dom.appendChild(inputWrapper, clearBtn)
  Dom.appendChild(customSection, inputWrapper)
  Dom.appendChild(lblMenu, customSection)

  Dom.appendChild(Dom.documentBody, lblMenu)

  Dom.setOnClick(labelButton, e => {
    Dom.stopPropagation(e)
    toggleLabelMenu(labelButton)
  })

  Dom.addEventListener(Dom.documentBody, "click", e => {
    let target = Dom.target(e)
    let closestMenu = Dom.closest(target, "#v-scene-label-menu")
    let closestBtn = Dom.closest(target, "#v-scene-label-btn")

    if Nullable.make(closestMenu) == Nullable.null && Nullable.make(closestBtn) == Nullable.null {
      closeLabelMenu()
    }
  })

  lblMenu
}
