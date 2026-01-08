import { showLinkModal } from "./LinkModal.js";
import { store } from "../store.js";
import { syncLabelMenu } from "./LabelMenu.js";
import { syncHotspots, createHotspotConfig } from "./HotspotManager.js";
import {
  getIsSimulationMode,
  getIncomingLink,
  setIncomingLink,
  getAutoForwardChain,
  resetAutoForwardChain,
  getPendingReturnSceneName,
  setPendingReturnSceneName,
  navigateToScene,
  updateReturnPrompt,
  handleAutoForward,
  initNavigation,
  cancelNavigation
} from "../systems/NavigationSystem.js";
import { setupViewerUI } from "./ViewerUI.js";
import { HotspotLineSystem } from "../systems/HotspotLineSystem.js";
import { Debug } from "../utils/Debug.js";
import { HOTSPOT_VISUAL_OFFSET_DEGREES } from "../constants.js";

const GLOBAL_HFOV = 90;
let viewerA = null;
let viewerB = null;
let activeViewerKey = 'A'; // 'A' or 'B'
let lastMouseEvent = null;
let guide = null; // Global reference to the cursor guide element
let lastPreloadingIndex = -1;

// FOLLOW CURSOR STATE
let mouseXNorm = 0; // -1 to 1
let mouseYNorm = 0; // -1 to 1
let followLoopActive = false;
let ratchetState = {
  pitchOffset: 0,
  yawOffset: 0,
  maxPitchOffset: 0,
  minPitchOffset: 0,
  maxYawOffset: 0,
  minYawOffset: 0
};

function getActiveViewer() { return activeViewerKey === 'A' ? viewerA : viewerB; }
function getInactiveViewer() { return activeViewerKey === 'A' ? viewerB : viewerA; }
function getActiveContainerId() { return activeViewerKey === 'A' ? 'panorama-a' : 'panorama-b'; }
function getInactiveContainerId() { return activeViewerKey === 'A' ? 'panorama-b' : 'panorama-a'; }

/**
 * Animation loop for the "Follow Cursor" behavior in Phase 2
 */
function updateFollowLoop() {
  // ABORT: If store is busy processing a heavy upload
  const progressUi = document.getElementById("processing-ui");
  if (progressUi && !progressUi.classList.contains("hidden")) return;

  const viewer = getActiveViewer();
  if (!followLoopActive || !viewer || !store.state.linkDraft || !store.state.isLinking) {
    followLoopActive = false;
    return;
  }

  // Speed Factor: CUBIC scaling (less sensitive at center, more at edges)
  const yawSpeed = 1.0;
  const pitchSpeed = 0.7;

  // Deadzone (don't move if very close to center)
  const deadzone = 0.1;

  if (Math.abs(mouseXNorm) > deadzone || Math.abs(mouseYNorm) > deadzone) {
    // CUBIC CURVE: Less sensitive at center, more sensitive at edges
    // This allows precision near the center while maintaining control at the edges
    const yawDelta = Math.pow(mouseXNorm, 3) * yawSpeed;
    const pitchDelta = -(Math.pow(mouseYNorm, 3) * pitchSpeed);

    let appliedYawDelta = 0;
    let appliedPitchDelta = 0;

    // Track relative movement
    ratchetState.yawOffset += yawDelta;
    ratchetState.pitchOffset += pitchDelta;

    const edgeThreshold = 0.85; // Cursor must be near edge to override ratchet
    const edgeReluctance = 0.4; // 40% speed when pusing against the ratchet at the edge

    if (ratchetState.yawOffset > ratchetState.maxYawOffset) {
      appliedYawDelta = (ratchetState.yawOffset - ratchetState.maxYawOffset);
      ratchetState.maxYawOffset = ratchetState.yawOffset;
      ratchetState.minYawOffset = Math.min(ratchetState.minYawOffset, ratchetState.yawOffset);
    } else if (ratchetState.yawOffset < ratchetState.minYawOffset) {
      appliedYawDelta = (ratchetState.yawOffset - ratchetState.minYawOffset);
      ratchetState.minYawOffset = ratchetState.yawOffset;
      ratchetState.maxYawOffset = Math.max(ratchetState.maxYawOffset, ratchetState.yawOffset);
    } else if (Math.abs(mouseXNorm) > edgeThreshold) {
      // EDGE OVERRIDE: Move reluctantly if at the edge, even if not a new extreme
      appliedYawDelta = yawDelta * edgeReluctance;
      ratchetState.maxYawOffset += appliedYawDelta;
      ratchetState.minYawOffset += appliedYawDelta;
    }

    if (ratchetState.pitchOffset > ratchetState.maxPitchOffset) {
      appliedPitchDelta = (ratchetState.pitchOffset - ratchetState.maxPitchOffset);
      ratchetState.maxPitchOffset = ratchetState.pitchOffset;
      ratchetState.minPitchOffset = Math.min(ratchetState.minPitchOffset, ratchetState.pitchOffset);
    } else if (ratchetState.pitchOffset < ratchetState.minPitchOffset) {
      appliedPitchDelta = (ratchetState.pitchOffset - ratchetState.minPitchOffset);
      ratchetState.minPitchOffset = ratchetState.pitchOffset;
      ratchetState.maxPitchOffset = Math.max(ratchetState.maxPitchOffset, ratchetState.pitchOffset);
    } else if (Math.abs(mouseYNorm) > edgeThreshold) {
      // EDGE OVERRIDE: Move reluctantly if at the edge
      appliedPitchDelta = pitchDelta * edgeReluctance;
      ratchetState.maxPitchOffset += appliedPitchDelta;
      ratchetState.minPitchOffset += appliedPitchDelta;
    }

    if (appliedYawDelta !== 0) viewer.setYaw(viewer.getYaw() + appliedYawDelta, false);
    if (appliedPitchDelta !== 0) viewer.setPitch(viewer.getPitch() + appliedPitchDelta, false);
  }

  // ALWAYS update lines in the loop to support the flowing arrow animation
  HotspotLineSystem.updateLines(viewer, store.state, lastMouseEvent);

  requestAnimationFrame(updateFollowLoop);
}

