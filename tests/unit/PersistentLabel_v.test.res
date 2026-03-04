// @efficiency: infra-adapter
open Vitest
open ReBindings
open Types

describe("PersistentLabel", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  let defaultScene: scene = {
    id: "s1",
    name: "Scene 1",
    label: "Living Room",
    file: Url("test.webp"),
    tinyFile: None,
    originalFile: None,
    hotspots: [],
    category: "indoor",
    floor: "ground",
    quality: None,
    colorGroup: None,
    categorySet: false,
    labelSet: false,
    _metadataSource: "user",
    isAutoForward: false,
    sequenceId: 0,
  }

  testAsync("should render sequence badge and label", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let scenes = [defaultScene]

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <PersistentLabel activeIndex=0 scenes />)

    await wait(50)

    let labelEl = Dom.getElementById("v-scene-persistent-label")
    switch Nullable.toOption(labelEl) {
    | Some(el) =>
      let labelText = Dom.getTextContent(el)
      t->expect(labelText->String.includes("# 1"))->Expect.toBe(true)
      t->expect(labelText->String.includes(defaultScene.label))->Expect.toBe(true)
      t->expect(Dom.classList(el)->Dom.ClassList.contains("state-visible"))->Expect.toBe(true)
    | None => t->expect(false)->Expect.toBe(true)
    }

    Dom.removeElement(container)
  })

  testAsync("should default to unlabeled and be hidden if label is empty", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let unlabeledScene = {...defaultScene, label: ""}
    let scenes = [unlabeledScene]

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <PersistentLabel activeIndex=0 scenes />)

    await wait(50)

    let labelEl = Dom.getElementById("v-scene-persistent-label")
    switch Nullable.toOption(labelEl) {
    | Some(el) =>
      t->expect(Dom.getTextContent(el)->String.includes("unlabeled"))->Expect.toBe(true)
      t->expect(Dom.classList(el)->Dom.ClassList.contains("state-hidden"))->Expect.toBe(true)
    | None => t->expect(false)->Expect.toBe(true)
    }

    Dom.removeElement(container)
  })
})
