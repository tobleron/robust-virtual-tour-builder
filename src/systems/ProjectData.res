/* src/systems/ProjectData.res */

open Types

// VersionData is accessed natively

/* Serialize State to JSON */
let toJSON = (state: Types.state) => {
  let scenes = Belt.Array.map(state.scenes, scene => {
    let hotspots = Belt.Array.map(scene.hotspots, h => {
      {
        "linkId": h.linkId,
        "pitch": h.pitch,
        "yaw": h.yaw,
        "target": h.target,
        "displayPitch": h.displayPitch,
        "truePitch": Nullable.null,
        "startPitch": h.startPitch,
        "startYaw": h.startYaw,
        "startHfov": h.startHfov,
        "viewFrame": h.viewFrame,
        "returnViewFrame": h.returnViewFrame,
        "isReturnLink": h.isReturnLink,
        "targetYaw": h.targetYaw,
        "targetPitch": h.targetPitch,
        "waypoints": h.waypoints,
        "transition": h.transition,
        "duration": h.duration,
      }
    })

    {
      "id": scene.id,
      "name": scene.name,
      "label": scene.label,
      "category": scene.category,
      "floor": scene.floor,
      "isAutoForward": scene.isAutoForward,
      "quality": scene.quality,
      "colorGroup": scene.colorGroup,
      "categorySet": scene.categorySet,
      "labelSet": scene.labelSet,
      "_metadataSource": scene._metadataSource,
      "hotspots": hotspots,
    }
  })

  {
    "version": VersionData.version,
    "tourName": state.tourName,
    "savedAt": Date.toISOString(Date.make()),
    "activeIndex": state.activeIndex,
    "deletedSceneIds": state.deletedSceneIds,
    "scenes": scenes,
    "timeline": state.timeline,
    "lastUsedCategory": state.lastUsedCategory,
    "exifReport": state.exifReport->Nullable.fromOption,
  }
}

/* Parse Loaded Scenes (Helper for ProjectManager.js) */
/* Receives a raw JS object from the loaded JSON and sanitizes it for the Store */
let sanitizeLoadedScenes = (rawScenes: array<JSON.t>) => {
  Belt.Array.map(rawScenes, item => {
    let i = JsonTypes.castToProjectScene(item)

    /* We return a structure compatible with what ProjectManager appends 'file' to */
    /* Actually ProjectManager maps this, attaches 'file', then passes to Store */
    /* So we just help cleaner mapping of properties if needed */
    /* Currently strict pass-through is fine, but we can ensure defaults here */

    let hotspots = switch Nullable.toOption(i.hotspots) {
    | Some(arr) =>
      let hArr = JsonTypes.castToHotspots(Obj.magic(arr)) // arr is already hotspotJson array
      Belt.Array.map(hArr, h => {
        /* Ensure structured data is preserved */
        {
          "linkId": switch Nullable.toOption(h.linkId) {
          | Some(l) => l
          | None => ""
          },
          "pitch": h.pitch,
          "yaw": h.yaw,
          "target": h.target,
          "startPitch": h.startPitch,
          "startYaw": h.startYaw,
          "startHfov": h.startHfov,
          "viewFrame": h.viewFrame,
          "returnViewFrame": h.returnViewFrame,
          "isReturnLink": h.isReturnLink,
          "targetYaw": h.targetYaw,
          "targetPitch": h.targetPitch,
          "waypoints": h.waypoints,
          "transition": h.transition,
          "duration": h.duration,
        }
      })
    | None => []
    }

    {
      "id": switch Nullable.toOption(i.id) {
      | Some(id) => id
      | None => "legacy_" ++ i.name
      },
      "name": i.name,
      "label": switch Nullable.toOption(i.label) {
      | Some(l) => l
      | None => ""
      },
      "category": switch Nullable.toOption(i.category) {
      | Some(c) => c
      | None => "outdoor"
      },
      "floor": switch Nullable.toOption(i.floor) {
      | Some(f) => f
      | None => "ground"
      },
      "isAutoForward": switch Nullable.toOption(i.isAutoForward) {
      | Some(b) => b
      | None => false
      },
      "categorySet": switch Nullable.toOption(i.categorySet) {
      | Some(b) => b
      | None => false
      },
      "labelSet": switch Nullable.toOption(i.labelSet) {
      | Some(b) => b
      | None => false
      },
      "_metadataSource": switch Nullable.toOption(i.metadataSource) {
      | Some(s) => s
      | None => "user"
      },
      "quality": i.quality,
      "colorGroup": i.colorGroup,
      "hotspots": hotspots,
      /* ProjectManager will attach fields: file, originalFile */
    }
  })
}
