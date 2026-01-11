import { updateProgressBar } from "../utils/ProgressBar.js";
import { notify } from "../utils/NotificationSystem.js";
/**
 * Teaser System
 * 
 * Generates automated video teasers of virtual tours with:
 * - Intelligent pathfinding through linked scenes
 * - Smooth camera animations (dissolve or punchy styles)
 * - Logo watermarking
 * - WebM and MP4 export support
 * 
 * @module TeaserSystem
 */

import { store } from "../store.js";
import { DownloadSystem } from "./DownloadSystem.js";
import { getSimulationPath, startAutoPilot, stopAutoPilot, isAutoPilotActive } from "./SimulationSystem.js";
import { CacheSystem } from "./CacheSystem.js";
import { VideoEncoder } from "./VideoEncoder.js";
import { Debug } from "../utils/Debug.js";
import { BACKEND_URL } from "../constants.js";
import {
  TEASER_CANVAS_WIDTH,
  TEASER_CANVAS_HEIGHT,
  TEASER_FRAME_RATE,
  TEASER_STYLE_DISSOLVE,
  TEASER_STYLE_PUNCHY,
  TEASER_LOGO,
  FFMPEG_CRF_QUALITY,
  FFMPEG_PRESET,
  FFMPEG_CORE_VERSION,
  SCENE_STABILIZATION_DELAY,
  VIEWER_LOAD_CHECK_INTERVAL,
  PANNING_VELOCITY,
  PANNING_MIN_DURATION,
  PANNING_MAX_DURATION,
} from "../constants.js";
import { VERSION } from "../version.js";

let isTeasing = false;
let ghostCanvas = null;
let ghostCtx = null;
let mediaRecorder = null;
let activeRecorder = null; // Track the active recorder for pause/resume during transitions
let recordedChunks = [];
let streamLoopId = null;

let fadeOpacity = 0;

// TELEMETRY STATE
let frameCount = 0;
let recordingStartTime = 0;
let lastFrameTime = 0;
let fpsBuffer = [];

/**
 * Initialize the ghost canvas for off-screen rendering
 * This canvas captures the panorama viewer for teaser recording
 */
function initGhost() {
  if (ghostCanvas) return;
  ghostCanvas = document.createElement("canvas");
  ghostCanvas.width = TEASER_CANVAS_WIDTH;  // 1920px (Full HD)
  ghostCanvas.height = TEASER_CANVAS_HEIGHT; // 1080px
  ghostCtx = ghostCanvas.getContext("2d", { alpha: false });
}

function startGhostLoop() {
  const draw = () => {
    const sourceCanvas = document.querySelector(
      ".pnlm-render-container canvas",
    );
    // Only draw if source is valid
    if (sourceCanvas && sourceCanvas.width > 0) {
      // Safe draw: Aspect Fill
      const sw = sourceCanvas.width,
        sh = sourceCanvas.height;
      const dw = ghostCanvas.width,
        dh = ghostCanvas.height;
      const sourceAspect = sw / sh;
      const destAspect = dw / dh;
      let renderW, renderH, renderX, renderY;

      if (sourceAspect > destAspect) {
        renderH = dh;
        renderW = dh * sourceAspect;
        renderX = (dw - renderW) / 2;
        renderY = 0;
      } else {
        renderW = dw;
        renderH = dw / sourceAspect;
        renderX = 0;
        renderY = (dh - renderH) / 2;
      }

      ghostCtx.fillStyle = "#000";
      ghostCtx.fillRect(0, 0, dw, dh);
      ghostCtx.drawImage(sourceCanvas, renderX, renderY, renderW, renderH);

      // Fade Overlay
      if (fadeOpacity > 0) {
        ghostCtx.fillStyle = `rgba(0, 0, 0, ${fadeOpacity})`;
        ghostCtx.fillRect(0, 0, dw, dh);
      }
    }
    streamLoopId = requestAnimationFrame(draw);
  };
  draw();
}

