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
      const rawLabel = typeof scenesData[sceneId]?.label === "string" ? scenesData[sceneId].label.trim() : "";
      if (rawLabel !== "") {
        labelEl.textContent = "# " + rawLabel;
        labelEl.classList.remove("state-hidden");
        labelEl.classList.add("state-visible");
        if (animateOnShow === true) {
          void labelEl.offsetWidth;
          labelEl.classList.add("state-shortcut-animate");
        }
        return;
      }
      labelEl.textContent = "";
      labelEl.classList.remove("state-shortcut-animate");
      labelEl.classList.remove("state-visible");
      labelEl.classList.add("state-hidden");
    }
    function navigateToFloorTagShortcut(targetSceneId, options) {
      if (!window.viewer || typeof window.viewer.getScene !== "function") return;
      const fromMap = options?.fromMap === true;
      const mapSelectedRow = options?.mapSelectedRow ?? null;
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
          pendingShortcutLabelSceneId = resolvedTargetSceneId;
          updateExportRoomLabel(resolvedTargetSceneId, true);
          pendingShortcutLabelSceneId = null;
          updateNavShortcutsV2(resolvedTargetSceneId, true);
          return;
        }
        pendingShortcutLabelSceneId = resolvedTargetSceneId;
        navigateToNextScene({ targetSceneId: resolvedTargetSceneId }, resolvedTargetSceneId);
      };
      if (fromMap && window.viewer.getScene() === targetSceneId) {
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
      const nextTarget = resolveScenePlaybackHotspot(sceneId, currentSceneData);
      const nextSceneId = nextTarget ? nextTarget.targetSceneId : null;
      const prevSceneId = persistentFrom;

      // Update state for keyboard/input logic
      floorTagShortcutState.sceneId = sceneId;
      floorTagShortcutState.nextSceneId = nextSceneId;
      floorTagShortcutState.prevSceneId = prevSceneId;

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
        panel.appendChild(createRow(nextSceneId, "↑", nextLabel, () => navigateToFloorTagShortcut(nextSceneId)));
      }

      // 2. Previous Scene (Down Arrow)
      if (prevSceneId && prevSceneId !== sceneId) {
        const prevLabel = scenesData[prevSceneId]?.label || scenesData[prevSceneId]?.name || "Back";
        panel.appendChild(createRow(prevSceneId, "↓", prevLabel, () => navigateToFloorTagShortcut(prevSceneId)));
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
