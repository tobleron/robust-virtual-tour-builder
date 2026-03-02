open ReBindings
open EventBus

// Helper for styles
external makeStyle: {..} => ReactDOM.Style.t = "%identity"

module ElementExt = {
  @send external closest: (Dom.element, string) => Nullable.t<Dom.element> = "closest"
}

module Logic = {
  let handleFocusTrap = (e: Dom.event, modal: Dom.element) => {
    let focusables = Dom.querySelectorAll(
      modal,
      "button, input, select, textarea, [tabindex]:not([tabindex=\"-1\"])",
    )
    let focusablesArray = JsHelpers.from(focusables)
    switch (
      Belt.Array.get(focusablesArray, 0),
      Belt.Array.get(focusablesArray, Array.length(focusablesArray) - 1),
    ) {
    | (Some(first), Some(last)) =>
      let isShift = Dom.shiftKey(e)
      if isShift {
        if Dom.document["activeElement"] === first {
          Dom.preventDefault(e)
          Dom.focus(last)
        }
      } else if Dom.document["activeElement"] === last {
        Dom.preventDefault(e)
        Dom.focus(first)
      }
    | _ => ()
    }
  }
}

let useIsModalOpen = () => {
  let (isOpen, setIsOpen) = React.useState(_ => false)

  React.useEffect0(() => {
    let unsubscribe = EventBus.subscribe(event => {
      switch event {
      | ShowModal(_) => setIsOpen(_ => true)
      | CloseModal => setIsOpen(_ => false)
      | _ => ()
      }
    })
    Some(unsubscribe)
  })

  isOpen
}

@react.component
let make = () => {
  let (activeConfig, setActiveConfig) = React.useState(_ => None)

  React.useEffect0(() => {
    let unsubscribe = EventBus.subscribe(event => {
      switch event {
      | ShowModal(config) => setActiveConfig(_ => Some(config))
      | CloseModal =>
        setActiveConfig(
          prev => {
            prev->Option.forEach(
              config => {
                config.onClose->Option.forEach(cb => cb())
              },
            )
            None
          },
        )
      | _ => ()
      }
    })
    Some(unsubscribe)
  })

  // Escape key handler & Focus Trap
  React.useEffect1(() => {
    let handleKey = (e: Dom.event) => {
      let key = Dom.key(e)
      if key == "Escape" {
        switch activeConfig {
        | Some(config) =>
          if Belt.Option.getWithDefault(config.allowClose, true) {
            EventBus.dispatch(CloseModal)
          }
        | None => ()
        }
      }

      // Enter key support
      if activeConfig != None && key == "Enter" {
        switch activeConfig {
        | Some(config) =>
          switch Belt.Array.get(config.buttons, 0) {
          | Some(primaryBtn) =>
            Dom.preventDefault(e)
            primaryBtn.onClick()
            if Belt.Option.getWithDefault(primaryBtn.autoClose, true) {
              EventBus.dispatch(CloseModal)
            }
          | None => ()
          }
        | None => ()
        }
      }

      // Focus Trap logic
      if activeConfig != None && key == "Tab" {
        let modalEl = Dom.getElementById("modal-title")
        switch Nullable.toOption(modalEl) {
        | Some(el) =>
          let root = ElementExt.closest(el, ".modal-box-premium")
          switch Nullable.toOption(root) {
          | Some(modal) => Logic.handleFocusTrap(e, modal)
          | None => ()
          }
        | None => ()
        }
      }
    }
    let _ = Window.addEventListener("keydown", handleKey)

    // Initial focus
    if activeConfig != None {
      let _ = Window.setTimeout(() => {
        let modalEl = Dom.getElementById("modal-title")
        switch Nullable.toOption(modalEl) {
        | Some(el) =>
          let root = ElementExt.closest(el, ".modal-box-premium")
          switch Nullable.toOption(root) {
          | Some(modal) =>
            let focusables = Dom.querySelectorAll(
              modal,
              "button, [tabindex]:not([tabindex=\"-1\"])",
            )
            let focusablesArray = JsHelpers.from(focusables)
            switch Belt.Array.get(focusablesArray, 0) {
            | Some(first) => Dom.focus(first)
            | None => Dom.focus(el)
            }
          | None => ()
          }
        | None => ()
        }
      }, 50)
    }

    Some(() => Window.removeEventListener("keydown", handleKey))
  }, [activeConfig])

  // Portal logic removed.
  switch activeConfig {
  | Some(config) =>
    <div className="modal-overlay">
      <div
        className={`modal-box-premium ${config.className->Option.getOr("")}`}
        role="dialog"
        ariaModal=true
        ariaLabelledby="modal-title"
      >
        // Icon
        {switch config.icon {
        | Some(icon) =>
          <div className="modal-icon-container">
            {switch icon {
            | "success" | "check_circle" =>
              <LucideIcons.CircleCheck className="modal-icon text-success" size=40 />
            | "error" | "error_outline" =>
              <LucideIcons.CircleAlert className="modal-icon text-danger" size=40 />
            | "warning" | "warning_amber" =>
              <LucideIcons.TriangleAlert className="modal-icon text-warning" size=40 />
            | "link" | "add_link" =>
              <LucideIcons.Link className="modal-icon text-primary" size=40 />
            | "info" | "info_outline" | _ =>
              <LucideIcons.Info className="modal-icon text-primary" size=40 />
            }}
          </div>
        | None => React.null
        }}
        // Title
        <h3 id="modal-title" className="modal-title-custom"> {React.string(config.title)} </h3>
        // Description
        {switch config.description {
        | Some(desc) => <p className="modal-description-custom"> {React.string(desc)} </p>
        | None => React.null
        }}
        // Content
        {switch config.content {
        | Some(element) => <div className="modal-content-body"> element </div>
        | None => React.null
        }}
        // Buttons
        <div className="modal-actions">
          {config.buttons
          ->Belt.Array.mapWithIndex((i, btn) => {
            <button
              key={Belt.Int.toString(i)}
              className={`modal-btn-premium modal-btn-full ${btn.class_}`}
              onClick={_ => {
                btn.onClick()
                if Belt.Option.getWithDefault(btn.autoClose, true) {
                  EventBus.dispatch(CloseModal)
                }
              }}
            >
              <span> {React.string(btn.label)} </span>
            </button>
          })
          ->React.array}
        </div>
      </div>
    </div>
  | None => React.null
  }
}
