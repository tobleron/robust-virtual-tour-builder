// @efficiency: infra-adapter
open Vitest
open ReBindings
open Types

%%raw(`
  vi.mock('../../src/components/HotspotActionMenu.bs.js', () => ({
    make: () => {
        const React = require('react');
        return React.createElement('div', { 'data-testid': 'hotspot-action-menu' }, 'Mock Menu')
    }
  }));
`)

describe("HotspotMenuLayer", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  let defaultHotspot: hotspot = {
    linkId: "hs1",
    yaw: 0.0,
    pitch: 0.0,
    target: "s2",
    targetSceneId: None,
    targetYaw: None,
    targetPitch: None,
    targetHfov: None,
    startYaw: None,
    startPitch: None,
    startHfov: None,
    viewFrame: None,
    waypoints: None,
    displayPitch: None,
    transition: None,
    duration: None,
    isAutoForward: None,
    sequenceOrder: None,
  }

  testAsync("should open popover when OpenHotspotMenu event is dispatched", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <HotspotMenuLayer />)

    await wait(50)

    let anchor = Dom.createElement("div")
    EventBus.dispatch(
      OpenHotspotMenu({
        "anchor": anchor,
        "hotspot": defaultHotspot,
        "index": 0,
      }),
    )

    await wait(50)

    let menu = Dom.querySelector(Dom.documentBody, "[data-testid='hotspot-action-menu']")
    t->expect(Nullable.toOption(menu)->Belt.Option.isSome)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
