let script = `
    const EXPORT_FLOOR_LEVELS = [
      { id: "b2", label: "Basement 2", short: "B", suffix: "-2" },
      { id: "b1", label: "Basement 1", short: "B", suffix: "-1" },
      { id: "ground", label: "Ground Floor", short: "G", suffix: "" },
      { id: "first", label: "First Floor", short: "+1", suffix: "" },
      { id: "second", label: "Second Floor", short: "+2", suffix: "" },
      { id: "third", label: "Third Floor", short: "+3", suffix: "" },
      { id: "fourth", label: "Fourth Floor", short: "+4", suffix: "" },
      { id: "roof", label: "Roof Top", short: "R", suffix: "" }
    ];
    const FLOOR_TAG_SHORTCUT_PAGE_SIZE = 3;
    let pendingShortcutLabelSceneId = null;
    const floorTagShortcutState = {
      sceneId: null,
      floorId: null,
      pageStart: 0,
      totalEntries: 0,
      hasMore: false,
      visibleEntries: [],
    };
    function normalizeSceneFloor(sceneData) {
      const floor = typeof sceneData?.floor === "string" ? sceneData.floor.trim() : "";
      return floor === "" ? null : floor;
    }
    function normalizeSceneLabel(sceneData) {
      const label = typeof sceneData?.label === "string" ? sceneData.label.trim() : "";
      return label === "" ? null : label;
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
    function clearExportFloorTagShortcuts(panel) {
      floorTagShortcutState.totalEntries = 0;
      floorTagShortcutState.hasMore = false;
      floorTagShortcutState.visibleEntries = [];
      if (!panel) return;
      while (panel.firstChild) panel.removeChild(panel.firstChild);
      panel.classList.add("state-hidden");
    }
    function buildFloorTagEntries(sceneId) {
      const activeFloorId = normalizeSceneFloor(scenesData?.[sceneId]);
      if (!activeFloorId) return { floorId: null, entries: [] };
      const entries = [];
      for (const [candidateSceneId, candidateSceneData] of Object.entries(scenesData || {})) {
        if (candidateSceneId === sceneId) continue;
        if (normalizeSceneFloor(candidateSceneData) !== activeFloorId) continue;
        const label = normalizeSceneLabel(candidateSceneData);
        if (!label) continue;
        entries.push({ sceneId: candidateSceneId, label: label });
      }
      return { floorId: activeFloorId, entries: entries };
    }
    function navigateToFloorTagShortcut(targetSceneId) {
      if (!window.viewer || typeof window.viewer.getScene !== "function") return;
      const row = document.querySelector('.floor-tag-shortcut-row[data-scene-id="' + String(targetSceneId) + '"]');
      if (row) {
        row.classList.add("state-selected");
        setTimeout(() => {
          row.classList.remove("state-selected");
        }, 500);
      }
      const resolvedTargetSceneId = resolveExistingSceneId(targetSceneId);
      if (!resolvedTargetSceneId) return;
      if (window.viewer.getScene() === resolvedTargetSceneId) {
        pendingShortcutLabelSceneId = resolvedTargetSceneId;
        updateExportRoomLabel(resolvedTargetSceneId, true);
        pendingShortcutLabelSceneId = null;
        updateExportFloorTagShortcuts(resolvedTargetSceneId, true);
        return;
      }
      pendingShortcutLabelSceneId = resolvedTargetSceneId;
      navigateToNextScene({ targetSceneId: resolvedTargetSceneId }, resolvedTargetSceneId);
    }
    function navigateToExportHome() {
      if (!window.viewer || typeof window.viewer.getScene !== "function") return;
      const homeSceneId = resolveExistingSceneId(firstSceneId);
      if (!homeSceneId) return;
      if (window.viewer.getScene() === homeSceneId) {
        pendingShortcutLabelSceneId = homeSceneId;
        updateExportRoomLabel(homeSceneId, true);
        pendingShortcutLabelSceneId = null;
        updateExportFloorTagShortcuts(homeSceneId, true);
        return;
      }
      pendingShortcutLabelSceneId = homeSceneId;
      navigateToNextScene({ targetSceneId: homeSceneId }, homeSceneId);
    }
    function cycleExportFloorTagShortcutPage() {
      if (!floorTagShortcutState.hasMore) return;
      if (!floorTagShortcutState.sceneId) return;
      const total = floorTagShortcutState.totalEntries;
      if (total <= FLOOR_TAG_SHORTCUT_PAGE_SIZE) return;
      floorTagShortcutState.pageStart =
        (floorTagShortcutState.pageStart + FLOOR_TAG_SHORTCUT_PAGE_SIZE) % total;
      updateExportFloorTagShortcuts(floorTagShortcutState.sceneId, false);
    }
    function updateExportFloorTagShortcuts(sceneId, resetPage) {
      const panel = document.getElementById("viewer-floor-tags-export");
      if (!panel) return;
      const sceneEntries = buildFloorTagEntries(sceneId);
      const floorId = sceneEntries.floorId;
      const entries = sceneEntries.entries;
      const previousFloorId = floorTagShortcutState.floorId;
      const previousSceneId = floorTagShortcutState.sceneId;
      const shouldResetPage =
        resetPage === true ||
        previousFloorId !== floorId ||
        previousSceneId !== sceneId;
      floorTagShortcutState.sceneId = sceneId;
      floorTagShortcutState.floorId = floorId;
      if (!floorId || entries.length === 0) {
        floorTagShortcutState.pageStart = 0;
        clearExportFloorTagShortcuts(panel);
        return;
      }
      if (shouldResetPage) floorTagShortcutState.pageStart = 0;
      const total = entries.length;
      if (floorTagShortcutState.pageStart >= total) floorTagShortcutState.pageStart = 0;
      const visibleEntries = entries.slice(
        floorTagShortcutState.pageStart,
        floorTagShortcutState.pageStart + FLOOR_TAG_SHORTCUT_PAGE_SIZE,
      );
      while (panel.firstChild) panel.removeChild(panel.firstChild);
      panel.classList.remove("state-hidden");
      visibleEntries.forEach((entry, index) => {
        const row = document.createElement("button");
        row.type = "button";
        row.className = "floor-tag-shortcut-row";
        row.setAttribute("data-scene-id", entry.sceneId);
        row.setAttribute("aria-label", "Shortcut " + String(index + 1) + " " + entry.label);
        row.addEventListener("click", () => navigateToFloorTagShortcut(entry.sceneId));

        const arrowEl = document.createElement("span");
        arrowEl.className = "shortcut-indicator-arrow";
        arrowEl.innerHTML = '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M12 5l7 7-7 7"/></svg>';

        const indexEl = document.createElement("span");
        indexEl.className = "floor-tag-shortcut-index";
        indexEl.textContent = String(index + 1);

        const labelEl = document.createElement("span");
        labelEl.className = "floor-tag-shortcut-label";
        labelEl.textContent = entry.label;

        row.appendChild(arrowEl);
        row.appendChild(indexEl);
        row.appendChild(labelEl);
        panel.appendChild(row);
      });
      const hasMore = total > FLOOR_TAG_SHORTCUT_PAGE_SIZE;
      if (hasMore) {
        const moreRow = document.createElement("button");
        moreRow.type = "button";
        moreRow.className = "floor-tag-shortcut-row";
        moreRow.setAttribute("aria-label", "More shortcuts. Press H to go home.");
        moreRow.addEventListener("click", () => cycleExportFloorTagShortcutPage());

        const spacer = document.createElement("span");
        spacer.className = "shortcut-indicator-spacer";

        const moreIndex = document.createElement("span");
        moreIndex.className = "floor-tag-shortcut-index";
        moreIndex.textContent = "m";

        const moreLabel = document.createElement("span");
        moreLabel.className = "floor-tag-shortcut-label";
        moreLabel.textContent = "more \u00A0|\u00A0 h home";

        moreRow.appendChild(spacer);
        moreRow.appendChild(moreIndex);
        moreRow.appendChild(moreLabel);
        panel.appendChild(moreRow);
      }
      floorTagShortcutState.totalEntries = total;
      floorTagShortcutState.hasMore = hasMore;
      floorTagShortcutState.visibleEntries = visibleEntries;
    }
`