// --- HELPER: Find a logical path through the tour ---
// Phase 1: Forward traversal via non-return links
// Phase 2: Return traversal via return links back to start
function getWalkPath(skipAutoForward = false) {
  const scenes = store.state.scenes;
  if (scenes.length === 0) return [];

  // 0. PRIORITY: TIMELINE
  // If the user has defined a visual timeline, use it as the source of truth.
  if (store.state.timeline && store.state.timeline.length > 0) {
    return getTimelinePath(store.state.timeline, scenes, skipAutoForward);
  }

  let path = [];
  let visitedScenes = new Set();
  let currentIdx = 0;

  // Start at the beginning
  // For the first scene, use the viewFrame of the FIRST hotspot (if available)
  // This is the camera position when the user created the first link
  let firstArrivalYaw = 0;
  let firstArrivalPitch = 0;
  const firstScene = scenes[0];
  if (firstScene.hotspots && firstScene.hotspots.length > 0) {
    const firstHotspot = firstScene.hotspots[0];
    Debug.debug('Teaser', 'First scene hotspot[0]:', {
      target: firstHotspot.target,
      viewFrame: firstHotspot.viewFrame,
      targetYaw: firstHotspot.targetYaw,
      targetPitch: firstHotspot.targetPitch,
      yaw: firstHotspot.yaw,
      pitch: firstHotspot.pitch
    });

    // CORRECT LOGIC: For the starting scene, we want the "Director's View" (viewFrame)
    // defined when the link was created.
    // We MUST NOT use targetYaw here, because targetYaw is the view for the NEXT scene (the target).
    if (firstHotspot.viewFrame) {
      firstArrivalYaw = firstHotspot.viewFrame.yaw !== undefined ? firstHotspot.viewFrame.yaw : 0;
      firstArrivalPitch = firstHotspot.viewFrame.pitch !== undefined ? firstHotspot.viewFrame.pitch : 0;
    }
  }

  Debug.debug('Teaser', 'First scene arrivalView computed:', { yaw: firstArrivalYaw, pitch: firstArrivalPitch });

  path.push({
    idx: 0,
    transitionTarget: null,
    arrivalView: { yaw: firstArrivalYaw, pitch: firstArrivalPitch }
  });
  visitedScenes.add(0);

  // === PHASE 1: FORWARD TRAVERSAL ===
  // Follow non-return links to unvisited scenes
  for (let i = 0; i < 12; i++) {
    const currentScene = scenes[currentIdx];

    // Find a FORWARD link (not a return link) that goes to an unvisited scene
    let forwardLink = currentScene.hotspots.find(h => {
      if (h.isReturnLink) return false; // Skip return links in forward phase
      const targetIdx = scenes.findIndex(s => s.name === h.target);
      return targetIdx !== -1 && !visitedScenes.has(targetIdx);
    });

    if (forwardLink) {
      let nextIdx = scenes.findIndex(s => s.name === forwardLink.target);

      // Update the PREVIOUS step to know where it's going (for Dissolve lookAt)
      let transYaw = forwardLink.yaw;
      let transPitch = forwardLink.pitch || 0;

      if (forwardLink.viewFrame) {
        transYaw = forwardLink.viewFrame.yaw;
        transPitch = forwardLink.viewFrame.pitch;
      }

      // Record where the camera SHOULD look (at the physical link)
      path[path.length - 1].transitionTarget = {
        yaw: transYaw,
        pitch: transPitch,
        targetName: forwardLink.target
      };

      // SKIP AUTO-FORWARD LOGIC
      // If the immediate target is an auto-forward scene, and we are skipping them,
      // we traverse the chain until we find a stable scene.
      if (skipAutoForward) {
        let chainSafeCounter = 0;
        while (chainSafeCounter < 10) {
          const nextScene = scenes[nextIdx];
          if (!nextScene || !nextScene.isAutoForward) break;

          // It is an auto-forward scene, so we mark it as visited (effectively skipping it)
          visitedScenes.add(nextIdx);

          // Find the next link from THIS auto-forward scene
          // (Same priority: unvisited, non-return)
          const jumpLink = nextScene.hotspots.find(h => {
            const tIdx = scenes.findIndex(s => s.name === h.target);
            return tIdx !== -1 && !visitedScenes.has(tIdx);
          });

          if (jumpLink) {
            // Found a valid jump, update nextIdx and continue loop
            const jumpIdx = scenes.findIndex(s => s.name === jumpLink.target);
            nextIdx = jumpIdx;
            // Note: We DO NOT update transitionTarget of the original start scene.
            // We still want the camera to look at the FIRST link (the door),
            // even if we eventually cut to a room 3 hops away.
          } else {
            // Dead end in auto-chain, just stop here (render this auto scene)
            break;
          }
          chainSafeCounter++;
        }
      }

      // We have our final destination (either the direct link, or the end of a skip chain)
      const effectiveNextScene = scenes[nextIdx];
      // Note: We might have changed nextIdx, but we rely on the original forwardLink data
      // for the arrivalView IF it was a direct jump. 
      // If we skipped scenes, we effectively arrive at the new scene. 
      // Ideally, the "arrival view" should be the DEFAULT view of that new scene,
      // because we don't have a specific "incoming link" viewFrame for a jump.

      // Let's try to find if there was a direct link to this final scene (unlikely if skipped)
      // Fallback: Use the scene's initial view if we skipped, OR use the link data if direct.

      let arrivalYaw = 0;
      let arrivalPitch = 0;

      // If we skipped (nextIdx != original target index), we default to 0,0 or scene default
      // If we didn't skip, use the link's target info.
      const originalTargetIdx = scenes.findIndex(s => s.name === forwardLink.target);

      if (nextIdx === originalTargetIdx) {
        // Direct link logic (preserved)
        if (forwardLink.viewFrame) {
          arrivalYaw = forwardLink.viewFrame.yaw !== undefined ? forwardLink.viewFrame.yaw : 0;
          arrivalPitch = forwardLink.viewFrame.pitch !== undefined ? forwardLink.viewFrame.pitch : 0;
        } else if (forwardLink.targetYaw !== undefined) {
          arrivalYaw = forwardLink.targetYaw;
          arrivalPitch = forwardLink.targetPitch !== undefined ? forwardLink.targetPitch : 0;
        }
      } else {
        // We arrived via a skip. Use partial smart logic or default 0,0
        // Optimization: Check if the skipped scene had a link with specific target info? 
        // Too complex. Defaulting to 0,0 is safe for now.
        // Better: Check if the effectiveNextScene has a 'default' view (not currently stored, usually 0,0)
      }

      Debug.debug('Teaser', `Scene ${nextIdx} arrivalView (Skipped=${nextIdx !== originalTargetIdx}):`, { yaw: arrivalYaw, pitch: arrivalPitch });

      path.push({
        idx: nextIdx,
        transitionTarget: null,
        arrivalView: { yaw: arrivalYaw, pitch: arrivalPitch }
      });

      visitedScenes.add(nextIdx);
      currentIdx = nextIdx;
    } else {
      break; // No more forward links, end Phase 1
    }
  }


  // === PHASE 2: RETURN TRAVERSAL ===
  // Follow return links back toward the starting scene
  for (let i = 0; i < 12; i++) {
    const currentScene = scenes[currentIdx];

    // Find a RETURN link
    const returnLink = currentScene.hotspots.find(h => h.isReturnLink === true);

    if (returnLink) {
      const nextIdx = scenes.findIndex(s => s.name === returnLink.target);
      if (nextIdx === -1) break; // Invalid target

      // Update the PREVIOUS step to know where it's going
      // Use viewFrame (Camera View of Last Click) explicitly
      let transYaw = returnLink.yaw;
      let transPitch = returnLink.pitch || 0;

      if (returnLink.viewFrame) {
        transYaw = returnLink.viewFrame.yaw;
        transPitch = returnLink.viewFrame.pitch;
      }

      path[path.length - 1].transitionTarget = {
        yaw: transYaw,
        pitch: transPitch,
        targetName: returnLink.target
      };

      // Use targetYaw (Live View) if available, otherwise viewFrame (Director's View)
      let arrivalYaw = 0;
      let arrivalPitch = 0;
      Debug.debug('Teaser', 'Return link found:', {
        target: returnLink.target,
        viewFrame: returnLink.viewFrame,
        targetYaw: returnLink.targetYaw,
        targetPitch: returnLink.targetPitch,
        linkYaw: returnLink.yaw,
        linkPitch: returnLink.pitch
      });

      // Priority: viewFrame > targetYaw
      if (returnLink.viewFrame) {
        arrivalYaw = returnLink.viewFrame.yaw !== undefined ? returnLink.viewFrame.yaw : 0;
        arrivalPitch = returnLink.viewFrame.pitch !== undefined ? returnLink.viewFrame.pitch : 0;
      } else if (returnLink.targetYaw !== undefined) {
        arrivalYaw = returnLink.targetYaw;
        arrivalPitch = returnLink.targetPitch !== undefined ? returnLink.targetPitch : 0;
      }

      path.push({
        idx: nextIdx,
        transitionTarget: null,
        arrivalView: { yaw: arrivalYaw, pitch: arrivalPitch }
      });

      currentIdx = nextIdx;

      // Stop if we've returned to the starting scene
      if (nextIdx === 0) break;

      // SKIP AUTO-FORWARD LOGIC FOR RETURN TRAVERSAL
      if (skipAutoForward) {
        let chainSafeCounter = 0;
        let visitedInChain = new Set();
        visitedInChain.add(nextIdx);

        while (chainSafeCounter < 10) {
          const nextScene = scenes[nextIdx];
          if (!nextScene || !nextScene.isAutoForward) break;

          // Find a return link from this auto-forward scene
          const jumpLink = nextScene.hotspots.find(h => h.isReturnLink === true);
          if (jumpLink) {
            const jumpIdx = scenes.findIndex(s => s.name === jumpLink.target);
            if (jumpIdx === -1 || visitedInChain.has(jumpIdx)) break;

            nextIdx = jumpIdx;
            visitedInChain.add(nextIdx);
            // Arrival view for jumps defaults to 0,0
            arrivalYaw = 0;
            arrivalPitch = 0;
          } else {
            break;
          }
          chainSafeCounter++;
        }
      }

      path.push({
        idx: nextIdx,
        transitionTarget: null,
        arrivalView: { yaw: arrivalYaw, pitch: arrivalPitch }
      });

      currentIdx = nextIdx;

      // Stop if we've returned to the starting scene (re-check after skip)
      if (nextIdx === 0) break;
    } else {
      break; // No return link found, end Phase 2
    }
  }

  // --- FINAL CLEANUP PASS ---
  if (skipAutoForward) {
    // 1. Filter out any remaining auto-forward scenes (catch-all)
    path = path.filter(step => {
      const scene = scenes[step.idx];
      return scene && !scene.isAutoForward;
    });
  }

  // 2. Deduplicate: Remove adjacent identical scenes
  // This can happen if multiple transitions skip to the same destination
  path = path.filter((step, i) => i === 0 || step.idx !== path[i - 1].idx);

  return path;
}

