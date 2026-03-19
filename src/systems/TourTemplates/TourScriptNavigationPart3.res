let script = `
      };
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
      const requestedSequenceCursor = Number.isInteger(options?.sequenceCursorOverride)
        ? options.sequenceCursorOverride
        : fallbackSequenceCursor;
      const sequenceCursor = requestedSequenceCursor;
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
