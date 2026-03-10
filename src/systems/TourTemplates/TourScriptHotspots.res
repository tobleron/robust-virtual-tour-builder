let script = `
    // Scene Tracking: Track which scenes have already animated during this session
    let animatedScenes = new Set();
    // Auto-Forward Tracking: Track which auto-forward links have already triggered
    let visitedAutoForwards = new Set();
    window.isAutoTourActive = false;
    window.autoTourVisitedScenes = new Set();
    function stripSceneTag(raw) {
      const trimmed = typeof raw === "string" ? raw.trim() : "";
      if (!trimmed) return "";
      return trimmed.startsWith("#") ? trimmed.slice(1).trim() : trimmed;
    }
    function formatSceneLabel(sceneId) {
      if (!sceneId) return "";
      const sceneData = scenesData?.[sceneId];
      if (!sceneData) return "";
      const rawLabel = (sceneData.label?.trim() || sceneData.name?.trim() || "");
      if (!rawLabel) return "";
      // Untagged logic: If the label is explicitly 'untagged', show nothing.
      if (rawLabel.toLowerCase().includes("untagged")) return "";
      return stripSceneTag(rawLabel);
    }
    function getPlaybackTerminalView(primary) {
      const endYaw = Number.isFinite(primary?.viewFrame?.yaw)
        ? primary.viewFrame.yaw
        : (Number.isFinite(primary.targetYaw) ? primary.targetYaw : primary.yaw);
      const endPitch = Number.isFinite(primary?.viewFrame?.pitch)
        ? primary.viewFrame.pitch
        : (Number.isFinite(primary.targetPitch)
            ? primary.targetPitch
            : (Number.isFinite(primary.truePitch) ? primary.truePitch : primary.pitch));
      return { yaw: endYaw, pitch: endPitch };
    }
    function snapToPlaybackTerminalView(terminalView) {
      window.viewer.lookAt(terminalView.pitch, terminalView.yaw, getCurrentHfov(), false);
    }
    function animateHorizontalPan(sceneId, startYaw, targetYaw, pitch, durationMs) {
      if (window.viewer.getScene() !== sceneId) return;
      const yawDelta = normalizeYawDelta(startYaw, targetYaw);
      const startAt = performance.now();
      const tick = now => {
        if (window.viewer.getScene() !== sceneId) {
          waypointRuntime.postArrivalAnimationId = null;
          return;
        }
        const linear = Math.min(1, (now - startAt) / durationMs);
        const eased = trapezoidal(linear, TRAPEZOID_FACTOR);
        const currentYaw = normalizeYaw(startYaw + yawDelta * eased);
        window.viewer.lookAt(pitch, currentYaw, getCurrentHfov(), false);
        if (linear < 1) {
          waypointRuntime.postArrivalAnimationId = requestAnimationFrame(tick);
          return;
        }
        waypointRuntime.postArrivalAnimationId = null;
      };
      if (waypointRuntime.postArrivalAnimationId !== null) cancelAnimationFrame(waypointRuntime.postArrivalAnimationId);
      waypointRuntime.postArrivalAnimationId = requestAnimationFrame(tick);
    }
    function finalizeSceneArrival(sceneId, retries, playbackTarget, isAutoForward, autoForwardAlreadyVisited, forceAutoForward, terminalView) {
      waypointRuntime.animationId = null;
      waypointRuntime.arrivedSceneId = sceneId;
      setSceneHotspotsReadyWithRetry(sceneId, retries);

      const shouldAutoForward = (isAutoForward && !autoForwardAlreadyVisited) || forceAutoForward;
      if (shouldAutoForward) {
        if (forceAutoForward) {
          const tid = playbackTarget.targetSceneId;
          if (!tid || autoTourVisitedScenes.has(sceneId + ":" + tid)) {
            if (typeof completeTourAndReturnHome === "function") completeTourAndReturnHome();
            return;
          }
          autoTourVisitedScenes.add(sceneId + ":" + tid);
        }

        const afKey = sceneId + ":" + playbackTarget.hotspotIndex;
        waypointRuntime.autoForwardTimeoutId = setTimeout(() => {
          if (window.viewer.getScene() !== sceneId) return;
          snapToPlaybackTerminalView(terminalView);
          visitedAutoForwards.add(afKey);
          attemptAutoForwardNavigation(sceneId, playbackTarget, 16, terminalView);
        }, 360);
      } else {
        resetAutoForwardLoopGuard();
      }

      lookingMode = shouldAutoForward ? false : manualLookingMode;
      updateLookingModeUI();
    }
    
    function animateSceneToPrimaryHotspot(sceneId, retries) {
      if (window.viewer.getScene() !== sceneId) return;
      const sd = scenesData[sceneId];
      const playbackTarget = resolveScenePlaybackHotspot(sceneId, sd);
      if (!playbackTarget) {
        if (typeof completeTourAndReturnHome === "function") completeTourAndReturnHome();
        return;
      }
      const primary = playbackTarget.hotspot;
      const primaryIndex = playbackTarget.hotspotIndex;
      waypointRuntime.arrivedSceneId = null;
      setSceneHotspotsPending(sceneId);
      
      const isAutoForward = playbackTarget.autoForward === true;
      const afKey = sceneId + ":" + primaryIndex;
      const autoForwardAlreadyVisited = isAutoForward && visitedAutoForwards.has(afKey);
      const fallbackTerminalView = getPlaybackTerminalView(primary);
      const arrivalContext =
        pendingArrivalContext?.targetSceneId === sceneId ? pendingArrivalContext : null;
      pendingArrivalContext = null;

      // ANIMATION POLICY: Skip animation if this scene has already animated in this session
      const hasAnimated = animatedScenes.has(sceneId);
      const forceAnimation = window.isAutoTourActive === true;
      
      if (hasAnimated && !forceAnimation) {
        // Scene already animated - show hotspots immediately without animation
        finalizeSceneArrival(
          sceneId,
          retries,
          playbackTarget,
          isAutoForward,
          autoForwardAlreadyVisited,
          forceAnimation,
          fallbackTerminalView,
        );
        if (arrivalContext) {
          const entryHotspot = resolveForwardHotspotByTargetScene(sceneId, sd, arrivalContext.sourceSceneId);
          if (entryHotspot) {
            const currentPitch = typeof window.viewer.getPitch === "function" ? window.viewer.getPitch() : 0;
            const oppositeYaw = normalizeYaw(entryHotspot.hotspot.yaw + 180);
            window.viewer.lookAt(currentPitch, oppositeYaw, getCurrentHfov(), false);
            const postArrivalHotspot = resolvePostArrivalFocusHotspot(sceneId, sd);
            if (postArrivalHotspot) {
              animateHorizontalPan(
                sceneId,
                oppositeYaw,
                postArrivalHotspot.yaw,
                currentPitch,
                700,
              );
            }
          }
        }
        return;
      }
      
      let durationMs = PAN_MIN_DURATION;
      const startPitch = typeof window.viewer.getPitch === 'function' ? window.viewer.getPitch() : 0;
      const startYaw = typeof window.viewer.getYaw === 'function' ? window.viewer.getYaw() : 0;
      const path = buildPath(primary, startPitch, startYaw);
      const pathInfo = buildSegments(path);
      const terminalView = path.length > 0
        ? path[path.length - 1]
        : fallbackTerminalView;
      animatedScenes.add(sceneId);
      if (!pathInfo.segments.length || pathInfo.total <= 0) {
        finalizeSceneArrival(
          sceneId,
          retries,
          playbackTarget,
          isAutoForward,
          autoForwardAlreadyVisited,
          window.isAutoTourActive === true,
          terminalView,
        );
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
        finalizeSceneArrival(
          sceneId,
          retries,
          playbackTarget,
          isAutoForward,
          autoForwardAlreadyVisited,
          window.isAutoTourActive === true,
          terminalView,
        );
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
      const ownerHotspot = scenesData?.[ownerScene]?.hotSpots?.[hotspotIndex];
      const ownerSceneData = scenesData?.[ownerScene];
      const isAutoForwardConfig = args.targetIsAutoForward === true;
      const isReturnLink = args.isReturnLink === true || ownerHotspot?.isReturnLink === true;
      const dynamicSequenceEdge = !isReturnLink
        ? resolveSequenceEdgeForVisibleHotspot(ownerScene, ownerSceneData, hotspotIndex)
        : null;
      const dynamicSequenceFromEdge = Number.isFinite(dynamicSequenceEdge?.sequenceNumber)
        ? Math.trunc(dynamicSequenceEdge.sequenceNumber)
        : null;
      const sequenceFromArgs = Number.isFinite(args.sequenceNumber) && args.sequenceNumber > 0
        ? Math.trunc(args.sequenceNumber)
        : null;
      const sequenceFromOwner = Number.isFinite(ownerHotspot?.sequenceNumber) && ownerHotspot.sequenceNumber > 0
        ? Math.trunc(ownerHotspot.sequenceNumber)
        : null;
      const resolvedSequenceNumber = dynamicSequenceFromEdge ?? sequenceFromArgs ?? sequenceFromOwner;
      const displaySequenceNumber = resolvedSequenceNumber !== null ? (resolvedSequenceNumber + 1) : null;
      const faceText = isReturnLink ? "R" : (displaySequenceNumber !== null ? String(displaySequenceNumber) : "");
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
      
      const resolvedTargetSceneId = resolveTargetSceneId(args, null);
      hotSpotDiv.dataset.ownerScene = ownerScene;
      const targetSceneForLabel = resolvedTargetSceneId ?? ownerHotspot?.targetSceneId ?? "";
      hotSpotDiv.dataset.targetSceneId = targetSceneForLabel;
      const labelText = formatSceneLabel(targetSceneForLabel);
      hotSpotDiv.dataset.hotspotIndex = String(hotspotIndex);
      hotSpotDiv.dataset.returnLink = isReturnLink ? "true" : "false";
      hotSpotDiv.dataset.sequenceNumber = resolvedSequenceNumber !== null ? String(resolvedSequenceNumber) : "";
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
          if (typeof stopAutoTour === "function") stopAutoTour();
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
      if (labelText) {
        const labelEl = document.createElement("div");
        labelEl.className = "export-hotspot-label";
        labelEl.textContent = labelText;
        root.appendChild(labelEl);
      }
      const btn = document.createElement("div");
      btn.className = "export-hotspot-btn";
      const sweep = document.createElement("div");
      sweep.className = "export-hotspot-btn-sweep";
      btn.appendChild(sweep);
      if (faceText) {
        const textEl = document.createElement("span");
        textEl.className = "export-hotspot-face-text" + (isReturnLink ? " is-return" : "");
        textEl.textContent = faceText;
        btn.appendChild(textEl);
      } else {
        const icon = document.createElementNS(ns, "svg");
        icon.setAttribute("class", "export-hotspot-icon");
        icon.setAttribute("viewBox", "0 0 24 24");
        const p = document.createElementNS(ns, "path");
        p.setAttribute("d", "M6 14 L12 8 L18 14");
        icon.appendChild(p);
        btn.appendChild(icon);
      }
      root.appendChild(btn);
      while (hotSpotDiv.firstChild) hotSpotDiv.removeChild(hotSpotDiv.firstChild);
      hotSpotDiv.appendChild(root);
      hotSpotDiv.__navInFlight = false;
      hotSpotDiv.__navigateNext = function(options) { 
        if (isAutoForwardConfig) {
          visitedAutoForwards.add(afKey);
        }
        const sceneData = ownerSceneData;
        if (isReturnLink) {
          navigateToNextScene(
            args,
            null,
            {
              ...options,
              sourceSceneId: ownerScene,
              targetSceneId: resolvedTargetSceneId ?? null,
              sequenceCursorOverride: getCurrentSceneSequenceCursor(ownerScene, sceneData),
            },
          );
          return;
        }
        const sequenceEdge = resolveSequenceEdgeForVisibleHotspot(ownerScene, sceneData, hotspotIndex);
        if (sequenceEdge) {
          navigateToNextScene(
            {...args, sequenceNumber: sequenceEdge.sequenceNumber},
            sequenceEdge.targetSceneId,
            {
              ...options,
              sourceSceneId: ownerScene,
              targetSceneId: sequenceEdge.targetSceneId,
              sequenceCursorOverride: sequenceEdge.sequenceNumber,
            },
          );
          return;
        }
        navigateToNextScene(args, null, options); 
      };
      bindNavigateHandlers(hotSpotDiv, hotSpotDiv);
      bindNavigateHandlers(root, hotSpotDiv);
      bindNavigateHandlers(btn, hotSpotDiv);
    }
`
