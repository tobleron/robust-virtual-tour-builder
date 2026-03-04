// @efficiency: infra-adapter
open Vitest
open Types
open Actions

describe("LinkModal", () => {
  // Helper to create a dummy scene
  let createScene = (name): scene => {
    {
      id: "id_" ++ name,
      name,
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "test",
      floor: "1",
      label: "label",
      quality: None,
      colorGroup: None,
      _metadataSource: "manual",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
      sequenceId: 0,
    }
  }

  test("showLinkModal should dispatch ShowModal with correct content", t => {
    // Setup State
    let scene1 = createScene("Scene1")
    let scene2 = createScene("Scene2")
    let initialState = TestUtils.createMockState(~scenes=[scene1, scene2], ~activeIndex=0, ())
    AppStateBridge.updateState(initialState)

    // Capture EventBus
    let receivedConfig = ref(None)
    let unsubscribe = EventBus.subscribe(
      evt => {
        switch evt {
        | ShowModal(config) => receivedConfig := Some(config)
        | _ => ()
        }
      },
    )

    LinkModal.showLinkModal(
      ~pitch=10.0,
      ~yaw=20.0,
      ~camPitch=0.0,
      ~camYaw=0.0,
      ~camHfov=90.0,
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
      (),
    )
    unsubscribe()

    switch receivedConfig.contents {
    | Some(config) => {
        t->expect(config.title)->Expect.toBe("Link Destination")
        // Verify buttons
        t->expect(Array.length(config.buttons))->Expect.toBe(2)
        switch Belt.Array.get(config.buttons, 0) {
        | Some(btn) => t->expect(btn.label)->Expect.toBe("Save Link")
        | None => t->expect(false)->Expect.toBe(true)
        }
      }
    | None => t->expect(false)->Expect.toBe(true)
    }
  })

  test("Save button should dispatch AddHotspot", t => {
    // Setup State
    let scene1 = createScene("Scene1")
    let scene2 = createScene("Scene2")
    let initialState = TestUtils.createMockState(~scenes=[scene1, scene2], ~activeIndex=0, ())
    AppStateBridge.updateState(initialState)

    // Capture Dispatch
    let dispatchedActions = ref([])
    AppStateBridge.registerDispatch(
      action => {
        Array.push(dispatchedActions.contents, action)
      },
    )

    // Capture EventBus
    let receivedConfig = ref(None)
    let unsubscribe = EventBus.subscribe(
      evt => {
        switch evt {
        | ShowModal(config) => receivedConfig := Some(config)
        | _ => ()
        }
      },
    )

    LinkModal.showLinkModal(
      ~pitch=10.0,
      ~yaw=20.0,
      ~camPitch=0.0,
      ~camYaw=0.0,
      ~camHfov=90.0,
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
      (),
    )
    unsubscribe()

    // Setup Mock DOM
    let _ = %raw(`(function(){
      const select = document.createElement("select");
      select.id = "link-target";
      const option = document.createElement("option");
      option.value = "Scene2";
      option.selected = true;
      select.appendChild(option);
      document.body.appendChild(select);
      select.value = "Scene2"; 
    })()`)

    switch receivedConfig.contents {
    | Some(config) =>
      switch Belt.Array.get(config.buttons, 0) {
      | Some(saveBtn) =>
        if saveBtn.label == "Save Link" {
          saveBtn.onClick()

          let isFound = Belt.Array.some(
            dispatchedActions.contents,
            a => {
              switch a {
              | AddToTimeline(_) => true
              | AddHotspot(_, _) => true
              | _ => false
              }
            },
          )

          if isFound {
            t->expect(true)->Expect.toBe(true)
          } else {
            t->expect(false)->Expect.toBe(true)
          }
        } else {
          t->expect(false)->Expect.toBe(true)
        }
      | None => t->expect(false)->Expect.toBe(true)
      }
    | None => t->expect(false)->Expect.toBe(true)
    }

    // Cleanup DOM
    let _ = %raw(`(function(){ document.body.innerHTML = "" })()`)
  })

  test("Retarget modal save should dispatch sequence reorder updates when sequence is changed", t => {
    let h1: hotspot = {
      linkId: "A01",
      yaw: 0.0,
      pitch: 0.0,
      target: "Scene2",
      targetSceneId: Some("id_Scene2"),
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
    let h2: hotspot = {
      ...h1,
      linkId: "A02",
      target: "Scene3",
      targetSceneId: Some("id_Scene3"),
    }

    let scene1 = {...createScene("Scene1"), hotspots: [h1, h2]}
    let scene2 = createScene("Scene2")
    let scene3 = createScene("Scene3")

    let initialState = TestUtils.createMockState(~scenes=[scene1, scene2, scene3], ~activeIndex=0, ())
    AppStateBridge.updateState(initialState)

    let dispatchedActions = ref([])
    AppStateBridge.registerDispatch(action => Array.push(dispatchedActions.contents, action))

    let receivedConfig = ref(None)
    let unsubscribe = EventBus.subscribe(evt => {
      switch evt {
      | ShowModal(config) => receivedConfig := Some(config)
      | _ => ()
      }
    })

    let draft: linkDraft = {
      pitch: 0.0,
      yaw: 0.0,
      camPitch: 0.0,
      camYaw: 0.0,
      camHfov: 90.0,
      intermediatePoints: None,
      retargetHotspot: Some({
        sceneIndex: 0,
        hotspotIndex: 0,
        sceneId: Some(scene1.id),
        hotspotLinkId: Some("A01"),
      }),
    }

    LinkModal.showLinkModal(
      ~pitch=0.0,
      ~yaw=0.0,
      ~camPitch=0.0,
      ~camYaw=0.0,
      ~camHfov=90.0,
      ~linkDraft=Nullable.make(draft),
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
      (),
    )
    unsubscribe()

    let _ = %raw(`(function(){
      const select = document.createElement("select");
      select.id = "link-target";
      const option = document.createElement("option");
      option.value = "Scene2";
      option.selected = true;
      select.appendChild(option);
      document.body.appendChild(select);
      select.value = "Scene2";

      const seqInput = document.createElement("input");
      seqInput.id = "link-sequence-order";
      seqInput.value = "2";
      document.body.appendChild(seqInput);
    })()`)

    switch receivedConfig.contents {
    | Some(config) =>
      switch Belt.Array.get(config.buttons, 0) {
      | Some(saveBtn) =>
        if saveBtn.label == "Save Link" {
          saveBtn.onClick()

          let hasReorderBatch = dispatchedActions.contents->Belt.Array.some(action =>
            switch action {
            | Batch(actions) =>
              actions->Belt.Array.some(inner =>
                switch inner {
                | UpdateHotspotMetadata(_, _, _) => true
                | _ => false
                }
              )
            | _ => false
            }
          )

          t->expect(hasReorderBatch)->Expect.toBe(true)
        } else {
          t->expect(false)->Expect.toBe(true)
        }
      | None => t->expect(false)->Expect.toBe(true)
      }
    | None => t->expect(false)->Expect.toBe(true)
    }

    let _ = %raw(`(function(){ document.body.innerHTML = "" })()`)
  })
})