// TRACKING for state management
let lastSceneId = null;
let lastHotspotCount = 0;
let lastIsLinking = false;
let lastCategory = "indoor";
let lastFloor = "ground";
let lastAppliedYaw = null;
let lastAppliedPitch = null;

// Viewport saving debounce to prevent accidental changes
let viewportSaveTimeout = null;

// Snapshot pre-calculation timeout
let idleSnapshotTimeout = null;

// Scene loading guard to prevent race conditions
let loadingSceneId = null;
let isSceneLoading = false;
let loadSafetyTimeout = null;

// PERFORMANCE: Cached DOM references to avoid querySelectorAll on every syncUI call
let cachedFloorCircles = null;

/**
 * Capture a snapshot of the current viewer state for smooth transitions.
 * Pre-calculating this during idle time avoids frame drops when the transition starts.
 */
function requestIdleSnapshot() {
  if (idleSnapshotTimeout) clearTimeout(idleSnapshotTimeout);

  idleSnapshotTimeout = setTimeout(() => {
    const viewer = getActiveViewer();
    if (!viewer) return;

    try {
      const containerId = getActiveContainerId();
      const canvas = document.getElementById(containerId)?.querySelector("canvas");
      if (!canvas) return;

      canvas.toBlob((blob) => {
        if (blob) {
          const snapshotUrl = URL.createObjectURL(blob);
          const state = store.state;
          const currentScene = state.scenes[state.activeIndex];

          if (currentScene) {
            // Clean up old pre-calculated URL if it exists
            if (currentScene._preCalculatedSnapshot) {
              URL.revokeObjectURL(currentScene._preCalculatedSnapshot);
            }
            currentScene._preCalculatedSnapshot = snapshotUrl;
            console.log(`[Viewer] Pre-calculated snapshot for: ${currentScene.name}`);
          }
        }
      }, "image/webp", 0.7);
    } catch (e) {
      console.warn("[Viewer] Idle snapshot capture failed:", e);
    }
    idleSnapshotTimeout = null;
  }, 2000); // Capture after 2 seconds of idleness
}

/**
 * Main Viewer Component
 */
