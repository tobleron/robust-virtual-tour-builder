let script = `
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
      const sceneData = scenesData[sceneId];
      const currentFloor = normalizeSceneFloor(sceneData);
      const visibleFloorLevels = getExportFloorLevelsInUse();
      while (nav.firstChild) nav.removeChild(nav.firstChild);
      for (const level of visibleFloorLevels) {
        const btn = document.createElement("div");
        btn.className = "floor-nav-btn " + (level.id === currentFloor ? "state-active" : "state-idle");
        btn.setAttribute("title", level.label);
        btn.setAttribute("aria-label", level.label);
        btn.textContent = level.short;
        if (level.suffix) {
          const suffix = document.createElement("sup");
          suffix.textContent = level.suffix;
          btn.appendChild(suffix);
        }
        nav.appendChild(btn);
      }
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
      const getSceneSequenceNumber = sid => {
        if (typeof getCurrentSceneSequenceCursor === "function" && sid === window.viewer?.getScene?.()) {
          const currentSeq = getCurrentSceneSequenceCursor(sid, scenesData?.[sid]);
          if (Number.isInteger(currentSeq) && currentSeq >= 0) return currentSeq + 1;
        }
        if (typeof resolveFirstSequencePositionForScene === "function") {
          const seq = resolveFirstSequencePositionForScene(sid);
          return Number.isInteger(seq) && seq >= 1 ? seq : null;
        }
        return null;
      };
      const rawLabel = typeof scenesData[sceneId]?.label === "string" ? scenesData[sceneId].label.trim() : "";
      if (rawLabel !== "") {
        while (labelEl.firstChild) labelEl.removeChild(labelEl.firstChild);
        const seqNo = getSceneSequenceNumber(sceneId);
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
    function buildSceneSequenceRows() {
      const sceneSequenceRows = [];
      if (typeof buildSceneSequencePositionMaps === "function") {
        buildSceneSequencePositionMaps();
      }
      if (typeof sceneIdBySequencePosition?.forEach === "function") {
        sceneIdBySequencePosition.forEach((sceneId, sequence) => {
          sceneSequenceRows.push({ sequence, sceneId });
        });
      }
      sceneSequenceRows.sort((a, b) => a.sequence - b.sequence);
      return sceneSequenceRows;
    }
    function navigateToSceneBySequenceValue(chosen) {
      if (!Number.isInteger(chosen) || chosen < 1) return false;
      const sceneSequenceRows = buildSceneSequenceRows();
      if (sceneSequenceRows.length === 0) return false;
      const targetEntry = sceneSequenceRows.find(item => item.sequence === chosen);
      if (!targetEntry || !targetEntry.sceneId) return false;
      navigateToFloorTagShortcut(
        targetEntry.sceneId,
        { fromMap: true, sequencePosition: targetEntry.sequence },
      );
      return true;
    }
    function isSceneSequencePromptOpen() {
      return mapSequenceInputState.isOpen === true;
    }
    function closeSceneSequencePrompt() {
      mapSequenceInputState.isOpen = false;
      mapSequenceInputState.error = "";
      mapSequenceInputState.value = "";
      removeMapSequencePromptPanel();
      if (typeof updateNavShortcutsV2 === "function") {
        const sid = window.viewer?.getScene?.() ?? floorTagShortcutState.sceneId;
        if (sid) updateNavShortcutsV2(sid, true);
      }
    }
    function submitSceneSequencePrompt() {
      const normalized = String(mapSequenceInputState.value || "").trim().toLowerCase();
      if (normalized === "") {
        mapSequenceInputState.error = "enter a sequence number";
        return false;
      }
      if (normalized === "e") {
        closeSceneSequencePrompt();
        return true;
      }
      const chosen = Number.parseInt(normalized, 10);
      const didNavigate = navigateToSceneBySequenceValue(chosen);
      if (!didNavigate) {
        mapSequenceInputState.error = "invalid sequence";
        return false;
      }
      mapSequenceInputState.error = "";
      closeSceneSequencePrompt();
      return true;
    }
    function openSceneSequencePrompt() {
      const rows = buildSceneSequenceRows();
      if (rows.length === 0) return false;
      mapSequenceInputState.isOpen = true;
      mapSequenceInputState.error = "";
      mapSequenceInputState.value = "";
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
      const existing = document.getElementById("viewer-map-sequence-prompt-export");
      if (existing && existing.parentNode) {
        existing.parentNode.removeChild(existing);
      }
    }
    function renderMapSequencePromptPanel(panel) {
      removeMapSequencePromptPanel();
      if (!panel || mapSequenceInputState.isOpen !== true) return;
      const rows = buildSceneSequenceRows();
      const maxSeq = rows.length > 0 ? rows[rows.length - 1].sequence : 0;
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
      input.setAttribute("aria-label", "Scene sequence input");
      input.placeholder = maxSeq > 0 ? "1-" + String(maxSeq) : "";
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
      exitHint.textContent = "e to exit";

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

      panel.appendChild(prompt);
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
      const prevUsesReturnLink = floorTagShortcutState.prevUsesReturnLink === true;
      if (!sceneId || !prevSceneId) return false;
      if (prevUsesReturnLink && typeof navigateReturnHotspotFromCurrentScene === "function") {
        return navigateReturnHotspotFromCurrentScene();
      }
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
              sequenceCursorOverride: getCurrentSceneSequenceCursor(sceneId, scenesData?.[sceneId]),
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
          sequenceCursorOverride: getCurrentSceneSequenceCursor(sceneId, scenesData?.[sceneId]),
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
      floorTagShortcutState.prevUsesReturnLink = false;
      if (!panel) return;
      while (panel.firstChild) panel.removeChild(panel.firstChild);
      panel.classList.add("state-hidden");
    }
    function updateNavShortcutsV2(sceneId, _resetPage) {
      const panel = document.getElementById("viewer-floor-tags-export");
      if (!panel) return;
      if (suppressShortcutPanelUntilNextLoad) {
        clearExportFloorTagShortcuts(panel);
        return;
      }
      
      while (panel.firstChild) panel.removeChild(panel.firstChild);
      panel.classList.remove("state-hidden");
      const mapEntries = buildMapEntries();
      floorTagShortcutState.hasMap = mapEntries.length > 0;
      if (isExportMapOpen()) {
        renderExportMapRows(panel, mapEntries);
        return;
      }

      if (floorTagShortcutState.isAutoTourActive) {
        const stopRow = document.createElement("button");
        stopRow.type = "button";
        stopRow.className = "floor-tag-shortcut-row";
        stopRow.setAttribute("aria-label", "Stop auto tour");
        stopRow.addEventListener("click", stopAutoTour);

        const stopSpacer = document.createElement("span");
        stopSpacer.className = "shortcut-indicator-spacer";
        const stopIndex = document.createElement("span");
        stopIndex.className = "floor-tag-shortcut-index";
        stopIndex.textContent = "s";
        const stopLabel = document.createElement("span");
        stopLabel.className = "floor-tag-shortcut-label";
        stopLabel.textContent = "stop auto tour";

        stopRow.appendChild(stopSpacer);
        stopRow.appendChild(stopIndex);
        stopRow.appendChild(stopLabel);
        panel.appendChild(stopRow);
        return;
      }
      if (autoTourHomeReturnCountdownRemaining > 0) {
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
        return;
      }

      const currentSceneData = scenesData[sceneId];
      if (!currentSceneData) return;

      // Navigation Logic: Next (Up) and Previous (Down)
      const preferredTarget = resolvePreferredNavigationTarget(sceneId, currentSceneData);
      const backtrackTarget = resolveBacktrackTarget(sceneId, currentSceneData);
      const nextSceneId =
        preferredTarget?.hotspot && Number.isInteger(preferredTarget?.hotspotIndex)
          ? preferredTarget.targetSceneId
          : null;
      const prevSceneId = backtrackTarget ? backtrackTarget.targetSceneId : null;

      // Update state for keyboard/input logic
      floorTagShortcutState.sceneId = sceneId;
      floorTagShortcutState.nextSceneId = nextSceneId;
      floorTagShortcutState.prevSceneId = prevSceneId;
      floorTagShortcutState.nextHotspotIndex = nextSceneId ? preferredTarget.hotspotIndex : null;
      floorTagShortcutState.nextSequenceNumber = nextSceneId ? preferredTarget.sequenceCursorOverride : null;
      floorTagShortcutState.prevHotspotIndex = backtrackTarget ? backtrackTarget.hotspotIndex : null;
      floorTagShortcutState.prevUsesReturnLink = backtrackTarget?.usesReturnLink === true;

      const createRow = (id, iconChar, label, onClick) => {
        const row = document.createElement("button");
        row.type = "button";
        row.className = "floor-tag-shortcut-row";
        if (id) row.setAttribute("data-scene-id", id);
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

      // 1. Next Scene (Up Arrow)
      if (nextSceneId) {
        const nextLabel = scenesData[nextSceneId]?.label || scenesData[nextSceneId]?.name || "Next";
        panel.appendChild(createRow(nextSceneId, "↑", nextLabel, () => navigateToNextSequenceShortcut()));
      }

      // 2. Previous Scene (Down Arrow)
      if (prevSceneId && prevSceneId !== sceneId) {
        const prevLabel = scenesData[prevSceneId]?.label || scenesData[prevSceneId]?.name || "Back";
        panel.appendChild(createRow(prevSceneId, "↓", prevLabel, () => navigateToPreviousSequenceShortcut()));
      }

      // 3. Home (h)
      const homeSceneId = resolveExistingSceneId(firstSceneId);
      if (homeSceneId && homeSceneId !== sceneId) {
        panel.appendChild(createRow(homeSceneId, "h", "home", () => navigateToFloorTagShortcut(homeSceneId)));
      }

      // 4. Map Placeholder (m)
      const mapRow = document.createElement("button");
      mapRow.type = "button";
      mapRow.className = "floor-tag-shortcut-row";
      mapRow.setAttribute("aria-label", "Map");
      mapRow.addEventListener("click", () => {
        toggleExportMap();
      });
      const mapSpacer = document.createElement("span");
      mapSpacer.className = "shortcut-indicator-spacer";
      const mapIndex = document.createElement("span");
      mapIndex.className = "floor-tag-shortcut-index";
      mapIndex.textContent = "m";
      const mapLabel = document.createElement("span");
      mapLabel.className = "floor-tag-shortcut-label";
      mapLabel.textContent = "map";
      mapRow.appendChild(mapSpacer);
      mapRow.appendChild(mapIndex);
      mapRow.appendChild(mapLabel);
      if (floorTagShortcutState.hasMap) {
        panel.appendChild(mapRow);
      }

      const autoRow = document.createElement("button");
      autoRow.type = "button";
      autoRow.className = "floor-tag-shortcut-row";
      autoRow.setAttribute("aria-label", "Start auto tour");
      autoRow.addEventListener("click", startAutoTour);
      const autoSpacer = document.createElement("span");
      autoSpacer.className = "shortcut-indicator-spacer";
      const autoIndex = document.createElement("span");
      autoIndex.className = "floor-tag-shortcut-index";
      autoIndex.textContent = "a";
      const autoLabel = document.createElement("span");
      autoLabel.className = "floor-tag-shortcut-label";
      autoLabel.textContent = "auto tour";

      autoRow.appendChild(autoSpacer);
      autoRow.appendChild(autoIndex);
      autoRow.appendChild(autoLabel);
      panel.appendChild(autoRow);
    }
`