/**
 * Converts the visual timeline into a renderable path for the teaser system.
 * Handles merging steps for continuous paths and explicit jumps for discontinuities.
 */
function getTimelinePath(timeline, scenes, skipAutoForward) {
  const path = [];

  timeline.forEach((item, index) => {
    // START SCENE
    const startSceneIdx = scenes.findIndex(s => s.id === item.sceneId);
    if (startSceneIdx === -1) return; // broken link or deleted scene

    const startScene = scenes[startSceneIdx];

    // SKIP AUTO-FORWARD LOGIC (START)
    // If skipping is enabled and this item starts from an auto-forward scene,
    // we skip it entirely because the PREVIOUS item would have already jumped over it.
    if (skipAutoForward && startScene.isAutoForward) {
      return;
    }

    // Find the actual hotspot to get camera angles
    let hotspot = null;
    if (item.linkId) {
      hotspot = startScene.hotspots.find(h => h.linkId === item.linkId);
    } else {
      // Fallback by target name matching if linkId missing (legacy)
      hotspot = startScene.hotspots.find(h => h.target === item.targetScene);
    }

    // Determine look angles for the transition
    let transYaw = 0, transPitch = 0;
    if (hotspot) {
      transYaw = hotspot.yaw;
      transPitch = hotspot.pitch;
      if (hotspot.viewFrame) {
        transYaw = hotspot.viewFrame.yaw;
        transPitch = hotspot.viewFrame.pitch;
      }
    }

    // Logic to merge with previous step if continuous
    const lastStep = path[path.length - 1];
    let currentStep;

    // We can merge if:
    // 1. We have a previous step
    // 2. The previous step arrived at THIS scene (startSceneIdx)
    // 3. The previous step doesn't already have an outgoing transition
    if (lastStep && lastStep.idx === startSceneIdx && !lastStep.transitionTarget) {
      currentStep = lastStep;
    } else {
      // Discontinuity or first step. Add new step.
      currentStep = {
        idx: startSceneIdx,
        transitionTarget: null,
        arrivalView: { yaw: 0, pitch: 0 } // Default arrival for jump
      };
      path.push(currentStep);
    }

    // Set Transition Target for this step
    currentStep.transitionTarget = {
      yaw: transYaw,
      pitch: transPitch,
      targetName: item.targetScene,
      timelineItemId: item.id // TRACKING: Link this step back to the visual pipeline
    };

    // END SCENE (Arrival)
    // Calculate the destination scene logic, including auto-forward skipping
    let targetIdx = scenes.findIndex(s => s.name === item.targetScene);
    let arrivalYaw = 0;
    let arrivalPitch = 0;

    if (targetIdx !== -1) {
      // Get initial arrival view from link target info
      if (hotspot) {
        if (hotspot.targetYaw !== undefined) {
          arrivalYaw = hotspot.targetYaw;
          arrivalPitch = hotspot.targetPitch;
        }
      }

      // SKIP AUTO-FORWARD LOGIC (END)
      if (skipAutoForward) {
        let chainSafeCounter = 0;
        let visitedInChain = new Set();
        visitedInChain.add(targetIdx);

        while (chainSafeCounter < 10) {
          const nextScene = scenes[targetIdx];
          if (!nextScene || !nextScene.isAutoForward) break;

          // Find the next logical link to jump to
          const jumpLink = nextScene.hotspots.find(h => {
            const tIdx = scenes.findIndex(s => s.name === h.target);
            return tIdx !== -1 && !visitedInChain.has(tIdx);
          });

          if (jumpLink) {
            const jumpIdx = scenes.findIndex(s => s.name === jumpLink.target);
            targetIdx = jumpIdx;
            visitedInChain.add(targetIdx);
            // Reset arrival view for jump (as we lose the direct link context)
            arrivalYaw = 0;
            arrivalPitch = 0;
          } else {
            break; // Dead end
          }
          chainSafeCounter++;
        }
      }

      // Push the arrival step
      const nextStep = {
        idx: targetIdx,
        transitionTarget: null, // Will be filled by next timeline item if continuous
        arrivalView: { yaw: arrivalYaw, pitch: arrivalPitch }
      };
      path.push(nextStep);
    }
  });

  // --- FINAL CLEANUP ---
  let finalPath = path;
  if (skipAutoForward) {
    finalPath = finalPath.filter(step => {
      const scene = scenes[step.idx];
      return scene && !scene.isAutoForward;
    });
  }

  // Deduplication: Remove adjacent identical scenes
  finalPath = finalPath.filter((step, i) => i === 0 || step.idx !== finalPath[i - 1].idx);

  return finalPath;
}


/**
 * Main entry point for starting an automated teaser recording.
 * Now modularized into smaller sub-steps.
 */
