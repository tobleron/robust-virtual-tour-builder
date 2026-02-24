/* src/core/JsonParsersEncoders.res */
/* @efficiency-role: data-model */

open JsonCombinators.Json

let value = (v: JSON.t) => v

let nullable = (encoder, v: Nullable.t<'a>) => {
  switch Nullable.toOption(v) {
  | Some(x) => encoder(x)
  | None => Encode.null
  }
}

let file = (f: Types.file) => {
  switch f {
  | Url(u) => Encode.string(u)
  | File(_) => Encode.string("")
  | Blob(_) => Encode.string("")
  }
}

let viewFrame = (v: Types.viewFrame) => {
  Encode.object([
    ("yaw", Encode.float(v.yaw)),
    ("pitch", Encode.float(v.pitch)),
    ("hfov", Encode.float(v.hfov)),
  ])
}

let hotspot = (h: Types.hotspot) => {
  Encode.object([
    ("linkId", Encode.string(h.linkId)),
    ("yaw", Encode.float(h.yaw)),
    ("pitch", Encode.float(h.pitch)),
    ("target", Encode.string(h.target)),
    ("targetSceneId", Encode.option(Encode.string)(h.targetSceneId)),
    ("targetYaw", Encode.option(Encode.float)(h.targetYaw)),
    ("targetPitch", Encode.option(Encode.float)(h.targetPitch)),
    ("targetHfov", Encode.option(Encode.float)(h.targetHfov)),
    ("startYaw", Encode.option(Encode.float)(h.startYaw)),
    ("startPitch", Encode.option(Encode.float)(h.startPitch)),
    ("startHfov", Encode.option(Encode.float)(h.startHfov)),
    ("isReturnLink", Encode.option(Encode.bool)(h.isReturnLink)),
    ("viewFrame", Encode.option(viewFrame)(h.viewFrame)),
    ("returnViewFrame", Encode.option(viewFrame)(h.returnViewFrame)),
    ("waypoints", Encode.option(Encode.array(viewFrame))(h.waypoints)),
    ("displayPitch", Encode.option(Encode.float)(h.displayPitch)),
    ("transition", Encode.option(Encode.string)(h.transition)),
    ("duration", Encode.option(i => Encode.float(Belt.Int.toFloat(i)))(h.duration)),
    ("isAutoForward", Encode.option(Encode.bool)(h.isAutoForward)),
  ])
}

let scene = (s: Types.scene) => {
  Encode.object([
    ("id", Encode.string(s.id)),
    ("name", Encode.string(s.name)),
    ("file", file(s.file)),
    ("tinyFile", Encode.option(file)(s.tinyFile)),
    ("originalFile", Encode.option(file)(s.originalFile)),
    ("hotspots", Encode.array(hotspot)(s.hotspots)),
    ("category", Encode.string(s.category)),
    ("floor", Encode.string(s.floor)),
    ("label", Encode.string(s.label)),
    ("quality", Encode.option(value)(s.quality)),
    ("colorGroup", Encode.option(Encode.string)(s.colorGroup)),
    ("_metadataSource", Encode.string(s._metadataSource)),
    ("categorySet", Encode.bool(s.categorySet)),
    ("labelSet", Encode.bool(s.labelSet)),
    ("isAutoForward", Encode.bool(s.isAutoForward)),
    ("sequenceId", Encode.int(s.sequenceId)),
  ])
}

let timelineItem = (t: Types.timelineItem) => {
  Encode.object([
    ("id", Encode.string(t.id)),
    ("linkId", Encode.string(t.linkId)),
    ("sceneId", Encode.string(t.sceneId)),
    ("targetScene", Encode.string(t.targetScene)),
    ("transition", Encode.string(t.transition)),
    ("duration", Encode.float(Belt.Int.toFloat(t.duration))),
  ])
}

let sceneStatus = (s: Types.sceneStatus) => {
  switch s {
  | Active => Encode.string("Active")
  | Deleted(t) =>
    Encode.object([("status", Encode.string("Deleted")), ("timestamp", Encode.float(t))])
  }
}

