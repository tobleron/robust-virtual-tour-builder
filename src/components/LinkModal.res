/* src/components/LinkModal.res */

open Types
open ReBindings
open! EventBus

// Constants

// Helper to escape HTML
let escapeHtml = unsafe => {
  unsafe
  ->String.replaceRegExp(/&/g, "&amp;")
  ->String.replaceRegExp(/</g, "&lt;")
  ->String.replaceRegExp(/>/g, "&gt;")
  ->String.replaceRegExp(/\"/g, "&quot;")
  ->String.replaceRegExp(/'/g, "&#039;")
}

let showLinkModal = (
  ~pitch: float,
  ~yaw: float,
  ~camPitch: float,
  ~camYaw: float,
  ~camHfov: float,
  ~pendingReturnSceneName: Nullable.t<string>=Nullable.null,
  ~linkDraft: Nullable.t<Types.linkDraft>=Nullable.null,
  (),
) => {
  let state = GlobalStateBridge.getState()

  // Determine next sequential index for smart selection
  let nextIndex = state.activeIndex + 1

  let scenes = state.scenes
  let sceneOptions =
    scenes
    ->Belt.Array.mapWithIndex((i, s) => {
      let safeName = escapeHtml(s.name)

      // Auto-select logic
      let isSelected = switch (
        Nullable.toOption(pendingReturnSceneName),
        Nullable.toOption(linkDraft),
      ) {
      | (Some(name), _) => s.name == name
      // Fix: Allow default selection (next index) even if linkDraft exists
      | (None, _) => i == nextIndex
      }

      if i == state.activeIndex {
        ""
      } else {
        let selectedStr = if isSelected {
          "selected"
        } else {
          ""
        }
        let style = "background: #1e293b;"
        `<option value="${safeName}" ${selectedStr} style="${style}">${safeName}</option>`
      }
    })
    ->Js.Array.joinWith("", _)

  let contentHtml = `
        <label for="link-target" class="sr-only">Select destination room</label>
        <select 
          id="link-target" 
          style="width: 100%; height: 44px; padding: 0 36px 0 12px; margin-bottom: 16px; background-color: rgba(0,0,0,0.3); border: 1px solid rgba(255,255,255,0.15); border-radius: 10px; color: white; font-weight: 600; font-size: 13px; outline: none; cursor: pointer; appearance: none; background-image: url('data:image/svg+xml,%3Csvg fill%3D%22%23ffffff%22 height%3D%2224%22 viewBox%3D%220 0 24 24%22 width%3D%2224%22 xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%3E%3Cpath d%3D%22M7 10l5 5 5-5z%22%2F%3E%3C%2Fsvg%3E'); background-repeat: no-repeat; background-position: right 10px center; background-size: 20px;"
          aria-label="Select destination room for navigation link"
        >
            <option value="" style="background: #1e293b;">-- Select Room --</option>
            ${sceneOptions}
        </select>
  `

  let onSave = () => {
    let element = Dom.getElementById("link-target")
    switch Nullable.toOption(element) {
    | Some(el) =>
      let targetName = Dom.getValue(el)
      if targetName == "" {
        EventBus.dispatch(ShowNotification("Please select a destination room", #Warning))
      } else {
        // Check for existing link to same target
        let currentScene = Belt.Array.get(state.scenes, state.activeIndex)
        let exists = switch currentScene {
        | Some(scene) => Belt.Array.some(scene.hotspots, h => h.target == targetName)
        | None => false
        }

        if exists {
          EventBus.dispatch(ShowNotification("A link to this room already exists here!", #Warning))
        } else {
          let isReturnLink = Belt.Option.isSome(Nullable.toOption(pendingReturnSceneName))
          let displayPitch = pitch -. Constants.hotspotVisualOffsetDegrees

          let draftOpt = Nullable.toOption(linkDraft)
          let startPitch = switch draftOpt {
          | Some(d) => d.camPitch
          | None => camPitch
          }
          let startYaw = switch draftOpt {
          | Some(d) => d.camYaw
          | None => camYaw
          }
          let startHfov = switch draftOpt {
          | Some(d) => d.camHfov
          | None => camHfov
          }

          // Generate unique Link ID
          let allLinkIds = state.scenes->Belt.Array.reduce([], (acc, s) => {
            Belt.Array.concat(acc, s.hotspots->Belt.Array.map(h => h.linkId))
          })
          let usedSet = Belt.Set.String.fromArray(allLinkIds)
          let newLinkId = TourLogic.generateLinkId(usedSet)

          // Handle types for Nullable fields
          let newHotspot: Types.hotspot = {
            linkId: newLinkId,
            yaw,
            pitch,
            target: targetName,
            targetYaw: None,
            targetPitch: None,
            targetHfov: None,
            startYaw: Some(startYaw),
            startPitch: Some(startPitch),
            startHfov: Some(startHfov),
            isReturnLink: Some(isReturnLink),
            viewFrame: Some({yaw: camYaw, pitch: camPitch, hfov: camHfov}),
            returnViewFrame: if isReturnLink {
              Some({yaw: camYaw, pitch: camPitch, hfov: camHfov})
            } else {
              None
            },
            waypoints: switch draftOpt {
            | Some(d) =>
              switch d.intermediatePoints {
              | Some(points) =>
                let mapped = points->Belt.Array.map(p => {
                  let vf: Types.viewFrame = {
                    yaw: p.camYaw,
                    pitch: p.camPitch,
                    hfov: p.camHfov,
                  }
                  vf
                })
                Some(mapped)
              | None => None
              }
            | None => None
            },
            displayPitch: Some(displayPitch),
            transition: None,
            duration: None,
          }

          GlobalStateBridge.dispatch(AddHotspot(state.activeIndex, newHotspot))
          GlobalStateBridge.dispatch(Actions.StopLinking)
          EventBus.dispatch(CloseModal)
        }
      }
    | None => ()
    }
  }

  EventBus.dispatch(
    ShowModal({
      title: "Link Destination",
      description: Some("Saving current view as \"Target\""),
      icon: Some("add_link"),
      contentHtml: Some(contentHtml),
      allowClose: Some(true),
      onClose: Some(
        () => {
          GlobalStateBridge.dispatch(Actions.StopLinking)
        },
      ),
      buttons: [
        {
          label: "Save Link",
          class_: "btn-blue",
          onClick: onSave,
          autoClose: Some(false),
        },
        {
          label: "Cancel",
          class_: "btn-secondary",
          onClick: () => {EventBus.dispatch(CloseModal)},
          autoClose: Some(false),
        },
      ],
    }),
  )

  let _ = setTimeout(() => {
    switch Nullable.toOption(Dom.getElementById("link-target")) {
    | Some(el) => Dom.focus(el)
    | None => ()
    }
  }, 300)
}
