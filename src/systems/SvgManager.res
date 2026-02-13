/* src/systems/SvgManager.res - Consolidated SVG System */

open ReBindings

// --- CONSTANTS ---

let containerId = "viewer-hotspot-lines"
let namespace = Svg.namespace

// --- CACHE & STATE ---

type cache = {
  elementMap: dict<Dom.element>,
  lastContainer: option<Dom.element>,
}

let globalCache = ref({
  elementMap: Dict.make(),
  lastContainer: None,
})

// --- CORE MANAGER ---

let getContainer = () => Dom.getElementById(containerId)

let syncContainer = () => {
  let current = getContainer()->Nullable.toOption
  switch (current, globalCache.contents.lastContainer) {
  | (Some(curr), Some(last)) if curr !== last =>
    globalCache := {elementMap: Dict.make(), lastContainer: Some(curr)}
  | (Some(curr), None) => globalCache := {...globalCache.contents, lastContainer: Some(curr)}
  | _ => ()
  }
  current
}

let clearAll = () => {
  switch syncContainer() {
  | Some(svg) =>
    Dom.setTextContent(svg, "")
    globalCache := {elementMap: Dict.make(), lastContainer: globalCache.contents.lastContainer}
  | None => ()
  }
}

let getElement = (id: string) => {
  let _ = syncContainer()
  switch Dict.get(globalCache.contents.elementMap, id) {
  | Some(el) =>
    switch globalCache.contents.lastContainer {
    | Some(container) if Dom.containsElement(container, el) => Some(el)
    | _ =>
      Dict.delete(globalCache.contents.elementMap, id)
      None
    }
  | None =>
    globalCache.contents.lastContainer->Option.flatMap(svg => {
      Dom.querySelector(svg, "#" ++ id)
      ->Nullable.toOption
      ->Option.map(found => {
        Dict.set(globalCache.contents.elementMap, id, found)
        found
      })
    })
  }
}

let create = (id: string, tag: string) => {
  syncContainer()->Option.map(svg => {
    let el = Svg.createElementNS(namespace, tag)
    Svg.setAttribute(el, "id", id)
    Svg.appendChild(svg, el)
    Dict.set(globalCache.contents.elementMap, id, el)
    el
  })
}

let getOrCreate = (id: string, tag: string) => {
  switch getElement(id) {
  | Some(el) => Some(el)
  | None => create(id, tag)
  }
}

let hide = (id: string) => {
  getElement(id)->Option.forEach(el => Dom.setProperty(el, "display", "none"))
}
let show = (id: string, ~tag="path") => {
  getOrCreate(id, tag)->Option.forEach(el => Dom.setProperty(el, "display", "block"))
}
let remove = (id: string) => {
  getElement(id)->Option.forEach(el => {
    Dom.removeElement(el)
    Dict.delete(globalCache.contents.elementMap, id)
  })
}

// --- RENDERER ---

module Renderer = {
  let updateLine = (id, x1, y1, x2, y2, color, width, opacity, ~dashArray=?, ~className=?, ()) => {
    switch getOrCreate(id, "line") {
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
    points: array<Types.screenCoords>,
    color,
    width,
    opacity,
    ~dashArray=?,
    ~className=?,
    (),
  ) => {
    let len = Array.length(points)
    if len >= 2 {
      let cmds = []
      let first = ref(true)
      points->Belt.Array.forEach(coords => {
        let _ = Array.push(
          cmds,
          if first.contents {
            first := false
            "M"
          } else {
            "L"
          },
        )
        let _ = Array.push(cmds, Float.toString(Math.round(coords.x *. 10.0) /. 10.0))
        let _ = Array.push(cmds, Float.toString(Math.round(coords.y *. 10.0) /. 10.0))
      })
      let dString = Array.join(cmds, " ")
      if dString != "" {
        switch getOrCreate(id, "path") {
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
        hide(id)
      }
    } else {
      hide(id)
    }
  }

  let drawArrow = (id, x, y, angle, color, opacity) => {
    if Float.isFinite(x) && Float.isFinite(y) && Float.isFinite(angle) {
      switch getOrCreate(id, "path") {
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
        Svg.setAttribute(arrow, "cursor", "pointer")
        Svg.setAttribute(arrow, "pointer-events", "auto")
        if opacity < 1.0 {
          Svg.setAttribute(arrow, "opacity", Float.toString(opacity))
        } else {
          Dom.removeAttribute(arrow, "opacity")
        }
      | None => ()
      }
    } else {
      hide(id)
    }
  }

  let hide = hide
}
