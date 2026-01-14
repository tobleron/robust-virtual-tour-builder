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
      let spaceBelow = Belt.Int.toFloat(Obj.magic(Window.window)["innerHeight"]) -. rect.top

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
  let doc = Obj.magic(Window.window)["document"]
  let labelPills: array<Dom.element> = Obj.magic(doc["querySelectorAll"](".label-pill"))
  let labelSections: array<Dom.element> = Obj.magic(doc["querySelectorAll"](".label-section"))
  let inp = Dom.getElementById("v-scene-label-custom")

  let currentLabel = scene.label
  let currentCategory = scene.category

  // Filter Sections
  Belt.Array.forEach(labelSections, section => {
    let s: {..} = Obj.magic(section)
    if s["dataset"]["category"] == currentCategory {
      Dom.setDisplay(section, "flex")
    } else {
      Dom.setDisplay(section, "none")
    }
  })

  // Update Pills
  Belt.Array.forEach(labelPills, pill => {
    let p: {..} = Obj.magic(pill)
    let isActive = p["dataset"]["val"] == currentLabel
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
  | Some(i) => (Obj.magic(i): {..})["value"] = currentLabel
  | None => ()
  }
}

let createLabelMenu = (_viewerStage: Dom.element, labelButton: Dom.element) => {
  // Remove existing
  let existing = Dom.getElementById("v-scene-label-menu")
  switch Nullable.toOption(existing) {
  | Some(e) => (Obj.magic(e): {..})["remove"]()
  | None => ()
  }

  let lblMenu = Dom.createElement("div")
  Dom.setId(lblMenu, "v-scene-label-menu")

  let _ = (
    Obj.magic(lblMenu): {..}
  )["className"] = "hidden fixed flex flex-col gap-4 z-[9999] pointer-events-auto transition-all duration-300 ease-out scale-95 opacity-0 overflow-hidden modal-box"
  Dom.setPosition(lblMenu, "fixed")
  Dom.setMargin(lblMenu, "0")
  Dom.setStyleWidth(lblMenu, "95%")
  Dom.setMaxWidth(lblMenu, "360px")
  Dom.setPadding(lblMenu, "24px")
  Dom.setOverflow(lblMenu, "hidden")

  // Cross-browser scrollbar nuclear option
  let styleEl = Dom.createElement("style")
  let _ = (Obj.magic(styleEl): {..})["textContent"] = "
    #v-scene-label-menu ::-webkit-scrollbar { width: 4px; }
    #v-scene-label-menu ::-webkit-scrollbar-track { background: transparent; }
    #v-scene-label-menu ::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 10px; }
    #v-scene-label-menu ::-webkit-scrollbar-thumb:hover { background: #cbd5e1; }
    .scroll-indicator-bottom {
      content: \"\"; position: absolute; bottom: 84px; left: 24px; right: 24px; height: 30px;
      background: linear-gradient(to top, rgba(255,255,255,0.95), transparent);
      pointer-events: none; z-index: 10; transition: opacity 0.3s;
    }
  "
  Dom.appendChild(lblMenu, styleEl)

  // Scroll Fade
  let scrollFade = Dom.createElement("div")
  let _ = (Obj.magic(scrollFade): {..})["className"] = "scroll-indicator-bottom"
  Dom.appendChild(lblMenu, scrollFade)

  // Presets Wrapper
  let presetsWrapper = Dom.createElement("div")
  Dom.setId(presetsWrapper, "label-presets-scroll")
  let _ = (
    Obj.magic(presetsWrapper): {..}
  )["className"] = "flex-1 flex flex-col gap-4 overflow-y-auto pr-1 relative"
  Dom.setMaxHeight(presetsWrapper, "360px")

  let _ = (Obj.magic(presetsWrapper): {..})["onscroll"] = () => {
    let p = (Obj.magic(presetsWrapper): {..})
    let remaining = p["scrollHeight"] - p["scrollTop"] - p["clientHeight"]
    Dom.setOpacity(
      scrollFade,
      if remaining > 10 {
        "1"
      } else {
        "0"
      },
    )
  }

  // Categories
  let categories = Dict.toArray(Constants.roomLabelPresets)
  Belt.Array.forEach(categories, ((category, labels)) => {
    let section = Dom.createElement("div")
    let _ = (Obj.magic(section): {..})["className"] = "label-section flex flex-col gap-2.5"
    let _ = (Obj.magic(section): {..})["dataset"]["category"] = category

    let header = Dom.createElement("div")
    let _ = (Obj.magic(header): {..})["className"] = "flex items-center gap-2"
    Dom.setInnerHTML(
      header,
      "
      <span class=\"text-[9px] font-black text-slate-400 uppercase tracking-[2px]\">" ++
      category ++ "</span>
      <div class=\"h-[1px] flex-1 bg-slate-100\"></div>
    ",
    )
    Dom.appendChild(section, header)

    let grid = Dom.createElement("div")
    let _ = (Obj.magic(grid): {..})["className"] = "grid grid-cols-2 gap-1.5"

    Belt.Array.forEach(labels, label => {
      let chip = Dom.createElement("button")
      let _ = (
        Obj.magic(chip): {..}
      )["className"] = "label-pill px-3 py-2 font-ui text-[10px] font-bold uppercase text-slate-600 bg-slate-50 border border-slate-100 rounded-lg cursor-pointer transition-all hover:bg-remax-blue hover:text-white hover:border-remax-blue hover:shadow-md active:scale-95 text-left"
      let _ = (Obj.magic(chip): {..})["textContent"] = label
      let _ = (Obj.magic(chip): {..})["dataset"]["val"] = label
      let _ = (Obj.magic(chip): {..})["dataset"]["category"] = category

      let _ = (Obj.magic(chip): {..})["onclick"] = e => {
        (e: {..})["stopPropagation"]()
        let state = GlobalStateBridge.getState()
        GlobalStateBridge.dispatch(
          UpdateSceneMetadata(state.activeIndex, Obj.magic({"label": label})),
        )
        Logger.info(~module_="LabelMenu", ~message="LABEL_SET", ~data=Some({"label": label}), ())
        EventBus.dispatch(ShowNotification("Label Set: " ++ label, #Success))
        scheduleMenuClose()
      }
      Dom.appendChild(grid, chip)
    })

    Dom.appendChild(section, grid)
    Dom.appendChild(presetsWrapper, section)
  })

  Dom.appendChild(lblMenu, presetsWrapper)

  // Custom Section
  let customSection = Dom.createElement("div")
  let _ = (
    Obj.magic(customSection): {..}
  )["className"] = "flex flex-col gap-2 pt-4 mt-1 border-t border-slate-100 bg-white/50 backdrop-blur-sm sticky bottom-0"
  Dom.setBackgroundColor(customSection, "white") // approximate sticky background

  let customTitle = Dom.createElement("div")
  let _ = (
    Obj.magic(customTitle): {..}
  )["className"] = "text-[9px] font-black text-slate-300 uppercase tracking-[1px]"
  let _ = (Obj.magic(customTitle): {..})["textContent"] = "Custom Label Entry"
  Dom.appendChild(customSection, customTitle)

  let inputWrapper = Dom.createElement("div")
  let _ = (Obj.magic(inputWrapper): {..})["className"] = "flex gap-2 items-center"

  let inp = Dom.createElement("input")
  Dom.setId(inp, "v-scene-label-custom")
  let _ = (Obj.magic(inp): {..})["type"] = "text"
  let _ = (Obj.magic(inp): {..})["placeholder"] = "Enter custom name..."
  let _ = (
    Obj.magic(inp): {..}
  )["className"] = "flex-1 px-4 py-2 bg-slate-50 border border-slate-200 text-slate-700 rounded-xl text-xs font-bold outline-none focus:ring-4 focus:ring-remax-blue/5 focus:border-remax-blue placeholder:text-slate-300 transition-all"
  let _ = (Obj.magic(inp): {..})["onclick"] = e => (e: {..})["stopPropagation"]()

  let setBtn = Dom.createElement("button")
  Dom.setInnerHTML(setBtn, "SET")
  let _ = (
    Obj.magic(setBtn): {..}
  )["className"] = "shrink-0 px-3 py-2 text-white text-[10px] font-black rounded-xl transition-all active:scale-95 shadow-sm"
  Dom.setBackgroundColor(setBtn, "#007BA7")

  let clearBtn = Dom.createElement("button")
  Dom.setInnerHTML(clearBtn, "CLEAR")
  let _ = (
    Obj.magic(clearBtn): {..}
  )["className"] = "shrink-0 px-3 py-2 bg-slate-200 text-slate-600 text-[10px] font-black rounded-xl hover:bg-slate-300 transition-all active:scale-95"

  let applyCustom = () => {
    let val = (Obj.magic(inp): {..})["value"]->String.trim
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
    let _ = (Obj.magic(inp): {..})["value"] = ""
    EventBus.dispatch(ShowNotification("Label Cleared", #Warning))
    scheduleMenuClose()
  }

  let _ = (Obj.magic(setBtn): {..})["onclick"] = e => {
    (e: {..})["stopPropagation"]()
    applyCustom()
  }

  let _ = (Obj.magic(clearBtn): {..})["onclick"] = e => {
    (e: {..})["stopPropagation"]()
    clearLabel()
  }

  let _ = (Obj.magic(inp): {..})["onkeydown"] = e => {
    if (e: {..})["key"] == "Enter" {
      (e: {..})["stopPropagation"]()
      applyCustom()
    }
  }

  Dom.appendChild(inputWrapper, inp)
  Dom.appendChild(inputWrapper, setBtn)
  Dom.appendChild(inputWrapper, clearBtn)
  Dom.appendChild(customSection, inputWrapper)
  Dom.appendChild(lblMenu, customSection)

  Dom.appendChild(Dom.documentBody, lblMenu)

  let _ = (Obj.magic(labelButton): {..})["onclick"] = e => {
    (e: {..})["stopPropagation"]()
    toggleLabelMenu(labelButton)
  }

  let _ = (Obj.magic(Window.window)["document"]: {..})["addEventListener"]("click", e => {
    let target = (e: {..})["target"]
    let closestMenu = (target: {..})["closest"]("#v-scene-label-menu")
    let closestBtn = (target: {..})["closest"]("#v-scene-label-btn")

    if Nullable.make(closestMenu) == Nullable.null && Nullable.make(closestBtn) == Nullable.null {
      closeLabelMenu()
    }
  })

  lblMenu
}
