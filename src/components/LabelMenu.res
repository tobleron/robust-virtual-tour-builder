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

      Dom.add(m, "opacity-0")
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
      }, 2400))
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

      let left = if rect.right +. 360.0 > Belt.Int.toFloat(Window.innerWidth) {
        let l = rect.left -. 350.0
        if l < 10.0 {
          10.0
        } else {
          l
        }
      } else {
        rect.right +. 12.0
      }

      Dom.setTop(m, Float.toString(top) ++ "px")
      Dom.setLeft(m, Float.toString(left) ++ "px")

      Dom.remove(m, "hidden")

      let _ = Window.setTimeout(() => {
        Dom.remove(m, "opacity-0")
        Dom.add(m, "opacity-100")
        Logger.debug(~module_="LabelMenu", ~message="MENU_OPEN", ())
      }, 10)
    } else {
      closeLabelMenu()
    }
  | None => ()
  }
}

let syncLabelMenu = (label: string, category: string) => {
  let labelPills = JsHelpers.from(Dom.querySelectorAllDoc(".label-pill"))
  let labelSections = JsHelpers.from(Dom.querySelectorAllDoc(".label-section"))
  let inp = Dom.getElementById("v-scene-label-custom")

  let currentLabel = label
  let currentCategory = category

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
      Dom.add(pill, "state-active")
    } else {
      Dom.remove(pill, "state-active")
    }
  })

  // Update Input
  switch Nullable.toOption(inp) {
  | Some(i) => Dom.setValue(i, currentLabel)
  | None => ()
  }
}

let createLabelMenu = (_viewerStage: Dom.element, _labelButton: Dom.element) => {
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
    "hidden fixed flex flex-col gap-0 z-[9999] transition-all duration-300 ease-out opacity-0 overflow-hidden label-menu-container",
  )
  Dom.setPosition(lblMenu, "fixed")
  Dom.setMargin(lblMenu, "0")
  Dom.setStyleWidth(lblMenu, "95%")
  Dom.setMaxWidth(lblMenu, "280px")
  Dom.setPadding(lblMenu, "0")
  Dom.setOverflow(lblMenu, "hidden")

  // Scroll Fade
  let scrollFade = Dom.createElement("div")
  Dom.setClassName(
    scrollFade,
    "scroll-indicator-bottom absolute bottom-[64px] left-0 right-0 h-[40px] pointer-events-none z-10 transition-opacity duration-300 opacity-0",
  )
  Dom.appendChild(lblMenu, scrollFade)

  // Presets Wrapper
  let presetsWrapper = Dom.createElement("div")
  Dom.setId(presetsWrapper, "label-presets-scroll")
  Dom.setClassName(presetsWrapper, "flex-1 flex flex-col gap-0 overflow-y-auto relative py-1")
  Dom.setMaxHeight(presetsWrapper, "400px")

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
    Dom.setClassName(header, "label-section-header")
    Dom.setInnerHTML(
      header,
      "<span class=\"label-section-title\">" ++
      category ++ "</span><div class=\"label-section-divider\"></div>",
    )
    Dom.appendChild(section, header)

    let grid = Dom.createElement("div")
    Dom.setClassName(grid, "flex flex-col gap-0.5 px-1.5")

    Belt.Array.forEach(labels, label => {
      let chip = Dom.createElement("button")
      Dom.setClassName(
        chip,
        "label-pill focus-visible:ring-2 focus-visible:ring-remax-blue focus-visible:outline-none",
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
  Dom.setClassName(customSection, "label-custom-section sticky bottom-0 z-20")

  let customTitle = Dom.createElement("div")
  Dom.setClassName(customTitle, "label-custom-title")
  Dom.setTextContent(customTitle, "Custom Label Entry")
  Dom.appendChild(customSection, customTitle)

  let inputWrapper = Dom.createElement("div")
  Dom.setClassName(inputWrapper, "label-custom-input-wrapper")

  let inp = Dom.createElement("input")
  Dom.setId(inp, "v-scene-label-custom")
  Dom.setAttribute(inp, "type", "text")
  Dom.setAttribute(inp, "placeholder", "Enter custom name...")
  Dom.setClassName(inp, "label-custom-input")
  Dom.setOnClick(inp, e => Dom.stopPropagation(e))

  let setBtn = Dom.createElement("button")
  Dom.setInnerHTML(setBtn, "SET")
  Dom.setClassName(
    setBtn,
    "label-btn-set shrink-0 active:scale-95 focus-visible:ring-2 focus-visible:ring-primary focus-visible:outline-none",
  )
  Dom.setAttribute(setBtn, "aria-label", "Apply custom label")

  let clearBtn = Dom.createElement("button")
  Dom.setInnerHTML(clearBtn, "CLEAR")
  Dom.setClassName(
    clearBtn,
    "label-btn-clear shrink-0 active:scale-95 focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:outline-none",
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

  lblMenu
}
