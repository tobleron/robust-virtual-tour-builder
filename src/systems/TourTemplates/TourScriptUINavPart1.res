let script = `
    function getPortraitModeSelectorPanel() {
      return document.getElementById("viewer-portrait-mode-selector-export");
    }
    function getSceneSequencePromptHost() {
      return document.getElementById("viewer-sequence-prompt-export");
    }
    function clearPortraitModeSelectorPanel(panel) {
      if (!panel) return;
      while (panel.firstChild) panel.removeChild(panel.firstChild);
      panel.classList.remove("is-portrait-adaptive-preview");
      panel.classList.remove("is-portrait-mode-selector");
      panel.classList.remove("state-intro");
      panel.classList.remove("state-collapsing");
      panel.classList.remove("state-docked");
      panel.classList.add("state-hidden");
      panel.setAttribute("aria-hidden", "true");
    }
    function getExportFloorLevelsInUse() {
      const activeFloorIds = new Set();
      if (scenesData && typeof scenesData === "object") {
        for (const sceneData of Object.values(scenesData)) {
          const floorId = normalizeSceneFloor(sceneData);
          if (floorId) activeFloorIds.add(floorId);
        }
      }
      return EXPORT_FLOOR_LEVELS.filter(level => activeFloorIds.has(level.id));
    }
    function updateExportFloorNav(sceneId) {
      const nav = document.getElementById("viewer-floor-nav-export");
      if (!nav) return;
      const shouldShowFloorNav =
        !(
          typeof isPortraitModeSelectorBlockingUi === "function" &&
          isPortraitModeSelectorBlockingUi()
        );
      const sceneData = scenesData[sceneId];
      const currentFloor = normalizeSceneFloor(sceneData);
      const visibleFloorLevels = getExportFloorLevelsInUse();
      nav.classList.toggle("state-interactive", shouldShowFloorNav && visibleFloorLevels.length > 0);
      nav.setAttribute("aria-hidden", shouldShowFloorNav && visibleFloorLevels.length > 0 ? "false" : "true");
      while (nav.firstChild) nav.removeChild(nav.firstChild);
      for (const level of visibleFloorLevels) {
        const btn = document.createElement("button");
        btn.type = "button";
        btn.className = "floor-nav-btn " + (level.id === currentFloor ? "state-active" : "state-idle");
        btn.setAttribute("title", level.label);
        btn.setAttribute("aria-label", level.label);
        btn.textContent = level.short;
        btn.addEventListener("click", () => {
          if (typeof navigateToFirstSceneInFloor === "function") {
            navigateToFirstSceneInFloor(level.id);
          }
        });
        if (level.suffix) {
          const suffix = document.createElement("sup");
          suffix.textContent = level.suffix;
          btn.appendChild(suffix);
        }
        nav.appendChild(btn);
      }
    }
    function clearPortraitJoystick() {
      const joystick = document.getElementById("viewer-portrait-joystick-export");
      if (!joystick) return;
      while (joystick.firstChild) joystick.removeChild(joystick.firstChild);
      joystick.classList.add("state-hidden");
      joystick.setAttribute("aria-hidden", "true");
    }
    function syncFloorTagShortcutState(sceneId, nextTarget, prevTarget) {
      const nextSceneId = nextTarget?.targetSceneId ?? null;
      const prevSceneId = prevTarget?.targetSceneId ?? null;
      floorTagShortcutState.sceneId = sceneId;
      floorTagShortcutState.nextSceneId = nextSceneId;
      floorTagShortcutState.prevSceneId = prevSceneId;
      floorTagShortcutState.nextHotspotIndex = nextSceneId ? nextTarget.hotspotIndex : null;
      floorTagShortcutState.nextSequenceNumber = nextSceneId ? nextTarget.sequenceCursorOverride : null;
      floorTagShortcutState.prevHotspotIndex = prevSceneId ? prevTarget.hotspotIndex : null;
      floorTagShortcutState.prevSequenceNumber = prevSceneId ? prevTarget.sequenceCursorOverride : null;
      floorTagShortcutState.prevUsesReturnLink = prevSceneId ? prevTarget?.usesReturnLink === true : false;
    }
    function resolvePortraitAutoOrbLabel() {
      if (!floorTagShortcutState.isAutoTourActive) return "Auto";
      return typeof isAutoTourSpeedBoosted === "function" && isAutoTourSpeedBoosted()
        ? "2x"
        : "1x";
    }
    function resolvePortraitModeOrbLines(mode) {
      const normalizedMode =
        typeof normalizePortraitNavigationMode === "function"
          ? normalizePortraitNavigationMode(mode)
          : mode;
      if (normalizedMode === EXPORT_NAVIGATION_MODE_MANUAL) {
        return { primary: "Manual", secondary: "" };
      }
      if (normalizedMode === EXPORT_NAVIGATION_MODE_AUTO) {
        return { primary: resolvePortraitAutoOrbLabel(), secondary: "" };
      }
      return { primary: "Semi", secondary: "Auto" };
    }
    function refreshExportNavigationUi() {
      if (typeof syncPortraitModeSelectorClasses === "function") {
        syncPortraitModeSelectorClasses();
      }
      if (typeof renderMapSequencePromptPanel === "function") {
        renderMapSequencePromptPanel();
      }
      const sid = window.viewer?.getScene?.() ?? floorTagShortcutState.sceneId;
      if (sid && typeof updateNavShortcutsV2 === "function") {
        updateNavShortcutsV2(sid, true);
      }
    }
    function activateExportNavigationMode(mode) {
      const normalizedMode =
        typeof normalizePortraitNavigationMode === "function"
          ? normalizePortraitNavigationMode(mode)
          : mode;
      if (
        normalizedMode !== EXPORT_NAVIGATION_MODE_MANUAL &&
        normalizedMode !== EXPORT_NAVIGATION_MODE_SEMI_AUTO
      ) {
        return false;
      }
      if (typeof setPortraitBaseNavigationMode === "function") {
        setPortraitBaseNavigationMode(normalizedMode);
      }
      if (floorTagShortcutState.isAutoTourActive && typeof stopAutoTour === "function") {
        stopAutoTour();
        return true;
      }
      refreshExportNavigationUi();
      return true;
    }
    function triggerAutoNavigationMode() {
      if (autoTourHomeReturnCountdownRemaining > 0) return false;
      if (!floorTagShortcutState.isAutoTourActive) {
        if (typeof startAutoTour === "function") startAutoTour();
        return true;
      }
      if (typeof speedUpAutoTour === "function") {
        return speedUpAutoTour();
      }
      return false;
    }
    function handlePortraitModeSelectorClick(mode, event) {
      if (typeof event?.preventDefault === "function") event.preventDefault();
      if (typeof event?.stopPropagation === "function") event.stopPropagation();
      const normalizedMode =
        typeof normalizePortraitNavigationMode === "function"
          ? normalizePortraitNavigationMode(mode)
          : mode;
      const shouldCollapseIntro =
        typeof isPortraitModeSelectorIntroVisible === "function" &&
        isPortraitModeSelectorIntroVisible();

      if (normalizedMode === EXPORT_NAVIGATION_MODE_AUTO) {
        if (autoTourHomeReturnCountdownRemaining > 0) return;
        if (
          typeof shouldIgnorePortraitAutoOrbTap === "function" &&
          shouldIgnorePortraitAutoOrbTap()
        ) {
          return;
        }
        if (!floorTagShortcutState.isAutoTourActive) {
          if (shouldCollapseIntro && typeof collapsePortraitModeSelectorIntro === "function") {
            collapsePortraitModeSelectorIntro();
          }
          return triggerAutoNavigationMode();
        }
        return triggerAutoNavigationMode();
      }

      activateExportNavigationMode(normalizedMode);
      if (shouldCollapseIntro && typeof collapsePortraitModeSelectorIntro === "function") {
        collapsePortraitModeSelectorIntro();
        return;
      }
      refreshExportNavigationUi();
    }
    function updatePortraitJoystick() {
      const joystick = document.getElementById("viewer-portrait-joystick-export");
      if (!joystick) return;
      while (joystick.firstChild) joystick.removeChild(joystick.firstChild);
      if (
        !(
          typeof isTouchFriendlyExportUi === "function" && isTouchFriendlyExportUi()
        ) ||
        isExportMapOpen() ||
        (
          typeof isPortraitModeSelectorBlockingUi === "function" &&
          isPortraitModeSelectorBlockingUi()
        ) ||
        autoTourHomeReturnCountdownRemaining > 0
      ) {
        joystick.classList.add("state-hidden");
        joystick.setAttribute("aria-hidden", "true");
        return;
      }
      joystick.classList.remove("state-hidden");
      joystick.setAttribute("aria-hidden", "false");
      const createButton = (direction, enabled, onClick) => {
        const btn = document.createElement("button");
        btn.type = "button";
        btn.className =
          "portrait-joystick-btn state-" +
          direction +
          " " +
          (enabled ? "state-enabled state-active" : "state-disabled");
        btn.setAttribute("aria-label", direction === "up" ? "Go forward" : "Go back");
        btn.disabled = !enabled;

        const icon = document.createElementNS("http://www.w3.org/2000/svg", "svg");
        icon.setAttribute("class", "portrait-joystick-icon");
        icon.setAttribute("viewBox", "0 0 24 24");
        icon.setAttribute("fill", "none");

        const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
        path.setAttribute("d", "M5 12h14M12 5l7 7-7 7");
        icon.appendChild(path);
        btn.appendChild(icon);

        if (enabled) {
          btn.addEventListener("click", onClick);
        }
        return btn;
      };
      const nextEnabled = !!floorTagShortcutState.nextSceneId && !floorTagShortcutState.isAutoTourActive;
      const prevEnabled =
        !!floorTagShortcutState.prevSceneId &&
        floorTagShortcutState.prevSceneId !== floorTagShortcutState.sceneId &&
        !floorTagShortcutState.isAutoTourActive;
      joystick.appendChild(
        createButton("up", nextEnabled, () => {
          if (typeof stopAutoTour === "function") stopAutoTour();
          if (typeof navigateToNextSequenceShortcut === "function") {
            navigateToNextSequenceShortcut();
          }
        }),
      );
      joystick.appendChild(
        createButton("down", prevEnabled, () => {
          if (typeof stopAutoTour === "function") stopAutoTour();
          if (typeof navigateToPreviousSequenceShortcut === "function") {
            navigateToPreviousSequenceShortcut();
          }
        }),
      );
    }
    function renderPortraitAdaptiveShortcutPanel(panel) {
      if (!panel) return;
      while (panel.firstChild) panel.removeChild(panel.firstChild);
      panel.classList.remove("state-hidden");
      panel.classList.remove("is-portrait-adaptive-preview");
      panel.classList.add("is-portrait-mode-selector");
      const isIntroVisible =
        typeof isPortraitModeSelectorIntroVisible === "function" &&
        isPortraitModeSelectorIntroVisible();
      const isTransitioning =
        typeof isPortraitModeSelectorTransitioning === "function" &&
        isPortraitModeSelectorTransitioning();
      panel.classList.toggle("state-intro", isIntroVisible);
      panel.classList.toggle("state-collapsing", isTransitioning);
      panel.classList.toggle("state-docked", !isIntroVisible && !isTransitioning);
      panel.setAttribute("aria-hidden", "false");

      const title = document.createElement("div");
      title.className = "portrait-mode-selector-title";
      title.textContent = "Choose tour mode:";
      panel.appendChild(title);

      const cluster = document.createElement("div");
      cluster.className = "portrait-mode-selector-cluster";
      const createModeOrb = mode => {
        const orb = document.createElement("button");
        orb.type = "button";
        const normalizedMode =
          typeof normalizePortraitNavigationMode === "function"
            ? normalizePortraitNavigationMode(mode)
            : mode;
        const activeMode =
          typeof resolveActivePortraitNavigationMode === "function"
            ? resolveActivePortraitNavigationMode()
            : normalizedMode;
        const isActive = activeMode === normalizedMode;
        const isBoosted =
          normalizedMode === EXPORT_NAVIGATION_MODE_AUTO &&
          typeof isAutoTourSpeedBoosted === "function" &&
          isAutoTourSpeedBoosted();
        orb.className =
          "portrait-mode-orb state-" +
          String(normalizedMode).replace(/[^a-z0-9]+/gi, "-") +
          (isActive ? " state-active" : " state-idle") +
          (isBoosted ? " state-boosted" : "");
        orb.setAttribute(
          "aria-label",
          normalizedMode === EXPORT_NAVIGATION_MODE_SEMI_AUTO
            ? "Semi-Auto mode"
            : normalizedMode === EXPORT_NAVIGATION_MODE_MANUAL
              ? "Manual mode"
              : "Auto mode",
        );
        orb.disabled =
          normalizedMode === EXPORT_NAVIGATION_MODE_AUTO &&
          autoTourHomeReturnCountdownRemaining > 0;
        const labelLines = resolvePortraitModeOrbLines(normalizedMode);
        const primary = document.createElement("span");
        primary.className = "portrait-mode-orb-line portrait-mode-orb-line-primary";
        primary.textContent = labelLines.primary;
        orb.appendChild(primary);
        if (labelLines.secondary !== "") {
          const secondary = document.createElement("span");
          secondary.className = "portrait-mode-orb-line portrait-mode-orb-line-secondary";
          secondary.textContent = labelLines.secondary;
          orb.appendChild(secondary);
        }
        if (!orb.disabled) {
          orb.addEventListener("click", event => {
            handlePortraitModeSelectorClick(normalizedMode, event);
          });
        }
        return orb;
      };
      cluster.appendChild(createModeOrb(EXPORT_NAVIGATION_MODE_SEMI_AUTO));
      cluster.appendChild(createModeOrb(EXPORT_NAVIGATION_MODE_MANUAL));
      cluster.appendChild(createModeOrb(EXPORT_NAVIGATION_MODE_AUTO));
      panel.appendChild(cluster);
      if (
        typeof isTouchFriendlyExportUi === "function" &&
        isTouchFriendlyExportUi() &&
        autoTourHomeReturnCountdownRemaining > 0
      ) {
        const countdown = document.createElement("div");
        countdown.className = "portrait-mode-selector-countdown";
        countdown.setAttribute("aria-live", "polite");

        const countdownLabel = document.createElement("span");
        countdownLabel.className = "portrait-mode-selector-countdown-label";
        countdownLabel.textContent = "Returning home";
`