let sceneEntry = (e: Types.sceneEntry) => {
  Encode.object([("scene", scene(e.scene)), ("status", sceneStatus(e.status))])
}

let inventory = (inv: Belt.Map.String.t<Types.sceneEntry>) => {
  let toObj = ((id, entry)) => {
    Encode.object([("id", Encode.string(id)), ("entry", sceneEntry(entry))])
  }
  inv->Belt.Map.String.toArray->Belt.Array.map(toObj)->Encode.jsonArray
}

let logoFile = (f: Types.file) => {
  switch f {
  | Url(u) => Encode.string(u)
  | File(_) => Encode.string("logo_upload")
  | Blob(_) => Encode.string("logo_upload")
  }
}

let project = (p: Types.project) => {
  Encode.object([
    ("tourName", Encode.string(p.tourName)),
    ("scenes", Encode.array(scene)(SceneInventory.getActiveScenes(p.inventory, p.sceneOrder))),
    ("inventory", inventory(p.inventory)),
    ("sceneOrder", Encode.array(Encode.string)(p.sceneOrder)),
    ("lastUsedCategory", Encode.string(p.lastUsedCategory)),
    ("exifReport", Encode.option(value)(p.exifReport)),
    ("sessionId", Encode.option(Encode.string)(p.sessionId)),
    ("deletedSceneIds", Encode.array(Encode.string)(SceneInventory.getDeletedIds(p.inventory))),
    ("timeline", Encode.array(timelineItem)(p.timeline)),
    ("logo", Encode.option(logoFile)(p.logo)),
    ("nextSceneSequenceId", Encode.int(p.nextSceneSequenceId)),
  ])
}

let persistedSession = (~version: int, ~timestamp: float, ~projectData: JSON.t) => {
  Encode.object([
    ("version", Encode.int(version)),
    ("timestamp", Encode.float(timestamp)),
    ("projectData", projectData),
  ])
}

let pathRequest = (req: Types.pathRequest) => {
  Encode.object([
    ("type", Encode.string(req.type_)),
    ("scenes", Encode.array(scene)(req.scenes)),
    ("skipAutoForward", Encode.bool(req.skipAutoForward)),
    ("timeline", Encode.option(Encode.array(timelineItem))(req.timeline)),
  ])
}

let gpsData = (g: SharedTypes.gpsData) => {
  Encode.object([("lat", Encode.float(g.lat)), ("lon", Encode.float(g.lon))])
}

let exifMetadata = (m: SharedTypes.exifMetadata) => {
  Encode.object([
    ("date", nullable(Encode.string, m.dateTime)),
    ("gps", nullable(gpsData, m.gps)),
    ("cameraModel", nullable(Encode.string, m.make)),
    ("lensModel", nullable(Encode.string, m.model)),
    ("focalLength", nullable(Encode.float, m.focalLength)),
    ("fNumber", nullable(Encode.float, m.aperture)),
    ("iso", nullable(Encode.int, m.iso)),
    ("width", Encode.int(m.width)),
    ("height", Encode.int(m.height)),
  ])
}

let similarityPair = (p: SharedTypes.similarityPair) => {
  Encode.object([
    ("idA", Encode.string(p.idA)),
    ("idB", Encode.string(p.idB)),
    ("histogramA", value(p.histogramA)),
    ("histogramB", value(p.histogramB)),
  ])
}

let transition = (t: Types.transition) => {
  Encode.object([
    (
      "type",
      Encode.string(
        switch t.type_ {
        | Cut => "Cut"
        | Fade => "Fade"
        | Link => "Link"
        | Unknown(s) => s
        },
      ),
    ),
    ("targetHotspotIndex", Encode.int(t.targetHotspotIndex)),
    ("fromSceneName", Encode.option(Encode.string)(t.fromSceneName)),
  ])
}

let uploadReport = (r: Types.uploadReport) => {
  Encode.object([
    ("success", Encode.array(Encode.string)(r.success)),
    ("skipped", Encode.array(Encode.string)(r.skipped)),
  ])
}

