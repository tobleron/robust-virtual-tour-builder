// @efficiency-role: state-hook

let useSidebarProcessing = () => {
  let fileInputRef = React.useRef(Nullable.null)

  let (procState, setProcState) = React.useState(_ => {
    "active": false,
    "progress": 0.0,
    "message": "",
    "phase": "",
    "error": false,
    "onCancel": () => (),
  })

  let appearanceTimerRef = React.useRef(Nullable.null)
  let hideTimerRef = React.useRef(Nullable.null)
  let isBarVisible = React.useRef(false)

  React.useEffect0(() => {
    let unsubscribe = EventBus.subscribe(event => {
      switch event {
      | TriggerUpload =>
        switch Nullable.toOption(fileInputRef.current) {
        | Some(el) => ReBindings.Dom.click(el)
        | None => ()
        }
      | UpdateProcessing(payload) => {
          let wantedActive = payload["active"]

          if wantedActive {
            // Cancel any pending hide
            switch Nullable.toOption(hideTimerRef.current) {
            | Some(timerId) =>
              ReBindings.Window.clearTimeout(timerId)
              hideTimerRef.current = Nullable.null
            | None => ()
            }

            if isBarVisible.current {
              // Already showing, just update
              setProcState(_ => payload)
            } else if Nullable.isNullable(appearanceTimerRef.current) {
              // Not showing, and no timer? Start appearance delay.
              let tid = ReBindings.Window.setTimeout(() => {
                setProcState(_ => payload)
                isBarVisible.current = true
                appearanceTimerRef.current = Nullable.null
              }, 1000)
              appearanceTimerRef.current = Nullable.fromOption(Some(tid))
            }
          } else {
            // Operation is finished (Inactive)

            // 1. Cancel any pending appearance
            switch Nullable.toOption(appearanceTimerRef.current) {
            | Some(tid) =>
              ReBindings.Window.clearTimeout(tid)
              appearanceTimerRef.current = Nullable.null
            | None => ()
            }

            // 2. Cancel any pending hide
            switch Nullable.toOption(hideTimerRef.current) {
            | Some(tid) =>
              ReBindings.Window.clearTimeout(tid)
              hideTimerRef.current = Nullable.null
            | None => ()
            }

            if payload["progress"] >= 100.0 && isBarVisible.current {
              // Done and visible: Victory Lap (Hold 1500ms)
              setProcState(_ => payload)
              let tid = ReBindings.Window.setTimeout(() => {
                setProcState(prev => {
                  let next = Object.assign(Object.make(), prev)
                  next["active"] = false
                  next
                })
                isBarVisible.current = false
                hideTimerRef.current = Nullable.null
              }, 1500)
              hideTimerRef.current = Nullable.fromOption(Some(tid))
            } else {
              // Error, Cancelled, or was never visible: Instant hide/stay hidden
              setProcState(_ => payload)
              isBarVisible.current = false
            }
          }
        }
      | _ => ()
      }
    })
    Some(unsubscribe)
  })

  (procState, fileInputRef)
}
