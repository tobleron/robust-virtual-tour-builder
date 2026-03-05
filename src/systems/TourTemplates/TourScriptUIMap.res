let script = `
    const EXPORT_FLOOR_LEVELS = [
      { id: "b2", label: "Basement 2", short: "B", suffix: "-2" },
      { id: "b1", label: "Basement 1", short: "B", suffix: "-1" },
      { id: "ground", label: "Ground Floor", short: "G", suffix: "" },
      { id: "first", label: "First Floor", short: "+1", suffix: "" },
      { id: "second", label: "Second Floor", short: "+2", suffix: "" },
      { id: "third", label: "Third Floor", short: "+3", suffix: "" },
      { id: "fourth", label: "Fourth Floor", short: "+4", suffix: "" },
      { id: "fifth", label: "Fifth Floor", short: "+5", suffix: "" },
      { id: "roof", label: "Roof Top", short: "R", suffix: "" }
    ];
    const EXPORT_MAP_FLOOR_LEVELS = [
      { id: "roof", shortcut: "r", mapLabel: "Roof" },
      { id: "fifth", shortcut: "5", mapLabel: "Fifth floor" },
      { id: "fourth", shortcut: "4", mapLabel: "Fourth floor" },
      { id: "third", shortcut: "3", mapLabel: "Third floor" },
      { id: "second", shortcut: "2", mapLabel: "Second floor" },
      { id: "first", shortcut: "1", mapLabel: "First floor" },
      { id: "ground", shortcut: "g", mapLabel: "Ground floor" },
      { id: "b1", shortcut: "b", mapLabel: "Basement level -1" },
      { id: "b2", shortcut: "z", mapLabel: "Basement level -2" }
    ];
    const FLOOR_TAG_SHORTCUT_PAGE_SIZE = 3;
    let pendingShortcutLabelSceneId = null;
    let suppressNextRoomLabelOnLoad = false;
    let autoTourCountdownIntervalId = null;
    let autoTourHomeReturnTimeoutId = null;
    let autoTourHomeReturnCountdownRemaining = 0;
    let suppressShortcutPanelUntilNextLoad = false;
    const mapRuntime = { isOpen: false };
    const mapSequenceInputState = { isOpen: false, value: "", error: "" };
    const floorTagShortcutState = { sceneId: null, floorId: null, pageStart: 0, totalEntries: 0, hasMap: false, visibleEntries: [], isAutoTourActive: false };
    function clearAutoTourCompletionCountdown() {
      if (autoTourCountdownIntervalId !== null) {
        clearInterval(autoTourCountdownIntervalId);
        autoTourCountdownIntervalId = null;
      }
      if (autoTourHomeReturnTimeoutId !== null) {
        clearTimeout(autoTourHomeReturnTimeoutId);
        autoTourHomeReturnTimeoutId = null;
      }
      autoTourHomeReturnCountdownRemaining = 0;
    }
    function beginAutoTourCompletionCountdown() {
      const sid = window.viewer?.getScene?.();
      clearAutoTourCompletionCountdown();
      autoTourHomeReturnCountdownRemaining = 5;
      updateNavShortcutsV2(sid, true);
      autoTourCountdownIntervalId = setInterval(() => {
        if (autoTourHomeReturnCountdownRemaining <= 1) {
          if (autoTourCountdownIntervalId !== null) {
            clearInterval(autoTourCountdownIntervalId);
            autoTourCountdownIntervalId = null;
          }
          autoTourHomeReturnCountdownRemaining = 1;
          const activeSceneId = window.viewer?.getScene?.();
          updateNavShortcutsV2(activeSceneId, true);
          return;
        }
        autoTourHomeReturnCountdownRemaining = autoTourHomeReturnCountdownRemaining - 1;
        const activeSceneId = window.viewer?.getScene?.();
        updateNavShortcutsV2(activeSceneId, true);
      }, 1000);
      autoTourHomeReturnTimeoutId = setTimeout(() => {
        autoTourHomeReturnTimeoutId = null;
        clearAutoTourCompletionCountdown();
        const homeSceneId = resolveExistingSceneId(firstSceneId);
        const currentSceneId = window.viewer?.getScene?.() ?? null;
        if (homeSceneId && currentSceneId && currentSceneId !== homeSceneId) {
          suppressNextRoomLabelOnLoad = true;
          suppressShortcutPanelUntilNextLoad = true;
        }
        navigateToExportHome();
      }, 5000);
    }
    function completeTourAndReturnHome() {
      if (!floorTagShortcutState.isAutoTourActive) return;
      floorTagShortcutState.isAutoTourActive = false;
      window.isAutoTourActive = false;
      document.body.classList.remove('is-auto-tour-active');
      if (waypointRuntime.autoForwardTimeoutId) {
        clearTimeout(waypointRuntime.autoForwardTimeoutId);
        waypointRuntime.autoForwardTimeoutId = null;
      }
      beginAutoTourCompletionCountdown();
    }
    function completeAutoTour() {
      completeTourAndReturnHome();
    }
    function normalizeSceneFloor(sceneData) {
      const floor = typeof sceneData?.floor === "string" ? sceneData.floor.trim() : "";
      return floor === "" ? null : floor;
    }
    function normalizeSceneLabel(sceneData) {
      const label = typeof sceneData?.label === "string" ? sceneData.label.trim() : "";
      return label === "" ? null : label;
    }
    function resolveSceneTagName(sceneId, sceneData) {
      const label = normalizeSceneLabel(sceneData);
      if (label) return label;
      const sceneName = typeof sceneData?.name === "string" ? sceneData.name.trim() : "";
      if (sceneName !== "") return sceneName;
      return sceneId;
    }
    function getSceneLinkCount(sceneId, sceneData) {
      const hotSpots = Array.isArray(sceneData?.hotSpots) ? sceneData.hotSpots : [];
      if (hotSpots.length === 0) return 0;
      let count = 0;
      hotSpots.forEach((hotspot, hotspotIndex) => {
        const targetSceneId = resolveTargetSceneId({
          sourceSceneId: sceneId,
          i: hotspotIndex,
          targetSceneId: hotspot?.targetSceneId,
          target: hotspot?.target,
          targetName: hotspot?.target
        }, null);
        if (targetSceneId) count = count + 1;
      });
      return count;
    }
    function buildMapEntries() {
      const floorToScenes = new Map();
      if (scenesData && typeof scenesData === "object") {
        for (const [sceneId, sceneData] of Object.entries(scenesData)) {
          const floorId = normalizeSceneFloor(sceneData);
          if (!floorId) continue;
          if (!floorToScenes.has(floorId)) floorToScenes.set(floorId, []);
          floorToScenes.get(floorId).push({ sceneId, sceneData });
        }
      }
      const entries = [];
      EXPORT_MAP_FLOOR_LEVELS.forEach(level => {
        const scenesInFloor = floorToScenes.get(level.id);
        if (!scenesInFloor || scenesInFloor.length === 0) return;
        let best = scenesInFloor[0];
        let bestLinks = getSceneLinkCount(best.sceneId, best.sceneData);
        for (let i = 1; i < scenesInFloor.length; i = i + 1) {
          const candidate = scenesInFloor[i];
          const candidateLinks = getSceneLinkCount(candidate.sceneId, candidate.sceneData);
          if (candidateLinks > bestLinks) {
            best = candidate;
            bestLinks = candidateLinks;
          }
        }
        entries.push({
          shortcut: level.shortcut,
          floorLabel: level.mapLabel,
          sceneId: best.sceneId,
          tagName: resolveSceneTagName(best.sceneId, best.sceneData),
        });
      });
      return entries;
    }
    function navigateExportMapShortcut(shortcutKey) {
      if (typeof shortcutKey !== "string" || shortcutKey === "") return false;
      const normalizedShortcut = shortcutKey.toLowerCase();
      const mapEntries = buildMapEntries();
      const currentSceneId = window.viewer?.getScene?.() ?? null;
      for (let i = 0; i < mapEntries.length; i = i + 1) {
        const entry = mapEntries[i];
        const entryShortcut = typeof entry?.shortcut === "string" ? entry.shortcut.toLowerCase() : "";
        if (entryShortcut !== normalizedShortcut) continue;
        if (currentSceneId && entry.sceneId === currentSceneId) return true;
        navigateToFloorTagShortcut(entry.sceneId, { fromMap: true });
        return true;
      }
      return false;
    }
    function isExportMapOpen() {
      return mapRuntime.isOpen === true;
    }
    function setExportMapOpen(nextOpen) {
      const willOpen = nextOpen === true;
      if (mapRuntime.isOpen === willOpen) return;
      mapRuntime.isOpen = willOpen;
      if (willOpen) {
        document.body.classList.add("is-map-open");
      } else {
        document.body.classList.remove("is-map-open");
      }
    }
    function openExportMap() {
      if (isExportMapOpen()) return;
      if (!floorTagShortcutState.hasMap) return;
      if (floorTagShortcutState.isAutoTourActive && typeof stopAutoTour === "function") {
        stopAutoTour();
      }
      if (typeof lookingMode !== "undefined") lookingMode = false;
      if (typeof updateLookingModeUI === "function") updateLookingModeUI();
      setExportMapOpen(true);
      const sid = window.viewer?.getScene?.() ?? floorTagShortcutState.sceneId;
      if (sid) updateNavShortcutsV2(sid, true);
    }
    function closeExportMap() {
      if (!isExportMapOpen()) return;
      setExportMapOpen(false);
      mapSequenceInputState.isOpen = false;
      mapSequenceInputState.value = "";
      mapSequenceInputState.error = "";
      if (typeof removeMapSequencePromptPanel === "function") {
        removeMapSequencePromptPanel();
      }
      if (typeof manualLookingMode !== "undefined" && typeof lookingMode !== "undefined") {
        lookingMode = manualLookingMode;
      }
      if (typeof updateLookingModeUI === "function") updateLookingModeUI();
      const sid = window.viewer?.getScene?.() ?? floorTagShortcutState.sceneId;
      if (sid) updateNavShortcutsV2(sid, true);
    }
    function toggleExportMap() {
      if (isExportMapOpen()) {
        closeExportMap();
      } else {
        openExportMap();
      }
    }
    function renderExportMapRows(panel, mapEntries) {
      if (!panel) return;
      while (panel.firstChild) panel.removeChild(panel.firstChild);
      panel.classList.remove("state-hidden");
      const currentSceneId = window.viewer?.getScene?.() ?? floorTagShortcutState.sceneId ?? null;
      const appendExitRow = () => {
        const exitRow = document.createElement("button");
        exitRow.type = "button";
        exitRow.className = "floor-map-shortcut-row floor-map-shortcut-row-exit";
        exitRow.setAttribute("aria-label", "Exit map mode");
        exitRow.addEventListener("click", closeExportMap);

        const exitIndicatorEl = document.createElement("span");
        exitIndicatorEl.className = "shortcut-indicator-arrow";
        exitIndicatorEl.innerHTML = '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M12 5l7 7-7 7"/></svg>';

        const exitKeyEl = document.createElement("span");
        exitKeyEl.className = "floor-map-shortcut-key";
        exitKeyEl.textContent = "e";

        const exitTextEl = document.createElement("span");
        exitTextEl.className = "floor-map-shortcut-text";
        exitTextEl.textContent = "Exit Map Mode";

        exitRow.appendChild(exitIndicatorEl);
        exitRow.appendChild(exitKeyEl);
        exitRow.appendChild(exitTextEl);
        panel.appendChild(exitRow);
      };
      const appendJumpBySequenceRow = () => {
        const jumpRow = document.createElement("button");
        jumpRow.type = "button";
        jumpRow.className = "floor-map-shortcut-row";
        jumpRow.setAttribute("aria-label", "Jump to scene");
        jumpRow.addEventListener("click", () => {
          if (typeof openSceneSequencePrompt === "function") {
            openSceneSequencePrompt();
          }
        });

        const jumpIndicatorEl = document.createElement("span");
        jumpIndicatorEl.className = "shortcut-indicator-arrow";
        jumpIndicatorEl.innerHTML = '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M12 5l7 7-7 7"/></svg>';

        const jumpKeyEl = document.createElement("span");
        jumpKeyEl.className = "floor-map-shortcut-key";
        jumpKeyEl.textContent = "n";

        const jumpTextEl = document.createElement("span");
        jumpTextEl.className = "floor-map-shortcut-text";
        jumpTextEl.textContent = "Jump to Scene";

        jumpRow.appendChild(jumpIndicatorEl);
        jumpRow.appendChild(jumpKeyEl);
        jumpRow.appendChild(jumpTextEl);
        panel.appendChild(jumpRow);
      };
      if (!mapEntries || mapEntries.length === 0) {
        if (typeof renderMapSequencePromptPanel === "function") {
          renderMapSequencePromptPanel(panel);
        }
        const emptyRow = document.createElement("div");
        emptyRow.className = "floor-map-shortcut-empty";
        emptyRow.textContent = "no mapped floors available";
        panel.appendChild(emptyRow);
        appendJumpBySequenceRow();
        appendExitRow();
        return;
      }
      if (typeof renderMapSequencePromptPanel === "function") {
        renderMapSequencePromptPanel(panel);
      }
      mapEntries.forEach(entry => {
        const row = document.createElement("button");
        row.type = "button";
        const isCurrentScene = currentSceneId && entry.sceneId === currentSceneId;
        row.className = "floor-map-shortcut-row" + (isCurrentScene ? " state-current state-selected" : "");
        row.setAttribute("aria-label", entry.floorLabel + ": " + entry.tagName);
        if (isCurrentScene) {
          row.setAttribute("aria-current", "true");
          row.disabled = true;
        } else {
          row.addEventListener("click", () => {
            navigateToFloorTagShortcut(entry.sceneId, { fromMap: true, mapSelectedRow: row });
          });
        }

        const indicatorEl = document.createElement("span");
        indicatorEl.className = "shortcut-indicator-arrow";
        indicatorEl.innerHTML = '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M12 5l7 7-7 7"/></svg>';

        const keyEl = document.createElement("span");
        keyEl.className = "floor-map-shortcut-key";
        keyEl.textContent = entry.shortcut;

        const textEl = document.createElement("span");
        textEl.className = "floor-map-shortcut-text";
        textEl.textContent = entry.floorLabel + ": " + entry.tagName;

        row.appendChild(indicatorEl);
        row.appendChild(keyEl);
        row.appendChild(textEl);
        panel.appendChild(row);
      });
      appendJumpBySequenceRow();
      appendExitRow();
    }
`