export async function startAutoTeaser(style = "fast", includeLogo = true, format = "webm", skipAutoForward = false) {
  if (isTeasing) return;

  const scenes = store.state.scenes;
  if (scenes.length === 0) {
    console.error("No scenes to film.");
    return;
  }

  // CINEMATIC MODE: Run actual simulation and record it
  if (style === "cinematic") {
    if (format === 'mp4') {
      const overlay = document.getElementById("teaser-overlay");
      if (overlay) overlay.style.display = "flex";
      isTeasing = true;
      store.setIsTeasing(true);
      try {
        const blob = await generateServerTeaser((pct, msg) => updateProgressBar(pct, msg, true, "Server Generating..."));
        DownloadSystem.saveBlob(blob, `Cinematic_${store.state.tourName}.mp4`);
      } catch (e) {
        notify("Server Generation Failed", "error");
      } finally {
        isTeasing = false;
        store.setIsTeasing(false);
        if (overlay) overlay.style.display = "none";
        updateProgressBar(0, "", false);
      }
    } else {
      await startCinematicTeaser(includeLogo, format, skipAutoForward);
    }
    return;
  }

  try {
    // 1. Initial Setup
    initGhost();
    isTeasing = true;
    store.setIsTeasing(true); // Flag store for high-quality single-phase loading
    const overlay = document.getElementById("teaser-overlay");
    const label = document.getElementById("teaser-text");
    if (overlay) overlay.style.display = "flex";

    const pathSteps = getWalkPath(skipAutoForward);

    // 1b. Preload all involved assets to ensure they are in memory
    if (label) label.innerText = "Preloading Scenes...";

    updateProgressBar(0, "Preloading Scenes...", true, "Buffering Memory");

    // 4. Override Ghost Loop with Animation Rendering
    cancelAnimationFrame(streamLoopId);
    updateAnimationLoop(style, includeLogo, logoState, snapState);

    // 5. Preparation & Record
    await prepareFirstScene(pathSteps[0], label, style, config);
    activeRecorder = recorder; // Store for pause/resume access
    recorder.start();

    // 6. Execute Path
    for (let i = 0; i < pathSteps.length; i++) {
      const step = pathSteps[i];
      await recordShot(i, pathSteps, style, config, label, snapState.ctx);
      if (i < pathSteps.length - 1) {
        await transitionToNextShot(i, pathSteps, style, config, snapState.canvas);
      }
    }

    // 7. Finalize
    activeRecorder = null;
    recorder.stop();
    recorder.onstop = () => finalizeTeaser(recordedChunks, format, config.baseName, overlay);
  } catch (err) {
    console.error("Teaser Production Failed:", err);
    isTeasing = false;
    store.setIsTeasing(false);
    const overlay = document.getElementById("teaser-overlay");
    if (overlay) overlay.style.display = "none";
    notify("Teaser Production Failed", "error");
    updateProgressBar(0, "Error", false);
  }
}

/**
 * CINEMATIC MODE: Record the actual simulation as it runs
 * This captures EXACTLY what the user sees during simulation mode
 */
async function startCinematicTeaser(includeLogo = true, format = "webm", skipAutoForward = false) {
  if (isTeasing) return;

  try {
    // 1. Initial Setup
    initGhost();
    isTeasing = true;
    store.setIsTeasing(true); // Flag store for high-quality single-phase loading
    const overlay = document.getElementById("teaser-overlay");
    const label = document.getElementById("teaser-text");
    if (overlay) overlay.style.display = "flex";
    if (label) label.innerText = "Recording Simulation...";

    // 1b. Preload ALL scenes for the entire project in cinematic mode
    if (label) label.innerText = "Preloading All Scenes...";

    updateProgressBar(0, "Preloading All Scenes...", true, "Buffering Memory");
    const allSteps = store.state.scenes.map((_, i) => ({ idx: i }));
    lastFrameTime = performance.now();

    if (!window.HEADLESS_READY) recorder.start();
    Debug.info('Teaser', 'Cinematic recording started - running simulation');

    // 6. Start the ACTUAL simulation
    // This will run the auto-pilot which handles all camera movements, waypoints, timing, etc.
    startAutoPilot(skipAutoForward);

    // 7. Wait for simulation to complete
    // Poll until isAutoPilotActive() returns false
    await new Promise((resolve) => {
      const checkComplete = () => {
        if (!isAutoPilotActive()) {
          Debug.info('Teaser', 'Simulation complete - stopping recording');
          resolve();
        } else {
          // Update progress based on visited scenes (rough estimate)
          if (label) label.innerText = "Recording Simulation...";
          setTimeout(checkComplete, 500);
        }
      };
      // Start checking after a brief delay to let simulation begin
      setTimeout(checkComplete, 1000);
    });

    // 8. Brief hold at the end
    await new Promise(r => setTimeout(r, 500));

    // 9. Stop recording and finalize
    if (!window.HEADLESS_READY) {
      recorder.stop();
      recorder.onstop = () => finalizeTeaser(recordedChunks, format, baseName, overlay);
    } else {
      isTeasing = false;
      store.setIsTeasing(false);
    }

  } catch (err) {
    console.error("Cinematic Teaser Failed:", err);
    isTeasing = false;
    store.setIsTeasing(false);

    // Make sure simulation is stopped if it was running
    if (isAutoPilotActive()) {
      stopAutoPilot(false);
    }

    const overlay = document.getElementById("teaser-overlay");
    if (overlay) overlay.style.display = "none";
    notify("Cinematic Teaser Failed", "error");
    updateProgressBar(0, "Error", false);
  }
}


/**
 * Ensures all scene images are loaded into browser memory before recording begins.
 * This prevents the recording from starting with blurred or missing textures.
 */
async function preloadPathAssets(pathSteps) {
  const imagesToLoad = new Set();
  pathSteps.forEach(step => {
    const scene = store.state.scenes[step.idx];
    if (scene && scene.file) imagesToLoad.add(scene.file);
  });

  const urlsToRevoke = [];
  const promises = Array.from(imagesToLoad).map(blob => {
    return new Promise((resolve, reject) => {
      const img = new Image();
      const url = URL.createObjectURL(blob);
      urlsToRevoke.push(url);

      img.onload = () => {
        Debug.debug('Teaser', `Asset preloaded into memory: ${blob.size} bytes`);
        resolve();
      };
      img.onerror = (err) => {
        const msg = `Failed to preload asset into memory`;
        Debug.error('Teaser', msg, err);
        // We reject here so Promise.all fails fast if critical assets are missing
        // Alternatively, we could resolve to allow partial success, but for teasers, missing images are bad.
        // Let's WARN but resolve, consistently with "show must go on" philosophy, but now we LOG it properly.
        notify("Asset preload failed - quality may be reduced", "warning");
        resolve();
      };
      img.src = url;
    });
  });

  await Promise.all(promises);

  // Briefly wait for GPU upload
  await new Promise(r => setTimeout(r, 500));

  // Revoke URLs to free memory
  urlsToRevoke.forEach(url => URL.revokeObjectURL(url));
}

// --- MODULAR SUB-FUNCTIONS ---

function getTeaserConfig(style, timestamp) {
  const tourName = store.state.tourName || "Virtual_Tour";
  const safeName = tourName.replace(/[^a-z0-9]/gi, "_").toLowerCase();
  const baseName = `Teaser_RMX_${safeName}_v${VERSION}`;

  if (style === "punchy") {
    return {
      ...TEASER_STYLE_PUNCHY,
      baseName: baseName
    };
  }

  if (style === "cinematic") {
    return {
      ...TEASER_STYLE_DISSOLVE, // Cinematic uses smooth dissolve
      baseName: baseName + "_Cinematic"
    };
  }
  return {
    ...TEASER_STYLE_DISSOLVE,
    baseName: baseName
  };
}

function setupMediaRecorder(stream) {
  let options = {
    mimeType: "video/webm",
    videoBitsPerSecond: 10000000 // 10 Mbps for high-quality 1080p
  };
  if (MediaRecorder.isTypeSupported("video/webm;codecs=vp9")) {
    options.mimeType = "video/webm;codecs=vp9";
  }

  try {
    const recorder = new MediaRecorder(stream, options);
    recordedChunks = [];
    recorder.ondataavailable = (e) => {
      if (e.data.size > 0) recordedChunks.push(e.data);
    };
    return recorder;
  } catch (e) {
    console.error("MediaRecorder Error:", e);
    return null;
  }
}

