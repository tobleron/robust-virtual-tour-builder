let script = `
    // Scene Tracking: Track which scenes have already animated during this session
    let animatedScenes = new Set();
    // Auto-Forward Tracking: Track which auto-forward links have already triggered
    let visitedAutoForwards = new Set();
    
    function animateSceneToPrimaryHotspot(sceneId, retries) {
      if (window.viewer.getScene() !== sceneId) return;
      const sd = scenesData[sceneId];
      const playbackTarget = resolveScenePlaybackHotspot(sceneId, sd);
      if (!playbackTarget) return;
      const primary = playbackTarget.hotspot;
      const primaryIndex = playbackTarget.hotspotIndex;
      waypointRuntime.arrivedSceneId = null;
      setSceneHotspotsPending(sceneId);
      
      const isAutoForward = playbackTarget.autoForward === true;
      const afKey = sceneId + ":" + primaryIndex;
      const autoForwardAlreadyVisited = isAutoForward && visitedAutoForwards.has(afKey);

      // ANIMATION POLICY: Skip animation if this scene has already animated in this session
      const hasAnimated = animatedScenes.has(sceneId);
      
      if (hasAnimated) {
        // Scene already animated - show hotspots immediately without animation
        setSceneHotspotsReadyWithRetry(sceneId, retries);
        const shouldAutoForward = isAutoForward && !autoForwardAlreadyVisited;
        
        if (shouldAutoForward) {
          waypointRuntime.autoForwardTimeoutId = setTimeout(() => {
            if (window.viewer.getScene() !== sceneId) return;
            visitedAutoForwards.add(afKey);
            attemptAutoForwardNavigation(sceneId, playbackTarget, 16);
          }, 360);
        } else {
          resetAutoForwardLoopGuard();
        }
        lookingMode = shouldAutoForward ? false : manualLookingMode;
        updateLookingModeUI();
        return;
      }
      
      let durationMs = PAN_MIN_DURATION;
      const startPitch = typeof window.viewer.getPitch === 'function' ? window.viewer.getPitch() : 0;
      const startYaw = typeof window.viewer.getYaw === 'function' ? window.viewer.getYaw() : 0;
      const path = buildPath(primary, startPitch, startYaw);
      const pathInfo = buildSegments(path);
      if (!pathInfo.segments.length || pathInfo.total <= 0) {
        setSceneHotspotsReadyWithRetry(sceneId, retries);
        return;
      }
      durationMs = Math.min(Math.max((pathInfo.total / PAN_VELOCITY) * 1000.0, PAN_MIN_DURATION), PAN_MAX_DURATION);

      // Surgical: Disable looking mode during animation
      lookingMode = false;
      updateLookingModeUI();
      window.viewer.lookAt(path[0].pitch, path[0].yaw, getCurrentHfov(), false);
      const startAt = performance.now();
      const tick = now => {
        if (window.viewer.getScene() !== sceneId) return;
        const linear = Math.min(1, (now - startAt) / durationMs);
        const progress = trapezoidal(linear, TRAPEZOID_FACTOR);
        const current = samplePath(pathInfo.segments, pathInfo.total, progress);
        window.viewer.lookAt(current.pitch, current.yaw, getCurrentHfov(), false);
        if (linear < 1) {
          waypointRuntime.animationId = requestAnimationFrame(tick);
          return;
        }
        waypointRuntime.animationId = null;
        waypointRuntime.arrivedSceneId = sceneId;
        setSceneHotspotsReadyWithRetry(sceneId, retries);
        
        // Mark this scene as having animated
        animatedScenes.add(sceneId);
        
        const shouldAutoForward = isAutoForward && !autoForwardAlreadyVisited;
        if (shouldAutoForward) {
          waypointRuntime.autoForwardTimeoutId = setTimeout(() => {
            if (window.viewer.getScene() !== sceneId) return;
            visitedAutoForwards.add(afKey);
            attemptAutoForwardNavigation(sceneId, playbackTarget, 16);
          }, 360);
        } else {
          resetAutoForwardLoopGuard();
        }

        // Keep Looking mode OFF when this scene auto-forwards immediately.
        lookingMode = shouldAutoForward ? false : manualLookingMode;
        updateLookingModeUI();
      };
      waypointRuntime.animationId = requestAnimationFrame(tick);
    }
    function renderOrangeHotspot(hotSpotDiv, args) {
      const currentSceneId = window.viewer.getScene();
      const currentSceneData = scenesData[currentSceneId];
      const ownerScene = args.sourceSceneId ?? currentSceneId;
      hotSpotDiv.style.width = "__BASE_SIZE__px"; hotSpotDiv.style.height = "__BASE_SIZE__px";
      hotSpotDiv.style.pointerEvents = "auto";
      hotSpotDiv.style.cursor = "pointer";
      
      const hotspotIndex = args.i ?? 0;
      const isAutoForwardConfig = args.targetIsAutoForward === true;
      const afKey = ownerScene + ":" + hotspotIndex;
      const isAutoForwardExpired = isAutoForwardConfig && visitedAutoForwards.has(afKey);

      // HUB SCENE LOGIC: Auto-forward links in hub scenes are shown as normal buttons
      // Only hide auto-forward in non-hub scenes if NOT expired
      const isHubScene = currentSceneData?.isHubScene === true;
      const isAutoForwardVisual = isAutoForwardConfig && !isHubScene && !isAutoForwardExpired;
      const shouldHideAutoForward = isAutoForwardConfig && !isHubScene && !isAutoForwardExpired;
      
      if (shouldHideAutoForward) {
        hotSpotDiv.style.setProperty("display", "none", "important");
      } else {
        hotSpotDiv.style.removeProperty("display");
      }
      
      hotSpotDiv.dataset.ownerScene = ownerScene;
      hotSpotDiv.dataset.targetSceneId = resolveTargetSceneId(args, null) ?? "";
      hotSpotDiv.dataset.hotspotIndex = String(hotspotIndex);
      hotSpotDiv.dataset.ready = "false";
      hotSpotDiv.classList.remove("waypoint-ready");
      hotSpotDiv.classList.add("waypoint-pending");
      if (waypointRuntime.arrivedSceneId === ownerScene) {
        hotSpotDiv.dataset.ready = "true";
        hotSpotDiv.classList.remove("waypoint-pending");
        hotSpotDiv.classList.add("waypoint-ready");
      }
      const ns = "http://www.w3.org/2000/svg";
      const bindNavigateHandlers = function(trigger, root) {
        if (!trigger) return;
        trigger.style.pointerEvents = "auto";
        trigger.style.cursor = "pointer";
        if (trigger.__exportNavClickHandler) {
          trigger.removeEventListener("click", trigger.__exportNavClickHandler);
        }
        if (trigger.__exportNavPointerUpHandler) {
          trigger.removeEventListener("pointerup", trigger.__exportNavPointerUpHandler);
        }
        const handleNavigate = function(e) {
          if (e && typeof e.stopPropagation === "function") e.stopPropagation();
          if (e && typeof e.preventDefault === "function") e.preventDefault();
          if (typeof root.__navigateNext !== "function") return;
          if (root.__navInFlight === true) return;
          root.__navInFlight = true;
          setTimeout(function() { root.__navInFlight = false; }, 700);
          root.__navigateNext();
        };
        trigger.__exportNavClickHandler = handleNavigate;
        trigger.__exportNavPointerUpHandler = handleNavigate;
        trigger.addEventListener("click", trigger.__exportNavClickHandler);
        trigger.addEventListener("pointerup", trigger.__exportNavPointerUpHandler);
      };
      const svg = document.createElementNS(ns, "svg");
      svg.setAttribute("class", "custom-arrow-svg"); svg.setAttribute("viewBox", "0 0 100 100"); svg.style.overflow = "visible";

      const root = document.createElement("div");
      root.className = "export-hotspot-root" + (isAutoForwardVisual ? " auto-forward" : "");
      const btn = document.createElement("div");
      btn.className = "export-hotspot-btn";
      const sweep = document.createElement("div");
      sweep.className = "export-hotspot-btn-sweep";
      const icon = document.createElementNS(ns, "svg");
      icon.setAttribute("class", "export-hotspot-icon");
      icon.setAttribute("viewBox", "0 0 24 24");
      if (isAutoForwardVisual) {
        const p1 = document.createElementNS(ns, "path"); p1.setAttribute("d", "M6 17 L11 12 L6 7"); icon.appendChild(p1);
        const p2 = document.createElementNS(ns, "path"); p2.setAttribute("d", "M13 17 L18 12 L13 7"); icon.appendChild(p2);
      } else {
        const p = document.createElementNS(ns, "path"); p.setAttribute("d", "M6 14 L12 8 L18 14"); icon.appendChild(p);
      }
      btn.appendChild(sweep);
      btn.appendChild(icon);
      root.appendChild(btn);
      while (hotSpotDiv.firstChild) hotSpotDiv.removeChild(hotSpotDiv.firstChild);
      hotSpotDiv.appendChild(root);
      hotSpotDiv.__navInFlight = false;
      hotSpotDiv.__navigateNext = function(options) { 
        if (isAutoForwardConfig) {
          visitedAutoForwards.add(afKey);
        }
        navigateToNextScene(args, null, options); 
      };
      bindNavigateHandlers(hotSpotDiv, hotSpotDiv);
      bindNavigateHandlers(root, hotSpotDiv);
      bindNavigateHandlers(btn, hotSpotDiv);
    }
`
