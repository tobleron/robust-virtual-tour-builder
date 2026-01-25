/* src/systems/SvgRenderer.res */
open ReBindings
open HotspotLineTypes

let updateLine = (id, x1, y1, x2, y2, color, width, opacity, ~dashArray=?, ~className=?, ()) => {
  switch SvgManager.getOrCreate(id, "line") {
  | Some(line) =>
    Svg.setAttribute(line, "x1", Float.toString(x1))
    Svg.setAttribute(line, "y1", Float.toString(y1))
    Svg.setAttribute(line, "x2", Float.toString(x2))
    Svg.setAttribute(line, "y2", Float.toString(y2))
    Svg.setAttribute(line, "stroke", color)
    Svg.setAttribute(line, "stroke-width", Float.toString(width))
    Svg.setAttribute(line, "stroke-opacity", Float.toString(opacity))
    Dom.setProperty(line, "display", "block")

    switch dashArray {
    | Some(d) => Svg.setAttribute(line, "stroke-dasharray", d)
    | None => Dom.removeAttribute(line, "stroke-dasharray")
    }

    switch className {
    | Some(c) => Svg.setAttribute(line, "class", c)
    | None => Dom.removeAttribute(line, "class")
    }
  | None => ()
  }
}

let drawPolyLine = (
  id,
  points: array<screenCoords>,
  color,
  width,
  opacity,
  ~dashArray=?,
  ~className=?,
  (),
) => {
  let len = Array.length(points)
  if len >= 2 {
    let pathCommands = []
    let first = ref(true)

    for i in 0 to len - 1 {
      switch Belt.Array.get(points, i) {
      | Some(coords) =>
        let prefix = if first.contents {
          first := false
          "M"
        } else {
          "L"
        }
        let _ = Array.push(pathCommands, prefix)
        let _ = Array.push(pathCommands, Float.toString(Math.round(coords.x *. 10.0) /. 10.0))
        let _ = Array.push(pathCommands, Float.toString(Math.round(coords.y *. 10.0) /. 10.0))
      | None => ()
      }
    }

    let dString = Array.join(pathCommands, " ")

    if dString != "" {
      switch SvgManager.getOrCreate(id, "path") {
      | Some(pathEl) =>
        Svg.setAttribute(pathEl, "d", dString)
        Svg.setAttribute(pathEl, "stroke", color)
        Svg.setAttribute(pathEl, "stroke-width", Float.toString(width))
        Svg.setAttribute(pathEl, "stroke-opacity", Float.toString(opacity))
        Svg.setAttribute(pathEl, "fill", "none")
        Svg.setAttribute(pathEl, "stroke-linecap", "round")
        Svg.setAttribute(pathEl, "stroke-linejoin", "round")
        Dom.setProperty(pathEl, "display", "block")

        switch dashArray {
        | Some(da) => Svg.setAttribute(pathEl, "stroke-dasharray", da)
        | None => Dom.removeAttribute(pathEl, "stroke-dasharray")
        }

        switch className {
        | Some(c) => Svg.setAttribute(pathEl, "class", c)
        | None => Dom.removeAttribute(pathEl, "class")
        }
      | None => ()
      }
    } else {
      SvgManager.hide(id)
    }
  } else {
    SvgManager.hide(id)
  }
}

let drawArrow = (id, x, y, angle, color, opacity) => {
  if Float.isFinite(x) && Float.isFinite(y) && Float.isFinite(angle) {
    switch SvgManager.getOrCreate(id, "path") {
    | Some(arrow) =>
      Svg.setAttribute(arrow, "d", "M -10,-7 L 6,0 L -10,7 Z")
      Svg.setAttribute(arrow, "fill", color)
      Svg.setAttribute(arrow, "stroke", "#000")
      Svg.setAttribute(arrow, "stroke-width", "1")
      Svg.setAttribute(
        arrow,
        "transform",
        "translate(" ++
        Float.toString(x) ++
        ", " ++
        Float.toString(y) ++
        ") rotate(" ++
        Float.toString(angle) ++ ")",
      )
      Dom.setProperty(arrow, "display", "block")

      if opacity < 1.0 {
        Svg.setAttribute(arrow, "opacity", Float.toString(opacity))
      } else {
        Dom.removeAttribute(arrow, "opacity")
      }
    | None => ()
    }
  } else {
    SvgManager.hide(id)
  }
}

let hide = id => SvgManager.hide(id)