async function loadLogo() {
  const logoImg = new Image();
  logoImg.src = "images/logo.png";
  return new Promise(resolve => {
    logoImg.onload = () => resolve({ img: logoImg, loaded: true });
    logoImg.onerror = () => resolve({ img: null, loaded: false });
  });
}

function createSnapshotState() {
  const canvas = document.createElement('canvas');
  canvas.width = TEASER_CANVAS_WIDTH;
  canvas.height = TEASER_CANVAS_HEIGHT;
  return {
    canvas,
    ctx: canvas.getContext('2d', { alpha: false })
  };
}

function updateAnimationLoop(style, includeLogo, logoState, snapState) {
  const draw = () => {
    const sourceCanvas = document.querySelector(".pnlm-render-container canvas");

    // 1. Draw current viewer frame (or black if not ready)
    if (ghostCtx) {
      if (sourceCanvas && sourceCanvas.width > 0) {
        renderBaseFrame(sourceCanvas);
      } else {
        // Fallback: Clear to black if viewer canvas is missing during recreation
        ghostCtx.fillStyle = "#000";
        ghostCtx.fillRect(0, 0, ghostCanvas.width, ghostCanvas.height);
      }

      // 2. Draw snapshot overlay if active (hides loading/pixelation)
      if (fadeOpacity > 0.01) {
        renderSnapshotOverlay(snapState.canvas);
      }

      // 3. Draw Watermark last (always on top)
      if (logoState.loaded && includeLogo) {
        renderWatermark(logoState.img);
      }
    }

    // FPS TRACKING
    const now = performance.now();
    const delta = now - lastFrameTime;
    lastFrameTime = now;
    if (delta > 0) {
      const fps = 1000 / delta;
      fpsBuffer.push(fps);
      if (fpsBuffer.length > 100) fpsBuffer.shift();
    }
    frameCount++;

    streamLoopId = requestAnimationFrame(draw);
  };
  draw();
}

function renderBaseFrame(sourceCanvas) {
  const sw = sourceCanvas.width, sh = sourceCanvas.height;
  const dw = ghostCanvas.width, dh = ghostCanvas.height;
  const sourceAspect = sw / sh;
  const destAspect = dw / dh;
  let rw, rh, rx, ry;

  if (sourceAspect > destAspect) {
    rh = dh; rw = dh * sourceAspect;
    rx = (dw - rw) / 2; ry = 0;
  } else {
    rw = dw; rh = dw / sourceAspect;
    rx = 0; ry = (dh - rh) / 2;
  }

  ghostCtx.fillStyle = "#000";
  ghostCtx.fillRect(0, 0, dw, dh);
  ghostCtx.drawImage(sourceCanvas, rx, ry, rw, rh);
}

function renderWatermark(logoImg) {
  // Constants aligned with ViewerUI.js
  // ViewerUI: max-w-[120px], p-[2px], rounded-xl (12px), bottom-6 (24px), right-6 (24px)
  // Teaser Canvas is 1920x1080. We need to scale visual proportions relative to 1080p.
  // ViewerUI is roughly desktop scale, let's assume 120px width is good for 1920px too or slightly larger.
  // Let's use 150px width for 1080p to be legible.

  const logoWidth = 150; // Scaled up slightly for 1080p video from 120px viewer
  const padding = 4; // Scaled up from 2px
  const borderRadius = 16; // Scaled up from 12px
  const margin = 32; // Scaled up from 24px (bottom-6/right-6)

  const imgAspect = logoImg.height / logoImg.width;
  const logoHeight = logoWidth * imgAspect;

  // Box dimensions
  const boxWidth = logoWidth + (padding * 2);
  const boxHeight = logoHeight + (padding * 2);

  // Box Position (Bottom Right)
  const boxX = ghostCanvas.width - boxWidth - margin;
  const boxY = ghostCanvas.height - boxHeight - margin;

  ghostCtx.save();

  // 1. Draw Shadow (Subtle)
  ghostCtx.shadowColor = "rgba(0, 0, 0, 0.15)";
  ghostCtx.shadowBlur = 10;
  ghostCtx.shadowOffsetX = 0;
  ghostCtx.shadowOffsetY = 4;

  // 2. Draw White Background Box
  ghostCtx.fillStyle = "#ffffff";
  ghostCtx.beginPath();
  if (ghostCtx.roundRect) {
    ghostCtx.roundRect(boxX, boxY, boxWidth, boxHeight, borderRadius);
  } else {
    // Fallback for older browsers
    ghostCtx.rect(boxX, boxY, boxWidth, boxHeight);
  }
  ghostCtx.fill();

  // Reset shadow for image
  ghostCtx.shadowColor = "transparent";
  ghostCtx.shadowBlur = 0;
  ghostCtx.shadowOffsetX = 0;
  ghostCtx.shadowOffsetY = 0;

  // 3. Clip for Image (optional, but good for safety)
  // We draw the image *inside* the padding
  const imgX = boxX + padding;
  const imgY = boxY + padding;
  const imgW = logoWidth;
  const imgH = logoHeight;

  ghostCtx.drawImage(logoImg, imgX, imgY, imgW, imgH);

  // 4. Draw subtle border (border-black/5 equivalent)
  ghostCtx.strokeStyle = "rgba(0, 0, 0, 0.05)";
  ghostCtx.lineWidth = 1;
  ghostCtx.stroke();

  ghostCtx.restore();
}

function renderSnapshotOverlay(snapCanvas) {
  ghostCtx.save();
  ghostCtx.globalAlpha = fadeOpacity;
  ghostCtx.drawImage(snapCanvas, 0, 0);
  ghostCtx.restore();
}

