let script = `
    let exportViewportState = "";
    let exportTouchDevice = false;
    let exportInteractionShell = "classic";
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
      const viewportState = resolveExportViewportState();
      if (viewportState === "portrait") return "portrait-adaptive";
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
    function resolveExportViewportState() {
      const portraitViewport = window.innerHeight > window.innerWidth || window.innerWidth <= 720;
      if (portraitViewport) return "portrait";
      if (!EXPORT_ALLOW_TABLET_LANDSCAPE_STAGE) return "desktop";
      // Allow desktop mode if viewport is at least 60px wider than the stage max width
      if (window.innerWidth >= (STAGE_MAX_WIDTH + 60)) return "desktop";
      return "tablet";
    }
    function updateExportStateClasses() {
      const nextState = resolveExportViewportState();
      const nextInteractionShell = resolveExportInteractionShell();
      exportViewportState = nextState;
      exportInteractionShell = nextInteractionShell;
      exportTouchDevice = detectTouchPrimaryInput();
      if (!document || !document.body) return nextState;
      const previousPortraitAdaptiveUi = document.body.classList.contains("export-ui-portrait-adaptive");
      const nextPortraitAdaptiveUi = nextState === "portrait";
      document.body.classList.remove("export-state-desktop");
      document.body.classList.remove("export-state-tablet");
      document.body.classList.remove("export-state-portrait");
      document.body.classList.remove("is-touch-device");
      document.body.classList.remove("export-ui-portrait-adaptive");
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

      if (typeof ensurePortraitModeSelectorForViewport === "function") {
        ensurePortraitModeSelectorForViewport(previousPortraitAdaptiveUi, nextPortraitAdaptiveUi);
      }

      if (typeof IS_HD_EXPORT === 'boolean' && IS_HD_EXPORT) {
        document.body.classList.add("is-hd-export");
      }

      if (previousPortraitAdaptiveUi !== nextPortraitAdaptiveUi) {
        setTimeout(() => {
          if (typeof syncExportAdaptiveUiForCurrentScene === "function") {
            syncExportAdaptiveUiForCurrentScene();
          }
        }, 0);
      }

      return nextState;
    }
    function getCurrentHfov() {
      const state = exportViewportState === "" ? updateExportStateClasses() : exportViewportState;
      return state === "portrait" ? MIN_HFOV : MAX_HFOV;
    }
    function applyCurrentHfov() {
      updateExportStateClasses();
      if (!window.viewer || typeof window.viewer.setHfov !== "function") return;
      if (typeof window.viewer.resize === "function") window.viewer.resize();
      window.viewer.setHfov(getCurrentHfov(), false);
      // Double trigger to catch late layout paint
      setTimeout(() => { if (window.viewer && window.viewer.resize) window.viewer.resize(); }, 50);
    }
`