export function initViewer() {
  const viewerContainer = document.getElementById("viewer-container");
  if (!viewerContainer) return;

  // Remove legacy styles if present
  const oldStyle = document.getElementById("viewer-styles");
  if (oldStyle) oldStyle.remove();

  const viewerStage = document.getElementById("viewer-stage");
  if (!viewerStage) return;

  // Initialize Navigation State
  initNavigation();

  // Setup UI elements only once
  if (!document.getElementById("btn-add-link-fab")) {
    setupViewerUI(viewerStage, null); // Pass null for now, we'll sync viewer in syncHotspots
    // Cache floor circles after UI is built (one-time query)
    cachedFloorCircles = document.querySelectorAll(".floor-circle");
    // Initial Dimming State Check
    syncViewControls(store.state);

    // --- 1. KEYBOARD CONTROLS ---
    window.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        if (store.state.isLinking) {
          store.state.isLinking = false;
          store.setLinkDraft(null);
          store.notify();
          window.notify("Link Cancelled", "info");
        }
      }

      if (e.key === "Enter") {
        const state = store.state;
        if (state.isLinking && state.linkDraft) {
          // FINISH LINKING
          console.log("[Viewer] Enter pressed. Finishing link creation.");

          // STOP movement
          followLoopActive = false;

          const draft = state.linkDraft;
          // Target location is the LAST point added.
          // If no intermediate points, maybe use the start point? (Zero length link?)
          // Or use current mouse path? We can't easily get mouse path here without tracking it.
          // Assumption: User clicked at least once for start.
          // If they press Enter immediately after start -> valid 0-length link? Or error?
          // Better: If points > 0, use the last one. If 0, warn user.

          let targetPitch, targetYaw;

          if (draft.intermediatePoints && draft.intermediatePoints.length > 0) {
            const lastPoint = draft.intermediatePoints[draft.intermediatePoints.length - 1];
            targetPitch = lastPoint.pitch;
            targetYaw = lastPoint.yaw;
          } else {
            // No intermediate points. Use start point? 
            // Or maybe they just want to link to a scene without a path?
            // Let's just use the start point, creating a point-hotspot without a line?
            targetPitch = draft.pitch;
            targetYaw = draft.yaw;
          }

          const viewer = getActiveViewer();
          const camPitch = viewer ? viewer.getPitch() : 0;
          const camYaw = viewer ? viewer.getYaw() : 0;
          const camHfov = viewer ? viewer.getHfov() : 100;

          showLinkModal(targetPitch, targetYaw, camPitch, camYaw, camHfov, getPendingReturnSceneName(), draft);
          setPendingReturnSceneName(null);
        }
      }
    });

    if (store.state.scenes.length > 0) {
      syncUI(store.state, store.state.scenes[store.state.activeIndex]);
    }
  }

  // --- 2. LASER POINTER / CURSOR GUIDE ---
  guide = document.getElementById("cursor-guide");
  if (viewerStage && guide) {
    viewerStage.addEventListener("mousemove", (e) => {
      lastMouseEvent = e;
      const state = store.state;
      const progressUi = document.getElementById("processing-ui");
      const isBusy = progressUi && !progressUi.classList.contains("hidden");
      const viewer = getActiveViewer();

      if (viewer && !isBusy) HotspotLineSystem.updateLines(viewer, state, e);

      const centerIndicator = document.getElementById("viewer-center-indicator");

      if (state.isLinking && viewer && centerIndicator && guide) {
        const rect = viewerStage.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;

        // Calculate normalized mouse position for follow loop
        mouseXNorm = ((x / rect.width) * 2) - 1;
        mouseYNorm = ((y / rect.height) * 2) - 1;

        if (!state.linkDraft) {
          // --- PHASE 1: Click 1 (Blinking circle follows mouse) ---
          centerIndicator.style.display = "block";
          centerIndicator.classList.add("animate-slow-blink");
          centerIndicator.style.left = x + "px";
          centerIndicator.style.top = y + "px";

          // Hide yellow crosshair guide in Phase 1
          guide.style.display = "none";
        } else {
          // --- PHASE 2: Click 2 (Anchored circle + Yellow crosshair follows mouse) ---

          // Start follow loop if not active
          if (!followLoopActive) {
            followLoopActive = true;
            // Initialize ratchet state for this session
            ratchetState = {
              pitchOffset: 0,
              yawOffset: 0,
              maxPitchOffset: 0,
              minPitchOffset: 0,
              maxYawOffset: 0,
              minYawOffset: 0
            };
            requestAnimationFrame(updateFollowLoop);
          }

          // 1. Anchored Circle (Now represents the CAMERA's starting orientation)
          const coords = HotspotLineSystem.getScreenCoords(viewer, state.linkDraft.camPitch, state.linkDraft.camYaw, rect);
          if (coords) {
            centerIndicator.style.display = "block";
            centerIndicator.classList.remove("animate-slow-blink"); // Stop blinking
            centerIndicator.style.left = coords.x + "px";
            centerIndicator.style.top = coords.y + "px";
          } else {
            centerIndicator.style.display = "none";
          }

          // 2. Yellow Crosshair Guide follows mouse
          guide.style.display = "block";
          guide.style.left = x + "px";
          guide.style.top = y + "px";

          // Precision Perspective Line (from existing logic)
          const pCoords = viewer.mouseEventToCoords(e);
          const clickPitch = pCoords[0];
          const targetPitch = clickPitch - 15;
          const toRad = (deg) => deg * (Math.PI / 180);
          const hfov = viewer.getHfov();
          const camPitch = viewer.getPitch();
          const aspectRatio = rect.width / rect.height;
          const tanVfov2 = Math.tan(toRad(hfov / 2)) / aspectRatio;
          const yClickRel = Math.tan(toRad(clickPitch - camPitch)) / tanVfov2;
          const yTargetRel = Math.tan(toRad(targetPitch - camPitch)) / tanVfov2;
          const halfHeight = rect.height / 2;
          const yClickScreen = halfHeight * (1 - yClickRel);
          const yTargetScreen = halfHeight * (1 - yTargetRel);
          const guideHeight = yTargetScreen - yClickScreen;
          guide.style.height = Math.max(0, guideHeight) + "px";
        }
      }

      if (!state.isLinking || !viewer) {
        if (centerIndicator) centerIndicator.style.display = "none";
        guide.style.display = "none";
        return;
      }
    });

    viewerStage.addEventListener("mousedown", (e) => {
      // Manual interactions always reset the navigation guard!
      cancelNavigation();

      // Stop internal Pannellum movement if we have an active viewer
      const viewer = getActiveViewer();
      if (viewer) {
        // setting a coordinate with 0 duration usually stops ongoing movement
        viewer.setPitch(viewer.getPitch(), false);
        viewer.setYaw(viewer.getYaw(), false);
      }
    });

    viewerContainer.addEventListener("mouseleave", () => {
      guide.style.display = "none";
    });
  }

  // --- 3. STORE SUBSCRIPTION ---
  store.subscribe((state) => {
    syncViewControls(state);
    const centerIndicator = document.getElementById("viewer-center-indicator");

    // Stop follow loop if linking is disabled
    if (!state.isLinking) {
      followLoopActive = false;
    }

    if (state.scenes.length === 0) {
      if (centerIndicator) {
        centerIndicator.style.display = "none";
        centerIndicator.style.left = "50%";
        centerIndicator.style.top = "50%";
      }
      if (viewerA) { try { viewerA.destroy(); } catch (e) { } viewerA = null; }
      if (viewerB) { try { viewerB.destroy(); } catch (e) { } viewerB = null; }
      window.pannellumViewer = null;
      document.getElementById('panorama-a').classList.add('active');
      document.getElementById('panorama-b').classList.remove('active');
      activeViewerKey = 'A';
      // Also clear any stuck snapshot
      const snapshot = document.getElementById("viewer-snapshot-overlay");
      if (snapshot) {
        snapshot.classList.remove("snapshot-visible");
        snapshot.style.backgroundImage = 'none';
      }
      // Sync FAB and Cancel Hint even with no scenes loaded
      syncLinkingModeUI(state);
      return;
    }

    const currentScene = state.scenes[state.activeIndex];

    // Ensure center indicator visibility is tied strictly to linking mode
    if (centerIndicator) {
      if (state.isLinking) centerIndicator.style.display = "block";
      else centerIndicator.style.display = "none";
    }

    syncUI(state, currentScene);

    // --- ANTICIPATORY PRE-LOADING ---
    const preIndex = state.preloadingSceneIndex;
    if (preIndex !== -1 && preIndex !== lastPreloadingIndex && preIndex !== state.activeIndex) {
      console.log(`[Viewer] Detected anticipatory pre-load signal for Scene ${preIndex}`);
      lastPreloadingIndex = preIndex;
      // Trigger load on inactive viewer, but don't swap yet
      loadNewScene(lastSceneId, preIndex);
    }

    const hasSceneChanged = currentScene.id !== lastSceneId;
    const hasHotspotsChanged = currentScene.hotspots.length !== lastHotspotCount;

    // IF SCENE CHANGED: Determine if it was a manual jump or a linked navigation
    if (hasSceneChanged) {
      const isLinkedNavigation = state.transition && (state.transition.type === 'link' || state.transition.type === 'drone');
      if (!isLinkedNavigation) {
        // Manual jump (Sidebar) - Clear stale history and auto-forward chain
        setIncomingLink(null);
        resetAutoForwardChain();
      }
    }

    // SETTINGS PERSISTENCE: Inheritance & Memory
    const isVirgin = currentScene._metadataSource === "default" &&
      currentScene.hotspots.length === 0 &&
      !currentScene.label;

    if (hasSceneChanged && isVirgin) {
      let changed = false;
      const updates = {};
      if (currentScene.category !== lastCategory) { updates.category = lastCategory; changed = true; }
      if (currentScene.floor !== lastFloor) { updates.floor = lastFloor; changed = true; }
      if (changed) {
        console.log(`Inheriting settings for virgin scene: cat=${lastCategory}, floor=${lastFloor}`);
        store.updateSceneMetadata(state.activeIndex, updates);
      }
    }

    // Update memory
    lastCategory = currentScene.category || "indoor";
    lastFloor = currentScene.floor || "ground";

    // If only linking state or hotspots changed, don't reload entire viewer
    if (!hasSceneChanged) {
      const viewer = getActiveViewer();
      syncHotspots(viewer, state, currentScene, getIncomingLink(), getIsSimulationMode(), navigateToScene);

      // AUTO-FOCUS REDIRECTION: If view coordinates in state changed (manual jump), re-orient
      if (viewer && (state.activeYaw !== lastAppliedYaw || state.activePitch !== lastAppliedPitch)) {
        console.log(`[Viewer] Scene same, but view changed (${state.activeYaw}, ${state.activePitch}). Re-orienting.`);
        viewer.setYaw(state.activeYaw, false);
        viewer.setPitch(state.activePitch, false);
        lastAppliedYaw = state.activeYaw;
        lastAppliedPitch = state.activePitch;
      }

      if (viewer) HotspotLineSystem.updateLines(viewer, state, lastMouseEvent);
      lastIsLinking = state.isLinking;
      lastHotspotCount = currentScene.hotspots.length;
      return;
    }

    // SCENE RELOAD LOGIC
    // CRITICAL: Capture the previous scene ID BEFORE updating lastSceneId
    const prevSceneId = lastSceneId;
    lastSceneId = currentScene.id;
    lastHotspotCount = currentScene.hotspots.length;
    lastAppliedYaw = state.activeYaw;
    lastAppliedPitch = state.activePitch;

    const snapshot = document.getElementById("viewer-snapshot-overlay");

    function performSwap(loadedScene) {
      const swapStartTime = Date.now();
      const inactiveKey = activeViewerKey === 'A' ? 'B' : 'A';

      // Capture elements based on CURRENT active key before we switch it
      const activeContainerId = activeViewerKey === 'A' ? 'panorama-a' : 'panorama-b';
      const inactiveContainerId = activeViewerKey === 'B' ? 'panorama-a' : 'panorama-b';

      const activeEl = document.getElementById(activeContainerId);
      const inactiveEl = document.getElementById(inactiveContainerId);

      const oldViewer = getActiveViewer(); // Reference to the outgoing viewer

      // Get reference to the new viewer BEFORE switching context
      const newViewer = inactiveKey === 'A' ? viewerA : viewerB;

      // Helper to get computed opacity
      const getComputedOpacity = (el) => el ? parseFloat(window.getComputedStyle(el).opacity) : null;
      const snapshotEl = document.getElementById('viewer-snapshot-overlay');
      const hotspotEls = document.querySelectorAll('.pnlm-hotspot');

      // TELEMETRY: Log swap initiation (Essential info only)
      Debug.info('Viewer', 'SWAP_INITIATED', {
        scene: loadedScene?.name,
        activeViewer: activeViewerKey,
        isSimulation: getIsSimulationMode()
      });

      // TRIGGER CROSSFADE OR CUT
      finishSwap();

      function finishSwap() {
        const finishStartTime = Date.now();

        // 1. SWITCH GLOBAL CONTEXT
        activeViewerKey = inactiveKey;
        window.pannellumViewer = getActiveViewer();

        // 2. DRAW UI (Hidden but ready)
        HotspotLineSystem.updateLines(getActiveViewer(), state, lastMouseEvent);
        // Force redraw of persistent lines (waypoints) specifically after state sync
        setTimeout(() => HotspotLineSystem.updateLines(getActiveViewer(), state), 0);

        // 3. TRIGGER CROSSFADE OR CUT
        const isCut = state.transition && state.transition.type === 'cut';

        if (isCut) {
          // Disable transitions for instant cut
          activeEl.style.transition = 'none';
          inactiveEl.style.transition = 'none';
        } else {
          // ensure transitions are enabled (default css)
          activeEl.style.transition = '';
          inactiveEl.style.transition = '';
        }

        activeEl.classList.remove('active');
        inactiveEl.classList.add('active');

        // Capture visual state IMMEDIATELY after class change
        const panoAOpacity = parseFloat(window.getComputedStyle(document.getElementById('panorama-a')).opacity);
        const panoBOpacity = parseFloat(window.getComputedStyle(document.getElementById('panorama-b')).opacity);

        if (isCut) {
          // Restore transitions asynchronously
          setTimeout(() => {
            activeEl.style.transition = '';
            inactiveEl.style.transition = '';
          }, 50);
        }

        // TELEMETRY: Log crossfade trigger with timing and VISUAL state
        Debug.info('Viewer', 'SWAP_INITIATED', {
          type: isCut ? 'CUT' : 'CROSSFADE',
          scene: loadedScene?.name,
          totalSwapTime: Date.now() - swapStartTime,
          preAnimationDelay: finishStartTime - swapStartTime,
          cssTransitionDuration: '300ms',
          newViewerCamera: { pitch: getActiveViewer()?.getPitch(), yaw: getActiveViewer()?.getYaw() },
          visual: {
            panoramaA: { nowActive: inactiveEl?.id === 'panorama-a', opacity: panoAOpacity },
            panoramaB: { nowActive: inactiveEl?.id === 'panorama-b', opacity: panoBOpacity },
            fadeDirection: `${activeContainerId} → ${inactiveContainerId}`
          }
        });

        // 4. CLEANUP
        // Defer destruction of old viewer to ensure smooth texture hand-off
        // MAINTAIN SYNC WITH CSS: transition: opacity 0.3s
        setTimeout(() => {
          if (oldViewer) {
            try { oldViewer.destroy(); } catch (e) { }
            // If we are now 'B', then 'A' was the old one.
            if (activeViewerKey === 'B') viewerA = null; else viewerB = null;
          }
        }, 500);

        // Fade out AND clear snapshot (ONLY in non-simulation mode)
        // In simulation mode, snapshot causes visual interference during rapid transitions
        if (snapshot && !getIsSimulationMode()) {
          snapshot.classList.remove("snapshot-visible");
          setTimeout(() => {
            if (!snapshot.classList.contains("snapshot-visible")) {
              snapshot.style.backgroundImage = 'none';
            }
          }, 450);
        } else if (snapshot && getIsSimulationMode()) {
          // Force hide snapshot in simulation mode
          snapshot.classList.remove("snapshot-visible");
          snapshot.style.backgroundImage = 'none';
        }

        // Only request new snapshot in non-simulation mode
        if (!getIsSimulationMode()) {
          requestIdleSnapshot();
        }

        // FINAL SYNC CHECK: If store changed while we were loading, trigger next load immediately
        isSceneLoading = false;
        loadingSceneId = null;

        const latestState = store.state;
        const latestActiveScene = latestState.scenes[latestState.activeIndex];
        if (latestActiveScene && latestActiveScene.id !== loadedScene.id) {
          console.log(`[Viewer] Scene changed during load (${loadedScene.name} -> ${latestActiveScene.name}). Triggering recovery load.`);
          // lastAppliedSceneId is already set to the latest one by the subscriber, 
          // but we need to call loadNewScene to catch up
          loadNewScene(loadedScene.id);
        }
      }
    }

    function loadNewScene(capturedPrevSceneId, anticipatoryTargetIndex = null) {
      const isAnticipatory = anticipatoryTargetIndex !== null;
      const targetIndex = isAnticipatory ? anticipatoryTargetIndex : state.activeIndex;
      const targetScene = state.scenes[targetIndex];

      if (!targetScene) return;

      const inactiveKey = activeViewerKey === 'A' ? 'B' : 'A';
      const inactiveViewer = inactiveKey === 'A' ? viewerA : viewerB;
      const containerId = inactiveKey === 'A' ? 'panorama-a' : 'panorama-b';

      // REUSE CHECK: If the inactive viewer already has this scene loaded/loading, don't start over
      if (inactiveViewer && !isAnticipatory) {
        const config = inactiveViewer.getConfig();
        const currentPano = config.panorama;
        // Check if the panorama URL matches or if we can identify the scene
        // Since we use blob URLs, we might need a better way. 
        // Let's attach the scene ID to the viewer object for reliable checking.
        if (inactiveViewer._sceneId === targetScene.id) {
          console.log(`[Viewer] Inactive viewer already has Scene ${targetScene.name}. Reusing.`);
          // If it was already loaded, it might be waiting for activeIndex to match.
          // Trigger the check manually.
          if (inactiveViewer._isLoaded) {
            if (store.state.activeIndex === targetIndex) {
              console.log("[Viewer] Reused viewer is ready. Swapping.");
              performSwap(targetScene);
            }
          }
          return;
        }
      }

      if (isSceneLoading) {
        // If we are already loading a DIFFERENT scene, we let it finish, 
        // the performSwap() hook above will catch the discrepancy and start the correct load.
        console.warn(`[Viewer] Load in progress. Queueing Scene ${targetScene.name} via next sync cycle.`);
        return;
      }
      isSceneLoading = true;
      loadingSceneId = targetScene.id;

      // SAFETY TIMEOUT: If load takes > 10s, force reset guard
      if (loadSafetyTimeout) clearTimeout(loadSafetyTimeout);
      loadSafetyTimeout = setTimeout(() => {
        if (isSceneLoading && loadingSceneId === targetScene.id) {
          console.error(`[Viewer] Scene load timed out for ${targetScene.name}. Force clearing guard.`);
          isSceneLoading = false;
          loadingSceneId = null;
        }
      }, 10000);


      // Use pre-calculated snapshot if available for the PREVIOUS scene
      const prevScene = state.scenes.find(s => s.id === capturedPrevSceneId);
      const snapshot = document.getElementById("viewer-snapshot-overlay");

      if (prevScene && prevScene._preCalculatedSnapshot && snapshot) {
        const snapUrl = prevScene._preCalculatedSnapshot;
        // Don't show snapshot if doing an instant cut
        const isCut = state.transition && state.transition.type === 'cut';
        if (!isCut) {
          snapshot.style.backgroundImage = `url(${snapUrl})`;
          snapshot.classList.add("snapshot-visible");
        }

        // We "take" the URL, and defer revocation slightly
        prevScene._preCalculatedSnapshot = null;
        setTimeout(() => URL.revokeObjectURL(snapUrl), 1000);
      } else {
        // Fallback to immediate capture if no pre-calculated exists
        try {
          const activeViewer = getActiveViewer();
          if (activeViewer) {
            const canvas = document.getElementById(getActiveContainerId())?.querySelector("canvas");
            if (canvas) {
              canvas.toBlob((blob) => {
                if (blob && snapshot) {
                  const isCut = state.transition && state.transition.type === 'cut';
                  // Don't show snapshot if doing an instant cut
                  if (!isCut) {
                    if (window._currentSnapshotUrl) URL.revokeObjectURL(window._currentSnapshotUrl);
                    window._currentSnapshotUrl = URL.createObjectURL(blob);
                    snapshot.style.backgroundImage = `url(${window._currentSnapshotUrl})`;
                    snapshot.classList.add("snapshot-visible");
                  }
                }
              }, "image/webp", 0.7);
            }
          }
        } catch (e) {
          console.warn("Snapshot capture failed:", e);
        }
      }

      const panoramaUrl = URL.createObjectURL(targetScene.file);
      // OPTIMIZATION: In Simulation Mode or Pre-loading, we prioritize QUALITY over latency.
      // We disable progressive loading to ensure we don't swap textures (pop) during the cinematic transition.
      // We want the scene to be 100% ready (Master 4K) before the cross-dissolve starts.
      const useProgressive = !!targetScene.tinyFile && !getIsSimulationMode() && !isAnticipatory;
      const tinyUrl = useProgressive ? URL.createObjectURL(targetScene.tinyFile) : null;

      // SANITIZATION: Ensure yaw and pitch are never NaN
      const initialPitch = Number.isFinite(state.activePitch) ? state.activePitch : 0;
      const initialYaw = Number.isFinite(state.activeYaw) ? state.activeYaw : 0;
      const initialHfov = GLOBAL_HFOV; // Fixed at 90° - zoom disabled

      const viewerConfig = {
        default: { firstScene: useProgressive ? 'preview' : 'master' },
        scenes: {
          preview: {
            type: "equirectangular",
            panorama: tinyUrl,
            autoLoad: true,
            pitch: initialPitch,
            yaw: initialYaw,
            hfov: initialHfov,
            minHfov: GLOBAL_HFOV,
            maxHfov: GLOBAL_HFOV,
            mouseZoom: false,
            doubleClickZoom: false,
            friction: 0.05,
            hotSpots: targetScene.hotspots.map((h, i) => createHotspotConfig(h, i, state, targetScene, getIncomingLink(), getIsSimulationMode(), navigateToScene)),
          },
          master: {
            type: "equirectangular",
            panorama: panoramaUrl,
            autoLoad: true,
            pitch: initialPitch,
            yaw: initialYaw,
            hfov: initialHfov,
            minHfov: GLOBAL_HFOV,
            maxHfov: GLOBAL_HFOV,
            mouseZoom: false,
            doubleClickZoom: false,
            friction: 0.05,
            hotSpots: targetScene.hotspots.map((h, i) => createHotspotConfig(h, i, state, targetScene, getIncomingLink(), getIsSimulationMode(), navigateToScene)),
          }
        }
      };
      if (!useProgressive) { delete viewerConfig.scenes.preview; viewerConfig.default.firstScene = 'master'; }

      const newViewer = pannellum.viewer(containerId, viewerConfig);
      newViewer._sceneId = targetScene.id;
      newViewer._isLoaded = false;
      if (inactiveKey === 'A') viewerA = newViewer; else viewerB = newViewer;

      newViewer.on('load', () => {
        const loadedScene = newViewer.getScene();
        const isTinyLoaded = loadedScene === 'preview';
        const isMasterLoaded = loadedScene === 'master';

        if (useProgressive && isTinyLoaded) {
          console.log("[Viewer] Low-res preview loaded, background loading 4K master...");
          const img = new Image();
          img.onload = () => {
            console.log("[Viewer] 4K master pre-loaded, swapping texture...");
            if (newViewer && newViewer.getScene() === 'preview') {
              newViewer.loadScene('master', newViewer.getPitch(), newViewer.getYaw(), newViewer.getHfov());
            } else {
              console.warn("[Viewer] Swap cancelled: Viewer changed or master already set");
            }
          };
          img.onerror = (e) => {
            console.error("[Viewer] Failed to background-load 4K panorama", e);
            isSceneLoading = false; // Allow recovery
          };
          img.src = panoramaUrl;
          return;
        }

        // Scene is fully ready
        if (!useProgressive || isMasterLoaded) {
          newViewer._isLoaded = true;
          console.log(`[Viewer] Final texture for ${targetScene.name} loaded successfully.`);

          const checkReadyAndSwap = () => {
            // Only swap if this scene is actually the store's active scene now
            if (store.state.activeIndex === targetIndex && !isAnticipatory) {
              console.log("[Viewer] Active index matches loaded scene. Swapping now.");
              performSwap(targetScene);
            } else {
              // Scene is loaded but journey isn't at 80% yet. We wait.
              console.log("[Viewer] Anticipatory load complete. Waiting for active index to match...");
              isSceneLoading = false;

              // We'll be triggered again by the store subscriber when activeIndex changes
              // AND we hit the reuse check.
            }
          };

          if (getIsSimulationMode()) {
            // STABILITY: Wait for 3 animation frames to ensure GPU has fully rendered logic
            let frameCount = 0;
            const waitForDeepRender = () => {
              frameCount++;
              // 3 frames at 60fps is ~50ms, but guarantees composition
              if (frameCount < 3) {
                requestAnimationFrame(waitForDeepRender);
              } else {
                checkReadyAndSwap();
              }
            };
            requestAnimationFrame(waitForDeepRender);
          } else {
            checkReadyAndSwap();
          }
        }
      });

      newViewer.on('error', (err) => {
        isSceneLoading = false;
        loadingSceneId = null;
        console.error('[Viewer] Panorama load error:', err);
        console.error('[Viewer] Failed URL:', newViewer.getConfig().panorama);
        console.error('[Viewer] targetScene:', targetScene.name, { id: targetScene.id, hasTiny: !!targetScene.tinyFile });
        if (window.notify) window.notify(`Load Error: ${err}`, "error");
        // Clear stuck snapshot on error
        const snapshotEl = document.getElementById("viewer-snapshot-overlay");
        if (snapshotEl) snapshotEl.classList.remove("snapshot-visible");
      });

      // Safety timeout for snapshot dismissal
      setTimeout(() => {
        const snapshotEl = document.getElementById("viewer-snapshot-overlay");
        if (snapshotEl && snapshotEl.classList.contains("snapshot-visible")) {
          snapshotEl.classList.remove("snapshot-visible");
        }
      }, 3000);

      newViewer.on('mousedown', (e) => {
        const state = store.state;
        // SIMULATION MODE GUARD: Don't intercept clicks if in simulation mode
        if (getIsSimulationMode()) return;
        if (!state.isLinking) return;

        const coords = newViewer.mouseEventToCoords(e);
        const clickPitch = coords[0];
        const clickYaw = coords[1];
        const camPitch = newViewer.getPitch();
        const camYaw = newViewer.getYaw();
        const camHfov = newViewer.getHfov();

        if (!state.linkDraft) {
          // --- CLICK 1: START LOCATION ---
          console.log("[Viewer] Click 1: Saving start position", { clickPitch, clickYaw });
          store.setLinkDraft({
            pitch: clickPitch,
            yaw: clickYaw,
            camPitch,
            camYaw,
            camHfov,
            intermediatePoints: [] // Initialize path array
          });
          if (window.notify) window.notify("Start Point Set. Click to add path points. ENTER to finish.", "success");
        } else {
          // --- CLICK 2+: INTERMEDIATE POINTS ---
          console.log("[Viewer] Adding intermediate point", { clickPitch, clickYaw });

          // Add this point to the draft
          const currentDraft = state.linkDraft;
          if (!currentDraft.intermediatePoints) currentDraft.intermediatePoints = [];

          currentDraft.intermediatePoints.push({
            pitch: clickPitch,
            yaw: clickYaw,
            camPitch,
            camYaw
          });

          // Verify we updated the internal object (store state is reactive but deep mutations might need check)
          // We trigger an update to ensure reactivity if needed, or just rely on the object ref
          store.notify();

          if (window.notify) window.notify(`Point Added (${currentDraft.intermediatePoints.length}). Press ENTER to finish.`, "success");
        }
      });

      // KEYDOWN LISTENER FOR "ENTER" TO FINISH LINKING
      // We attach it to the container or window, but ensure we don't duplicate
      // Best to attach once globally or manage carefully. 
      // Since `newViewer` is created often, let's attach to the viewer container via a named function we can remove?
      // Or just check state in a global listener. 
      // Actually, Global listener in initViewer is better, but let's put it here for now if we can ensure cleanup.
      // Better: Use a dedicated finishLinking function called by a global listener established in initViewer.


      newViewer.on('animatefinished', () => {
        requestIdleSnapshot(); // Re-capture after animation stops
        const incoming = getIncomingLink();
        if (incoming && viewportSaveTimeout === null) {
          if (state.transition && (state.transition.type === 'link' || state.transition.type === 'drone')) {
            const hotspot = state.scenes[incoming.sceneIndex]?.hotspots[incoming.hotspotIndex];
            // For return links, update returnViewFrame; otherwise update targetYaw
            if (hotspot?.isReturnLink && hotspot?.returnViewFrame) {
              store.updateHotspotReturnView(incoming.sceneIndex, incoming.hotspotIndex, newViewer.getYaw(), newViewer.getPitch(), newViewer.getHfov());
            } else {
              store.updateHotspotTargetView(incoming.sceneIndex, incoming.hotspotIndex, newViewer.getYaw(), newViewer.getPitch(), newViewer.getHfov());
            }
          }
        }
      });

      newViewer.on('viewchange', () => {
        // Only update lines for the currently active viewer
        if (activeViewerKey === inactiveKey) HotspotLineSystem.updateLines(newViewer, store.state, lastMouseEvent);
        requestIdleSnapshot(); // Re-capture after user stops moving
        const incoming = getIncomingLink();
        if (incoming) {
          if (viewportSaveTimeout) {
            clearTimeout(viewportSaveTimeout);
          }
          viewportSaveTimeout = setTimeout(() => {
            const hotspot = state.scenes[incoming.sceneIndex]?.hotspots[incoming.hotspotIndex];
            // For return links, update returnViewFrame; otherwise update targetYaw
            if (hotspot?.isReturnLink && hotspot?.returnViewFrame) {
              store.updateHotspotReturnView(incoming.sceneIndex, incoming.hotspotIndex, newViewer.getYaw(), newViewer.getPitch(), newViewer.getHfov());
            } else {
              store.updateHotspotTargetView(incoming.sceneIndex, incoming.hotspotIndex, newViewer.getYaw(), newViewer.getPitch(), newViewer.getHfov());
            }
            viewportSaveTimeout = null;
          }, 800);
        }
      });
    }

    loadNewScene(prevSceneId);
  });
}