async function prepareFirstScene(step, label, style, config) {
  // For punchy: load at arrivalView; for dissolve: load at transitionTarget offset
  // For cinematic: load at startYaw/startPitch (beginning of the waypoint path)
  let initialYaw = 0;
  let initialPitch = 0;

  if (style === "punchy") {
    // Punchy uses arrivalView (saved camera position)
    if (step.arrivalView) {
      initialYaw = step.arrivalView.yaw || 0;
      initialPitch = step.arrivalView.pitch || 0;
    }
  } else if (style === "cinematic") {
    // Cinematic uses startYaw/startPitch (beginning of waypoint path)
    if (step.transitionTarget) {
      initialYaw = step.transitionTarget.startYaw ?? step.arrivalView?.yaw ?? 0;
      initialPitch = step.transitionTarget.startPitch ?? step.arrivalView?.pitch ?? 0;
    } else if (step.arrivalView) {
      initialYaw = step.arrivalView.yaw || 0;
      initialPitch = step.arrivalView.pitch || 0;
    }
  } else {
    // Dissolve uses transitionTarget with offset
    if (step.transitionTarget) {
      initialYaw = step.transitionTarget.yaw - config.cameraPanOffset;
      initialPitch = step.transitionTarget.pitch || 0;
    }
  }

  Debug.debug('Teaser', 'prepareFirstScene:', {
    style,
    stepArrivalView: step.arrivalView,
    computedYaw: initialYaw,
    computedPitch: initialPitch
  });

  const targetScene = store.state.scenes[step.idx];
  store.setActiveScene(step.idx, initialYaw, initialPitch);
  if (label) label.innerText = `Preparing: ${targetScene.name}...`;

  updateProgressBar(0, "Preparing...", true, "Creating property teaser");

  await new Promise(r => setTimeout(r, SCENE_STABILIZATION_DELAY));
  await waitForViewerReady(targetScene.id);

  const viewer = window.pannellumViewer;

  // Ensure orientation is correct after load - use 0 duration to prevent animation
  if (viewer) {
    viewer.setYaw(initialYaw, 0);
    viewer.setPitch(initialPitch, 0);
    Debug.debug('Teaser', 'Viewer orientation set:', {
      setYaw: initialYaw,
      setPitch: initialPitch,
      actualYaw: viewer.getYaw(),
      actualPitch: viewer.getPitch()
    });
  }

  await new Promise(r => setTimeout(r, SCENE_STABILIZATION_DELAY));
}

async function recordShot(i, pathSteps, style, config, label, snapCtx) {
  const step = pathSteps[i];
  const scene = store.state.scenes[step.idx];

  // SYNC VISUAL PIPELINE: Update highlight if this step belongs to a timeline item
  if (step.transitionTarget && step.transitionTarget.timelineItemId) {
    store.setActiveTimelineStep(step.transitionTarget.timelineItemId);
  } else if (i > 0 && pathSteps[i - 1].transitionTarget && pathSteps[i - 1].transitionTarget.timelineItemId) {
    // If we are on the ARRIVAL step of a transition, we might still want to highlight the source step
    // or maybe the NEXT step. For now, matching the source step is often what users expect to see
    // while that scene is being filmed.
  }


  const pct = ((i / pathSteps.length) * 100);
  updateProgressBar(pct, `Recording Shot ${i + 1}/${pathSteps.length}: ${scene.name}`);
  if (label) label.innerText = `Shot ${i + 1}: ${scene.name}`;

  const viewer = window.pannellumViewer;
  if (!viewer) {
    console.error("Viewer lost during recordShot");
    return;
  }

  if (style === "punchy") {
    // PUNCHY: Static hold at arrivalView - NO animation, NO panning
    // Camera is already positioned correctly from prepareFirstScene/transitionToNextShot
    // Just wait for the clip duration
    await new Promise(r => setTimeout(r, config.clipDuration));
  } else if (style === "cinematic") {
    // CINEMATIC: Animate through ALL waypoints like the simulation arrow
    // This follows the exact path the user created with multi-point links

    if (!step.transitionTarget) {
      // No transition target means we're at the end - just hold
      await new Promise(r => setTimeout(r, config.clipDuration / 2));
      return;
    }

    const waypoints = step.transitionTarget.waypoints || [];
    const startYaw = step.transitionTarget.startYaw ?? step.arrivalView?.yaw ?? viewer.getYaw();
    const startPitch = step.transitionTarget.startPitch ?? step.arrivalView?.pitch ?? viewer.getPitch();
    const endYaw = step.transitionTarget.yaw;
    const endPitch = step.transitionTarget.pitch;

    // Build full path: Start -> Waypoints -> End
    const path = [{ yaw: startYaw, pitch: startPitch }];
    waypoints.forEach(wp => {
      // Waypoints may have yaw/pitch or camYaw/camPitch depending on format
      const wpYaw = wp.yaw ?? wp.camYaw ?? 0;
      const wpPitch = wp.pitch ?? wp.camPitch ?? 0;
      path.push({ yaw: wpYaw, pitch: wpPitch });
    });
    path.push({ yaw: endYaw, pitch: endPitch });

    // Calculate total distance for timing
    let totalDistance = 0;
    const segments = [];

    for (let j = 0; j < path.length - 1; j++) {
      const p1 = path[j];
      const p2 = path[j + 1];

      let yawDiff = p2.yaw - p1.yaw;
      while (yawDiff > 180) yawDiff -= 360;
      while (yawDiff < -180) yawDiff += 360;

      const pitchDiff = p2.pitch - p1.pitch;
      const dist = Math.sqrt(yawDiff * yawDiff + pitchDiff * pitchDiff);

      segments.push({ dist, yawDiff, pitchDiff, p1, p2 });
      totalDistance += dist;
    }

    Debug.debug('Teaser', `Cinematic path for scene ${step.idx}:`, {
      pathLength: path.length,
      totalDistance: totalDistance.toFixed(1),
      waypoints: waypoints.length
    });

    // Use the EXACT SAME velocity formula as simulation mode (NavigationSystem.js)
    // Formula: duration = (totalDistance / PANNING_VELOCITY) * 1000ms
    // Clamped between PANNING_MIN_DURATION and PANNING_MAX_DURATION
    const rawDuration = (totalDistance / PANNING_VELOCITY) * 1000;
    const dynamicDuration = Math.min(Math.max(rawDuration, PANNING_MIN_DURATION), PANNING_MAX_DURATION);

    Debug.debug('Teaser', `Cinematic animation timing:`, {
      totalDistance: totalDistance.toFixed(1),
      velocity: PANNING_VELOCITY,
      rawDuration: Math.round(rawDuration),
      clampedDuration: Math.round(dynamicDuration)
    });

    // Animate through the path
    const startTime = Date.now();

    while (Date.now() - startTime < dynamicDuration) {
      const v = window.pannellumViewer;
      if (!v) break;

      const elapsed = Date.now() - startTime;
      const progress = Math.min(elapsed / dynamicDuration, 1.0);
      const targetDist = progress * totalDistance;

      // Find current position on path
      let currentYaw = startYaw;
      let currentPitch = startPitch;

      if (totalDistance > 0 && segments.length > 0) {
        let covered = 0;

        for (const seg of segments) {
          if (targetDist <= covered + seg.dist) {
            const segmentProgress = (seg.dist > 0) ? (targetDist - covered) / seg.dist : 0;
            currentYaw = seg.p1.yaw + seg.yawDiff * segmentProgress;
            currentPitch = seg.p1.pitch + seg.pitchDiff * segmentProgress;
            break;
          }
          covered += seg.dist;
          currentYaw = seg.p2.yaw;
          currentPitch = seg.p2.pitch;
        }
      }

      v.setYaw(currentYaw);
      v.setPitch(currentPitch);

      await new Promise(r => requestAnimationFrame(r));
    }

    // Ensure we end exactly at the target
    if (window.pannellumViewer) {
      window.pannellumViewer.setYaw(endYaw);
      window.pannellumViewer.setPitch(endPitch);
    }

  } else {
    // DISSOLVE: Animate pan from (transitionTarget - offset) to transitionTarget
    const targetYaw = step.transitionTarget ? step.transitionTarget.yaw : viewer.getYaw();
    const targetPitch = step.transitionTarget ? step.transitionTarget.pitch : 0;
    const startYaw = targetYaw - config.cameraPanOffset;

    const startTime = Date.now();
    while (Date.now() - startTime < config.clipDuration) {
      const v = window.pannellumViewer;
      if (v) {
        const p = (Date.now() - startTime) / config.clipDuration;
        v.setYaw(startYaw + ((targetYaw - startYaw) * p));
        v.setPitch(targetPitch);
      }
      await new Promise(r => requestAnimationFrame(r));
    }

    if (window.pannellumViewer) {
      window.pannellumViewer.setYaw(targetYaw);
      window.pannellumViewer.setPitch(targetPitch);
    }
  }
}

