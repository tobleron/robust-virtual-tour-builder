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

        const countdownNumber = document.createElement("span");
        countdownNumber.className = "portrait-mode-selector-countdown-number";
        countdownNumber.textContent = String(autoTourHomeReturnCountdownRemaining);

        countdown.appendChild(countdownLabel);
        countdown.appendChild(countdownNumber);
        panel.appendChild(countdown);
      }
      if (typeof syncPortraitModeSelectorClasses === "function") {
        syncPortraitModeSelectorClasses();
      }
      updatePortraitJoystick();
    }
    function updateExportRoomLabel(sceneId, animateOnShow) {
      const labelEl = document.getElementById("viewer-room-label-export");
      if (!labelEl) return;
      labelEl.classList.remove("state-shortcut-animate");
      const clearLabel = () => {
        while (labelEl.firstChild) labelEl.removeChild(labelEl.firstChild);
        labelEl.classList.remove("state-shortcut-animate");
        labelEl.classList.remove("state-visible");
        labelEl.classList.add("state-hidden");
      };
      const getSceneNumber = sid => {
        const rawSceneNumber = scenesData?.[sid]?.sceneNumber;
        return Number.isInteger(rawSceneNumber) && rawSceneNumber >= 1 ? rawSceneNumber : null;
      };
      const rawLabel = typeof scenesData[sceneId]?.label === "string" ? scenesData[sceneId].label.trim() : "";
      if (rawLabel !== "") {
        while (labelEl.firstChild) labelEl.removeChild(labelEl.firstChild);
        const seqNo = getSceneNumber(sceneId);
        const seqEl = document.createElement("span");
        seqEl.className = "viewer-persistent-label-export-seq";
        seqEl.textContent = "# " + (Number.isInteger(seqNo) ? String(seqNo) : "-");
        const nameEl = document.createElement("span");
        nameEl.className = "viewer-persistent-label-export-name";
        nameEl.textContent = rawLabel;
        labelEl.appendChild(seqEl);
        labelEl.appendChild(nameEl);
        labelEl.classList.remove("state-hidden");
        labelEl.classList.add("state-visible");
        if (animateOnShow === true) {
          void labelEl.offsetWidth;
          labelEl.classList.add("state-shortcut-animate");
        }
        return;
      }
      clearLabel();
    }
    function buildSceneNumberRows() {
      const sceneNumberRows = [];
      if (scenesData && typeof scenesData === "object") {
        Object.entries(scenesData).forEach(([sceneId, sceneData]) => {
          const sceneNumber = Number.isInteger(sceneData?.sceneNumber) ? sceneData.sceneNumber : null;
          if (Number.isInteger(sceneNumber) && sceneNumber >= 1) {
            sceneNumberRows.push({ sceneNumber, sceneId });
          }
        });
      }
      sceneNumberRows.sort((a, b) => a.sceneNumber - b.sceneNumber);
      return sceneNumberRows;
    }
    function navigateToSceneByNumberValue(chosen, options) {
      if (!Number.isInteger(chosen) || chosen < 1) return false;
      const sceneNumberRows = buildSceneNumberRows();
      if (sceneNumberRows.length === 0) return false;
      const targetEntry = sceneNumberRows.find(item => item.sceneNumber === chosen);
      if (!targetEntry || !targetEntry.sceneId) return false;
      navigateToFloorTagShortcut(targetEntry.sceneId, options);
      return true;
    }
    function isSceneSequencePromptOpen() {
      return mapSequenceInputState.isOpen === true;
    }
    function syncSceneSequencePromptHostState() {
      if (!document || !document.body) return;
      document.body.classList.toggle("is-sequence-prompt-open", mapSequenceInputState.isOpen === true);
      const host = getSceneSequencePromptHost();
      if (!host) return;
      host.classList.toggle("state-hidden", mapSequenceInputState.isOpen !== true);
      host.setAttribute("aria-hidden", mapSequenceInputState.isOpen === true ? "false" : "true");
    }
    function closeSceneSequencePrompt() {
      mapSequenceInputState.isOpen = false;
      mapSequenceInputState.error = "";
      mapSequenceInputState.value = "";
      removeMapSequencePromptPanel();
      syncSceneSequencePromptHostState();
      if (typeof updateNavShortcutsV2 === "function") {
        const sid = window.viewer?.getScene?.() ?? floorTagShortcutState.sceneId;
        if (sid) updateNavShortcutsV2(sid, true);
      }
    }
    function submitSceneSequencePrompt() {
      const normalized = String(mapSequenceInputState.value || "").trim().toLowerCase();
      if (normalized === "") {
        mapSequenceInputState.error = "enter a scene number";
        return false;
      }
      if (normalized === "e") {
        closeSceneSequencePrompt();
        return true;
      }
      const chosen = Number.parseInt(normalized, 10);
      const didNavigate = navigateToSceneByNumberValue(chosen, {
        fromSceneSequencePrompt: true,
      });
      if (!didNavigate) {
        mapSequenceInputState.error = "invalid scene";
        return false;
      }
      mapSequenceInputState.error = "";
      closeSceneSequencePrompt();
      return true;
    }
    function openSceneSequencePrompt() {
      const interactionShell =
        typeof resolveExportInteractionShell === "function"
          ? resolveExportInteractionShell()
          : "classic";
      if (interactionShell !== "classic") return false;
      const rows = buildSceneNumberRows();
      if (rows.length === 0) return false;
      if (typeof suspendLookingModeForSceneSequencePrompt === "function") {
        suspendLookingModeForSceneSequencePrompt();
      }
      mapSequenceInputState.isOpen = true;
      mapSequenceInputState.error = "";
      mapSequenceInputState.value = "";
      syncSceneSequencePromptHostState();
      if (typeof renderMapSequencePromptPanel === "function") {
        renderMapSequencePromptPanel();
      }
      if (typeof updateNavShortcutsV2 === "function") {
        const sid = window.viewer?.getScene?.() ?? floorTagShortcutState.sceneId;
        if (sid) updateNavShortcutsV2(sid, true);
      }
      return true;
    }
    function navigateToSceneBySequenceInput() {
      return openSceneSequencePrompt();
    }
    function removeMapSequencePromptPanel() {
      const host = getSceneSequencePromptHost();
      if (host) {
        while (host.firstChild) host.removeChild(host.firstChild);
      }
      const existing = document.getElementById("viewer-map-sequence-prompt-export");
      if (existing && existing.parentNode) {
        existing.parentNode.removeChild(existing);
      }
    }
    function renderMapSequencePromptPanel() {
      removeMapSequencePromptPanel();
      syncSceneSequencePromptHostState();
      const host = getSceneSequencePromptHost();
      if (!host || mapSequenceInputState.isOpen !== true) return;
      const rows = buildSceneNumberRows();
      const maxSceneNumber = rows.length > 0 ? rows[rows.length - 1].sceneNumber : 0;
      const prompt = document.createElement("div");
      prompt.id = "viewer-map-sequence-prompt-export";
      prompt.className = "map-sequence-prompt-export";

      const title = document.createElement("div");
      title.className = "map-sequence-prompt-title";
      title.textContent = "Jump to scene";

      const controls = document.createElement("div");
      controls.className = "map-sequence-prompt-controls";

      const input = document.createElement("input");
      input.type = "text";
      input.className = "map-sequence-prompt-input";
      input.setAttribute("inputmode", "numeric");
      input.setAttribute("autocomplete", "off");
      input.setAttribute("spellcheck", "false");
      input.setAttribute("aria-label", "Scene number input");
      input.placeholder = maxSceneNumber > 0 ? "1-" + String(maxSceneNumber) : "";
      input.value = String(mapSequenceInputState.value || "");
      input.addEventListener("input", event => {
        mapSequenceInputState.value = event?.target?.value ?? "";
        mapSequenceInputState.error = "";
      });

      const goBtn = document.createElement("button");
      goBtn.type = "button";
      goBtn.className = "map-sequence-prompt-btn";
      goBtn.textContent = "go";
      goBtn.addEventListener("click", () => {
        const didSubmit = submitSceneSequencePrompt();
        if (!didSubmit && typeof updateNavShortcutsV2 === "function") {
          const sid = window.viewer?.getScene?.() ?? floorTagShortcutState.sceneId;
          if (sid) updateNavShortcutsV2(sid, true);
        }
      });

      const exitHint = document.createElement("div");
      exitHint.className = "map-sequence-prompt-exit-hint";
      exitHint.textContent = "n to return";

      controls.appendChild(input);
      controls.appendChild(goBtn);
      prompt.appendChild(title);
      prompt.appendChild(controls);
      prompt.appendChild(exitHint);

      if (mapSequenceInputState.error && mapSequenceInputState.error !== "") {
        const errorEl = document.createElement("div");
        errorEl.className = "map-sequence-prompt-error";
        errorEl.textContent = mapSequenceInputState.error;
        prompt.appendChild(errorEl);
      }

      host.appendChild(prompt);
      setTimeout(() => {
        try {
          input.focus({ preventScroll: true });
          input.select();
        } catch (_err) {
          input.focus();
        }
      }, 0);
    }
    function navigateToFloorTagShortcut(targetSceneId, options) {
      if (!window.viewer || typeof window.viewer.getScene !== "function") return;
      const fromMap = options?.fromMap === true;
      const fromSceneSequencePrompt = options?.fromSceneSequencePrompt === true;
      const mapSelectedRow = options?.mapSelectedRow ?? null;
      const sequencePosition =
        Number.isInteger(options?.sequencePosition) && options.sequencePosition >= 1
          ? options.sequencePosition
          : null;
      const selectedDurationMs = 500;
      const runNavigation = () => {
        if (fromMap && typeof enableLookingModeAfterMapNavigation === "function") {
          enableLookingModeAfterMapNavigation();
        }
        if (
          fromSceneSequencePrompt &&
          typeof restoreLookingModeAfterSceneSequencePromptSuccess === "function"
        ) {
          restoreLookingModeAfterSceneSequencePromptSuccess();
        }
        if (isExportMapOpen()) closeExportMap();
        const row = document.querySelector('.floor-tag-shortcut-row[data-scene-id="' + String(targetSceneId) + '"]');
        if (row) {
          row.classList.add("state-selected");
          setTimeout(() => {
            row.classList.remove("state-selected");
          }, selectedDurationMs);
        }
        const resolvedTargetSceneId = resolveExistingSceneId(targetSceneId);
        if (!resolvedTargetSceneId) return;
        if (window.viewer.getScene() === resolvedTargetSceneId) {
          if (Number.isInteger(sequencePosition) && typeof applyManualSequencePosition === "function") {
            applyManualSequencePosition(resolvedTargetSceneId, sequencePosition);
          }
          pendingShortcutLabelSceneId = resolvedTargetSceneId;
          updateExportRoomLabel(resolvedTargetSceneId, true);
          pendingShortcutLabelSceneId = null;
          updateNavShortcutsV2(resolvedTargetSceneId, true);
          return;
        }
        pendingShortcutLabelSceneId = resolvedTargetSceneId;
        navigateToNextScene(
          { targetSceneId: resolvedTargetSceneId },
          resolvedTargetSceneId,
          Number.isInteger(sequencePosition)
            ? {
                targetSceneId: resolvedTargetSceneId,
                sequenceCursorOverride: sequencePosition - 1,
              }
            : undefined,
        );
      };
      if (
        fromMap &&
        window.viewer.getScene() === targetSceneId &&
        !Number.isInteger(sequencePosition)
      ) {
        return;
      }
      if (fromMap && mapSelectedRow) {
        mapSelectedRow.classList.add("state-selected");
        setTimeout(() => {
          mapSelectedRow.classList.remove("state-selected");
          runNavigation();
        }, selectedDurationMs);
        return;
      }
      runNavigation();
    }
    function navigateToNextSequenceShortcut() {
      const sceneId = floorTagShortcutState.sceneId;
      const nextSceneId = floorTagShortcutState.nextSceneId;
      const nextHotspotIndex = floorTagShortcutState.nextHotspotIndex;
      const nextSequenceNumber = floorTagShortcutState.nextSequenceNumber;
      if (!sceneId || !nextSceneId) return false;
      if (!Number.isInteger(nextHotspotIndex) || nextHotspotIndex < 0) {
        navigateToNextScene(
          { sourceSceneId: sceneId, targetSceneId: nextSceneId },
          nextSceneId,
          { sourceSceneId: sceneId, targetSceneId: nextSceneId, sequenceCursorOverride: nextSequenceNumber },
        );
        return true;
      }
      const hotspot = scenesData?.[sceneId]?.hotSpots?.[nextHotspotIndex];
      if (!hotspot) {
        navigateToNextScene(
          { sourceSceneId: sceneId, targetSceneId: nextSceneId },
          nextSceneId,
          { sourceSceneId: sceneId, targetSceneId: nextSceneId, sequenceCursorOverride: nextSequenceNumber },
        );
        return true;
      }
      pendingShortcutLabelSceneId = nextSceneId;
      navigateToNextScene(
        {
          sourceSceneId: sceneId,
          i: nextHotspotIndex,
          targetSceneId: hotspot?.targetSceneId ?? nextSceneId,
          target: hotspot?.target,
          targetName: hotspot?.target,
          isReturnLink: hotspot?.isReturnLink === true,
        },
        nextSceneId,
        { sourceSceneId: sceneId, targetSceneId: nextSceneId, sequenceCursorOverride: nextSequenceNumber },
      );
      return true;
    }
    function navigateToPreviousSequenceShortcut() {
      const sceneId = floorTagShortcutState.sceneId;
      const prevSceneId = floorTagShortcutState.prevSceneId;
      const prevHotspotIndex = floorTagShortcutState.prevHotspotIndex;
      const prevSequenceNumber = floorTagShortcutState.prevSequenceNumber;
      if (!sceneId || !prevSceneId) return false;
      if (Number.isInteger(prevHotspotIndex) && prevHotspotIndex >= 0) {
        const hotspot = scenesData?.[sceneId]?.hotSpots?.[prevHotspotIndex];
        if (hotspot) {
          pendingShortcutLabelSceneId = prevSceneId;
          navigateToNextScene(
            {
              sourceSceneId: sceneId,
              i: prevHotspotIndex,
              targetSceneId: hotspot?.targetSceneId ?? prevSceneId,
              target: hotspot?.target,
              targetName: hotspot?.target,
              isReturnLink: hotspot?.isReturnLink === true,
            },
            prevSceneId,
            {
              sourceSceneId: sceneId,
              targetSceneId: prevSceneId,
              sequenceCursorOverride: prevSequenceNumber,
            },
          );
          return true;
        }
      }
      navigateToNextScene(
        { sourceSceneId: sceneId, targetSceneId: prevSceneId },
        prevSceneId,
        {
          sourceSceneId: sceneId,
          targetSceneId: prevSceneId,
          sequenceCursorOverride: prevSequenceNumber,
        },
      );
      return true;
    }
    function navigateToExportHome() {
      if (!window.viewer || typeof window.viewer.getScene !== "function") return;
      const homeSceneId = resolveExistingSceneId(firstSceneId);
      if (!homeSceneId) return;
      if (window.viewer.getScene() === homeSceneId) {
        pendingShortcutLabelSceneId = homeSceneId;
        updateExportRoomLabel(homeSceneId, true);
        pendingShortcutLabelSceneId = null;
        updateNavShortcutsV2(homeSceneId, true);
        return;
      }
      pendingShortcutLabelSceneId = homeSceneId;
      navigateToNextScene({ targetSceneId: homeSceneId }, homeSceneId);
    }
    function startAutoTour() {
      if (floorTagShortcutState.isAutoTourActive) return;
      if (isExportMapOpen()) closeExportMap();
      clearAutoTourCompletionCountdown();
      floorTagShortcutState.isAutoTourActive = true;
      window.isAutoTourActive = true;
      if (typeof syncPortraitModeSelectorClasses === "function") {
        syncPortraitModeSelectorClasses();
      }
      if (typeof resetAutoTourManifestCursor === "function") {
        resetAutoTourManifestCursor();
      }
      if (typeof applyAutoTourBaseSpeed === "function") {
        applyAutoTourBaseSpeed();
      }
      window.autoTourVisitedScenes = new Set();
      document.body.classList.add('is-auto-tour-active');
      // Start from Home
      const sid = window.viewer.getScene();
      const homeSceneId = resolveExistingSceneId(firstSceneId);
      if (sid === homeSceneId) {
        // Already at home, force UI update and trigger auto-tour logic
        updateNavShortcutsV2(sid, true);
        animateSceneToPrimaryHotspot(sid, 20);
      } else {
        if (homeSceneId) suppressNextRoomLabelOnLoad = true;
        navigateToExportHome();
      }
    }
    function stopAutoTour() {
      if (!floorTagShortcutState.isAutoTourActive) return;
      floorTagShortcutState.isAutoTourActive = false;
      window.isAutoTourActive = false;
      if (typeof syncPortraitModeSelectorClasses === "function") {
        syncPortraitModeSelectorClasses();
      }
      if (typeof resetAutoTourManifestCursor === "function") {
        resetAutoTourManifestCursor();
      }
      if (typeof resetAutoTourSpeedMultiplier === "function") {
        resetAutoTourSpeedMultiplier();
      }
      document.body.classList.remove('is-auto-tour-active');
      clearAutoTourCompletionCountdown();
      if (waypointRuntime.autoForwardTimeoutId) {
        clearTimeout(waypointRuntime.autoForwardTimeoutId);
        waypointRuntime.autoForwardTimeoutId = null;
      }
      const sid = window.viewer.getScene();
      if (sid) updateNavShortcutsV2(sid, true);
    }
    function clearExportFloorTagShortcuts(panel) {
      floorTagShortcutState.nextSceneId = null;
      floorTagShortcutState.prevSceneId = null;
      floorTagShortcutState.nextHotspotIndex = null;
      floorTagShortcutState.nextSequenceNumber = null;
      floorTagShortcutState.prevHotspotIndex = null;
      floorTagShortcutState.prevSequenceNumber = null;
      floorTagShortcutState.prevUsesReturnLink = false;
      clearPortraitJoystick();
      clearPortraitModeSelectorPanel(getPortraitModeSelectorPanel());
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
    function updateNavShortcutsV2(sceneId, _resetPage) {
      const panel = document.getElementById("viewer-floor-tags-export");
      const portraitSelectorPanel = getPortraitModeSelectorPanel();
      if (!panel) return;
      const isTouchFriendlyUi =
        typeof isTouchFriendlyExportUi === "function" && isTouchFriendlyExportUi();
      const selectorBlockingUi =
        typeof isPortraitModeSelectorBlockingUi === "function" &&
        isPortraitModeSelectorBlockingUi();
      if (suppressShortcutPanelUntilNextLoad) {
        clearExportFloorTagShortcuts(panel);
        return;
      }

      while (panel.firstChild) panel.removeChild(panel.firstChild);
      panel.classList.remove("is-portrait-adaptive-preview");
      panel.classList.remove("is-portrait-mode-selector");
      panel.classList.remove("state-intro");
      panel.classList.remove("state-collapsing");
      panel.classList.remove("state-docked");
      panel.classList.remove("state-hidden");
      panel.setAttribute("aria-hidden", "false");
      const mapEntries = buildMapEntries();
      floorTagShortcutState.hasMap = mapEntries.length > 0;
      if (isExportMapOpen()) {
        clearPortraitJoystick();
        clearPortraitModeSelectorPanel(portraitSelectorPanel);
        renderExportMapRows(panel, mapEntries);
        return;
      }

      const currentSceneData = scenesData[sceneId];
      if (!currentSceneData) {
        clearPortraitJoystick();
        clearPortraitModeSelectorPanel(portraitSelectorPanel);
        return;
      }

      const shortcutTargets = resolveShortcutNavigationTargets(sceneId, currentSceneData);
      const nextTarget = shortcutTargets?.nextTarget ?? null;
      const prevTarget = shortcutTargets?.prevTarget ?? null;
      syncFloorTagShortcutState(sceneId, nextTarget, prevTarget);

      if (isTouchFriendlyUi || selectorBlockingUi) {
        panel.classList.add("state-hidden");
        panel.setAttribute("aria-hidden", "true");
        renderPortraitAdaptiveShortcutPanel(portraitSelectorPanel);
        renderMapSequencePromptPanel();
        return;
      }

      clearPortraitModeSelectorPanel(portraitSelectorPanel);
      clearPortraitJoystick();
      const appendSectionTitle = text => {
        const title = document.createElement("div");
        title.className = "floor-tag-shortcut-section-title";
        title.textContent = text;
        panel.appendChild(title);
      };
      const appendDivider = () => {
        const divider = document.createElement("div");
        divider.className = "floor-tag-shortcut-divider";
        panel.appendChild(divider);
      };
      const createClassicShortcutRow = ({id, iconChar, label, onClick, isActive, ariaLabel}) => {
        const row = document.createElement("button");
        row.type = "button";
        row.className = "floor-tag-shortcut-row" + (isActive ? " state-active" : "");
        if (id) row.setAttribute("data-scene-id", id);
        if (ariaLabel) row.setAttribute("aria-label", ariaLabel);
        row.addEventListener("click", onClick);

        const arrowEl = document.createElement("span");
        arrowEl.className = "shortcut-indicator-arrow";
        arrowEl.innerHTML = '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M12 5l7 7-7 7"/></svg>';

        const indexEl = document.createElement("span");
        indexEl.className = "floor-tag-shortcut-index";
        indexEl.textContent = iconChar;

        const labelEl = document.createElement("span");
        labelEl.className = "floor-tag-shortcut-label";
        labelEl.textContent = label;

        row.appendChild(arrowEl);
        row.appendChild(indexEl);
        row.appendChild(labelEl);
        return row;
      };

      const activeMode =
        typeof resolveActivePortraitNavigationMode === "function"
          ? resolveActivePortraitNavigationMode()
          : EXPORT_DEFAULT_NAVIGATION_MODE;
      const isSpeedBoosted =
        typeof isAutoTourSpeedBoosted === "function" && isAutoTourSpeedBoosted();
      const autoModeLabel = !floorTagShortcutState.isAutoTourActive
        ? "auto"
        : (isSpeedBoosted ? "auto 2x" : "auto 1x");

      if (!floorTagShortcutState.isAutoTourActive && autoTourHomeReturnCountdownRemaining <= 0) {
        appendSectionTitle("Navigation Mode");
        panel.appendChild(
          createClassicShortcutRow({
            iconChar: "m",
            label: "manual",
            onClick: () => {
              activateExportNavigationMode(EXPORT_NAVIGATION_MODE_MANUAL);
            },
            isActive: activeMode === EXPORT_NAVIGATION_MODE_MANUAL,
            ariaLabel: "Manual navigation mode",
          }),
        );
        panel.appendChild(
          createClassicShortcutRow({
            iconChar: "s",
            label: "semi-auto",
            onClick: () => {
              activateExportNavigationMode(EXPORT_NAVIGATION_MODE_SEMI_AUTO);
            },
            isActive: activeMode === EXPORT_NAVIGATION_MODE_SEMI_AUTO,
            ariaLabel: "Semi-auto navigation mode",
          }),
        );
      }
      panel.appendChild(
        createClassicShortcutRow({
          iconChar: "a",
          label: autoModeLabel,
          onClick: () => {
            triggerAutoNavigationMode();
          },
          isActive: activeMode === EXPORT_NAVIGATION_MODE_AUTO,
          ariaLabel: floorTagShortcutState.isAutoTourActive
            ? "Auto tour " + (isSpeedBoosted ? "2x" : "1x")
            : "Auto tour",
        }),
      );

      if (autoTourHomeReturnCountdownRemaining > 0) {
        appendDivider();
        const countdownRow = document.createElement("div");
        countdownRow.className = "floor-tag-shortcut-row";
        countdownRow.setAttribute("aria-live", "polite");
        const countdownSpacer = document.createElement("span");
        countdownSpacer.className = "shortcut-indicator-spacer";
        const countdownIndex = document.createElement("span");
        countdownIndex.className = "floor-tag-shortcut-index";
        countdownIndex.textContent = String(autoTourHomeReturnCountdownRemaining);
        const countdownLabel = document.createElement("span");
        countdownLabel.className = "floor-tag-shortcut-label";
        countdownLabel.textContent = "returning home";
        countdownRow.appendChild(countdownSpacer);
        countdownRow.appendChild(countdownIndex);
        countdownRow.appendChild(countdownLabel);
        panel.appendChild(countdownRow);
        renderMapSequencePromptPanel();
        return;
      }

      if (floorTagShortcutState.isAutoTourActive) {
        renderMapSequencePromptPanel();
        return;
      }

      const nextSceneId = nextTarget?.targetSceneId ?? null;
      const prevSceneId = prevTarget?.targetSceneId ?? null;
      const homeSceneId = resolveExistingSceneId(firstSceneId);

      appendDivider();
      if (nextSceneId) {
        const nextLabel = scenesData[nextSceneId]?.label || scenesData[nextSceneId]?.name || "next";
        panel.appendChild(
          createClassicShortcutRow({
            id: nextSceneId,
            iconChar: "↑",
            label: nextLabel,
            onClick: () => navigateToNextSequenceShortcut(),
            isActive: false,
            ariaLabel: "Go forward to " + nextLabel,
          }),
        );
      }
      if (prevSceneId && prevSceneId !== sceneId) {
        const prevLabel = scenesData[prevSceneId]?.label || scenesData[prevSceneId]?.name || "back";
        panel.appendChild(
          createClassicShortcutRow({
            id: prevSceneId,
            iconChar: "↓",
            label: prevLabel,
            onClick: () => navigateToPreviousSequenceShortcut(),
            isActive: false,
            ariaLabel: "Go back to " + prevLabel,
          }),
        );
      }
      if (homeSceneId && homeSceneId !== sceneId) {
        panel.appendChild(
          createClassicShortcutRow({
            id: homeSceneId,
            iconChar: "h",
            label: "home",
            onClick: () => navigateToFloorTagShortcut(homeSceneId),
            isActive: false,
            ariaLabel: "Go home",
          }),
        );
      }
      panel.appendChild(
        createClassicShortcutRow({
          iconChar: "n",
          label: "scene number",
          onClick: () => navigateToSceneBySequenceInput(),
          isActive: mapSequenceInputState.isOpen === true,
          ariaLabel: "Jump to scene number",
        }),
      );
      renderMapSequencePromptPanel();
    }
`