let rec linkDraft = (l: Types.linkDraft) => {
  Encode.object([
    ("pitch", Encode.float(l.pitch)),
    ("yaw", Encode.float(l.yaw)),
    ("camPitch", Encode.float(l.camPitch)),
    ("camYaw", Encode.float(l.camYaw)),
    ("camHfov", Encode.float(l.camHfov)),
    ("intermediatePoints", Encode.option(Encode.array(linkDraft))(l.intermediatePoints)),
  ])
}

let linkInfo = (l: Types.linkInfo) => {
  Encode.object([
    ("sceneIndex", Encode.int(l.sceneIndex)),
    ("hotspotIndex", Encode.int(l.hotspotIndex)),
  ])
}

let navigationStatus = (n: Types.navigationStatus) => {
  switch n {
  | Idle => Encode.string("Idle")
  | Navigating(_) => Encode.string("Navigating")
  | Previewing(l) => Encode.object([("status", Encode.string("Previewing")), ("link", linkInfo(l))])
  }
}

let navigationFsmState = (s: NavigationFSM.distinctState) => {
  Encode.string(NavigationFSM.toString(s))
}

let simulationState = (s: Types.simulationState) => {
  Encode.object([
    (
      "status",
      Encode.string(
        switch s.status {
        | Idle => "Idle"
        | Running => "Running"
        | Stopping => "Stopping"
        | Paused => "Paused"
        },
      ),
    ),
    ("visitedLinkIds", Encode.array(Encode.string)(s.visitedLinkIds)),
    ("autoPilotJourneyId", Encode.int(s.autoPilotJourneyId)),
  ])
}

let state = (s: Types.state) => {
  Encode.object([
    ("tourName", Encode.string(s.tourName)),
    ("scenes", Encode.array(scene)(SceneInventory.getActiveScenes(s.inventory, s.sceneOrder))),
    ("inventory", inventory(s.inventory)),
    ("sceneOrder", Encode.array(Encode.string)(s.sceneOrder)),
    ("activeIndex", Encode.int(s.activeIndex)),
    ("activeYaw", Encode.float(s.activeYaw)),
    ("activePitch", Encode.float(s.activePitch)),
    ("isLinking", Encode.bool(s.isLinking)),
    ("transition", transition(s.transition)),
    ("exifReport", Encode.option(value)(s.exifReport)),
    ("linkDraft", Encode.option(linkDraft)(s.linkDraft)),
    ("preloadingSceneIndex", Encode.int(s.preloadingSceneIndex)),
    ("isTeasing", Encode.bool(s.isTeasing)),
    ("deletedSceneIds", Encode.array(Encode.string)(SceneInventory.getDeletedIds(s.inventory))),
    ("timeline", Encode.array(timelineItem)(s.timeline)),
    ("activeTimelineStepId", Encode.option(Encode.string)(s.activeTimelineStepId)),
    ("navigation", navigationStatus(s.navigationState.navigation)),
    ("navigationFsm", navigationFsmState(s.navigationState.navigationFsm)),
    ("simulation", simulationState(s.simulation)),
    ("incomingLink", Encode.option(linkInfo)(s.navigationState.incomingLink)),
    ("autoForwardChain", Encode.array(Encode.int)(s.navigationState.autoForwardChain)),
    ("pendingReturnSceneName", Encode.option(Encode.string)(s.pendingReturnSceneName)),
    ("currentJourneyId", Encode.int(s.navigationState.currentJourneyId)),
    ("lastUsedCategory", Encode.string(s.lastUsedCategory)),
    ("sessionId", Encode.option(Encode.string)(s.sessionId)),
    ("logo", Encode.option(logoFile)(s.logo)),
    (
      "appMode",
      switch s.appMode {
      | Initializing => Encode.string("Initializing")
      | Interactive(_) => Encode.string("Interactive") // Minimal for session persistence
      | SystemBlocking(Uploading({progress})) =>
        Encode.object([("type", Encode.string("Uploading")), ("progress", Encode.float(progress))])
      | SystemBlocking(Summary(report, _)) =>
        Encode.object([("type", Encode.string("Summary")), ("report", uploadReport(report))])
      | SystemBlocking(ProjectLoading({name})) =>
        Encode.object([("type", Encode.string("ProjectLoading")), ("name", Encode.string(name))])
      | SystemBlocking(Exporting(_)) => Encode.object([("type", Encode.string("Exporting"))])
      | SystemBlocking(CriticalError(msg)) =>
        Encode.object([("type", Encode.string("CriticalError")), ("message", Encode.string(msg))])
      },
    ),
  ])
}

