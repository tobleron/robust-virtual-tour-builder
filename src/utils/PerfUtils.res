let useRenderBudget = (componentName: string) => {
  let count = React.useRef(0)
  let lastTime = React.useRef(Date.now())

  let _ = %raw("React.useEffect")(() => {
    count.current = count.current + 1
    let now = Date.now()
    let elapsed = now -. lastTime.current

    if elapsed >= 1000.0 {
      let rps = count.current->Belt.Int.toFloat /. (elapsed /. 1000.0)
      if rps > 15.0 {
        Logger.debug(
          ~module_="Perf",
          ~message="RENDER_BUDGET_EXCEEDED: " ++ componentName,
          ~data=Some({"rps": rps, "component": componentName}),
          (),
        )
      }
      count.current = 0
      lastTime.current = now
    }
    None
  })
}
