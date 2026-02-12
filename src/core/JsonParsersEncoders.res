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

let project = (p: Types.project) => {
  Encode.object([
    ("tourName", Encode.string(p.tourName)),
    ("scenes", Encode.array(scene)(p.scenes)),
    ("inventory", inventory(p.inventory)),
    ("sceneOrder", Encode.array(Encode.string)(p.sceneOrder)),
    ("lastUsedCategory", Encode.string(p.lastUsedCategory)),
    ("exifReport", Encode.option(value)(p.exifReport)),
    ("sessionId", Encode.option(Encode.string)(p.sessionId)),
    ("deletedSceneIds", Encode.array(Encode.string)(p.deletedSceneIds)),
    ("timeline", Encode.array(timelineItem)(p.timeline)),
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
    ("visitedScenes", Encode.array(Encode.int)(s.visitedScenes)),
    ("autoPilotJourneyId", Encode.int(s.autoPilotJourneyId)),
  ])
}

let state = (s: Types.state) => {
  Encode.object([
    ("tourName", Encode.string(s.tourName)),
    ("scenes", Encode.array(scene)(s.scenes)),
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
    ("deletedSceneIds", Encode.array(Encode.string)(s.deletedSceneIds)),
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
