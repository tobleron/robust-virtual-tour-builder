let script = `
    let exportViewportState = "";
    let exportTouchDevice = false;
    let exportInteractionShell = "classic";
    function clampExportMetric(value, min, max) {
      return Math.max(min, Math.min(max, value));
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
      const portraitViewport = window.innerHeight > window.innerWidth || window.innerWidth <= 720;
      if (portraitViewport) return "portrait";
      return "desktop";
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
      document.body.classList.remove("export-state-desktop");
      document.body.classList.remove("export-state-portrait");
      document.body.classList.remove("is-touch-device");
      document.body.classList.remove("export-ui-portrait-adaptive");
      document.body.classList.remove("export-ui-landscape-touch");
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

      return nextState;
    }
    function getAdaptivePortraitHfov() {
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
    function getCurrentHfov() {
      const state = exportViewportState === "" ? updateExportStateClasses() : exportViewportState;
      return state === "portrait" ? getAdaptivePortraitHfov() : MAX_HFOV;
    }
    function applyCurrentHfov() {
      updateExportStateClasses();
      if (!window.viewer || typeof window.viewer.setHfov !== "function") return;
      const nextHfov = getCurrentHfov();
      if (typeof window.viewer.setHfovBounds === "function") {
        if (typeof isTouchFriendlyExportUi === "function" && isTouchFriendlyExportUi()) {
          window.viewer.setHfovBounds([nextHfov, nextHfov]);
        } else {
          window.viewer.setHfovBounds([MIN_HFOV, MAX_HFOV]);
        }
      }
      if (typeof window.viewer.resize === "function") window.viewer.resize();
      window.viewer.setHfov(nextHfov, false);
      // Double trigger to catch late layout paint
      setTimeout(() => { if (window.viewer && window.viewer.resize) window.viewer.resize(); }, 50);
    }
`
