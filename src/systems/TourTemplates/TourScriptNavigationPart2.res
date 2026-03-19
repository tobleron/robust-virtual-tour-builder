let script = `
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
    function resolveStableSceneNumber(sceneId) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return null;
      const rawSceneNumber = scenesData?.[resolvedSceneId]?.sceneNumber;
      if (Number.isInteger(rawSceneNumber) && rawSceneNumber >= 1) return rawSceneNumber;
      const fallbackSceneNumber = resolveFirstSequencePositionForScene(resolvedSceneId);
      return Number.isInteger(fallbackSceneNumber) && fallbackSceneNumber >= 1
        ? fallbackSceneNumber
        : null;
    }
    function buildStableShortcutNavigationTarget(
      sceneId,
      hotspotDescriptor,
      targetSceneId,
      usesReturnLink,
      isBacktrack,
    ) {
      const targetSceneNumber = resolveStableSceneNumber(targetSceneId);
      return buildNavigationTarget(
        sceneId,
        hotspotDescriptor?.hotspot ?? null,
        hotspotDescriptor?.hotspotIndex ?? null,
        targetSceneId,
        Number.isInteger(targetSceneNumber) ? Math.max(0, targetSceneNumber - 1) : null,
        usesReturnLink,
        isBacktrack,
      );
    }
    function buildCurrentCursorBacktrackTarget(
      sceneId,
      sceneData,
      hotspotDescriptor,
      targetSceneId,
      usesReturnLink,
    ) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return null;
      const currentCursor = getCurrentSceneSequenceCursor(resolvedSceneId, sceneData);
      return buildNavigationTarget(
        resolvedSceneId,
        hotspotDescriptor?.hotspot ?? null,
        hotspotDescriptor?.hotspotIndex ?? null,
        targetSceneId,
        currentCursor,
        usesReturnLink,
        true,
      );
    }
    function resolveSceneNumberForwardShortcutTarget(sceneId, sceneData) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return null;
      const stableSceneNumber = resolveStableSceneNumber(resolvedSceneId);
      if (!Number.isInteger(stableSceneNumber) || stableSceneNumber < 1) return null;
      const forwardHotspots = resolveSceneForwardHotspots(resolvedSceneId, sceneData);
      let bestForward = null;
      forwardHotspots.forEach(entry => {
        const targetSceneNumber = resolveStableSceneNumber(entry.resolvedTarget);
        if (!Number.isInteger(targetSceneNumber) || targetSceneNumber <= stableSceneNumber) return;
        if (
          bestForward === null ||
          targetSceneNumber < bestForward.targetSceneNumber ||
          (
            targetSceneNumber === bestForward.targetSceneNumber &&
            entry.hotspotIndex < bestForward.entry.hotspotIndex
          )
        ) {
          bestForward = { entry, targetSceneNumber };
        }
      });
      if (bestForward !== null) {
        return buildStableShortcutNavigationTarget(
          resolvedSceneId,
          bestForward.entry,
          bestForward.entry.resolvedTarget,
          false,
          false,
        );
      }
      const returnHotspot = resolveSceneReturnHotspot(resolvedSceneId);
      const returnTargetSceneNumber = resolveStableSceneNumber(returnHotspot?.targetSceneId);
      if (
        forwardHotspots.length === 0 &&
        returnHotspot &&
        Number.isInteger(returnTargetSceneNumber) &&
        returnTargetSceneNumber < stableSceneNumber
      ) {
        return buildCurrentCursorBacktrackTarget(
          resolvedSceneId,
          sceneData,
          returnHotspot,
          returnHotspot.targetSceneId,
          true,
        );
      }
      return null;
    }
    function resolveProgressAwareForwardShortcutTarget(sceneId, sceneData) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return null;
      const homeSceneId = resolveExistingSceneId(firstSceneId);
      if (resolvedSceneId === homeSceneId) {
        return resolveSceneNumberForwardShortcutTarget(resolvedSceneId, sceneData);
      }
      const nextForwardEdge = resolveNextForwardSequenceEdge(resolvedSceneId, sceneData);
      const preferredTarget = resolvePreferredNavigationTarget(resolvedSceneId, sceneData);
      if (
        preferredTarget &&
        preferredTarget.usesReturnLink !== true &&
        preferredTarget.isBacktrack !== true
      ) {
        return preferredTarget;
      }
      if (!nextForwardEdge) {
        return preferredTarget;
      }
      return null;
    }
    function resolveSceneNumberBacktrackShortcutTarget(sceneId, sceneData) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return null;
      const stableSceneNumber = resolveStableSceneNumber(resolvedSceneId);
      if (!Number.isInteger(stableSceneNumber) || stableSceneNumber <= 1) return null;
      const returnHotspot = resolveSceneReturnHotspot(resolvedSceneId);
      const returnTargetSceneNumber = resolveStableSceneNumber(returnHotspot?.targetSceneId);
      if (
        returnHotspot &&
        Number.isInteger(returnTargetSceneNumber) &&
        returnTargetSceneNumber < stableSceneNumber
      ) {
        return buildCurrentCursorBacktrackTarget(
          resolvedSceneId,
          sceneData,
          returnHotspot,
          returnHotspot.targetSceneId,
          true,
        );
      }
      const forwardHotspots = resolveSceneForwardHotspots(resolvedSceneId, sceneData);
      let bestBacktrack = null;
      forwardHotspots.forEach(entry => {
        const targetSceneNumber = resolveStableSceneNumber(entry.resolvedTarget);
        if (!Number.isInteger(targetSceneNumber) || targetSceneNumber >= stableSceneNumber) return;
        if (
          bestBacktrack === null ||
          targetSceneNumber > bestBacktrack.targetSceneNumber ||
          (
            targetSceneNumber === bestBacktrack.targetSceneNumber &&
            entry.hotspotIndex < bestBacktrack.entry.hotspotIndex
          )
        ) {
          bestBacktrack = { entry, targetSceneNumber };
        }
      });
      if (bestBacktrack !== null) {
        return buildStableShortcutNavigationTarget(
          resolvedSceneId,
          bestBacktrack.entry,
          bestBacktrack.entry.resolvedTarget,
          false,
          true,
        );
      }
      return null;
    }
    function resolveShortcutNavigationTargets(sceneId, sceneData) {
      const resolvedSceneId = resolveExistingSceneId(sceneId) ?? normalizeSceneId(sceneId);
      if (!resolvedSceneId) return { nextTarget: null, prevTarget: null };
      const homeSceneId = resolveExistingSceneId(firstSceneId);
      const stableSceneNumber = resolveStableSceneNumber(resolvedSceneId);
      if (!Number.isInteger(stableSceneNumber) || stableSceneNumber < 1) {
        const nextTarget = resolveProgressAwareForwardShortcutTarget(resolvedSceneId, sceneData);
        const prevCandidate =
          resolvedSceneId === homeSceneId ? null : resolveBacktrackTarget(resolvedSceneId, sceneData);
        return {
          nextTarget,
          prevTarget:
            prevCandidate?.targetSceneId && prevCandidate.targetSceneId === nextTarget?.targetSceneId
              ? null
              : prevCandidate,
        };
      }
      const nextTarget = resolveProgressAwareForwardShortcutTarget(resolvedSceneId, sceneData);
      const prevCandidate =
        resolvedSceneId === homeSceneId || stableSceneNumber <= 1
          ? null
          : resolveBacktrackTarget(resolvedSceneId, sceneData);
      return {
        nextTarget,
        prevTarget:
          prevCandidate?.targetSceneId && prevCandidate.targetSceneId === nextTarget?.targetSceneId
            ? null
            : prevCandidate,
`
