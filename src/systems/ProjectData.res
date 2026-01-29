/* src/systems/ProjectData.res */

open Types

/* Serialize State to JSON */
let toJSON = (state: Types.state) => {
  let scenes = Belt.Array.map(state.scenes, scene => {
    let hotspots = Belt.Array.map(scene.hotspots, h => {
      {
        "linkId": h.linkId,
        "pitch": h.pitch,
        "yaw": h.yaw,
        "target": h.target,
        "displayPitch": h.displayPitch->Nullable.fromOption,
        "truePitch": Nullable.null,
        "startPitch": h.startPitch->Nullable.fromOption,
        "startYaw": h.startYaw->Nullable.fromOption,
        "startHfov": h.startHfov->Nullable.fromOption,
        "viewFrame": h.viewFrame->Nullable.fromOption,
        "returnViewFrame": h.returnViewFrame->Nullable.fromOption,
        "isReturnLink": h.isReturnLink->Nullable.fromOption,
        "targetYaw": h.targetYaw->Nullable.fromOption,
        "targetPitch": h.targetPitch->Nullable.fromOption,
        "waypoints": h.waypoints->Nullable.fromOption,
        "transition": h.transition->Nullable.fromOption,
        "duration": h.duration->Nullable.fromOption,
      }
    })

    {
      "id": scene.id,
      "name": scene.name,
      "label": scene.label,
      "category": scene.category,
      "floor": scene.floor,
      "isAutoForward": scene.isAutoForward,
      "quality": scene.quality->Nullable.fromOption,
      "colorGroup": scene.colorGroup->Nullable.fromOption,
      "categorySet": scene.categorySet,
      "labelSet": scene.labelSet,
      "_metadataSource": scene._metadataSource,
      "hotspots": hotspots,
    }
  })

  {
    "version": Version.version,
    "tourName": state.tourName,
    "savedAt": Date.toISOString(Date.make()),
    "activeIndex": state.activeIndex,
    "deletedSceneIds": state.deletedSceneIds,
    "scenes": scenes,
    "timeline": state.timeline,
    "lastUsedCategory": state.lastUsedCategory,
    "exifReport": state.exifReport->Nullable.fromOption,
    "sessionId": state.sessionId->Nullable.fromOption,
  }
}

/* Parse Loaded Scenes (Helper for ProjectManager.js) */
/* Receives a raw JS object from the loaded JSON and sanitizes it for the Store */
let sanitizeLoadedScenes = (rawScenes: array<JSON.t>) => {
  Belt.Array.map(rawScenes, item => {
    let i = Schemas.castToProjectScene(item)

    let hotspots = Belt.Array.map(i.hotspots, h => {
      {
        "linkId": h.linkId,
        "pitch": h.pitch,
        "yaw": h.yaw,
        "target": h.target,
        "startPitch": h.startPitch->Nullable.fromOption,
        "startYaw": h.startYaw->Nullable.fromOption,
        "startHfov": h.startHfov->Nullable.fromOption,
        "viewFrame": h.viewFrame->Nullable.fromOption,
        "returnViewFrame": h.returnViewFrame->Nullable.fromOption,
        "isReturnLink": h.isReturnLink->Nullable.fromOption,
        "targetYaw": h.targetYaw->Nullable.fromOption,
        "targetPitch": h.targetPitch->Nullable.fromOption,
        "waypoints": h.waypoints->Nullable.fromOption,
        "transition": h.transition->Nullable.fromOption,
        "duration": h.duration->Nullable.fromOption,
      }
    })

    {
      "id": i.id,
      "name": i.name,
      "label": i.label,
      "category": i.category,
      "floor": i.floor,
      "isAutoForward": i.isAutoForward,
      "categorySet": i.categorySet,
      "labelSet": i.labelSet,
      "_metadataSource": i._metadataSource,
      "quality": i.quality->Nullable.fromOption,
      "colorGroup": i.colorGroup->Nullable.fromOption,
      "hotspots": hotspots,
    }
  })
}
