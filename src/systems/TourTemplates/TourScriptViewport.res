let script = `
    let exportViewportState = "";
    let exportTouchDevice = false;
    let exportInteractionShell = "classic";
    let exportPortraitHfovCacheKey = "";
    let exportPortraitHfovCacheValue = null;
    let exportFormulaHfovObserversInstalled = false;
    let exportFormulaHfovUpdateQueued = false;
    let exportFormulaResizeObserver = null;
    let exportLastAppliedHfov = null;
    function clampExportMetric(value, min, max) {
      return Math.max(min, Math.min(max, value));
    }
    function lerpExportMetric(from, to, amount) {
      return from + ((to - from) * amount);
    }
    function smoothstepExportMetric(edge0, edge1, value) {
      if (edge0 === edge1) return 1.0;
      const t = clampExportMetric((value - edge0) / (edge1 - edge0), 0, 1);
      return t * t * (3 - 2 * t);
    }
    function clearFormulaPortraitHfovCache() {
      exportPortraitHfovCacheKey = "";
      exportPortraitHfovCacheValue = null;
    }
    function getStageLayoutMetrics() {
      const stage = document.getElementById("stage");
      const rect = stage?.getBoundingClientRect?.();
      const stageWidth = Number.isFinite(rect?.width) && rect.width > 0 ? rect.width : STAGE_MIN_WIDTH;
      const fallbackStageHeight = STAGE_MIN_WIDTH * (16.0 / 9.0);
      const stageHeight = Number.isFinite(rect?.height) && rect.height > 0
        ? rect.height
        : fallbackStageHeight;
      return { stageWidth, stageHeight };
    }
    function computeFormulaPortraitHfov(stageWidth, stageHeight) {
      const effectivePortraitWidth = Math.min(stageWidth, stageHeight * (9.0 / 16.0));
      const clampedWidth = clampExportMetric(effectivePortraitWidth, 375.0, 700.0);
      const portraitMaxHfov = clampExportMetric(Math.floor((MAX_HFOV * 0.93) * 10.0) / 10.0, MIN_HFOV, MAX_HFOV);
      if (clampedWidth <= 493.0) {
        return lerpExportMetric(65.0, 72.0, smoothstepExportMetric(375.0, 493.0, clampedWidth));
      }
      if (clampedWidth <= 607.0) {
        return lerpExportMetric(72.0, 78.0, smoothstepExportMetric(493.0, 607.0, clampedWidth));
      }
      return lerpExportMetric(78.0, portraitMaxHfov, smoothstepExportMetric(607.0, 700.0, clampedWidth));
    }
    // Rollback-only legacy path retained for manual recovery if the formula ever needs to be reverted.
    function getLegacyTieredPortraitHfov() {
      const stage = document.getElementById("stage");
      const stageWidth = stage?.getBoundingClientRect?.().width;
      const effectiveStageWidth =
        Number.isFinite(stageWidth) && stageWidth > 0 ? stageWidth : STAGE_MIN_WIDTH;
      const portraitMaxHfov = clampExportMetric(Math.floor((MAX_HFOV * 0.93) * 10.0) / 10.0, MIN_HFOV, MAX_HFOV);
      if (effectiveStageWidth >= 700) return portraitMaxHfov;
      if (effectiveStageWidth >= 600) return clampExportMetric(78.0, MIN_HFOV, portraitMaxHfov);
      if (effectiveStageWidth >= 480) return clampExportMetric(72.0, MIN_HFOV, portraitMaxHfov);
      return MIN_HFOV;
    }
    function updateTouchFriendlyOrbMetrics() {
      if (!document || !document.documentElement) return;
      const stage = document.getElementById("stage");
      const stageWidth = stage?.getBoundingClientRect?.().width;
      const stageHeight = stage?.getBoundingClientRect?.().height;
      const effectiveStageWidth =
        Number.isFinite(stageWidth) && stageWidth > 0 ? stageWidth : STAGE_MAX_WIDTH;
      const fallbackStageHeight = STAGE_MAX_WIDTH * (10.0 / 16.0);
      const effectiveStageHeight =
        Number.isFinite(stageHeight) && stageHeight > 0 ? stageHeight : fallbackStageHeight;
      const referenceStageArea = 832.0 * 520.0;
      const scale = Math.sqrt(
        (effectiveStageWidth * effectiveStageHeight) / referenceStageArea,
      );
      const orbSizePx = Math.round(clampExportMetric(48.0 * scale, 40.0, 60.0));
      const orbIconSizePx = Math.round(clampExportMetric(13.0 * scale, 11.0, 16.0));
      const primaryFontPx = Math.round(clampExportMetric(10.0 * scale, 8.0, 12.0));
      const secondaryFontPx = Math.round(clampExportMetric(9.0 * scale, 7.0, 11.0));
      const titleFontPx = Math.round(clampExportMetric(22.0 * scale, 18.0, 28.0));
      const floorButtonSizePx = Math.round(clampExportMetric(34.0 * scale, 28.0, 42.0));
      const floorButtonFontPx = Math.round(clampExportMetric(13.0 * scale, 10.0, 15.0));
      const floorButtonSupPx = Math.round(clampExportMetric(7.0 * scale, 6.0, 9.0));
      const orbGapPx = Math.round(clampExportMetric(8.0 * scale, 6.0, 10.0));
      const introGapPx = Math.round(clampExportMetric(14.0 * scale, 10.0, 18.0));
      const collapsedGapPx = Math.round(clampExportMetric(10.0 * scale, 8.0, 14.0));
      const railLeftPx = Math.round(clampExportMetric(13.0 * scale, 10.0, 18.0));
      const dockedTopPx = Math.round(clampExportMetric(12.0 * scale, 10.0, 18.0));
      const dockedOrbLeftPx = railLeftPx;
      const floorBottomPx = Math.round(clampExportMetric(20.0 * scale, 12.0, 28.0));
      const root = document.documentElement.style;
      root.setProperty("--export-touch-orb-size", orbSizePx + "px");
      root.setProperty("--export-touch-orb-icon-size", orbIconSizePx + "px");
      root.setProperty("--export-touch-orb-font-primary", primaryFontPx + "px");
      root.setProperty("--export-touch-orb-font-secondary", secondaryFontPx + "px");
      root.setProperty("--export-touch-mode-title-size", titleFontPx + "px");
      root.setProperty("--export-touch-floor-btn-size", floorButtonSizePx + "px");
      root.setProperty("--export-touch-floor-btn-font-size", floorButtonFontPx + "px");
      root.setProperty("--export-touch-floor-btn-sup-size", floorButtonSupPx + "px");
      root.setProperty("--export-touch-orb-gap", orbGapPx + "px");
      root.setProperty("--export-touch-orb-intro-gap", introGapPx + "px");
      root.setProperty("--export-touch-orb-collapsed-gap", collapsedGapPx + "px");
      root.setProperty("--export-touch-rail-left", railLeftPx + "px");
      root.setProperty("--export-touch-docked-top", dockedTopPx + "px");
      root.setProperty("--export-touch-docked-orb-left", dockedOrbLeftPx + "px");
      root.setProperty("--export-touch-floor-bottom", floorBottomPx + "px");
    }
    function syncExportAdaptiveUiForCurrentScene() {
      const sceneId = window.viewer?.getScene?.() ?? null;
      if (sceneId) {
        if (typeof updateExportFloorNav === "function") updateExportFloorNav(sceneId);
        if (typeof updateNavShortcutsV2 === "function") updateNavShortcutsV2(sceneId, true);
        return;
      }
      if (typeof clearPortraitJoystick === "function") clearPortraitJoystick();
    }
    function detectTouchPrimaryInput() {
      const nav = window.navigator;
      const maxTouchPoints = typeof nav?.maxTouchPoints === "number" ? nav.maxTouchPoints : 0;
      const hasCoarsePointer = typeof window.matchMedia === "function"
        ? window.matchMedia("(pointer: coarse)").matches || window.matchMedia("(any-pointer: coarse)").matches
        : false;
      const hasNoHover = typeof window.matchMedia === "function"
        ? window.matchMedia("(hover: none)").matches || window.matchMedia("(any-hover: none)").matches
        : false;
      return maxTouchPoints > 0 || hasCoarsePointer || hasNoHover;
    }
    function isExportTouchDevice() {
      return exportTouchDevice === true;
    }
    function resolveExportInteractionShell() {
      const forcedShell =
        typeof FORCED_EXPORT_INTERACTION_SHELL === "string"
          ? FORCED_EXPORT_INTERACTION_SHELL
          : "";
      if (
        forcedShell === "classic" ||
        forcedShell === "portrait-adaptive" ||
        forcedShell === "landscape-touch"
      ) {
        return forcedShell;
      }
      const viewportState = resolveExportViewportState();
      if (viewportState === "portrait") return "portrait-adaptive";
      if (detectTouchPrimaryInput()) return "landscape-touch";
      return "classic";
    }
    function isTouchFriendlyExportUi() {
      const interactionShell =
        exportInteractionShell === "" ? resolveExportInteractionShell() : exportInteractionShell;
      return interactionShell === "portrait-adaptive" || interactionShell === "landscape-touch";
    }
    function isPortraitAdaptiveExportUi() {
      const interactionShell =
        exportInteractionShell === "" ? resolveExportInteractionShell() : exportInteractionShell;
      return interactionShell === "portrait-adaptive";
    }
    function isLandscapeTouchExportUi() {
      const interactionShell =
        exportInteractionShell === "" ? resolveExportInteractionShell() : exportInteractionShell;
      return interactionShell === "landscape-touch";
    }
    function resolveExportViewportState() {
      const portraitViewport = window.innerHeight > window.innerWidth;
      if (portraitViewport) return "portrait";
      return "desktop";
    }
    function isCompactLandscapeTouch() {
      const interactionShell =
        exportInteractionShell === "" ? resolveExportInteractionShell() : exportInteractionShell;
      if (interactionShell !== "landscape-touch") return false;
      const stage = document.getElementById("stage");
      const stageHeight = stage?.getBoundingClientRect?.().height;
      const effectiveStageHeight =
        Number.isFinite(stageHeight) && stageHeight > 0 ? stageHeight : STAGE_MAX_WIDTH * (10.0 / 16.0);
      const stageWidth = stage?.getBoundingClientRect?.().width;
      const effectiveStageWidth =
        Number.isFinite(stageWidth) && stageWidth > 0 ? stageWidth : STAGE_MAX_WIDTH;
      const aspectRatio = effectiveStageWidth / effectiveStageHeight;
      const isShortHeight = effectiveStageHeight < 420;
      const isNarrowLandscape = aspectRatio > 1.8 && effectiveStageHeight < 480;
      return isShortHeight || isNarrowLandscape;
    }
    function updateExportStateClasses() {
      const nextState = resolveExportViewportState();
      const nextInteractionShell = resolveExportInteractionShell();
      exportViewportState = nextState;
      exportInteractionShell = nextInteractionShell;
      exportTouchDevice = detectTouchPrimaryInput();
      if (!document || !document.body) return nextState;
      const previousTouchFriendlyUi =
        document.body.classList.contains("export-ui-portrait-adaptive") ||
        document.body.classList.contains("export-ui-landscape-touch");
      const nextPortraitAdaptiveUi = nextInteractionShell === "portrait-adaptive";
      const nextLandscapeTouchUi = nextInteractionShell === "landscape-touch";
      const nextTouchFriendlyUi = nextPortraitAdaptiveUi || nextLandscapeTouchUi;
      const nextCompactLandscape = nextLandscapeTouchUi && isCompactLandscapeTouch();
      document.body.classList.remove("export-state-desktop");
      document.body.classList.remove("export-state-portrait");
      document.body.classList.remove("is-touch-device");
      document.body.classList.remove("export-ui-portrait-adaptive");
      document.body.classList.remove("export-ui-landscape-touch");
      document.body.classList.remove("export-ui-landscape-touch-compact");
      document.body.classList.remove("export-shell-classic");
      document.body.classList.remove("export-shell-portrait-adaptive");
      document.body.classList.remove("export-shell-landscape-touch");
      document.body.classList.add("export-state-" + nextState);
      document.body.classList.add("export-shell-" + nextInteractionShell);
      if (exportTouchDevice) {
        document.body.classList.add("is-touch-device");
      }
      if (nextPortraitAdaptiveUi) {
        document.body.classList.add("export-ui-portrait-adaptive");
      }
      if (nextLandscapeTouchUi) {
        document.body.classList.add("export-ui-landscape-touch");
      }
      if (nextCompactLandscape) {
        document.body.classList.add("export-ui-landscape-touch-compact");
      }

      if (typeof ensurePortraitModeSelectorForViewport === "function") {
        ensurePortraitModeSelectorForViewport(previousTouchFriendlyUi, nextTouchFriendlyUi);
      }

      if (typeof IS_HD_EXPORT === 'boolean' && IS_HD_EXPORT) {
        document.body.classList.add("is-hd-export");
      }

      if (previousTouchFriendlyUi !== nextTouchFriendlyUi) {
        setTimeout(() => {
          if (typeof syncExportAdaptiveUiForCurrentScene === "function") {
            syncExportAdaptiveUiForCurrentScene();
          }
        }, 0);
      }

      updateTouchFriendlyOrbMetrics();

      if (nextState !== "portrait") {
        clearFormulaPortraitHfovCache();
      }

      return nextState;
    }
    function getAdaptivePortraitHfov() {
      const metrics = getStageLayoutMetrics();
      const cacheKey =
        Math.round(metrics.stageWidth) + "x" + Math.round(metrics.stageHeight) + ":" + exportViewportState;
      if (exportPortraitHfovCacheKey === cacheKey && exportPortraitHfovCacheValue !== null) {
        return exportPortraitHfovCacheValue;
      }
      const nextHfov = computeFormulaPortraitHfov(metrics.stageWidth, metrics.stageHeight);
      exportPortraitHfovCacheKey = cacheKey;
      exportPortraitHfovCacheValue = nextHfov;
      return nextHfov;
    }
    function getCurrentHfov() {
      const state = exportViewportState === "" ? updateExportStateClasses() : exportViewportState;
      return state === "portrait" ? getAdaptivePortraitHfov() : MAX_HFOV;
    }
    const TRIPOD_DEAD_ZONE_ENABLED = __TRIPOD_DEAD_ZONE_ENABLED__;
    function getTripodSafePitchBounds() {
      if (!TRIPOD_DEAD_ZONE_ENABLED) {
        return { minPitch: -90.0, maxPitch: 90.0 };
      }
      const stage = document.getElementById("stage");
      const rect = stage?.getBoundingClientRect?.();
      const stageWidth = Number.isFinite(rect?.width) && rect.width > 0 ? rect.width : STAGE_MIN_WIDTH;
      const fallbackStageHeight = STAGE_MIN_WIDTH * (16.0 / 9.0);
      const stageHeight = Number.isFinite(rect?.height) && rect.height > 0
        ? rect.height
        : fallbackStageHeight;
      const aspectRatio = stageWidth > 0 && stageHeight > 0 ? stageWidth / stageHeight : (16.0 / 9.0);
      const safeAspectRatio = Number.isFinite(aspectRatio) && aspectRatio > 0 ? aspectRatio : (16.0 / 9.0);
      const hfov = getCurrentHfov();
      const vfov = 2.0 * Math.atan(Math.tan((hfov * Math.PI / 180.0) / 2.0) / safeAspectRatio) * 180.0 / Math.PI;
      const safetyMargin = safeAspectRatio < 1.0 ? TRIPOD_DEAD_ZONE_PORTRAIT_SAFETY_MARGIN : 0.0;
      const minPitch = TRIPOD_DEAD_ZONE_REFERENCE_PITCH - (vfov / 2.0) + safetyMargin;
      return { minPitch, maxPitch: TRIPOD_DEAD_ZONE_MAX_PITCH };
    }
    const TRIPOD_DEAD_ZONE_REFERENCE_PITCH = -30.0;
    const TRIPOD_DEAD_ZONE_PORTRAIT_SAFETY_MARGIN = 14.0;
    const TRIPOD_DEAD_ZONE_MAX_PITCH = 90.0;
    function applyTripodPitchBounds() {
      if (!window.viewer || typeof window.viewer.setPitchBounds !== "function") return;
      if (!TRIPOD_DEAD_ZONE_ENABLED) {
        window.viewer.setPitchBounds([-90.0, 90.0]);
        return;
      }
      const bounds = getTripodSafePitchBounds();
      window.viewer.setPitchBounds([bounds.minPitch, bounds.maxPitch]);
    }
    function scheduleFormulaHfovUpdate() {
      if (exportFormulaHfovUpdateQueued) return;
      exportFormulaHfovUpdateQueued = true;
      const run = () => {
        exportFormulaHfovUpdateQueued = false;
        applyCurrentHfov();
      };
      if (typeof window.requestAnimationFrame === "function") {
        window.requestAnimationFrame(run);
      } else {
        setTimeout(run, 0);
      }
    }
    function installFormulaHfovObservers() {
      if (exportFormulaHfovObserversInstalled) return;
      const stage = document.getElementById("stage");
      if (!stage) return;
      exportFormulaHfovObserversInstalled = true;
      if (typeof ResizeObserver === "function") {
        exportFormulaResizeObserver = new ResizeObserver(() => scheduleFormulaHfovUpdate());
        exportFormulaResizeObserver.observe(stage);
      }
      window.addEventListener("orientationchange", scheduleFormulaHfovUpdate, { passive: true });
      window.addEventListener("resize", scheduleFormulaHfovUpdate, { passive: true });
    }
    function applyCurrentHfov() {
      updateExportStateClasses();
      installFormulaHfovObservers();
      if (!window.viewer || typeof window.viewer.setHfov !== "function") return;
      const nextHfov = getCurrentHfov();
      const shouldSetHfov =
        typeof exportLastAppliedHfov !== "number" || Math.abs(exportLastAppliedHfov - nextHfov) >= 0.01;
      if (typeof window.viewer.setHfovBounds === "function") {
        if (typeof isTouchFriendlyExportUi === "function" && isTouchFriendlyExportUi()) {
          window.viewer.setHfovBounds([nextHfov, nextHfov]);
        } else {
          window.viewer.setHfovBounds([MIN_HFOV, MAX_HFOV]);
        }
      }
      if (typeof window.viewer.resize === "function") window.viewer.resize();
      if (shouldSetHfov) {
        window.viewer.setHfov(nextHfov, false);
        exportLastAppliedHfov = nextHfov;
      }
      applyTripodPitchBounds();
      // Double trigger to catch late layout paint
      setTimeout(() => { if (window.viewer && window.viewer.resize) window.viewer.resize(); }, 50);
    }
`