/**
 * Synchronize Linking Mode UI elements (FAB + Cancel Hint)
 * This can be called independently even when no scenes are loaded
 */
function syncLinkingModeUI(state) {
  const fab = document.getElementById("btn-add-link-fab");
  const cancelHint = document.getElementById("linking-cancel-hint");

  if (fab) {
    if (state.isLinking) {
      fab.style.background = "#ffcc00"; // Yellow Background
      fab.style.color = "#000000"; // Black Plus
      fab.classList.add("active");

      // Ensure crosshair dot blinks
      if (guide) guide.classList.add("cursor-dot-blinking");

      if (cancelHint) {
        // Show: animate to visible
        cancelHint.style.opacity = "1";
        cancelHint.style.transform = "translateX(-50%) translateY(0)";
      }
    } else {
      fab.style.background = "#dc3545"; // RE/MAX Red
      fab.style.color = "#ffffff"; // White Plus
      fab.classList.remove("active");

      if (guide) guide.classList.remove("cursor-dot-blinking");

      if (cancelHint) {
        // Hide: animate to invisible
        cancelHint.style.opacity = "0";
        cancelHint.style.transform = "translateX(-50%) translateY(8px)";
      }
    }
  }
}

/**
 * UI Synchronization
 */
export function syncUI(state, scene) {
  const simToggle = document.getElementById("v-scene-sim-toggle");
  const catToggle = document.getElementById("v-scene-cat-toggle");
  const lblBtn = document.getElementById("v-scene-label-btn");
  // PERFORMANCE: Use cached reference instead of querying DOM on every state change
  const circles = cachedFloorCircles || document.querySelectorAll(".floor-circle");

  // Sync FAB and Cancel Hint (shared with no-scenes case)
  syncLinkingModeUI(state);

  // Note: simToggle (Auto-Pilot) state is now managed exclusively by SimulationSystem.js
  // to avoid conflicts with the auto-pilot lifecycle and reactive UI updates.

  if (catToggle) {
    const isOutdoor = scene.category === "outdoor";
    catToggle.innerHTML = isOutdoor ? '<span class="material-icons text-[21px]">park</span>' : '<span class="material-icons text-[21px]">home</span>';
    catToggle.title = isOutdoor ? "Outdoor Scene Selected" : "Indoor Scene Selected";

    if (scene.categorySet) {
      catToggle.style.background = isOutdoor ? "#15803d" : "#c2410c"; // Green-700 or Dark Orange
    } else {
      catToggle.style.background = "#dc3545";
    }
  }

  if (lblBtn) {
    if (scene.labelSet) {
      lblBtn.style.background = "#2563eb";
    } else {
      lblBtn.style.background = "#dc3545";
    }
  }

  if (circles.length > 0) {
    circles.forEach(c => {
      const fid = c.dataset.id;
      c.style.display = "flex";
      const currentFloor = scene.floor || "ground";
      c.classList.remove("bg-floor-active", "border-floor-border-active");
      c.classList.add("bg-floor-default", "border-transparent");
      if (fid === currentFloor) {
        c.classList.remove("bg-floor-default", "border-transparent");
        c.classList.add("bg-floor-active", "border-floor-border-active");
      }
    });
  }

  syncLabelMenu(scene);
  updateReturnPrompt(state, scene);

  const pLabel = document.getElementById("v-scene-persistent-label");
  if (pLabel) {
    const currentLabel = scene.label || "";
    if (currentLabel) {
      pLabel.textContent = `#${currentLabel}`;
      pLabel.classList.remove("hidden");
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          pLabel.classList.remove("opacity-0", "-translate-y-2", "scale-95");
          pLabel.classList.add("opacity-100", "translate-y-0", "scale-100", "flex");
        });
      });
    } else {
      pLabel.classList.add("opacity-0", "-translate-y-2", "scale-95");
      pLabel.classList.remove("opacity-100", "translate-y-0", "scale-100");
      setTimeout(() => {
        if (!scene.label && pLabel.classList.contains("opacity-0")) {
          pLabel.classList.add("hidden");
          pLabel.classList.remove("flex");
        }
      }, 300);
    }
  }

  const qIndicator = document.getElementById("v-scene-quality-indicator");
  if (qIndicator) {
    const q = scene.quality;
    const badges = [];
    if (q) {
      if (q.isBlurry) badges.push({ text: "BLURRY", bg: "#dc2626" });
      else if (q.isSoft) badges.push({ text: "SOFT", bg: "#d97706" });
      if (q.isSeverelyDark) badges.push({ text: "DARK", bg: "#0f172a" });
      else if (q.isDim) badges.push({ text: "DIM", bg: "#64748b" });
    }

    if (badges.length > 0) {
      qIndicator.innerHTML = badges.map(b => `
        <span class="text-white text-[12px] font-black px-3 py-1 rounded-md tracking-wider leading-none shadow-lg border border-white/20" style="background: ${b.bg};">${b.text}</span>
      `).join('');
      qIndicator.classList.remove("hidden");
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          qIndicator.classList.remove("opacity-0", "translate-x-2", "scale-95");
          qIndicator.classList.add("opacity-100", "translate-x-0", "scale-100");
        });
      });
    } else {
      qIndicator.classList.add("opacity-0", "translate-x-2", "scale-95");
      qIndicator.classList.remove("opacity-100", "translate-x-0", "scale-100");
      setTimeout(() => {
        if ((!scene.quality || (!scene.quality.isBlurry && !scene.quality.isSoft && !scene.quality.isSeverelyDark && !scene.quality.isDim)) && qIndicator.classList.contains("opacity-0")) {
          qIndicator.classList.add("hidden");
        }
      }, 300);
    }
  }
}

function syncViewControls(state) {
  const utilityBar = document.getElementById("viewer-utility-bar");
  const floorNav = document.getElementById("viewer-floor-nav");
  const hasScenes = state.scenes.length > 0;

  if (utilityBar) {
    utilityBar.classList.toggle("viewer-utility-dimmed", !hasScenes);

    // SYNC SIMULATION BUTTON (Robustness fix)
    const simToggle = document.getElementById("v-scene-sim-toggle");
    if (simToggle) {
      const isSim = getIsSimulationMode(); // This is the source of truth for UI display
      if (isSim) {
        simToggle.innerHTML = '<span class="material-icons" style="font-size: 22px;">stop</span>';
        simToggle.style.setProperty('background-color', '#dc3545', 'important');
      } else {
        simToggle.innerHTML = '<span class="material-icons" style="font-size: 22px;">play_arrow</span>';
        simToggle.style.setProperty('background-color', '#10b981', 'important');
      }
    }
  }
  if (floorNav) {
    floorNav.classList.toggle("viewer-utility-dimmed", !hasScenes);
  }
}
