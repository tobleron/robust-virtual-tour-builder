open Types

let escapeHtml = (raw: string): string =>
  raw
  ->String.replaceRegExp(/&/g, "&amp;")
  ->String.replaceRegExp(/</g, "&lt;")
  ->String.replaceRegExp(/>/g, "&gt;")
  ->String.replaceRegExp(/"/g, "&quot;")
  ->String.replaceRegExp(/'/g, "&#39;")

let floatKey = (value: float): string => Belt.Float.toString(value)

let nullableFloatKey = (value: Nullable.t<float>): string =>
  switch Nullable.toOption(value) {
  | Some(v) => floatKey(v)
  | None => ""
  }

let nullableViewFrameKey = (value: Nullable.t<viewFrame>): string =>
  switch Nullable.toOption(value) {
  | Some(v) =>
    [
      floatKey(v.yaw),
      floatKey(v.pitch),
      floatKey(v.hfov),
    ]->Array.join("|")
  | None => ""
  }

let nullableWaypointsKey = (value: Nullable.t<array<viewFrame>>): string =>
  switch Nullable.toOption(value) {
  | Some(waypoints) =>
    waypoints
    ->Belt.Array.map(v =>
      [
        floatKey(v.yaw),
        floatKey(v.pitch),
        floatKey(v.hfov),
      ]->Array.join("|")
    )
    ->Array.join(";")
  | None => ""
  }

let exportHotspotDestinationKey = (hotspot: TourData.hotspotData): string =>
  [
    hotspot["targetSceneId"],
    if hotspot["targetIsAutoForward"] { "1" } else { "0" },
    hotspot["target"],
  ]->Array.join("::")

let waypointCount = (hotspot: TourData.hotspotData): int =>
  switch Nullable.toOption(hotspot["waypoints"]) {
  | Some(waypoints) => Belt.Array.length(waypoints)
  | None => 0
  }

let sequenceValue = (hotspot: TourData.hotspotData): int =>
  switch Nullable.toOption(hotspot["sequenceNumber"]) {
  | Some(v) => v
  | None => 1_000_000
  }

let prefersExportHotspot = (
  current: TourData.hotspotData,
  candidate: TourData.hotspotData,
): bool => {
  let currentWaypointCount = waypointCount(current)
  let candidateWaypointCount = waypointCount(candidate)
  if candidate["isReturnLink"] != current["isReturnLink"] {
    candidate["isReturnLink"]
  } else if candidateWaypointCount != currentWaypointCount {
    candidateWaypointCount < currentWaypointCount
  } else {
    sequenceValue(candidate) < sequenceValue(current)
  }
}

let dedupeExportHotspots = (hotspots: array<TourData.hotspotData>): array<TourData.hotspotData> => {
  let selectedByKey = Dict.make()
  let order: array<string> = []

  hotspots->Belt.Array.forEach(hotspot => {
    let key = exportHotspotDestinationKey(hotspot)
    switch Dict.get(selectedByKey, key) {
    | Some(current) =>
      if prefersExportHotspot(current, hotspot) {
        Dict.set(selectedByKey, key, hotspot)
      }
    | None =>
      order->Array.push(key)
      Dict.set(selectedByKey, key, hotspot)
    }
  })

  order->Belt.Array.keepMap(key => Dict.get(selectedByKey, key))
}

type exportHotspotEntry = {
  linkId: string,
  destinationKey: string,
  isReturnLink: bool,
  sequenceNumber: option<int>,
  hotspotData: TourData.hotspotData,
}

let generateTourHTML = (
  scenes: array<scene>,
  tourName,
  logoFilename: option<string>,
  exportType,
  baseSize,
  logoSize,
  _version,
  ~marketingBody: string="",
  ~marketingShowRent: bool=false,
  ~marketingShowSale: bool=false,
  ~marketingPhone1: string="",
  ~marketingPhone2: string="",
) => {
  let normalizedExportType = switch exportType {
  | "desktop_blob_2k" => "2k"
  | other => other
  }
  let allowFileProtocol = exportType == "desktop_blob_2k"

  let firstSceneName = scenes[0]->Option.map(s => s.name)->Option.getOr("unknown")
  let firstSceneId = scenes[0]->Option.map(s => s.id)->Option.getOr(firstSceneName)
  let rawScenesData = Dict.make()
  let hasSceneId = (sceneId: string) => scenes->Belt.Array.some(ts => ts.id == sceneId)
  let sequencingState: state = {
    ...State.initialState,
    inventory: scenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, scene) =>
      acc->Belt.Map.String.set(scene.id, {scene, status: Active})
    ),
    sceneOrder: scenes->Belt.Array.map(scene => scene.id),
    activeIndex: 0,
  }
  let derivedBadgeByLinkId = if scenes->Belt.Array.length > 0 {
    HotspotSequence.deriveBadgeByLinkId(~state=sequencingState)
  } else {
    Belt.Map.String.empty
  }
  let maxDerivedSequence =
    derivedBadgeByLinkId
    ->Belt.Map.String.toArray
    ->Belt.Array.reduce(0, (currentMax, (_, badge)) =>
      switch badge {
      | HotspotSequence.Sequence(sequenceNo) =>
        if sequenceNo > currentMax {
          sequenceNo
        } else {
          currentMax
        }
      | HotspotSequence.Return => currentMax
      }
    )
  let fallbackSequenceByLinkId = ref(Belt.Map.String.empty)
  let nextFallbackSequence = ref(maxDerivedSequence + 1)
  let resolveExportBadge = (~linkId: string, ~hasValidTarget: bool): (bool, option<int>) =>
    switch derivedBadgeByLinkId->Belt.Map.String.get(linkId) {
    | Some(HotspotSequence.Return) => (true, None)
    | Some(HotspotSequence.Sequence(sequenceNo)) => (false, Some(sequenceNo))
    | None =>
      if !hasValidTarget {
        (false, None)
      } else {
        switch fallbackSequenceByLinkId.contents->Belt.Map.String.get(linkId) {
        | Some(sequenceNo) => (false, Some(sequenceNo))
        | None =>
          let assignedSequence = nextFallbackSequence.contents
          nextFallbackSequence := assignedSequence + 1
          fallbackSequenceByLinkId :=
            fallbackSequenceByLinkId.contents->Belt.Map.String.set(linkId, assignedSequence)
          (false, Some(assignedSequence))
        }
      }
    }

  scenes->Belt.Array.forEach(s => {
    let rawHotspotEntries: array<exportHotspotEntry> =
      s.hotspots
      ->Belt.Array.keepMap(h => {
        let resolvedTargetId = switch h.targetSceneId {
        | Some(targetSceneId) =>
          if hasSceneId(targetSceneId) {
            targetSceneId
          } else {
            switch TourData.resolveSceneIdFromTargetRef(targetSceneId, scenes) {
            | Some(id) => id
            | None => TourData.resolveSceneIdFromTargetRef(h.target, scenes)->Option.getOr("")
            }
          }
        | None => TourData.resolveSceneIdFromTargetRef(h.target, scenes)->Option.getOr("")
        }
        let targetIsAutoForward = switch h.isAutoForward {
        | Some(true) => true
        | _ => false
        }
        let hasValidTarget = hasSceneId(resolvedTargetId)
        let (isReturnLink, sequenceNumber) = resolveExportBadge(~linkId=h.linkId, ~hasValidTarget)
        if hasValidTarget {
          let hotspotData: TourData.hotspotData = {
            "pitch": h.displayPitch->Option.getOr(h.pitch),
            "yaw": h.yaw,
            "target": h.target,
            "targetSceneId": resolvedTargetId,
            "targetIsAutoForward": targetIsAutoForward,
            "isReturnLink": isReturnLink,
            "sequenceNumber": sequenceNumber->Nullable.fromOption,
            "startYaw": h.startYaw->Nullable.fromOption,
            "startPitch": h.startPitch->Nullable.fromOption,
            "waypoints": h.waypoints->Nullable.fromOption,
            "truePitch": h.pitch,
            "viewFrame": h.viewFrame->Nullable.fromOption,
            "targetYaw": h.targetYaw->Nullable.fromOption,
            "targetPitch": h.targetPitch->Nullable.fromOption,
          }
          Some({
            linkId: h.linkId,
            destinationKey: exportHotspotDestinationKey(hotspotData),
            isReturnLink,
            sequenceNumber,
            hotspotData,
          })
        } else {
          None
        }
      })
    let rawHotspots =
      rawHotspotEntries
      ->Belt.Array.map(entry => entry.hotspotData)
      ->dedupeExportHotspots
    let visibleHotspotIndexByDestinationKey = Dict.make()
    rawHotspots->Belt.Array.forEachWithIndex((idx, hotspot) => {
      Dict.set(visibleHotspotIndexByDestinationKey, exportHotspotDestinationKey(hotspot), idx)
    })
    let sequenceEdges: array<TourData.sequenceEdgeData> =
      rawHotspotEntries
      ->Belt.Array.keepMap(entry =>
        switch (entry.isReturnLink, entry.sequenceNumber) {
        | (false, Some(sequenceNo)) =>
          switch Dict.get(visibleHotspotIndexByDestinationKey, entry.destinationKey) {
          | Some(visibleHotspotIndex) =>
            Some({
              "linkId": entry.linkId,
              "target": entry.hotspotData["target"],
              "targetSceneId": entry.hotspotData["targetSceneId"],
              "targetIsAutoForward": entry.hotspotData["targetIsAutoForward"],
              "sequenceNumber": sequenceNo,
              "visibleHotspotIndex": visibleHotspotIndex,
            }: TourData.sequenceEdgeData)
          | None => None
          }
        | _ => None
        }
      )
    let autoForwardHotspotIndex = {
      let routeFromDoubleChevron =
        rawHotspots->Belt.Array.getIndexBy(h =>
          h["targetIsAutoForward"] == true && hasSceneId(h["targetSceneId"])
        )
      switch routeFromDoubleChevron {
      | Some(idx) => idx
      | None =>
        let routeFromAnyDoubleChevron =
          rawHotspots->Belt.Array.getIndexBy(h =>
            h["targetIsAutoForward"] == true && hasSceneId(h["targetSceneId"])
          )
        switch routeFromAnyDoubleChevron {
        | Some(idx) => idx
        | None => -1
        }
      }
    }
    let autoForwardTargetSceneId = if autoForwardHotspotIndex >= 0 {
      rawHotspots
      ->Belt.Array.get(autoForwardHotspotIndex)
      ->Option.map(h => h["targetSceneId"])
      ->Option.getOr("")
    } else {
      ""
    }
    Dict.set(
      rawScenesData,
      s.id,
      (
        {
          "name": s.name,
          "panorama": `assets/images/${s.name}`,
          "autoLoad": true,
          "floor": s.floor,
          "category": s.category,
          "label": s.label,
          "isAutoForward": s.isAutoForward,
          "autoForwardHotspotIndex": autoForwardHotspotIndex,
          "autoForwardTargetSceneId": autoForwardTargetSceneId,
          "hotSpots": rawHotspots,
          "sequenceEdges": sequenceEdges,
          "isHubScene": Array.length(s.hotspots) >= 2,
        }: TourData.sceneData
      ),
    )
  })

  let (
    defaultHfov,
    minHfov,
    maxHfov,
    stageMinWidth,
    stageMaxWidth,
    dynamicHfovEnabled,
  ) = switch normalizedExportType {
  | "4k" => (90.0, 65.0, 90.0, 375, 1024, true)
  | "2k" => (90.0, 65.0, 90.0, 375, 832, true)
  | "hd" => (90.0, 65.0, 90.0, 375, 640, true)
  | _ => (90.0, 65.0, 90.0, 375, 640, true)
  }
  let exportTraversalMode = "canonical"
  let css = TourStyles.generateCSS(firstSceneName, normalizedExportType, baseSize, logoSize)
  let renderScript = TourScripts.generateRenderScript(
    baseSize,
    defaultHfov,
    minHfov,
    maxHfov,
    stageMinWidth,
    stageMaxWidth,
    dynamicHfovEnabled,
    normalizedExportType == "hd",
    ~exportTraversalMode,
  )
  let logoDiv = switch logoFilename {
  | Some(filename) => `<div class="watermark"><img src="../../assets/logo/${filename}"></div>`
  | None => ""
  }
  let marketingBody = marketingBody->String.trim
  let marketingPhone1 = marketingPhone1->String.trim
  let marketingPhone2 = marketingPhone2->String.trim
  let marketingBannerHtml = TourTemplateMarketing.buildBannerHtml(
    ~marketingBody,
    ~marketingShowRent,
    ~marketingShowSale,
  )
  let portraitMarketingHtml = TourTemplateMarketing.buildPortraitHtml(
    ~marketingShowRent,
    ~marketingShowSale,
    ~marketingPhone1,
    ~marketingPhone2,
  )

  let (defPitch, defYaw) =
    scenes[0]
    ->Option.flatMap(s => s.hotspots[0])
    ->Option.flatMap(h => h.viewFrame)
    ->Option.map(vf => (vf.pitch, vf.yaw))
    ->Option.getOr((0.0, 0.0))

  let scenesDataJson = JsonCombinators.Json.stringify(
    JsonCombinators.Json.Encode.dict(TourData.encodeSceneData)(rawScenesData),
  )

  let html = `<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>${tourName}</title><link rel="stylesheet" href="../../libs/pannellum.css"/><script src="../../libs/pannellum.js"></script><link href="https://fonts.googleapis.com/css2?family=Open+Sans:wght@500;600;700&family=Outfit:wght@400;600&display=swap" rel="stylesheet"><style>${css}</style></head><body><div id="stage"><div id="panorama"></div><div class="looking-mode-indicator"><div class="mode-status-line"><div id="looking-mode-dot" class="mode-dot"></div><div class="mode-label-group"><div id="looking-mode-title" class="mode-title">Looking mode: ON</div><div class="mode-subtitle"><span class="mode-shortcut-key">L</span> to toggle</div></div></div><div id="viewer-floor-tags-export" class="state-hidden" aria-live="polite"></div></div><div id="viewer-room-label-export" class="viewer-persistent-label-export state-hidden"></div><div id="viewer-floor-nav-export" aria-hidden="true"></div>${marketingBannerHtml}${portraitMarketingHtml}${logoDiv}</div><script>

    const firstSceneId = "${firstSceneId}"; ${renderScript}
    let transitionFrom = null; let persistentFrom = null; let isFirstLoad = true;
    const config = { "default": { "firstScene": "${firstSceneId}", "sceneFadeDuration": 1000, "pitch": ${Belt.Float.toString(
      defPitch,
    )}, "yaw": ${Belt.Float.toString(
      defYaw,
    )}, "hfov": getCurrentHfov(), "minHfov": ${Belt.Float.toString(
      minHfov,
    )}, "maxHfov": ${Belt.Float.toString(
      maxHfov,
    )}, "showControls": false, "mouseZoom": false, "doubleClickZoom": false, "keyboardZoom": false, "showZoomCtrl": false }, "scenes":{} };
    const scenesData = ${scenesDataJson};
    for (const [sceneId, data] of Object.entries(scenesData)) {
      config.scenes[sceneId] = { panorama: data.panorama, autoLoad: true, hotSpots: data.hotSpots.map((h, idx) => ({ pitch: h.pitch, yaw: h.yaw, type: "info", cssClass: "flat-arrow", createTooltipFunc: renderOrangeHotspot, createTooltipArgs: { i: idx, sourceSceneId: sceneId, targetSceneId: h.targetSceneId, target: h.target, targetName: h.target, targetIsAutoForward: h.targetIsAutoForward, sequenceNumber: h.sequenceNumber, viewFrame: h.viewFrame, targetYaw: h.targetYaw, targetPitch: h.targetPitch, isReturnLink: h.isReturnLink, returnViewFrame: h.returnViewFrame } })) };
    }
    const mountFileProtocolWarning = () => {
      const existing = document.getElementById('file-protocol-warning');
      if (existing) return;
      const host = document.createElement('div');
      host.id = 'file-protocol-warning';
      host.style.position = 'absolute';
      host.style.inset = '0';
      host.style.display = 'grid';
      host.style.placeItems = 'center';
      host.style.padding = '20px';
      host.style.zIndex = '99999';
      host.style.background = 'linear-gradient(to bottom, rgba(0,0,0,0.45), rgba(0,0,0,0.72))';
      host.innerHTML = '<div style=\"width:min(680px,94vw);background:#050b18;border:1px solid rgba(255,255,255,0.16);border-radius:14px;padding:20px 18px;color:#fff;font-family:Outfit,sans-serif;box-shadow:0 20px 50px rgba(0,0,0,0.45)\"><div style=\"font-size:20px;font-weight:700;margin-bottom:8px\">This tour cannot run via file://</div><div style=\"font-size:14px;line-height:1.6;opacity:.94\">Open this export through a small local HTTP server.</div><div style=\"margin-top:12px;font-size:13px;line-height:1.7;opacity:.95\"><div style=\"margin-bottom:6px;font-weight:600\">Quick start (from export root folder):</div><div><code style=\"background:#0d1b38;padding:3px 6px;border-radius:6px\">python3 -m http.server 8080</code></div><div style=\"margin-top:6px\">Then open <code style=\"background:#0d1b38;padding:3px 6px;border-radius:6px\">http://127.0.0.1:8080/web_only/index.html</code></div></div></div>';
      document.body.appendChild(host);
    };

    const allowFileProtocol = ${if allowFileProtocol {
      "true"
    } else {
      "false"
    }};
    if (window.location.protocol === 'file:' && !allowFileProtocol) {
      updateExportStateClasses();
      updateLookingModeUI();
      mountFileProtocolWarning();
    } else {
      updateExportStateClasses();
      updateLookingModeUI();
      window.viewer = pannellum.viewer('panorama', config); window.viewer.resize(); applyCurrentHfov();
      window.addEventListener('resize', () => { updateExportStateClasses(); window.viewer?.resize(); applyCurrentHfov(); });
      ${TourScripts.loadEventScript}
    }
  </script></body></html>`
  html
}
