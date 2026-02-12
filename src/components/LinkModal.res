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
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
  (),
) => {
  let state = getState()

  // Determine next sequential index for smart selection
  let nextIndex = state.activeIndex + 1
  let scenes = state.scenes

  let defaultTargetName =
    scenes
    ->Belt.Array.getIndexBy(s => {
      let isSelected = switch (
        Nullable.toOption(pendingReturnSceneName),
        Nullable.toOption(linkDraft),
      ) {
      | (Some(name), _) => s.name == name
      | (None, _) =>
        let idx = scenes->Belt.Array.getIndexBy(x => x.name == s.name)->Option.getOr(-1)
        idx == nextIndex
      }
      isSelected
    })
    ->Belt.Option.flatMap(idx => scenes->Belt.Array.get(idx))
    ->Belt.Option.map(s => s.name)
    ->Belt.Option.getWithDefault("")

  let content =
    <div className="flex flex-col gap-4">
      <label htmlFor="link-target" className="sr-only">
        {React.string("Select destination room")}
      </label>
      <select
        id="link-target"
        className="w-full h-11 px-9 pl-3 mb-4 bg-black/30 border border-white/15 rounded-lg text-white font-semibold text-[13px] outline-none cursor-pointer appearance-none bg-[url('data:image/svg+xml,%3Csvg%20fill%3D%22%23ffffff%22%20height%3D%2224%22%20viewBox%3D%220%200%2024%2024%22%20width%3D%2224%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%3E%3Cpath%20d%3D%22M7%2010l5%205%205-5z%22%2F%3E%3C%2Fsvg%3E')] bg-no-repeat bg-[right_10px_center] bg-[length:20px]"
        ariaLabel="Select destination room for navigation link"
        defaultValue={defaultTargetName}
      >
        <option value="" className="bg-slate-800"> {React.string("-- Select Room --")} </option>
        {scenes
        ->Belt.Array.mapWithIndex((i, s) => {
          if i == state.activeIndex {
            React.null
          } else {
            <option key={s.name} value={s.name} className="bg-slate-800">
              {React.string(s.name)}
            </option>
          }
        })
        ->React.array}
      </select>
    </div>

  let onSave = () => {
    let element = Dom.getElementById("link-target")
    switch Nullable.toOption(element) {
    | Some(el) =>
      let targetName = Dom.getValue(el)
      if targetName == "" {
        NotificationManager.dispatch({
          id: "",
          importance: Warning,
          context: Operation("link_modal"),
          message: "Please select a destination room",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Warning),
          dismissible: true,
          createdAt: Date.now(),
        })
      } else {
        // Check for existing link to same target
        let currentScene = Belt.Array.get(state.scenes, state.activeIndex)
        let exists = switch currentScene {
        | Some(scene) => Belt.Array.some(scene.hotspots, h => h.target == targetName)
        | None => false
        }

        if exists {
          NotificationManager.dispatch({
            id: "",
            importance: Warning,
            context: Operation("link_modal"),
            message: "A link to this room already exists here!",
            details: None,
            action: None,
            duration: NotificationTypes.defaultTimeoutMs(Warning),
            dismissible: true,
            createdAt: Date.now(),
          })
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

          Logger.info(
            ~module_="LinkModal",
            ~message="SAVING_LINK",
            ~data=Some({
              "targetName": targetName,
              "newLinkId": newLinkId,
              "beforeState": state.isLinking,
            }),
            (),
          )

          HotspotManager.handleAddHotspot(state.activeIndex, newHotspot, ~getState=() =>
            state
          )->ignore

          // Part 5 Helper: Auto-register in timeline for Visual Pipeline visibility
          let timelineItemJson = JsonParsers.Encoders.timelineItem({
            id: "step_" ++ Date.now()->Float.toString,
            linkId: newLinkId,
            sceneId: switch Belt.Array.get(state.scenes, state.activeIndex) {
            | Some(s) => s.id
            | None => ""
            },
            targetScene: targetName,
            transition: "fade",
            duration: 1000,
          })
          dispatch(Actions.AddToTimeline(timelineItemJson))

          // Use setTimeout to ensure state updates properly after hotspot is added
          let _ = setTimeout(() => {
            Logger.info(
              ~module_="LinkModal",
              ~message="EXIT_SEQUENCE_START",
              ~data=Some({"stateBeforeExit": getState().isLinking}),
              (),
            )

            // Step 1: Close modal first to prevent any re-renders
            EventBus.dispatch(CloseModal)
            Logger.info(~module_="LinkModal", ~message="MODAL_CLOSED", ())

            // Step 2: Hide draft lines immediately
            SvgManager.hide("link_draft_red")
            SvgManager.hide("link_draft_yellow")
            Logger.info(~module_="LinkModal", ~message="DRAFT_LINES_HIDDEN", ())

            // Step 3: Exit linking mode
            dispatch(Actions.StopLinking)
            Logger.info(
              ~module_="LinkModal",
              ~message="STOP_LINKING_DISPATCHED",
              ~data=Some({"stateAfterDispatch": getState().isLinking}),
              (),
            )
          }, 50)
        }
      }
    | None => ()
    }
  }

  EventBus.dispatch(
    ShowModal({
      title: "Link Destination",
      description: None,
      icon: Some("add_link"),
      content: Some(content),
      allowClose: Some(true),
      onClose: Some(
        () => {
          // Explicitly hide draft lines on modal close
          SvgManager.hide("link_draft_red")
          SvgManager.hide("link_draft_yellow")
          dispatch(Actions.StopLinking)
        },
      ),
      className: Some("modal-blue"),
      buttons: [
        {
          label: "Save Link",
          class_: "bg-blue-500/20 text-white hover:bg-blue-500/40",
          onClick: onSave,
          autoClose: Some(false),
        },
        {
          label: "Cancel",
          class_: "bg-slate-100/10 text-white hover:bg-white/20",
          onClick: () => {
            // Explicitly hide draft lines on cancel
            SvgManager.hide("link_draft_red")
            SvgManager.hide("link_draft_yellow")
            EventBus.dispatch(CloseModal)
          },
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
