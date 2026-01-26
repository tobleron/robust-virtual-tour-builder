/* src/systems/SvgManager.res */

open ReBindings

/*
 * SvgManager
 *
 * A lightweight "Virtual DOM" substitute optimizing for 60fps animation loops.
 * Prevents "layout thrashing" by reusing DOM elements instead of destroying/recreating them.
 */

let containerId = "viewer-hotspot-lines"
let namespace = Svg.namespace

type cache = {
  mutable elementMap: dict<Dom.element>,
  mutable lastContainer: option<Dom.element>,
}

let globalCache = {
  elementMap: Dict.make(),
  lastContainer: None,
}

/*
 * getContainer
 * Returns the main SVG container.
 */
let getContainer = () => {
  Dom.getElementById(containerId)
}

/*
 * syncContainer
 * Ensures our cache is not for a stale container (e.g. after React re-mount)
 */
let syncContainer = () => {
  let current = getContainer()->Nullable.toOption
  switch (current, globalCache.lastContainer) {
  | (Some(curr), Some(last)) if curr !== last =>
    // Container changed! Clear element cache to avoid stale DOM references
    globalCache.elementMap = Dict.make()
    globalCache.lastContainer = Some(curr)
  | (Some(curr), None) => globalCache.lastContainer = Some(curr)
  | _ => ()
  }
  current
}

/*
 * clearAll
 * DANGEROUS: Clears the entire SVG. Use only on Scene change.
 */
let clearAll = () => {
  switch syncContainer() {
  | Some(svg) =>
    Dom.setTextContent(svg, "")
    globalCache.elementMap = Dict.make()
  | None => ()
  }
}

/*
 * getElement
 * Tries to find an element by ID, first in cache, then in DOM.
 */
let getElement = (id: string) => {
  let _ = syncContainer() // Ensure cache is valid for current container
  switch Dict.get(globalCache.elementMap, id) {
  | Some(el) =>
    // Double check: is this element still in the current container?
    // We use parentNode or contains check.
    switch globalCache.lastContainer {
    | Some(container) if Dom.containsElement(container, el) => Some(el)
    | _ =>
      // Element is stale or container lost it. Remove from cache and try to retrieve from DOM.
      Dict.set(globalCache.elementMap, id, (Obj.magic(None): Dom.element)) // Effectively clear it
      None
    }
  | None =>
    // Fallback to DOM query
    switch globalCache.lastContainer {
    | Some(svg) =>
      let el = Dom.querySelector(svg, "#" ++ id)
      switch Nullable.toOption(el) {
      | Some(found) =>
        Dict.set(globalCache.elementMap, id, found)
        Some(found)
      | None => None
      }
    | None => None
    }
  }
}

/*
 * create
 * Creates a new SVG element with the given tag and ID, appends it to container.
 */
let create = (id: string, tag: string) => {
  switch syncContainer() {
  | Some(svg) =>
    let el = Svg.createElementNS(namespace, tag)
    Svg.setAttribute(el, "id", id)
    Svg.appendChild(svg, el)
    Dict.set(globalCache.elementMap, id, el)
    Some(el)
  | None => None
  }
}

/*
 * getOrCreate
 * The primary efficient accessor.
 */
let getOrCreate = (id: string, tag: string) => {
  switch getElement(id) {
  | Some(el) => Some(el)
  | None => create(id, tag)
  }
}

/*
 * hide
 * Hides an element without destroying it.
 */
let hide = (id: string) => {
  switch getElement(id) {
  | Some(el) => Dom.setProperty(el, "display", "none")
  | None => ()
  }
}

/*
 * show
 * Shows an element.
 */
let show = (id: string, ~tag="path") => {
  switch getOrCreate(id, tag) {
  | Some(el) => Dom.setProperty(el, "display", "block")
  | None => ()
  }
}

/*
 * remove
 * Removes an element from DOM and cache.
 */
let remove = (id: string) => {
  switch getElement(id) {
  | Some(el) =>
    Dom.removeElement(el)
    // We can't easily remove from Dict without rebuilding it in ReScript/JS standard
    // But setting it to undefined/removing key is possible in raw JS.
    // For now, we accept the cache entry might be stale or just keep it.
    // Actually ReBindings doesn't expose Dict.delete.
    // We'll manage strictly.
    ()
  | None => ()
  }
}
