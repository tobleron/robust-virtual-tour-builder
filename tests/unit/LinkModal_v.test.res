// @efficiency: infra-adapter
open Vitest
open Types

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
    }
  }

  test("showLinkModal should dispatch ShowModal with correct content", t => {
    // Setup State
    let scene1 = createScene("Scene1")
    let scene2 = createScene("Scene2")
    let initialState: state = {
      ...State.initialState,
      scenes: [scene1, scene2],
      activeIndex: 0,
      tourName: "Test Tour",
    }
    GlobalStateBridge.setState(initialState)

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

    LinkModal.showLinkModal(~pitch=10.0, ~yaw=20.0, ~camPitch=0.0, ~camYaw=0.0, ~camHfov=90.0, ())
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
    let initialState: state = {
      ...State.initialState,
      scenes: [scene1, scene2],
      activeIndex: 0,
    }
    GlobalStateBridge.setState(initialState)

    // Capture Dispatch
    let dispatchedActions = ref([])
    GlobalStateBridge.setDispatch(
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

    LinkModal.showLinkModal(~pitch=10.0, ~yaw=20.0, ~camPitch=0.0, ~camYaw=0.0, ~camHfov=90.0, ())
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

          let found = Belt.Array.getBy(
            dispatchedActions.contents,
            a => {
              switch a {
              | AddHotspot(_, _) => true
              | _ => false
              }
            },
          )

          switch found {
          | Some(AddHotspot(index, hotspot)) => {
              t->expect(index)->Expect.toBe(0)
              t->expect(hotspot.target)->Expect.toBe("Scene2")
              t->expect(hotspot.pitch)->Expect.toBe(10.0)
              t->expect(hotspot.yaw)->Expect.toBe(20.0)
            }
          | _ => t->expect(false)->Expect.toBe(true)
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

  test("should handle return link and waypoints from linkDraft", t => {
    let scene1 = createScene("Scene1")
    let scene2 = createScene("Scene2")
    let initialState: state = {
      ...State.initialState,
      scenes: [scene1, scene2],
      activeIndex: 0,
    }
    GlobalStateBridge.setState(initialState)

    let dispatchedActions = ref([])
    GlobalStateBridge.setDispatch(action => Array.push(dispatchedActions.contents, action))

    let receivedConfig = ref(None)
    let unsubscribe = EventBus.subscribe(
      evt => {
        switch evt {
        | ShowModal(config) => receivedConfig := Some(config)
        | _ => ()
        }
      },
    )

    let draft: linkDraft = {
      pitch: 0.0,
      yaw: 0.0,
      camPitch: 5.0,
      camYaw: 15.0,
      camHfov: 80.0,
      intermediatePoints: Some([
        {pitch: 0.0, yaw: 0.0, camPitch: 1.0, camYaw: 2.0, camHfov: 90.0, intermediatePoints: None},
        {pitch: 0.0, yaw: 0.0, camPitch: 3.0, camYaw: 4.0, camHfov: 85.0, intermediatePoints: None},
      ]),
    }

    LinkModal.showLinkModal(
      ~pitch=10.0,
      ~yaw=20.0,
      ~camPitch=0.0,
      ~camYaw=0.0,
      ~camHfov=90.0,
      ~pendingReturnSceneName=Nullable.make("Scene1"),
      ~linkDraft=Nullable.make(draft),
      (),
    )
    unsubscribe()

    // Mock DOM select
    let _ = %raw(`(function(){
      const select = document.createElement("select");
      select.id = "link-target";
      const option = document.createElement("option");
      option.value = "Scene1";
      option.selected = true;
      select.appendChild(option);
      document.body.appendChild(select);
      select.value = "Scene1";
    })()`)

    switch receivedConfig.contents {
    | Some(config) =>
      switch Belt.Array.get(config.buttons, 0) {
      | Some(saveBtn) =>
        saveBtn.onClick()

        let found = Belt.Array.getBy(
          dispatchedActions.contents,
          a => {
            switch a {
            | AddHotspot(_, _) => true
            | _ => false
            }
          },
        )

        switch found {
        | Some(AddHotspot(_, hotspot)) => {
            t->expect(hotspot.isReturnLink)->Expect.toBe(Some(true))
            // Should use draft values for start*
            t->expect(hotspot.startPitch)->Expect.toBe(Some(5.0))
            t->expect(hotspot.startYaw)->Expect.toBe(Some(15.0))
            t->expect(hotspot.startHfov)->Expect.toBe(Some(80.0))
            // Waypoints should be mapped
            switch hotspot.waypoints {
            | Some(w) => t->expect(Array.length(w))->Expect.toBe(2)
            | None => t->expect(false)->Expect.toBe(true)
            }
          }
        | _ => t->expect(false)->Expect.toBe(true)
        }
      | None => ()
      }
    | None => ()
    }

    let _ = %raw(`(function(){ document.body.innerHTML = "" })()`)
  })
})
