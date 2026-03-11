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

  testAsync("keeps the home scene label on scene one after a wrap-back hotspot", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let sceneA = {
      ...defaultScene,
      id: "s1",
      name: "Scene 1",
      label: "Entry",
      hotspots: [
        {
          linkId: "hAB",
          yaw: 0.0,
          pitch: 0.0,
          target: "s2",
          targetSceneId: Some("s2"),
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
        },
      ],
    }
    let sceneB = {
      ...defaultScene,
      id: "s2",
      name: "Scene 2",
      label: "Hall",
      hotspots: [
        {
          linkId: "hBC",
          yaw: 0.0,
          pitch: 0.0,
          target: "s3",
          targetSceneId: Some("s3"),
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
        },
      ],
    }
    let sceneC = {
      ...defaultScene,
      id: "s3",
      name: "Scene 3",
      label: "Bedroom",
      hotspots: [
        {
          linkId: "hCA",
          yaw: 0.0,
          pitch: 0.0,
          target: "s1",
          targetSceneId: Some("s1"),
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
        },
      ],
    }

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <PersistentLabel activeIndex=0 scenes={[sceneA, sceneB, sceneC]} />)

    await wait(50)

    let labelEl = Dom.getElementById("v-scene-persistent-label")
    switch Nullable.toOption(labelEl) {
    | Some(el) =>
      let labelText = Dom.getTextContent(el)
      t->expect(labelText->String.includes("# 1"))->Expect.toBe(true)
      t->expect(labelText->String.includes("Entry"))->Expect.toBe(true)
    | None => t->expect(false)->Expect.toBe(true)
    }

    Dom.removeElement(container)
  })
})