async function transitionToNextShot(i, pathSteps, style, config, snapCanvas) {
  // 1. Snapshot the current frame (for dissolve overlay)
  const snapCtx = snapCanvas.getContext('2d');
  // Draw the current state of ghostCanvas (which holds the previous scene)
  snapCtx.drawImage(ghostCanvas, 0, 0);
  fadeOpacity = 1; // Show snapshot overlay - this hides all loading activity

  // CRITICAL: Force one frame render so the snapshot is DEFINITELY on the ghostCanvas
  // before we pause. This ensures the "last frame" timestamped before pause is clean.
  await new Promise(r => requestAnimationFrame(r));
  await new Promise(r => requestAnimationFrame(r));

  // 2. PAUSE RECORDING during the dangerous load/swap window
  // The snapshot overlay is now showing the last clean frame from the previous scene.
  // We pause recording so absolutely no transitional/loading frames are captured.
  if (activeRecorder && activeRecorder.state === 'recording') {
    activeRecorder.pause();
    Debug.info('Teaser', 'Recorder PAUSED for scene transition');
  }

  // 3. Determine orientation based on style
  const nextStep = pathSteps[i + 1];
  const nextStepScene = store.state.scenes[nextStep.idx];
  let nextYaw = 0;
  let nextPitch = 0;

  if (style === "punchy") {
    // PUNCHY: Use arrivalView (saved camera position from link)
    if (nextStep.arrivalView) {
      nextYaw = nextStep.arrivalView.yaw || 0;
      nextPitch = nextStep.arrivalView.pitch || 0;
    }
  } else if (style === "cinematic") {
    // CINEMATIC: Use startYaw/startPitch (beginning of waypoint path for next scene)
    if (nextStep.transitionTarget) {
      nextYaw = nextStep.transitionTarget.startYaw ?? nextStep.arrivalView?.yaw ?? 0;
      nextPitch = nextStep.transitionTarget.startPitch ?? nextStep.arrivalView?.pitch ?? 0;
    } else if (nextStep.arrivalView) {
      nextYaw = nextStep.arrivalView.yaw || 0;
      nextPitch = nextStep.arrivalView.pitch || 0;
    }
  } else {
    // DISSOLVE: Use transitionTarget with offset (for pan animation)
    if (nextStep.transitionTarget) {
      nextYaw = nextStep.transitionTarget.yaw - config.cameraPanOffset;
      nextPitch = nextStep.transitionTarget.pitch || 0;
    }
  }

  Debug.debug('Teaser', 'transitionToNextShot:', {
    sceneIdx: nextStep.idx,
    style,
    nextStepArrivalView: nextStep.arrivalView,
    computedYaw: nextYaw,
    computedPitch: nextPitch
  });

  // 4. Switch scene with correct orientation from the start
  store.setActiveScene(nextStep.idx, nextYaw, nextPitch);

  // 5. Wait for viewer to be ready - must match the scene we just requested
  await waitForViewerReady(nextStepScene.id);
  const viewer = window.pannellumViewer;

  // 6. Ensure orientation is set (backup) - use 0 duration to prevent animation
  if (viewer) {
    viewer.setYaw(nextYaw, 0);
    viewer.setPitch(nextPitch, 0);
    Debug.debug('Teaser', `Scene ${nextStep.idx} viewer orientation:`, {
      setYaw: nextYaw,
      setPitch: nextPitch,
      actualYaw: viewer.getYaw(),
      actualPitch: viewer.getPitch()
    });
  }

  // 7. Stabilization delay - scene is now fully loaded and rendered
  await new Promise(r => setTimeout(r, SCENE_STABILIZATION_DELAY));

  // 8. RESUME RECORDING now that the new scene is confirmed ready
  // From this point, every frame captured will be clean.
  if (activeRecorder && activeRecorder.state === 'paused') {
    activeRecorder.resume();
    Debug.info('Teaser', 'Recorder RESUMED after scene ready');

    // CRITICAL: Wait for recorder to actually start capturing frames
    // MediaRecorder can take a moment to "warm up" after resume.
    // We add a longer buffer here to ensure the recording has definitely resumed
    // before we start changing the pixels (dissolving).
    // The viewer sees a static frame (snapshot) during this buffer, which is fine.
    await new Promise(r => setTimeout(r, 200));
    await new Promise(r => requestAnimationFrame(r));
    await new Promise(r => requestAnimationFrame(r));
  }

  // 9. Reveal with cross-dissolve (all styles get a smooth transition now)
  // Punchy uses 500ms dissolve for a snappy but clearly visible transition
  // Dissolve/Cinematic use the configured longer transition (1000ms)
  const dissolveDuration = (style === "punchy") ? 500 : config.transitionDuration;
  Debug.info('Teaser', `Starting cross-dissolve: ${dissolveDuration}ms, fadeOpacity=${fadeOpacity}, recorderState=${activeRecorder?.state}`);

  // Extra hold to guarantee continuity
  await new Promise(r => setTimeout(r, 100));

  await doCrossDissolve(dissolveDuration);
  Debug.info('Teaser', `Cross-dissolve complete, fadeOpacity now ${fadeOpacity}`);
}


/**
 * Robust helper to wait for the global pannellumViewer to be initialized and loaded.
 * Handles recreations during scene transitions.
 * 
 * @param {string} expectedSceneId - The ID of the scene we are waiting for
 */
async function waitForViewerReady(expectedSceneId = null) {
  const timeout = 12000; // Increased timeout for 4K loads
  const start = Date.now();

  while (Date.now() - start < timeout) {
    const v = window.pannellumViewer;

    // Check if viewer exists and is loaded
    if (v && typeof v.isLoaded === 'function' && v.isLoaded()) {

      // If we're waiting for a specific scene, ensure it's the one currently active in window.pannellumViewer
      // This prevents returning true while the OLD viewer instance is still active during a swap.
      if (expectedSceneId && v._sceneId !== expectedSceneId) {
        await new Promise(r => setTimeout(r, VIEWER_LOAD_CHECK_INTERVAL));
        continue;
      }

      // ADDITIONAL CHECK: If we are using progressive loading (scenes: preview, master)
      // we MUST wait until the 'master' scene is actually the active one.
      const currentScene = v.getScene();
      const config = v.getConfig();

      // If the viewer has multiple scenes (progressive mode), wait for 'master'
      if (config.scenes && config.scenes.master && config.scenes.preview) {
        if (currentScene === 'master') {
          // Final step: Wait for actual GPU render to complete
          await waitForCanvasRendered();
          return true;
        }
        // If still on preview, continue waiting for the swap
      } else {
        // Standard single-scene mode - wait for GPU render
        await waitForCanvasRendered();
        return true;
      }
    }
    await new Promise(r => setTimeout(r, VIEWER_LOAD_CHECK_INTERVAL));
  }
  throw new Error(`Viewer reach/load timeout for scene: ${expectedSceneId || 'unknown'}`);
}