let motionAnimationSegment = (s: Types.motionAnimationSegment) => {
  Encode.object([
    ("startYaw", Encode.float(s.startYaw)),
    ("endYaw", Encode.float(s.endYaw)),
    ("startPitch", Encode.float(s.startPitch)),
    ("endPitch", Encode.float(s.endPitch)),
    ("startHfov", Encode.float(s.startHfov)),
    ("endHfov", Encode.float(s.endHfov)),
    ("easing", Encode.string(s.easing)),
    ("durationMs", Encode.int(s.durationMs)),
  ])
}

let motionTransitionOut = (t: Types.motionTransitionOut) => {
  Encode.object([("type", Encode.string(t.type_)), ("durationMs", Encode.int(t.durationMs))])
}

let motionPathPoint = (p: Types.pathPoint) => {
  Encode.object([("yaw", Encode.float(p.yaw)), ("pitch", Encode.float(p.pitch))])
}

let motionPathSegment = (s: Types.pathSegment) => {
  Encode.object([
    ("dist", Encode.float(s.dist)),
    ("yawDiff", Encode.float(s.yawDiff)),
    ("pitchDiff", Encode.float(s.pitchDiff)),
    ("p1", motionPathPoint(s.p1)),
    ("p2", motionPathPoint(s.p2)),
  ])
}

let motionPathData = (pd: Types.pathData) => {
  Encode.object([
    ("startPitch", Encode.float(pd.startPitch)),
    ("startYaw", Encode.float(pd.startYaw)),
    ("startHfov", Encode.float(pd.startHfov)),
    ("targetPitchForPan", Encode.float(pd.targetPitchForPan)),
    ("targetYawForPan", Encode.float(pd.targetYawForPan)),
    ("targetHfovForPan", Encode.float(pd.targetHfovForPan)),
    ("totalPathDistance", Encode.float(pd.totalPathDistance)),
    ("segments", Encode.array(motionPathSegment)(pd.segments)),
    ("waypoints", Encode.array(motionPathPoint)(pd.waypoints)),
    ("panDuration", Encode.float(pd.panDuration)),
    ("arrivalYaw", Encode.float(pd.arrivalYaw)),
    ("arrivalPitch", Encode.float(pd.arrivalPitch)),
    ("arrivalHfov", Encode.float(pd.arrivalHfov)),
  ])
}

let motionShot = (s: Types.motionShot) => {
  Encode.object([
    ("sceneId", Encode.string(s.sceneId)),
    ("arrivalPose", viewFrame(s.arrivalPose)),
    ("animationSegments", Encode.array(motionAnimationSegment)(s.animationSegments)),
    ("transitionOut", Encode.option(motionTransitionOut)(s.transitionOut)),
    ("pathData", Encode.option(motionPathData)(s.pathData)),
    ("waitBeforePanMs", Encode.int(s.waitBeforePanMs)),
    ("blinkAfterPanMs", Encode.int(s.blinkAfterPanMs)),
  ])
}

let motionManifest = (m: Types.motionManifest) => {
  Encode.object([
    ("version", Encode.string(m.version)),
    ("fps", Encode.int(m.fps)),
    ("canvasWidth", Encode.int(m.canvasWidth)),
    ("canvasHeight", Encode.int(m.canvasHeight)),
    ("includeIntroPan", Encode.bool(m.includeIntroPan)),
    ("shots", Encode.array(motionShot)(m.shots)),
  ])
}
