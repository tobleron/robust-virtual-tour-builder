open Types

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
  | "desktop_blob_hd_landscape_touch" => "hd"
  | "desktop_blob_2k" => "2k"
  | "desktop_blob_2k_landscape_touch" => "2k"
  | "desktop_blob_4k_landscape_touch" => "4k"
  | other => other
  }
  let allowFileProtocol =
    exportType == "desktop_blob_2k" ||
    exportType == "desktop_blob_hd_landscape_touch" ||
    exportType == "desktop_blob_2k_landscape_touch" ||
    exportType == "desktop_blob_4k_landscape_touch"
  let forcedExportInteractionShell = switch exportType {
  | "desktop_blob_hd_landscape_touch" | "desktop_blob_2k_landscape_touch" => "landscape-touch"
  | "desktop_blob_4k_landscape_touch" => "landscape-touch"
  | _ => ""
  }

  let firstSceneName = scenes[0]->Option.map(s => s.name)->Option.getOr("unknown")
  let firstSceneId = scenes[0]->Option.map(s => s.id)->Option.getOr(firstSceneName)
  let rawScenesData = Dict.make()
  let entryByLinkId = Dict.make()
  let entryBySceneHotspotKey = Dict.make()
  let visibleHotspotIndexByLinkId = Dict.make()
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
  let sceneNumberBySceneId = if scenes->Belt.Array.length > 0 {
    HotspotSequence.deriveSceneNumberBySceneId(~state=sequencingState)
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
    let rawHotspotEntries: array<TourTemplateHtmlSupportData.exportHotspotEntry> =
      s.hotspots
      ->Belt.Array.mapWithIndex((hotspotIndex, h) => {
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
        let targetSceneNumber = sceneNumberBySceneId->Belt.Map.String.get(resolvedTargetId)
        let (isReturnLink, sequenceNumber) = resolveExportBadge(~linkId=h.linkId, ~hasValidTarget)
        if hasValidTarget {
          let hotspotData: TourData.hotspotData = {
            "pitch": h.displayPitch->Option.getOr(h.pitch),
            "yaw": h.yaw,
            "target": h.target,
            "targetSceneId": resolvedTargetId,
            "targetSceneNumber": targetSceneNumber->Nullable.fromOption,
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
          let entry: TourTemplateHtmlSupportData.exportHotspotEntry = {
            sourceSceneId: s.id,
            hotspotIndex,
            linkId: h.linkId,
            destinationKey: TourTemplateHtmlSupportData.exportHotspotDestinationKey(hotspotData),
            isReturnLink,
            sequenceNumber,
            hotspotData,
          }
          Some(entry)
        } else {
          None
        }
      })
      ->Belt.Array.keepMap(item => item)
    let rawHotspots =
      rawHotspotEntries
      ->Belt.Array.map(entry => entry.hotspotData)
      ->TourTemplateHtmlSupportData.dedupeExportHotspots
    let visibleHotspotIndexByDestinationKey = Dict.make()
    rawHotspots->Belt.Array.forEachWithIndex((idx, hotspot) => {
      Dict.set(
        visibleHotspotIndexByDestinationKey,
        TourTemplateHtmlSupportData.exportHotspotDestinationKey(hotspot),
        idx,
      )
    })
    rawHotspotEntries->Belt.Array.forEach(entry => {
      Dict.set(entryByLinkId, entry.linkId, entry)
      Dict.set(
        entryBySceneHotspotKey,
        TourTemplateHtmlSupportData.exportSceneHotspotKey(
          ~sceneId=entry.sourceSceneId,
          ~hotspotIndex=entry.hotspotIndex,
        ),
        entry,
      )
      switch Dict.get(visibleHotspotIndexByDestinationKey, entry.destinationKey) {
      | Some(visibleHotspotIndex) =>
        Dict.set(visibleHotspotIndexByLinkId, entry.linkId, visibleHotspotIndex)
      | None => ()
      }
    })
    let sequenceEdges: array<
      TourData.sequenceEdgeData,
    > = rawHotspotEntries->Belt.Array.keepMap(entry =>
      switch (entry.isReturnLink, entry.sequenceNumber) {
      | (false, Some(sequenceNo)) =>
        switch Dict.get(visibleHotspotIndexByDestinationKey, entry.destinationKey) {
        | Some(visibleHotspotIndex) =>
          Some(
            (
              {
                "linkId": entry.linkId,
                "target": entry.hotspotData["target"],
                "targetSceneId": entry.hotspotData["targetSceneId"],
                "targetIsAutoForward": entry.hotspotData["targetIsAutoForward"],
                "sequenceNumber": sequenceNo,
                "visibleHotspotIndex": visibleHotspotIndex,
              }: TourData.sequenceEdgeData
            ),
          )
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
          "sceneNumber": sceneNumberBySceneId->Belt.Map.String.get(s.id)->Option.getOr(1),
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
  let autoTourManifest = TourTemplateHtmlSupportData.deriveAutoTourManifest(
    ~state=sequencingState,
    ~firstSceneId,
    ~derivedBadgeByLinkId,
    ~entryByLinkId,
    ~entryBySceneHotspotKey,
    ~visibleHotspotIndexByLinkId,
  )

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
  | Some(filename) =>
    `<div class="watermark" id="export-watermark"><img id="export-watermark-image" src="../../assets/logo/${filename}"></div>`
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
  let autoTourManifestJson = JsonCombinators.Json.stringify(
    TourData.encodeAutoTourManifest(autoTourManifest),
  )

  let html = `<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>${tourName}</title><link rel="stylesheet" href="../../libs/pannellum.css"/><script src="../../libs/pannellum.js"></script><link href="https://fonts.googleapis.com/css2?family=Open+Sans:wght@500;600;700&family=Outfit:wght@400;600;700&display=swap" rel="stylesheet"><style>${css}</style></head><body><div id="stage"><div id="panorama"></div><div class="looking-mode-indicator"><div class="mode-status-line"><div id="looking-mode-dot" class="mode-dot"></div><span class="mode-shortcut-key mode-shortcut-key-inline">L</span><div id="looking-mode-title" class="mode-title">Looking mode: ON</div></div><div id="viewer-floor-tags-export" class="state-hidden" aria-live="polite"></div></div><div id="viewer-portrait-mode-selector-export" class="state-hidden" aria-hidden="true"></div><div id="viewer-sequence-prompt-export" class="state-hidden" aria-hidden="true"></div><div id="viewer-room-label-export" class="viewer-persistent-label-export state-hidden"></div><div id="viewer-floor-nav-export"></div><div id="viewer-portrait-joystick-export" class="state-hidden"></div>${marketingBannerHtml}${portraitMarketingHtml}${logoDiv}</div><script>

    const firstSceneId = "${firstSceneId}";
    const scenesData = ${scenesDataJson};
    const autoTourManifest = ${autoTourManifestJson};
    const FORCED_EXPORT_INTERACTION_SHELL = "${forcedExportInteractionShell}";
    const EXPORT_TOUCH_PAN_SPEED_COEFF = 1.0;
    const EXPORT_TOUCH_RELEASE_MOMENTUM_FACTOR = 1.4;
    ${renderScript}
    let transitionFrom = null; let persistentFrom = null; let isFirstLoad = true;
    const config = { "default": { "firstScene": "${firstSceneId}", "sceneFadeDuration": 1000, "pitch": ${Belt.Float.toString(
      defPitch,
    )}, "yaw": ${Belt.Float.toString(
      defYaw,
    )}, "hfov": getCurrentHfov(), "minHfov": ${Belt.Float.toString(
      minHfov,
    )}, "maxHfov": ${Belt.Float.toString(
      maxHfov,
    )}, "showControls": false, "mouseZoom": false, "doubleClickZoom": false, "keyboardZoom": false, "showZoomCtrl": false, "touchPanSpeedCoeffFactor": EXPORT_TOUCH_PAN_SPEED_COEFF, "touchReleaseMomentumFactor": EXPORT_TOUCH_RELEASE_MOMENTUM_FACTOR }, "scenes":{} };
    for (const [sceneId, data] of Object.entries(scenesData)) {
      config.scenes[sceneId] = { panorama: data.panorama, autoLoad: true, hotSpots: data.hotSpots.map((h, idx) => ({ pitch: h.pitch, yaw: h.yaw, type: "info", cssClass: "flat-arrow", createTooltipFunc: renderOrangeHotspot, createTooltipArgs: { i: idx, sourceSceneId: sceneId, targetSceneId: h.targetSceneId, target: h.target, targetName: h.target, targetSceneNumber: h.targetSceneNumber, targetIsAutoForward: h.targetIsAutoForward, sequenceNumber: h.sequenceNumber, viewFrame: h.viewFrame, targetYaw: h.targetYaw, targetPitch: h.targetPitch, isReturnLink: h.isReturnLink, returnViewFrame: h.returnViewFrame } })) };
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

    const LOGO_AREA_RATIO = 0.012;
    const LOGO_WIDTH_CAP_RATIO = 0.17;
    const LOGO_HEIGHT_CAP_RATIO = 0.095;
    const LOGO_PORTRAIT_AREA_MULTIPLIER = 1.55;
    const LOGO_PORTRAIT_WIDTH_CAP_RATIO = 0.22;
    const LOGO_PORTRAIT_HEIGHT_CAP_RATIO = 0.12;
    function syncExportLogoSize() {
      const stage = document.getElementById('stage');
      const logo = document.getElementById('export-watermark-image');
      if (!stage || !logo) return;
      const stageRect = stage.getBoundingClientRect();
      const stageWidth = stageRect.width || stage.clientWidth || 0;
      const stageHeight = stageRect.height || stage.clientHeight || 0;
      const naturalWidth = logo.naturalWidth || 0;
      const naturalHeight = logo.naturalHeight || 0;
      if (stageWidth <= 0 || stageHeight <= 0 || naturalWidth <= 0 || naturalHeight <= 0) return;
      const aspect = naturalWidth / naturalHeight;
      const targetArea = stageWidth * stageHeight * LOGO_AREA_RATIO;
      const rawHeight = Math.sqrt(targetArea / aspect);
      const rawWidth = rawHeight * aspect;
      const finalWidth = Math.min(rawWidth, stageWidth * LOGO_WIDTH_CAP_RATIO);
      const finalHeight = Math.min(rawHeight, stageHeight * LOGO_HEIGHT_CAP_RATIO, finalWidth / aspect);
      const portraitTargetArea =
        stageWidth * stageHeight * LOGO_AREA_RATIO * LOGO_PORTRAIT_AREA_MULTIPLIER;
      const portraitRawHeight = Math.sqrt(portraitTargetArea / aspect);
      const portraitRawWidth = portraitRawHeight * aspect;
      const portraitFinalWidth = Math.min(
        portraitRawWidth,
        stageWidth * LOGO_PORTRAIT_WIDTH_CAP_RATIO,
      );
      const portraitFinalHeight = Math.min(
        portraitRawHeight,
        stageHeight * LOGO_PORTRAIT_HEIGHT_CAP_RATIO,
        portraitFinalWidth / aspect,
      );
      stage.style.setProperty('--export-logo-width', finalWidth.toFixed(2) + 'px');
      stage.style.setProperty('--export-logo-height', finalHeight.toFixed(2) + 'px');
      stage.style.setProperty(
        '--export-logo-portrait-width',
        portraitFinalWidth.toFixed(2) + 'px',
      );
      stage.style.setProperty(
        '--export-logo-portrait-height',
        portraitFinalHeight.toFixed(2) + 'px',
      );
    }
    const setupExportLogoSizing = () => {
      const logo = document.getElementById('export-watermark-image');
      if (!logo) return;
      if (!logo.dataset.logoSizingBound) {
        logo.dataset.logoSizingBound = 'true';
        logo.addEventListener('load', syncExportLogoSize);
      }
      syncExportLogoSize();
    };

    const allowFileProtocol = ${if allowFileProtocol {
      "true"
    } else {
      "false"
    }};
    if (window.location.protocol === 'file:' && !allowFileProtocol) {
      updateExportStateClasses();
      setupExportLogoSizing();
      updateLookingModeUI();
      mountFileProtocolWarning();
    } else {
      updateExportStateClasses();
      updateLookingModeUI();
      window.viewer = pannellum.viewer('panorama', config); window.viewer.resize(); applyCurrentHfov();
      setupExportLogoSizing();
      window.addEventListener('resize', () => { updateExportStateClasses(); window.viewer?.resize(); applyCurrentHfov(); setupExportLogoSizing(); });
      ${TourScripts.loadEventScript}
    }
  </script></body></html>`
  html
}