/**
 * Waits until the Pannellum canvas has actually rendered non-black content.
 * This guarantees the GPU has finished uploading and painting the texture.
 * Protects against the edge case where isLoaded() is true but the first frame hasn't rendered yet.
 */
async function waitForCanvasRendered() {
  const maxWait = 3000; // 3 second max wait for GPU render
  const start = Date.now();

  while (Date.now() - start < maxWait) {
    const canvas = document.querySelector('.pnlm-render-container canvas');
    if (canvas && canvas.width > 0 && canvas.height > 0) {
      try {
        // Sample a few pixels from the center of the canvas
        const ctx = canvas.getContext('webgl') || canvas.getContext('webgl2');
        if (ctx) {
          const pixels = new Uint8Array(4);
          const centerX = Math.floor(canvas.width / 2);
          const centerY = Math.floor(canvas.height / 2);
          ctx.readPixels(centerX, centerY, 1, 1, ctx.RGBA, ctx.UNSIGNED_BYTE, pixels);

          // Check if we have any non-black content (R, G, or B > 0)
          if (pixels[0] > 5 || pixels[1] > 5 || pixels[2] > 5) {
            Debug.debug('Teaser', 'Canvas confirmed rendered with content');
            // Give GPU one more frame to stabilize
            await new Promise(r => requestAnimationFrame(r));
            await new Promise(r => requestAnimationFrame(r));
            return;
          }
        }
      } catch (e) {
        // WebGL context access failed, fall back to time-based wait
        Debug.warn('Teaser', 'Canvas pixel check failed, using fallback delay');
        await new Promise(r => setTimeout(r, 500));
        return;
      }
    }
    await new Promise(r => requestAnimationFrame(r));
  }

  // Timeout fallback - proceed anyway but log warning
  Debug.warn('Teaser', 'Canvas render check timed out, proceeding with recording');
}


async function doCrossDissolve(duration) {
  const start = Date.now();
  while (Date.now() - start < duration) {
    fadeOpacity = 1 - ((Date.now() - start) / duration);
    await new Promise(r => requestAnimationFrame(r));
  }
  fadeOpacity = 0;
}

async function finalizeTeaser(recordedChunks, format, baseName, overlay) {
  cancelAnimationFrame(streamLoopId);
  fadeOpacity = 0;

  if (overlay) overlay.style.display = "none";

  if (recordedChunks.length === 0) {
    isTeasing = false;
    store.setIsTeasing(false);
    return;
  }

  const webmBlob = new Blob(recordedChunks, { type: "video/webm" });
  const durationMs = Date.now() - recordingStartTime;

  // Calculate average FPS
  const avgFps = fpsBuffer.length > 0
    ? fpsBuffer.reduce((a, b) => a + b, 0) / fpsBuffer.length
    : 0;

  Debug.info('Teaser', 'RECORDING_COMPLETE', {
    durationMs,
    frameCount,
    avgFps: Math.round(avgFps * 100) / 100,
    sizeBytes: webmBlob.size,
    format,
    baseName
  });

  if (format === "webm") {
    DownloadSystem.saveBlob(webmBlob, `${baseName}.webm`);

    updateProgressBar(100, "Teaser Complete!", true);
    isTeasing = false;
    store.setIsTeasing(false);
  } else if (format === "mp4") {
    try {
      await VideoEncoder.transcodeWebMToMP4(webmBlob, baseName, (pct) => {

        updateProgressBar(pct, "Converting WebM to MP4...", true, "AI Encoder");
      });

      updateProgressBar(100, "Teaser Complete!", true);
    } catch (err) {
      console.error("MP4 Finalization Failed", err);
      // Fallback: save webm anyway
      DownloadSystem.saveBlob(webmBlob, `${baseName}.webm`);

      updateProgressBar(0, "MP4 Conversion Failed - WebM Saved", true, "Error");
    } finally {
      isTeasing = false;
      store.setIsTeasing(false);
    }
  } else {
    isTeasing = false;
    store.setIsTeasing(false);
  }
}

window.startCinematicTeaser = startCinematicTeaser;

// --- SERVER SIDE GENERATION ---

/**
 * Trigger server-side teaser generation
 * @param {Function} onProgress - Callback (pct, msg)
 */
export async function generateServerTeaser(onProgress) {
  if (onProgress) onProgress(0, "Preparing Project Data...");

  // 1. Prepare Project Data
  const state = store.state;
  // Dynamic import version if needed, or assume global? 
  // imports should be top level usually, but here fine.
  let VERSION = "1.0.0";
  try {
    const v = await import("../version.js");
    VERSION = v.VERSION;
  } catch (e) { }

  const projectData = {
    version: VERSION,
    projectName: state.tourName,
    scenes: state.scenes.map(scene => ({
      id: scene.id,
      name: scene.name,
      label: scene.label,
      category: scene.category,
      floor: scene.floor,
      isAutoForward: scene.isAutoForward,
      hotspots: scene.hotspots.map(h => ({
        pitch: h.pitch, yaw: h.yaw, target: h.target,
        targetYaw: h.targetYaw, targetPitch: h.targetPitch, targetHfov: h.targetHfov,
        viewFrame: h.viewFrame, returnViewFrame: h.returnViewFrame, isReturnLink: h.isReturnLink,
        waypoints: h.waypoints
      }))
    })),
    timeline: state.timeline
  };

  // 2. Prepare FormData
  const formData = new FormData();
  formData.append('project_data', JSON.stringify(projectData));
  formData.append('width', '1920');
  formData.append('height', '1080');

  // Append Images
  let addedCount = 0;
  state.scenes.forEach(scene => {
    if (scene.file) {
      formData.append('files', scene.file, scene.name);
      addedCount++;
    }
  });

  if (onProgress) onProgress(10, `Uploading ${addedCount} scenes...`);

  try {
    const response = await fetch(`${BACKEND_URL}/generate-teaser`, {
      method: "POST",
      body: formData
    });

    if (!response.ok) {
      throw new Error(`Server Error: ${response.status}`);
    }

    if (onProgress) onProgress(50, "Rendering on Server...");

    const videoBlob = await response.blob();

    if (onProgress) onProgress(100, "Done!");
    return videoBlob;

  } catch (err) {
    console.error("Server Teaser Failed:", err);
    throw err;
  }
}
