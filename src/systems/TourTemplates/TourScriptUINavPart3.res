let script = `
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
