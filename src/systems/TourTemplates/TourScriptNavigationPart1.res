let script = `
    function getSceneHotspots(sceneId) {
      return Array.from(document.querySelectorAll('.pnlm-hotspot.flat-arrow')).filter(el => el.dataset.ownerScene === sceneId);
    }
    function setSceneHotspotsPending(sceneId) {
      getSceneHotspots(sceneId).forEach(el => {
        el.classList.remove('waypoint-ready');
        el.classList.add('waypoint-pending');
        el.dataset.ready = 'false';
      });
    }
    function setSceneHotspotsReady(sceneId) {
      getSceneHotspots(sceneId).forEach(el => {
        el.classList.remove('waypoint-pending');
        el.classList.add('waypoint-ready');
        el.dataset.ready = 'true';
      });
    }
    function setSceneHotspotsReadyWithRetry(sceneId, retries) {
      const hotspots = getSceneHotspots(sceneId);
      hotspots.forEach(el => {
        el.classList.remove('waypoint-pending');
        el.classList.add('waypoint-ready');
        el.dataset.ready = 'true';
      });
      if (window.viewer.getScene() !== sceneId) return;
      const needsRetry = hotspots.length === 0 || hotspots.some(el => el.dataset.ready !== 'true');
      if (!needsRetry || retries <= 0) return;
      waypointRuntime.readyTimeoutId = setTimeout(() => setSceneHotspotsReadyWithRetry(sceneId, retries - 1), 80);
    }
    function resolveDestinationView(args, options) {
      let y = 90, p = 0;
      if (Number.isFinite(options?.destinationOverride?.yaw) && Number.isFinite(options?.destinationOverride?.pitch)) {
        y = options.destinationOverride.yaw;
        p = options.destinationOverride.pitch;
      } else
      if (args.isReturnLink && args.returnViewFrame) { y = args.returnViewFrame.yaw ?? 90; p = args.returnViewFrame.pitch ?? 0; }
      else { if (args.targetYaw !== undefined && args.targetYaw !== null) { y = args.targetYaw; p = args.targetPitch ?? 0; } else if (args.viewFrame) { y = args.viewFrame.yaw ?? 90; p = args.viewFrame.pitch ?? 0; } }
      return { yaw: y, pitch: p };
    }
    function normalizeSceneId(candidate) {
      if (typeof candidate !== "string") return null;
      let value = candidate.trim();
      if (!value) return null;
      try { value = decodeURIComponent(value); } catch (_) {}
      value = value.replaceAll("\\\\", "/");
      if (value.startsWith("./")) value = value.slice(2);
      if (value.startsWith("/")) value = value.slice(1);
      if (value.startsWith("assets/images/")) value = value.slice("assets/images/".length);
      value = value.trim();
      return value.length > 0 ? value : null;
    }
    function stripSceneExtension(sceneId) {
      const lower = sceneId.toLowerCase();
      const exts = [".jpeg", ".jpg", ".png", ".webp", ".avif"];
      for (const ext of exts) {
        if (lower.endsWith(ext)) return sceneId.slice(0, sceneId.length - ext.length);
      }
      return sceneId;
    }
    function getExportSceneIds() {
      if (scenesData && typeof scenesData === "object") {
        const sceneIds = Object.keys(scenesData);
        if (sceneIds.length > 0) return sceneIds;
      }
      if (config && config.scenes && typeof config.scenes === "object") {
        return Object.keys(config.scenes);
      }
      return [];
    }
    function resolveExistingSceneId(candidate) {
      const normalized = normalizeSceneId(candidate);
      if (!normalized) return null;
      const sceneIds = getExportSceneIds();
      if (sceneIds.length === 0) return normalized;
      if (sceneIds.includes(normalized)) return normalized;
      const normalizedNoExt = stripSceneExtension(normalized).toLowerCase();
      for (const sceneId of sceneIds) {
        if (sceneId.toLowerCase() === normalized.toLowerCase()) return sceneId;
      }
      for (const sceneId of sceneIds) {
        if (stripSceneExtension(sceneId).toLowerCase() === normalizedNoExt) return sceneId;
      }
      const normalizedBase = normalized.split("/").pop();
      const normalizedBaseNoExt = stripSceneExtension(normalizedBase ?? normalized).toLowerCase();
      if (normalizedBase && normalizedBase !== normalized) {
        for (const sceneId of sceneIds) {
          if (sceneId.toLowerCase() === normalizedBase.toLowerCase()) return sceneId;
          if (stripSceneExtension(sceneId).toLowerCase() === stripSceneExtension(normalizedBase).toLowerCase()) return sceneId;
        }
      }
      for (const sceneId of sceneIds) {
        const sceneNameRaw = scenesData?.[sceneId]?.name;
        const sceneName = normalizeSceneId(typeof sceneNameRaw === "string" ? sceneNameRaw : "");
        if (!sceneName) continue;
        const sceneNameNoExt = stripSceneExtension(sceneName).toLowerCase();
        const sceneNameBase = sceneName.split("/").pop() ?? sceneName;
        const sceneNameBaseNoExt = stripSceneExtension(sceneNameBase).toLowerCase();
        if (sceneName === normalized) return sceneId;
        if (sceneName.toLowerCase() === normalized.toLowerCase()) return sceneId;
        if (sceneNameNoExt === normalizedNoExt) return sceneId;
        if (sceneNameBase.toLowerCase() === (normalizedBase ?? normalized).toLowerCase()) return sceneId;
        if (sceneNameBaseNoExt === normalizedBaseNoExt) return sceneId;
      }
      return null;
    }
    function hasExportScene(sceneId) {
      return resolveExistingSceneId(sceneId) !== null;
    }
    const AUTO_FORWARD_MAX_HOPS = 24;
    let autoForwardChainVisited = [];
    let autoForwardChainActive = false;
    const defaultSceneSequenceCursorByScene = new Map();
    const sceneIdBySequencePosition = new Map();
    const firstSequencePositionBySceneId = new Map();
    const currentSceneSequenceContext = { sceneId: null, sequenceCursor: null, sourceSceneId: null };
    let pendingArrivalContext = null;
    const autoTourSteps = Array.isArray(autoTourManifest?.steps) ? autoTourManifest.steps : [];
    let autoTourManifestCursor = 0;
    function resetAutoTourManifestCursor() {
      autoTourManifestCursor = 0;
    }
    function getAutoTourFinalSceneId() {
      const configuredFinalSceneId = resolveExistingSceneId(autoTourManifest?.finalSceneId);
      if (configuredFinalSceneId) return configuredFinalSceneId;
      const lastStep = autoTourSteps.length > 0 ? autoTourSteps[autoTourSteps.length - 1] : null;
      return resolveExistingSceneId(lastStep?.targetSceneId)
        ?? resolveExistingSceneId(firstSceneId)
        ?? normalizeSceneId(firstSceneId);
    }
    function findAutoTourManifestStepIndex(sceneId, startIndex) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId || autoTourSteps.length === 0) return -1;
      const normalizedStartIndex = Number.isInteger(startIndex) && startIndex >= 0
        ? Math.min(startIndex, autoTourSteps.length - 1)
        : 0;
      return autoTourSteps.findIndex((step, idx) => {
        if (idx < normalizedStartIndex) return false;
        const sourceSceneId = resolveExistingSceneId(step?.sourceSceneId) ?? normalizeSceneId(step?.sourceSceneId);
        return sourceSceneId === resolvedSceneId;
      });
    }
    function resolveAutoTourManifestStep(sceneId) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId || autoTourSteps.length === 0) return null;
      const currentStep = autoTourSteps[autoTourManifestCursor];
      const currentSourceSceneId =
        resolveExistingSceneId(currentStep?.sourceSceneId) ?? normalizeSceneId(currentStep?.sourceSceneId);
      if (currentSourceSceneId === resolvedSceneId) {
        return currentStep;
      }
      const nextIndex = findAutoTourManifestStepIndex(resolvedSceneId, autoTourManifestCursor);
      if (nextIndex < 0) return null;
      autoTourManifestCursor = nextIndex;
      return autoTourSteps[nextIndex] ?? null;
    }
    function advanceAutoTourManifestCursor(sceneId, targetSceneId) {
      const step = resolveAutoTourManifestStep(sceneId);
      if (!step) return false;
      const resolvedTargetSceneId = resolveExistingSceneId(targetSceneId) ?? normalizeSceneId(targetSceneId);
      const stepTargetSceneId =
        resolveExistingSceneId(step?.targetSceneId) ?? normalizeSceneId(step?.targetSceneId);
      if (resolvedTargetSceneId && stepTargetSceneId && resolvedTargetSceneId !== stepTargetSceneId) {
        return false;
      }
      autoTourManifestCursor = Math.min(autoTourManifestCursor + 1, autoTourSteps.length);
      return true;
    }
    function buildPlaybackTargetFromAutoTourStep(sceneId) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      const homeSceneId = resolveExistingSceneId(firstSceneId);
      if (resolvedSceneId && homeSceneId && autoTourManifestCursor > 0 && resolvedSceneId === homeSceneId) {
        return null;
      }
      const step = resolveAutoTourManifestStep(sceneId);
      if (!step || !step.hotspot) return null;
      const targetSceneId = resolveExistingSceneId(step?.targetSceneId) ?? normalizeSceneId(step?.targetSceneId);
      if (!targetSceneId) return null;
      return {
        hotspot: step.hotspot,
        hotspotIndex: Number.isInteger(step?.hotspotIndex) ? step.hotspotIndex : null,
        autoForward: step.targetIsAutoForward === true,
        targetSceneId,
        usesReturnLink: step.isReturnLink === true,
        backtrack: step.isReturnLink === true,
        sequenceCursorOverride: Number.isInteger(step?.sequenceCursor) ? step.sequenceCursor : null,
        fromManifest: true,
      };
    }
    function resetAutoForwardLoopGuard() {
      autoForwardChainVisited = [];
      autoForwardChainActive = false;
    }
    function beginAutoForwardChain() {
      if (!autoForwardChainActive) {
        autoForwardChainVisited = [];
      }
      autoForwardChainActive = true;
    }
    function trackAutoForwardSource(sceneId) {
      if (!sceneId) return;
      if (!autoForwardChainVisited.includes(sceneId)) {
        autoForwardChainVisited.push(sceneId);
      }
    }
    function shouldBlockAutoForward(sourceSceneId, targetSceneId) {
      if (!sourceSceneId || !targetSceneId) return false;
      if (sourceSceneId === targetSceneId) return true;
      if (autoForwardChainVisited.length >= AUTO_FORWARD_MAX_HOPS) return true;
      return autoForwardChainVisited.includes(targetSceneId);
    }
    function pushDefaultSceneSequenceCursor(sceneId, sequenceNumber) {
      if (!sceneId || !Number.isInteger(sequenceNumber) || sequenceNumber < 0) return;
      const existing = defaultSceneSequenceCursorByScene.get(sceneId);
      if (!Number.isInteger(existing) || sequenceNumber < existing) {
        defaultSceneSequenceCursorByScene.set(sceneId, sequenceNumber);
      }
    }
    function pushSceneSequencePosition(sceneId, sequencePosition) {
      if (!sceneId || !Number.isInteger(sequencePosition) || sequencePosition < 1) return;
      if (!sceneIdBySequencePosition.has(sequencePosition)) {
        sceneIdBySequencePosition.set(sequencePosition, sceneId);
      }
      const existing = firstSequencePositionBySceneId.get(sceneId);
      if (!Number.isInteger(existing) || sequencePosition < existing) {
        firstSequencePositionBySceneId.set(sceneId, sequencePosition);
      }
    }
    function buildDefaultSceneSequenceCursorMap() {
      if (defaultSceneSequenceCursorByScene.size > 0) return;
      const homeSceneId = resolveExistingSceneId(firstSceneId);
      if (homeSceneId) pushDefaultSceneSequenceCursor(homeSceneId, 0);
      Object.entries(scenesData || {}).forEach(([sceneId, sceneData]) => {
        const sequenceEdges = Array.isArray(sceneData?.sequenceEdges) ? sceneData.sequenceEdges : [];
        sequenceEdges.forEach(edge => {
          const targetSceneId = resolveExistingSceneId(edge?.targetSceneId);
          if (!targetSceneId) return;
          const sequenceNumber = Number.isFinite(edge?.sequenceNumber)
            ? Math.trunc(edge.sequenceNumber)
            : null;
          if (!Number.isInteger(sequenceNumber) || sequenceNumber < 1) return;
          pushDefaultSceneSequenceCursor(targetSceneId, sequenceNumber);
        });
      });
    }
    function buildSceneSequencePositionMaps() {
      if (sceneIdBySequencePosition.size > 0) return;
      const homeSceneId = resolveExistingSceneId(firstSceneId);
      if (homeSceneId) {
        pushSceneSequencePosition(homeSceneId, 1);
      }
      Object.entries(scenesData || {}).forEach(([sourceSceneId, sourceSceneData]) => {
        const sequenceEdges = Array.isArray(sourceSceneData?.sequenceEdges) ? sourceSceneData.sequenceEdges : [];
        sequenceEdges.forEach(edge => {
          const seqRaw = Number.isFinite(edge?.sequenceNumber) ? Math.trunc(edge.sequenceNumber) : null;
          if (!Number.isInteger(seqRaw) || seqRaw < 1) return;
          const targetSceneId = resolveExistingSceneId(edge?.targetSceneId);
          if (targetSceneId) {
            pushSceneSequencePosition(targetSceneId, seqRaw + 1);
          }
        });
      });
    }
    function resolveSceneIdForSequencePosition(sequencePosition) {
      if (!Number.isInteger(sequencePosition) || sequencePosition < 1) return null;
      buildSceneSequencePositionMaps();
      return resolveExistingSceneId(sceneIdBySequencePosition.get(sequencePosition)) ?? null;
    }
    function resolveFirstSequencePositionForScene(sceneId) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return null;
      buildSceneSequencePositionMaps();
      const existing = firstSequencePositionBySceneId.get(resolvedSceneId);
      return Number.isInteger(existing) && existing >= 1 ? existing : null;
    }
    function applyManualSequencePosition(sceneId, sequencePosition) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return false;
      if (!Number.isInteger(sequencePosition) || sequencePosition < 1) return false;
      currentSceneSequenceContext.sceneId = resolvedSceneId;
      currentSceneSequenceContext.sequenceCursor = Math.max(0, sequencePosition - 1);
      currentSceneSequenceContext.sourceSceneId =
        resolveSceneIdForSequencePosition(sequencePosition - 1);
      pendingArrivalContext = null;
      return true;
    }
    function resolveDefaultSceneSequenceCursor(sceneId) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return 1;
      buildDefaultSceneSequenceCursorMap();
      const defaultCursor = defaultSceneSequenceCursorByScene.get(resolvedSceneId);
      return Number.isInteger(defaultCursor) ? defaultCursor : 1;
    }
    function getCurrentSceneSequenceCursor(sceneId, sceneData) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return 1;
      if (
        currentSceneSequenceContext.sceneId === resolvedSceneId &&
        Number.isInteger(currentSceneSequenceContext.sequenceCursor)
      ) {
        return currentSceneSequenceContext.sequenceCursor;
      }
      return resolveDefaultSceneSequenceCursor(resolvedSceneId);
    }
    function getCurrentSceneSourceSceneId(sceneId) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return null;
      if (currentSceneSequenceContext.sceneId !== resolvedSceneId) return null;
      return resolveExistingSceneId(currentSceneSequenceContext.sourceSceneId)
        ?? normalizeSceneId(currentSceneSequenceContext.sourceSceneId);
    }
    function applyPendingSequenceContext(sceneId) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return;
      if (
        pendingArrivalContext?.targetSceneId === resolvedSceneId &&
        Number.isInteger(pendingArrivalContext?.sequenceCursor)
      ) {
        currentSceneSequenceContext.sceneId = resolvedSceneId;
        currentSceneSequenceContext.sequenceCursor = pendingArrivalContext.sequenceCursor;
        currentSceneSequenceContext.sourceSceneId = pendingArrivalContext.sourceSceneId ?? null;
        return;
      }
      currentSceneSequenceContext.sceneId = resolvedSceneId;
      currentSceneSequenceContext.sequenceCursor = resolveDefaultSceneSequenceCursor(resolvedSceneId);
      currentSceneSequenceContext.sourceSceneId = null;
    }
    function resolveTargetSceneId(args, forceTargetSceneId) {
      const ownerSceneId = resolveExistingSceneId(args?.sourceSceneId) ?? normalizeSceneId(args?.sourceSceneId);
      const hotspotIndex = Number.isInteger(args?.i) ? args.i : null;
      const ownerHotspot = ownerSceneId !== null && hotspotIndex !== null && hotspotIndex >= 0
        ? scenesData?.[ownerSceneId]?.hotSpots?.[hotspotIndex]
        : null;
      const ownerTarget = ownerSceneId !== null && hotspotIndex !== null && hotspotIndex >= 0
        ? ownerHotspot?.targetSceneId ?? ownerHotspot?.target
        : null;
      const candidates = [
        forceTargetSceneId,
        ownerTarget,
        args?.targetSceneId,
        args?.target,
        args?.targetName,
        args?.targetId
      ];
      for (const candidate of candidates) {
        const resolved = resolveExistingSceneId(candidate);
        if (resolved) return resolved;
      }
      return null;
    }
    function buildResolvedHotspots(sceneId, sceneData) {
      const hotspots = Array.isArray(sceneData?.hotSpots) ? sceneData.hotSpots : [];
      return hotspots.map((hotspot, hotspotIndex) => {
        const directTarget = resolveExistingSceneId(hotspot?.targetSceneId);
        const resolvedTarget = resolveTargetSceneId({
          sourceSceneId: sceneId,
          i: hotspotIndex,
`
