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
    function resolveDestinationView(args) {
      let y = 90, p = 0;
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
    function navigateToNextScene(args, forceTargetSceneId, options) {
      const destination = resolveDestinationView(args);
      const requestedTargetSceneId = options?.targetSceneId ?? forceTargetSceneId;
      const targetSceneId = resolveTargetSceneId(args, requestedTargetSceneId);
      if (!targetSceneId) return;
      const fromAutoForward = options?.fromAutoForward === true;
      const sourceSceneId =
        resolveExistingSceneId(options?.sourceSceneId)
        ?? resolveExistingSceneId(args?.sourceSceneId)
        ?? resolveExistingSceneId(window.viewer.getScene())
        ?? normalizeSceneId(window.viewer.getScene());
      if (fromAutoForward) {
        beginAutoForwardChain();
        if (shouldBlockAutoForward(sourceSceneId, targetSceneId)) {
          resetAutoForwardLoopGuard();
          lookingMode = manualLookingMode;
          updateLookingModeUI();
          return;
        }
        trackAutoForwardSource(sourceSceneId);
      } else {
        resetAutoForwardLoopGuard();
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
      const resolvedHotspots = hotspots.map((hotspot, hotspotIndex) => {
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
      
      // PRIORITY 1: Unvisited, non-return, non-auto-forward (explore)
      const p1 = resolvedHotspots.find(h => !h.hotspot.__visited && !h.isReturn && !h.isAutoForward);
      if (p1) { p1.hotspot.__visited = true; return { hotspot: p1.hotspot, hotspotIndex: p1.hotspotIndex, autoForward: false, targetSceneId: p1.resolvedTarget }; }
      
      // PRIORITY 2: Unvisited, non-return, IS auto-forward (exit - taken LAST)
      const p2 = resolvedHotspots.find(h => !h.hotspot.__visited && !h.isReturn && h.isAutoForward);
      if (p2) { p2.hotspot.__visited = true; return { hotspot: p2.hotspot, hotspotIndex: p2.hotspotIndex, autoForward: true, targetSceneId: p2.resolvedTarget }; }
      
      // PRIORITY 3: Unvisited, return, non-auto-forward
      const p3 = resolvedHotspots.find(h => !h.hotspot.__visited && h.isReturn && !h.isAutoForward);
      if (p3) { p3.hotspot.__visited = true; return { hotspot: p3.hotspot, hotspotIndex: p3.hotspotIndex, autoForward: false, targetSceneId: p3.resolvedTarget }; }
      
      // PRIORITY 4: Unvisited, return, auto-forward
      const p4 = resolvedHotspots.find(h => !h.hotspot.__visited && h.isReturn && h.isAutoForward);
      if (p4) { p4.hotspot.__visited = true; return { hotspot: p4.hotspot, hotspotIndex: p4.hotspotIndex, autoForward: true, targetSceneId: p4.resolvedTarget }; }
      
      // All visited - return to start
      const startLink = resolvedHotspots.find(h => h.hotspotIndex === 0);
      if (startLink) return { hotspot: startLink.hotspot, hotspotIndex: 0, autoForward: false, targetSceneId: startLink.resolvedTarget };
      
      return { hotspot: hotspots[0], hotspotIndex: 0, autoForward: false, targetSceneId: resolvedHotspots[0]?.resolvedTarget ?? null };
    }
    function attemptAutoForwardNavigation(sceneId, playbackTarget, retriesLeft) {
      if (window.viewer.getScene() !== sceneId) return;
      const autoForwardOptions = { fromAutoForward: true, sourceSceneId: sceneId, targetSceneId: playbackTarget.targetSceneId ?? null };
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
      if (retriesLeft <= 0) return;
      waypointRuntime.autoForwardTimeoutId = setTimeout(
        () => attemptAutoForwardNavigation(sceneId, playbackTarget, retriesLeft - 1),
        120,
      );
    }
`
