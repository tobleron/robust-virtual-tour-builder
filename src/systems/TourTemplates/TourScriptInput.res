let script = `
    /* --- LOOKING MODE & LAZY DRIFT LOGIC --- */
    function isLookingModeInteractionAvailable() {
      const interactionShell =
        typeof resolveExportInteractionShell === "function"
          ? resolveExportInteractionShell()
          : (
              typeof resolveExportViewportState === "function" &&
              resolveExportViewportState() === "portrait"
            )
            ? "portrait-adaptive"
            : "classic";
      const isTouchPrimaryInput = typeof detectTouchPrimaryInput === "function"
        ? detectTouchPrimaryInput()
        : (typeof isExportTouchDevice === "function" ? isExportTouchDevice() : false);
      return interactionShell === "classic" && !isTouchPrimaryInput;
    }
    function shouldEnableLookingModeByDefault() {
      return isLookingModeInteractionAvailable();
    }
    let lookingMode = shouldEnableLookingModeByDefault();
    let manualLookingMode = shouldEnableLookingModeByDefault();
    const sceneSequencePromptRuntime = { restoreLookingModeOnSuccess: false };
    function enableLookingModeAfterMapNavigation() {
      if (!isLookingModeInteractionAvailable()) return;
      manualLookingMode = true;
      lookingMode = true;
      updateLookingModeUI();
    }
    function suspendLookingModeForSceneSequencePrompt() {
      if (!isLookingModeInteractionAvailable()) return;
      sceneSequencePromptRuntime.restoreLookingModeOnSuccess =
        manualLookingMode === true || lookingMode === true;
      manualLookingMode = false;
      lookingMode = false;
      updateLookingModeUI();
    }
    function restoreLookingModeAfterSceneSequencePromptSuccess() {
      if (!isLookingModeInteractionAvailable()) return;
      const shouldRestore = sceneSequencePromptRuntime.restoreLookingModeOnSuccess === true;
      sceneSequencePromptRuntime.restoreLookingModeOnSuccess = false;
      if (!shouldRestore) return;
      manualLookingMode = true;
      lookingMode = true;
      updateLookingModeUI();
    }
    function updateLookingModeUI() {
      if (!isLookingModeInteractionAvailable()) {
        manualLookingMode = false;
        lookingMode = false;
      }
      const titleEl = document.getElementById('looking-mode-title');
      const dotEl = document.getElementById('looking-mode-dot');
      const container = document.querySelector('.pnlm-container');
      if (titleEl) titleEl.textContent = lookingMode ? "Looking mode: ON" : "Looking mode: OFF";
      if (dotEl) { if (lookingMode) { dotEl.classList.remove('paused'); } else { dotEl.classList.add('paused'); } }
      if (container) { if (lookingMode) { container.classList.remove('mode-paused'); } else { container.classList.add('mode-paused'); } }
      if (!lookingMode) { driftRuntime.vector = { x: 0, y: 0 }; driftRuntime.smoothedVector = { x: 0, y: 0 }; driftRuntime.active = false; driftRuntime.lastTickTime = null; }
    }
    function toggleLookingMode() {
        if (!isLookingModeInteractionAvailable()) return;
        manualLookingMode = !manualLookingMode;
        lookingMode = manualLookingMode;
        updateLookingModeUI();
    }
    function handleExportKeydown(e) {
      if (!e || e.altKey || e.ctrlKey || e.metaKey) return;
      const key = typeof e.key === "string" ? e.key : "";
      const target = e.target;
      const targetTag = typeof target?.tagName === "string" ? target.tagName.toUpperCase() : "";
      const isTypingElement =
        targetTag === "INPUT" ||
        targetTag === "TEXTAREA" ||
        targetTag === "SELECT" ||
        target?.isContentEditable === true;
      const mapOpen = typeof isExportMapOpen === "function" && isExportMapOpen();
      const sequencePromptOpen =
        typeof isSceneSequencePromptOpen === "function" &&
        isSceneSequencePromptOpen();

      if (sequencePromptOpen) {
        if (key === "Escape" || key === "Esc" || key === "n" || key === "N") {
          if (typeof e.preventDefault === "function") e.preventDefault();
          if (typeof e.stopPropagation === "function") e.stopPropagation();
          if (typeof closeSceneSequencePrompt === "function") closeSceneSequencePrompt();
          return;
        }
        if (key === "Enter") {
          if (typeof e.preventDefault === "function") e.preventDefault();
          if (typeof e.stopPropagation === "function") e.stopPropagation();
          if (typeof submitSceneSequencePrompt === "function") {
            const didSubmit = submitSceneSequencePrompt();
            if (!didSubmit && typeof updateNavShortcutsV2 === "function") {
              const sid = window.viewer?.getScene?.() ?? floorTagShortcutState.sceneId;
              if (sid) updateNavShortcutsV2(sid, true);
            }
          }
          return;
        }
      }

      if (
        typeof isPortraitModeSelectorBlockingUi === "function" &&
        isPortraitModeSelectorBlockingUi()
      ) {
        return;
      }

      if (isTypingElement) return;

      if (key === "Escape" || key === "Esc") {
        if (!mapOpen) return;
        if (typeof e.preventDefault === "function") e.preventDefault();
        if (typeof e.stopPropagation === "function") e.stopPropagation();
        if (typeof closeExportMap === "function") closeExportMap();
        return;
      }
      if (key === "e" || key === "E") {
        if (!mapOpen && !sequencePromptOpen) return;
        if (typeof e.preventDefault === "function") e.preventDefault();
        if (typeof e.stopPropagation === "function") e.stopPropagation();
        if (mapOpen && typeof closeExportMap === "function") closeExportMap();
        return;
      }
      if (mapOpen) {
        const mapShortcutKey = key.toLowerCase();
        if (typeof navigateExportMapShortcut === "function" && mapShortcutKey !== "") {
          const didNavigateToMapScene = navigateExportMapShortcut(mapShortcutKey);
          if (didNavigateToMapScene) {
            if (typeof e.preventDefault === "function") e.preventDefault();
            if (typeof e.stopPropagation === "function") e.stopPropagation();
            return;
          }
        }
      }
      
      if (key === "s" || key === "S") {
        if (mapOpen && typeof closeExportMap === "function") closeExportMap();
        if (typeof e.preventDefault === "function") e.preventDefault();
        if (typeof e.stopPropagation === "function") e.stopPropagation();
        if (typeof activateExportNavigationMode === "function") {
          activateExportNavigationMode(EXPORT_NAVIGATION_MODE_SEMI_AUTO);
        }
        return;
      }

      if (key === "a" || key === "A") {
        if (mapOpen && typeof closeExportMap === "function") closeExportMap();
        if (typeof e.preventDefault === "function") e.preventDefault();
        if (typeof e.stopPropagation === "function") e.stopPropagation();
        if (typeof triggerAutoNavigationMode === "function") triggerAutoNavigationMode();
        return;
      }
      if (key === "l" || key === "L") {
        if (!isLookingModeInteractionAvailable()) return;
        if (mapOpen && typeof closeExportMap === "function") closeExportMap();
        if (typeof stopAutoTour === "function") stopAutoTour();
        if (typeof e.preventDefault === "function") e.preventDefault();
        if (typeof e.stopPropagation === "function") e.stopPropagation();
        toggleLookingMode();
        return;
      }

      if (key === "m" || key === "M") {
        if (typeof e.preventDefault === "function") e.preventDefault();
        if (typeof e.stopPropagation === "function") e.stopPropagation();
        if (mapOpen && typeof closeExportMap === "function") closeExportMap();
        if (typeof activateExportNavigationMode === "function") {
          activateExportNavigationMode(EXPORT_NAVIGATION_MODE_MANUAL);
        }
        return;
      }
      if (key === "n" || key === "N") {
        if (mapOpen && typeof closeExportMap === "function") closeExportMap();
        if (typeof e.preventDefault === "function") e.preventDefault();
        if (typeof e.stopPropagation === "function") e.stopPropagation();
        if (typeof navigateToSceneBySequenceInput === "function") {
          navigateToSceneBySequenceInput();
        }
        return;
      }
      if (key === "h" || key === "H") {
        if (mapOpen && typeof closeExportMap === "function") closeExportMap();
        if (typeof stopAutoTour === "function") stopAutoTour();
        if (typeof e.preventDefault === "function") e.preventDefault();
        if (typeof e.stopPropagation === "function") e.stopPropagation();
        navigateToExportHome();
        return;
      }
      if (key === "r" || key === "R") {
        if (mapOpen && typeof closeExportMap === "function") closeExportMap();
        if (typeof stopAutoTour === "function") stopAutoTour();
        if (typeof navigateReturnHotspotFromCurrentScene !== "function") return;
        const didNavigateReturn = navigateReturnHotspotFromCurrentScene();
        if (!didNavigateReturn) return;
        if (typeof e.preventDefault === "function") e.preventDefault();
        if (typeof e.stopPropagation === "function") e.stopPropagation();
        return;
      }
      if (key === "ArrowUp") {
        if (mapOpen && typeof closeExportMap === "function") closeExportMap();
        if (typeof stopAutoTour === "function") stopAutoTour();
        if (typeof navigateToNextSequenceShortcut !== "function") return;
        const didNavigateNext = navigateToNextSequenceShortcut();
        if (!didNavigateNext) return;
        if (typeof e.preventDefault === "function") e.preventDefault();
        if (typeof e.stopPropagation === "function") e.stopPropagation();
        return;
      }
      if (key === "ArrowDown") {
        if (mapOpen && typeof closeExportMap === "function") closeExportMap();
        if (typeof stopAutoTour === "function") stopAutoTour();
        if (typeof navigateToPreviousSequenceShortcut !== "function") return;
        const didNavigatePrev = navigateToPreviousSequenceShortcut();
        if (!didNavigatePrev) return;
        if (typeof e.preventDefault === "function") e.preventDefault();
        if (typeof e.stopPropagation === "function") e.stopPropagation();
        return;
      }
    }
    if (typeof window !== "undefined") {
      window.addEventListener("keydown", handleExportKeydown, true);
    }

    /* --- LAZY DRIFT LOGIC --- */
    const DRIFT_MAX_SPEED = 80.0;  // degrees/second — frame-rate independent
    const DRIFT_LERP = 0.10;       // smoothing factor (~10% per frame at 60fps)
    const DRIFT_DEADZONE = 0.2;    // 20% deadzone
    let driftRuntime = { active: false, rafId: null, vector: { x: 0, y: 0 }, smoothedVector: { x: 0, y: 0 }, lastTickTime: null };

    function updateDriftVector(e) {
      if (!lookingMode) return;
      if (waypointRuntime.animationId !== null) return; // Busy navigating
      // If mouse is down, user is dragging, so pause drift
      if (e.buttons > 0) return;

      const stage = document.getElementById('stage');
      if (!stage) return;
      const rect = stage.getBoundingClientRect();

      const w = rect.width;
      const h = rect.height;
      const cx = rect.left + w / 2; // Center X relative to viewport
      const cy = rect.top + h / 2;  // Center Y relative to viewport

      if (w < 1 || h < 1) return;

      const isOutside = e.clientX < rect.left ||
                        e.clientX > rect.right ||
                        e.clientY < rect.top ||
                        e.clientY > rect.bottom;

      let vx = 0;
      let vy = 0;

      if (isOutside) {
         // Premium feel: fade-out drift over distance beyond stage boundary
         const FADE_DISTANCE = 50;
         const START_DAMPING = 0.15; // Normalized 0–1 fraction of DRIFT_MAX_SPEED at edge

         const distX = Math.max(0, rect.left - e.clientX, e.clientX - rect.right);
         const distY = Math.max(0, rect.top - e.clientY, e.clientY - rect.bottom);
         const dist = Math.sqrt(distX*distX + distY*distY);

         const distFactor = Math.max(0, 1.0 - (dist / FADE_DISTANCE));
         const outsideSpeed = START_DAMPING * distFactor; // normalized 0–1

         // Normalize direction to unit vector to prevent diagonal acceleration
         const rawDx = (e.clientX - cx);
         const rawDy = (e.clientY - cy);
         const mag = Math.sqrt(rawDx*rawDx + rawDy*rawDy);
         if (mag > 0) {
             vx = (rawDx / mag) * outsideSpeed;
             vy = (rawDy / mag) * outsideSpeed;
         }
      } else {
        const dx = (e.clientX - cx) / (w / 2); // -1.0 to 1.0
        const dy = (e.clientY - cy) / (h / 2); // -1.0 to 1.0

        // Deadzone check (20% of half-dimension)
        const ax = Math.abs(dx);
        const ay = Math.abs(dy);

        if (ax > DRIFT_DEADZONE) {
          const sign = Math.sign(dx);
          const ramp = (ax - DRIFT_DEADZONE) / (1.0 - DRIFT_DEADZONE);
          const smooth = ramp * ramp * (3.0 - 2.0 * ramp); // smoothstep: gentle mid, firm edge
          vx = sign * smooth; // normalized 0–1
        }

        if (ay > DRIFT_DEADZONE) {
          const sign = Math.sign(dy);
          const ramp = (ay - DRIFT_DEADZONE) / (1.0 - DRIFT_DEADZONE);
          const smooth = ramp * ramp * (3.0 - 2.0 * ramp); // smoothstep
          vy = sign * smooth; // normalized 0–1
        }
      }

      driftRuntime.vector = { x: vx, y: vy };

      if (!driftRuntime.active && (vx !== 0 || vy !== 0)) {
        startDriftLoop();
      }
    }

    function startDriftLoop() {
      if (driftRuntime.active) return;
      driftRuntime.active = true;

      function tick(now) {
        // Stop if navigating — clear all state immediately
        if (waypointRuntime.animationId !== null) {
          driftRuntime.active = false;
          driftRuntime.vector = { x: 0, y: 0 };
          driftRuntime.smoothedVector = { x: 0, y: 0 };
          driftRuntime.lastTickTime = null;
          return;
        }

        // Delta time — frame-rate independent (cap at 50ms to survive tab hide/wake)
        const dt = driftRuntime.lastTickTime !== null ? Math.min((now - driftRuntime.lastTickTime) / 1000.0, 0.05) : 0.016;
        driftRuntime.lastTickTime = now;

        // Lerp smoothed vector toward target vector (inertia + coast-to-stop)
        driftRuntime.smoothedVector.x += (driftRuntime.vector.x - driftRuntime.smoothedVector.x) * DRIFT_LERP;
        driftRuntime.smoothedVector.y += (driftRuntime.vector.y - driftRuntime.smoothedVector.y) * DRIFT_LERP;

        const sx = driftRuntime.smoothedVector.x;
        const sy = driftRuntime.smoothedVector.y;

        // Stop once both the target and smoothed vector are effectively zero
        if (Math.abs(sx) < 0.001 && Math.abs(sy) < 0.001 &&
            driftRuntime.vector.x === 0 && driftRuntime.vector.y === 0) {
          driftRuntime.active = false;
          driftRuntime.smoothedVector = { x: 0, y: 0 };
          driftRuntime.lastTickTime = null;
          return;
        }

        if (window.viewer && typeof window.viewer.getYaw === 'function') {
           const nextYaw   = window.viewer.getYaw()   + sx * dt * DRIFT_MAX_SPEED;
           const nextPitch = window.viewer.getPitch() - sy * dt * DRIFT_MAX_SPEED; // Invert Y
           const clampedPitch = Math.max(-85, Math.min(85, nextPitch));
           window.viewer.lookAt(clampedPitch, nextYaw, getCurrentHfov(), false);
        }

        driftRuntime.rafId = requestAnimationFrame(tick);
      }
      driftRuntime.rafId = requestAnimationFrame(tick);
    }

    function shouldStopAutoTourOnPointerDown(event) {
      const target = event?.target;
      if (!target || typeof target.closest !== "function") return true;
      return !target.closest(
        "#viewer-floor-tags-export, #viewer-portrait-mode-selector-export, #viewer-floor-nav-export, #viewer-portrait-joystick-export, #viewer-sequence-prompt-export, .looking-mode-indicator",
      );
    }

    // Attach Global Listeners
    if (typeof document !== 'undefined') {
      document.addEventListener("mousemove", updateDriftVector);
      document.addEventListener("mousedown", event => {
         if (
           typeof stopAutoTour === "function" &&
           shouldStopAutoTourOnPointerDown(event)
         ) {
           stopAutoTour();
         }
         driftRuntime.vector = { x: 0, y: 0 };
         driftRuntime.smoothedVector = { x: 0, y: 0 };
         driftRuntime.active = false;
         driftRuntime.lastTickTime = null;
         if (driftRuntime.rafId) cancelAnimationFrame(driftRuntime.rafId);
      });
    }
`
