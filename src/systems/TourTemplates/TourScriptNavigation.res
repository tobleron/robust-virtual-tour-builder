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
          targetSceneId: hotspot?.targetSceneId,
          target: hotspot?.target,
          targetName: hotspot?.target,
        }, null) ?? directTarget;
        const isAutoForward = hotspotIndex === sceneData?.autoForwardHotspotIndex;
        const isReturn = hotspot?.isReturnLink === true;
        return { hotspot, hotspotIndex, resolvedTarget, isAutoForward, isReturn };
      });
    }
    function sortCanonicalHotspots(resolvedHotspots) {
      return resolvedHotspots.slice().sort((a, b) => {
        const seqA = Number.isFinite(a?.hotspot?.sequenceNumber) ? Math.trunc(a.hotspot.sequenceNumber) : null;
        const seqB = Number.isFinite(b?.hotspot?.sequenceNumber) ? Math.trunc(b.hotspot.sequenceNumber) : null;
        const rankA = a.isReturn ? 900000 + a.hotspotIndex : (seqA !== null ? seqA : 100000 + a.hotspotIndex);
        const rankB = b.isReturn ? 900000 + b.hotspotIndex : (seqB !== null ? seqB : 100000 + b.hotspotIndex);
        if (rankA !== rankB) return rankA - rankB;
        if (a.isAutoForward !== b.isAutoForward) return a.isAutoForward ? 1 : -1;
        return a.hotspotIndex - b.hotspotIndex;
      });
    }
    function getSceneSequenceEdges(sceneId, sceneData) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return [];
      const edges = Array.isArray(sceneData?.sequenceEdges) ? sceneData.sequenceEdges.slice() : [];
      return edges
        .filter(edge => {
          const targetSceneId = resolveExistingSceneId(edge?.targetSceneId);
          const sequenceNumber = Number.isFinite(edge?.sequenceNumber)
            ? Math.trunc(edge.sequenceNumber)
            : null;
          return !!targetSceneId && Number.isInteger(sequenceNumber) && sequenceNumber >= 1;
        })
        .map(edge => ({
          ...edge,
          targetSceneId: resolveExistingSceneId(edge.targetSceneId) ?? edge.targetSceneId,
          sequenceNumber: Math.trunc(edge.sequenceNumber),
          visibleHotspotIndex: Number.isFinite(edge?.visibleHotspotIndex)
            ? Math.trunc(edge.visibleHotspotIndex)
            : -1,
        }))
        .sort((a, b) => {
          if (a.sequenceNumber !== b.sequenceNumber) return a.sequenceNumber - b.sequenceNumber;
          return a.visibleHotspotIndex - b.visibleHotspotIndex;
        });
    }
    function resolveVisibleHotspotByIndex(sceneData, hotspotIndex) {
      const hotspots = Array.isArray(sceneData?.hotSpots) ? sceneData.hotSpots : [];
      if (!Number.isInteger(hotspotIndex) || hotspotIndex < 0) return null;
      return hotspots[hotspotIndex] ?? null;
    }
    function resolveVisibleHotspotForSequenceEdge(sceneData, edge) {
      if (!edge) return null;
      return resolveVisibleHotspotByIndex(sceneData, edge.visibleHotspotIndex);
    }
    function resolveNextForwardSequenceEdge(sceneId, sceneData) {
      const currentCursor = getCurrentSceneSequenceCursor(sceneId, sceneData);
      const sequenceEdges = getSceneSequenceEdges(sceneId, sceneData);
      return sequenceEdges.find(edge => edge.sequenceNumber > currentCursor) ?? null;
    }
    function resolveSequenceEdgeForVisibleHotspot(sceneId, sceneData, visibleHotspotIndex) {
      const currentCursor = getCurrentSceneSequenceCursor(sceneId, sceneData);
      const matchingEdges = getSceneSequenceEdges(sceneId, sceneData).filter(
        edge => edge.visibleHotspotIndex === visibleHotspotIndex,
      );
      if (matchingEdges.length === 0) return null;
      const nextEdge = matchingEdges.find(edge => edge.sequenceNumber > currentCursor);
      return nextEdge ?? matchingEdges[matchingEdges.length - 1];
    }
    function resolveForwardHotspotByTargetScene(sceneId, sceneData, targetSceneId) {
      const resolvedTargetSceneId = resolveExistingSceneId(targetSceneId);
      if (!resolvedTargetSceneId) return null;
      const resolvedHotspots = buildResolvedHotspots(sceneId, sceneData);
      return (
        sortCanonicalHotspots(resolvedHotspots).find(
          h => !h.isReturn && h.resolvedTarget === resolvedTargetSceneId,
        ) ?? null
      );
    }
    function resolveHotspotByTargetScene(sceneId, sceneData, targetSceneId, options) {
      const resolvedTargetSceneId = resolveExistingSceneId(targetSceneId);
      if (!resolvedTargetSceneId) return null;
      const includeReturn = options?.includeReturn === true;
      const resolvedHotspots = buildResolvedHotspots(sceneId, sceneData);
      return (
        sortCanonicalHotspots(resolvedHotspots).find(
          h => h.resolvedTarget === resolvedTargetSceneId && (includeReturn || !h.isReturn),
        ) ?? null
      );
    }
    function resolveArrivalReferenceHotspot(sceneId, sceneData, sourceSceneId) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      const resolvedSourceSceneId = resolveExistingSceneId(sourceSceneId) ?? normalizeSceneId(sourceSceneId);
      if (!resolvedSceneId || !resolvedSourceSceneId || resolvedSceneId === resolvedSourceSceneId) return null;
      return resolveHotspotByTargetScene(
        resolvedSceneId,
        sceneData,
        resolvedSourceSceneId,
        { includeReturn: true },
      );
    }
    function resolveSceneForwardHotspots(sceneId, sceneData) {
      const resolvedHotspots = buildResolvedHotspots(sceneId, sceneData);
      return sortCanonicalHotspots(resolvedHotspots).filter(h => !h.isReturn && !!h.resolvedTarget);
    }
    function resolveDeadEndExitHotspot(sceneId, sceneData) {
      const forwardHotspots = resolveSceneForwardHotspots(sceneId, sceneData);
      if (forwardHotspots.length > 0) return null;
      return resolveSceneReturnHotspot(sceneId);
    }
    function buildNavigationTarget(
      sceneId,
      hotspot,
      hotspotIndex,
      targetSceneId,
      sequenceCursorOverride,
      usesReturnLink,
      isBacktrack,
    ) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      const resolvedTargetSceneId = resolveExistingSceneId(targetSceneId) ?? normalizeSceneId(targetSceneId);
      if (!resolvedSceneId || !resolvedTargetSceneId) return null;
      return {
        hotspot: hotspot ?? null,
        hotspotIndex: Number.isInteger(hotspotIndex) ? hotspotIndex : null,
        targetSceneId: resolvedTargetSceneId,
        sourceSceneId: resolvedSceneId,
        sequenceCursorOverride: Number.isInteger(sequenceCursorOverride) ? sequenceCursorOverride : null,
        usesReturnLink: usesReturnLink === true,
        isBacktrack: isBacktrack === true,
      };
    }
    function resolveCanonicalPreviousSequenceTarget(sceneId, sceneData) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return null;
      const currentCursor = getCurrentSceneSequenceCursor(resolvedSceneId, sceneData);
      const previousSequencePosition = Number.isInteger(currentCursor) ? currentCursor : null;
      const previousSceneId = resolveSceneIdForSequencePosition(previousSequencePosition);
      if (!previousSceneId || previousSceneId === resolvedSceneId) return null;
      const backwardHotspot = resolveForwardHotspotByTargetScene(
        resolvedSceneId,
        sceneData,
        previousSceneId,
      );
      if (backwardHotspot) {
        return buildNavigationTarget(
          resolvedSceneId,
          backwardHotspot.hotspot,
          backwardHotspot.hotspotIndex,
          previousSceneId,
          currentCursor,
          false,
          true,
        );
      }
      return buildNavigationTarget(
        resolvedSceneId,
        null,
        null,
        previousSceneId,
        currentCursor,
        false,
        true,
      );
    }
    function resolvePreferredNavigationTarget(sceneId, sceneData) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return null;
      const nextForwardEdge = resolveNextForwardSequenceEdge(resolvedSceneId, sceneData);
      const nextForwardHotspot = resolveVisibleHotspotForSequenceEdge(sceneData, nextForwardEdge);
      if (nextForwardEdge && nextForwardHotspot) {
        return buildNavigationTarget(
          resolvedSceneId,
          nextForwardHotspot,
          nextForwardEdge.visibleHotspotIndex,
          nextForwardEdge.targetSceneId,
          nextForwardEdge.sequenceNumber,
          false,
          false,
        );
      }
      const returnHotspot = resolveSceneReturnHotspot(resolvedSceneId);
      if (returnHotspot) {
        return buildNavigationTarget(
          resolvedSceneId,
          returnHotspot.hotspot,
          returnHotspot.hotspotIndex,
          returnHotspot.targetSceneId,
          getCurrentSceneSequenceCursor(resolvedSceneId, sceneData),
          true,
          true,
        );
      }
      return resolveCanonicalPreviousSequenceTarget(resolvedSceneId, sceneData);
    }
    function resolveSourceBacktrackTarget(sceneId, sceneData, sourceSceneId, sequenceCursorOverride) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      const resolvedSourceSceneId = resolveExistingSceneId(sourceSceneId) ?? normalizeSceneId(sourceSceneId);
      if (!resolvedSceneId || !resolvedSourceSceneId || resolvedSourceSceneId === resolvedSceneId) return null;
      const sourceHotspot = resolveForwardHotspotByTargetScene(
        resolvedSceneId,
        sceneData,
        resolvedSourceSceneId,
      );
      if (sourceHotspot) {
        return buildNavigationTarget(
          resolvedSceneId,
          sourceHotspot.hotspot,
          sourceHotspot.hotspotIndex,
          resolvedSourceSceneId,
          sequenceCursorOverride,
          sourceHotspot.isReturn === true,
          true,
        );
      }
      const returnHotspot = resolveSceneReturnHotspot(resolvedSceneId);
      if (returnHotspot?.targetSceneId === resolvedSourceSceneId) {
        return buildNavigationTarget(
          resolvedSceneId,
          returnHotspot.hotspot,
          returnHotspot.hotspotIndex,
          resolvedSourceSceneId,
          sequenceCursorOverride,
          true,
          true,
        );
      }
      return buildNavigationTarget(
        resolvedSceneId,
        null,
        null,
        resolvedSourceSceneId,
        sequenceCursorOverride,
        false,
        true,
      );
    }
    function resolveBacktrackTarget(sceneId, sceneData) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return null;
      const currentCursor = getCurrentSceneSequenceCursor(resolvedSceneId, sceneData);
      const canonicalPrevious = resolveCanonicalPreviousSequenceTarget(resolvedSceneId, sceneData);
      const sourceSceneId = getCurrentSceneSourceSceneId(resolvedSceneId);
      if (sourceSceneId && sourceSceneId !== resolvedSceneId) {
        if (canonicalPrevious?.targetSceneId === sourceSceneId) {
          return canonicalPrevious;
        }
        const sourceFallback = resolveSourceBacktrackTarget(
          resolvedSceneId,
          sceneData,
          sourceSceneId,
          currentCursor,
        );
        if (sourceFallback) {
          return sourceFallback;
        }
      }
      return canonicalPrevious;
    }
    function resolvePreviousSequenceTarget(sceneId, sceneData) {
      return resolveCanonicalPreviousSequenceTarget(sceneId, sceneData);
    }
    function resolvePostArrivalFocusHotspot(sceneId, sceneData) {
      const preferredTarget = resolvePreferredNavigationTarget(sceneId, sceneData);
      return preferredTarget?.hotspot ?? null;
    }
    function resolveAutoForwardArrivalView(sceneId) {
      const resolvedSceneId = resolveExistingSceneId(sceneId);
      if (!resolvedSceneId) return null;
      const sceneData = scenesData?.[resolvedSceneId];
      if (!sceneData) return null;
      const hotspotIndex = sceneData?.autoForwardHotspotIndex;
      if (!Number.isInteger(hotspotIndex) || hotspotIndex < 0) return null;
      const hotspot = sceneData?.hotSpots?.[hotspotIndex];
      if (!hotspot) return null;
      const yaw = Number.isFinite(hotspot?.viewFrame?.yaw)
        ? hotspot.viewFrame.yaw
        : (Number.isFinite(hotspot?.targetYaw) ? hotspot.targetYaw : hotspot?.yaw);
      const pitch = Number.isFinite(hotspot?.viewFrame?.pitch)
        ? hotspot.viewFrame.pitch
        : (Number.isFinite(hotspot?.targetPitch)
            ? hotspot.targetPitch
            : (Number.isFinite(hotspot?.truePitch) ? hotspot.truePitch : hotspot?.pitch));
      if (!Number.isFinite(yaw) || !Number.isFinite(pitch)) return null;
      return { yaw, pitch };
    }
    function navigateToNextScene(args, forceTargetSceneId, options) {
      const requestedTargetSceneId = options?.targetSceneId ?? forceTargetSceneId;
      const targetSceneId = resolveTargetSceneId(args, requestedTargetSceneId);
      const fromAutoForward = options?.fromAutoForward === true;
      const fromManifest = options?.fromManifest === true;
      const isAutoTourBacktrack =
        options?.isBacktrack === true ||
        options?.usesReturnLink === true ||
        args?.isReturnLink === true;
      if (!targetSceneId) {
        if (fromAutoForward && typeof completeTourAndReturnHome === "function") completeTourAndReturnHome();
        return;
      }
      const destinationOverride = options?.destinationOverride ?? resolveAutoForwardArrivalView(targetSceneId);
      const destination = resolveDestinationView(args, { destinationOverride });
      const sourceSceneId =
        resolveExistingSceneId(options?.sourceSceneId)
        ?? resolveExistingSceneId(args?.sourceSceneId)
        ?? resolveExistingSceneId(window.viewer.getScene())
        ?? normalizeSceneId(window.viewer.getScene());
      if (fromAutoForward) {
        if (fromManifest) {
          resetAutoForwardLoopGuard();
        } else if (isAutoTourBacktrack) {
          resetAutoForwardLoopGuard();
        } else {
          beginAutoForwardChain();
          if (shouldBlockAutoForward(sourceSceneId, targetSceneId)) {
            resetAutoForwardLoopGuard();
            lookingMode = manualLookingMode;
            updateLookingModeUI();
            if (typeof completeTourAndReturnHome === "function") completeTourAndReturnHome();
            return;
          }
          trackAutoForwardSource(sourceSceneId);
        }
      } else {
        resetAutoForwardLoopGuard();
      }
      const fallbackSequenceCursor = args?.isReturnLink === true
        ? getCurrentSceneSequenceCursor(sourceSceneId, scenesData?.[sourceSceneId])
        : (Number.isFinite(args?.sequenceNumber) ? Math.trunc(args.sequenceNumber) : null);
      const homeSceneId = resolveExistingSceneId(firstSceneId);
      const requestedSequenceCursor = Number.isInteger(options?.sequenceCursorOverride)
        ? options.sequenceCursorOverride
        : fallbackSequenceCursor;
      const sequenceCursor = homeSceneId && targetSceneId === homeSceneId
        ? 0
        : requestedSequenceCursor;
      const shouldTrackArrivalOrientation =
        !!sourceSceneId &&
        !!targetSceneId &&
        Number.isInteger(sequenceCursor);
      if (shouldTrackArrivalOrientation) {
        pendingArrivalContext = {sourceSceneId, targetSceneId, sequenceCursor}
      } else {
        pendingArrivalContext = null
      }
      transitionFrom = window.viewer.getScene(); persistentFrom = transitionFrom;
      setTimeout(() => {
        const verifiedTarget = resolveExistingSceneId(targetSceneId);
        if (!verifiedTarget) return;
        const targetConfig = config?.scenes?.[verifiedTarget];
        if (!targetConfig || typeof targetConfig.panorama !== "string" || targetConfig.panorama.trim() === "") return;
        window.viewer.loadScene(
          verifiedTarget,
          destination.pitch,
          destination.yaw,
          getCurrentHfov(),
        );
      }, 450);
    }
    function resolveScenePlaybackHotspot(sceneId, sceneData) {
      const hotspots = Array.isArray(sceneData?.hotSpots) ? sceneData.hotSpots : [];
      if (!hotspots.length) return null;
      
      // Legacy export playback still drives first-arrival animation selection.
      // Reset transient hotspot visit flags here so rooms with return links do not
      // inherit stale playback state across revisits.
      hotspots.forEach(h => { if (h) h.__visited = false; });

      const resolvedHotspots = buildResolvedHotspots(sceneId, sceneData);
      const manifestPlaybackTarget =
        window.isAutoTourActive === true ? buildPlaybackTargetFromAutoTourStep(sceneId) : null;
      if (manifestPlaybackTarget) {
        return manifestPlaybackTarget;
      }
      if (window.isAutoTourActive === true) {
        return null;
      }

        if (EXPORT_TRAVERSAL_MODE === "canonical") {
          const preferredTarget = resolvePreferredNavigationTarget(sceneId, sceneData);
          if (preferredTarget?.hotspot && Number.isInteger(preferredTarget?.hotspotIndex)) {
            return {
              hotspot: preferredTarget.hotspot,
              hotspotIndex: preferredTarget.hotspotIndex,
              autoForward: preferredTarget.hotspotIndex === sceneData?.autoForwardHotspotIndex,
              targetSceneId: preferredTarget.targetSceneId,
              usesReturnLink: preferredTarget.usesReturnLink === true,
              backtrack: preferredTarget.isBacktrack === true,
            };
          }

          const canonicalSorted = sortCanonicalHotspots(resolvedHotspots);
          const canonicalFallback = canonicalSorted.find(h => h.hotspotIndex === 0) ?? canonicalSorted[0];
        if (canonicalFallback) {
            return {
              hotspot: canonicalFallback.hotspot,
              hotspotIndex: canonicalFallback.hotspotIndex,
              autoForward: canonicalFallback.isAutoForward,
              targetSceneId: canonicalFallback.resolvedTarget,
              usesReturnLink: canonicalFallback.isReturn === true,
              backtrack: canonicalFallback.isReturn === true,
            };
          }
        }
      
      // PRIORITY 1: Unvisited, non-return, non-auto-forward (explore)
      const p1 = resolvedHotspots.find(h => !h.hotspot.__visited && !h.isReturn && !h.isAutoForward);
      if (p1) { p1.hotspot.__visited = true; return { hotspot: p1.hotspot, hotspotIndex: p1.hotspotIndex, autoForward: false, targetSceneId: p1.resolvedTarget, usesReturnLink: false, backtrack: false }; }
      
      // PRIORITY 2: Unvisited, non-return, IS auto-forward (exit - taken LAST)
      const p2 = resolvedHotspots.find(h => !h.hotspot.__visited && !h.isReturn && h.isAutoForward);
      if (p2) { p2.hotspot.__visited = true; return { hotspot: p2.hotspot, hotspotIndex: p2.hotspotIndex, autoForward: true, targetSceneId: p2.resolvedTarget, usesReturnLink: false, backtrack: false }; }
      
      // PRIORITY 3: Unvisited, return, non-auto-forward
      const p3 = resolvedHotspots.find(h => !h.hotspot.__visited && h.isReturn && !h.isAutoForward);
      if (p3) { p3.hotspot.__visited = true; return { hotspot: p3.hotspot, hotspotIndex: p3.hotspotIndex, autoForward: false, targetSceneId: p3.resolvedTarget, usesReturnLink: true, backtrack: true }; }
      
      // PRIORITY 4: Unvisited, return, auto-forward
      const p4 = resolvedHotspots.find(h => !h.hotspot.__visited && h.isReturn && h.isAutoForward);
      if (p4) { p4.hotspot.__visited = true; return { hotspot: p4.hotspot, hotspotIndex: p4.hotspotIndex, autoForward: true, targetSceneId: p4.resolvedTarget, usesReturnLink: true, backtrack: true }; }
      
      // All visited - return to start
      const startLink = resolvedHotspots.find(h => h.hotspotIndex === 0);
      if (startLink) return { hotspot: startLink.hotspot, hotspotIndex: 0, autoForward: false, targetSceneId: startLink.resolvedTarget, usesReturnLink: startLink.isReturn === true, backtrack: startLink.isReturn === true };
      
      return {
        hotspot: hotspots[0],
        hotspotIndex: 0,
        autoForward: false,
        targetSceneId: resolvedHotspots[0]?.resolvedTarget ?? null,
        usesReturnLink: resolvedHotspots[0]?.isReturn === true,
        backtrack: resolvedHotspots[0]?.isReturn === true,
      };
    }
    function resolveSceneReturnHotspot(sceneId) {
      const resolvedSceneId = resolveExistingSceneId(sceneId);
      if (!resolvedSceneId) return null;
      const sceneData = scenesData?.[resolvedSceneId];
      const hotspots = Array.isArray(sceneData?.hotSpots) ? sceneData.hotSpots : [];
      for (let hotspotIndex = 0; hotspotIndex < hotspots.length; hotspotIndex += 1) {
        const hotspot = hotspots[hotspotIndex];
        if (!hotspot || hotspot.isReturnLink !== true) continue;
        const resolvedTarget = resolveTargetSceneId({
          sourceSceneId: resolvedSceneId,
          i: hotspotIndex,
          targetSceneId: hotspot?.targetSceneId,
          target: hotspot?.target,
          targetName: hotspot?.target,
        }, null);
        if (!resolvedTarget) continue;
        return { hotspot, hotspotIndex, targetSceneId: resolvedTarget, sourceSceneId: resolvedSceneId };
      }
      return null;
    }
    function navigateReturnHotspotFromCurrentScene() {
      const currentSceneId =
        resolveExistingSceneId(window.viewer.getScene())
        ?? normalizeSceneId(window.viewer.getScene());
      if (!currentSceneId) return false;
      const returnCandidate = resolveSceneReturnHotspot(currentSceneId);
      if (!returnCandidate) return false;
      const options = {
        fromAutoForward: false,
        sourceSceneId: currentSceneId,
        targetSceneId: returnCandidate.targetSceneId,
      };
      const hotspotsNow = getSceneHotspots(currentSceneId);
      const preferred = hotspotsNow.find(el => el.dataset.hotspotIndex === String(returnCandidate.hotspotIndex));
      if (preferred && typeof preferred.__navigateNext === "function") {
        preferred.__navigateNext(options);
        return true;
      }
      navigateToNextScene(returnCandidate.hotspot, returnCandidate.targetSceneId, options);
      return true;
    }
    function attemptAutoForwardNavigation(sceneId, playbackTarget, retriesLeft, destinationOverride) {
      if (window.viewer.getScene() !== sceneId) return;
      const autoForwardOptions = {
        fromAutoForward: true,
        sourceSceneId: sceneId,
        targetSceneId: playbackTarget.targetSceneId ?? null,
        destinationOverride: destinationOverride ?? null,
        usesReturnLink: playbackTarget.usesReturnLink === true,
        isBacktrack: playbackTarget.backtrack === true,
        sequenceCursorOverride: Number.isInteger(playbackTarget.sequenceCursorOverride)
          ? playbackTarget.sequenceCursorOverride
          : null,
        fromManifest: playbackTarget.fromManifest === true,
      };
      if (playbackTarget.fromManifest === true) {
        if (!playbackTarget.targetSceneId) {
          if (typeof completeTourAndReturnHome === "function") completeTourAndReturnHome();
          return;
        }
        const didAdvance = advanceAutoTourManifestCursor(sceneId, playbackTarget.targetSceneId);
        if (!didAdvance) {
          if (typeof completeTourAndReturnHome === "function") completeTourAndReturnHome();
          return;
        }
        navigateToNextScene(playbackTarget.hotspot, playbackTarget.targetSceneId, autoForwardOptions);
        return;
      }
      if (playbackTarget.targetSceneId) {
        navigateToNextScene(playbackTarget.hotspot, playbackTarget.targetSceneId, autoForwardOptions);
        return;
      }
      const hotspotsNow = getSceneHotspots(sceneId);
      const preferred = hotspotsNow.find(el => el.dataset.hotspotIndex === String(playbackTarget.hotspotIndex));
      const anyReady = preferred ?? hotspotsNow.find(el => typeof el.__navigateNext === 'function');
      if (anyReady && typeof anyReady.__navigateNext === 'function') {
        anyReady.__navigateNext(autoForwardOptions);
        return;
      }
      if (retriesLeft <= 0) {
        if (typeof completeTourAndReturnHome === "function") completeTourAndReturnHome();
        return;
      }
      waypointRuntime.autoForwardTimeoutId = setTimeout(
        () => attemptAutoForwardNavigation(sceneId, playbackTarget, retriesLeft - 1, destinationOverride),
        120,
      );
    }
`
