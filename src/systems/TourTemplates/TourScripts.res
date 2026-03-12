let renderScriptTemplate =
  TourScriptCore.script ++
  TourScriptViewport.script ++
  TourScriptNavigation.script ++
  TourScriptUI.script ++
  TourScriptInput.script ++
  TourScriptHotspots.script

let loadEventScript = `
    window.viewer.on('load', function() {
      const sid = window.viewer.getScene(); const sd = scenesData[sid];
      if (!transitionFrom && !isFirstLoad && !window.isAutoTourActive) return;
      if (sd?.hotSpots?.length > 0) applyCurrentHfov();
      persistentFrom = transitionFrom; transitionFrom = null; isFirstLoad = false;
      if (typeof applyPendingSequenceContext === "function") applyPendingSequenceContext(sid);
      updateExportFloorNav(sid);
      const suppressRoomLabelOnThisLoad = suppressNextRoomLabelOnLoad === true;
      suppressNextRoomLabelOnLoad = false;
      suppressShortcutPanelUntilNextLoad = false;
      if (suppressRoomLabelOnThisLoad) {
        updateExportRoomLabel("", false);
        pendingShortcutLabelSceneId = null;
      } else {
        const animateRoomLabel = pendingShortcutLabelSceneId === sid;
        updateExportRoomLabel(sid, animateRoomLabel);
        pendingShortcutLabelSceneId = null;
      }
      updateNavShortcutsV2(sid, true);
      updateExportStateClasses();
      updateLookingModeUI();
      clearWaypointRuntime();
      waypointRuntime.sceneId = sid;
      animateSceneToPrimaryHotspot(sid, 20);
    });
  `

let generateRenderScript = (
  baseSize,
  defaultHfov,
  minHfov,
  maxHfov,
  stageMinWidth,
  stageMaxWidth,
  dynamicHfovEnabled,
  isHdExport,
  ~exportTraversalMode: string="legacy",
  ~allowTabletLandscapeStage: bool=true,
) =>
  renderScriptTemplate
  ->String.replaceRegExp(/__BASE_SIZE__/g, Belt.Int.toString(baseSize))
  ->String.replaceRegExp(/__DEFAULT_HFOV__/g, Belt.Float.toString(defaultHfov))
  ->String.replaceRegExp(/__MIN_HFOV__/g, Belt.Float.toString(minHfov))
  ->String.replaceRegExp(/__MAX_HFOV__/g, Belt.Float.toString(maxHfov))
  ->String.replaceRegExp(/__STAGE_MIN_WIDTH__/g, Belt.Int.toString(stageMinWidth))
  ->String.replaceRegExp(/__STAGE_MAX_WIDTH__/g, Belt.Int.toString(stageMaxWidth))
  ->String.replaceRegExp(/__DYNAMIC_HFOV_ENABLED__/g, dynamicHfovEnabled ? "true" : "false")
  ->String.replaceRegExp(/__IS_HD_EXPORT__/g, isHdExport ? "true" : "false")
  ->String.replaceRegExp(
    /__EXPORT_ALLOW_TABLET_LANDSCAPE_STAGE__/g,
    allowTabletLandscapeStage ? "true" : "false",
  )
  ->String.replaceRegExp(/__EXPORT_TRAVERSAL_MODE__/g, exportTraversalMode)
