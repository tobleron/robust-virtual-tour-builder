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
import { CacheSystem } from "./CacheSystem.js";
import { VideoEncoder } from "./VideoEncoder.js";
import { Debug } from "../utils/Debug.js";
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
} from "../constants.js";
import { VERSION } from "../version.js";

let isTeasing = false;
let ghostCanvas = null;
let ghostCtx = null;
let mediaRecorder = null;
let recordedChunks = [];
let streamLoopId = null;

let fadeOpacity = 0;

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
function getWalkPath() {
  const scenes = store.state.scenes;
  if (scenes.length === 0) return [];

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
    const forwardLink = currentScene.hotspots.find(h => {
      if (h.isReturnLink) return false; // Skip return links in forward phase
      const targetIdx = scenes.findIndex(s => s.name === h.target);
      return targetIdx !== -1 && !visitedScenes.has(targetIdx);
    });

    if (forwardLink) {
      const nextIdx = scenes.findIndex(s => s.name === forwardLink.target);

      // Update the PREVIOUS step to know where it's going (for Dissolve lookAt)
      path[path.length - 1].transitionTarget = {
        yaw: forwardLink.yaw,
        pitch: forwardLink.pitch || 0,
        targetName: forwardLink.target
      };

      // Use targetYaw (Live View) if available, otherwise viewFrame (Director's View)
      let arrivalYaw = 0;
      let arrivalPitch = 0;
      Debug.debug('Teaser', 'Forward link found:', {
        target: forwardLink.target,
        viewFrame: forwardLink.viewFrame,
        targetYaw: forwardLink.targetYaw,
        targetPitch: forwardLink.targetPitch,
        linkYaw: forwardLink.yaw,
        linkPitch: forwardLink.pitch
      });

      if (forwardLink.targetYaw !== undefined) {
        arrivalYaw = forwardLink.targetYaw;
        arrivalPitch = forwardLink.targetPitch !== undefined ? forwardLink.targetPitch : 0;
      } else if (forwardLink.viewFrame) {
        arrivalYaw = forwardLink.viewFrame.yaw !== undefined ? forwardLink.viewFrame.yaw : 0;
        arrivalPitch = forwardLink.viewFrame.pitch !== undefined ? forwardLink.viewFrame.pitch : 0;
      }
      Debug.debug('Teaser', `Scene ${nextIdx} arrivalView:`, { yaw: arrivalYaw, pitch: arrivalPitch });

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
      path[path.length - 1].transitionTarget = {
        yaw: returnLink.yaw,
        pitch: returnLink.pitch || 0,
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

      if (returnLink.targetYaw !== undefined) {
        arrivalYaw = returnLink.targetYaw;
        arrivalPitch = returnLink.targetPitch !== undefined ? returnLink.targetPitch : 0;
      } else if (returnLink.viewFrame) {
        arrivalYaw = returnLink.viewFrame.yaw !== undefined ? returnLink.viewFrame.yaw : 0;
        arrivalPitch = returnLink.viewFrame.pitch !== undefined ? returnLink.viewFrame.pitch : 0;
      }

      path.push({
        idx: nextIdx,
        transitionTarget: null,
        arrivalView: { yaw: arrivalYaw, pitch: arrivalPitch }
      });

      currentIdx = nextIdx;

      // Stop if we've returned to the starting scene
      if (nextIdx === 0) break;
    } else {
      break; // No return link found, end Phase 2
    }
  }


  return path;
}


/**
 * Main entry point for starting an automated teaser recording.
 * Now modularized into smaller sub-steps.
 */
export async function startAutoTeaser(style = "fast", includeLogo = true, format = "webm") {
  if (isTeasing) return;

  const scenes = store.state.scenes;
  if (scenes.length === 0) {
    console.error("No scenes to film.");
    return;
  }

  try {
    // 1. Initial Setup
    initGhost();
    isTeasing = true;
    const overlay = document.getElementById("teaser-overlay");
    const label = document.getElementById("teaser-text");
    if (overlay) overlay.style.display = "flex";

    const pathSteps = getWalkPath();
    const timestamp = Date.now();
    const config = getTeaserConfig(style, timestamp);

    // 2. Prepare Recorder
    startGhostLoop();
    const stream = ghostCanvas.captureStream(TEASER_FRAME_RATE);
    const recorder = setupMediaRecorder(stream);
    if (!recorder) {
      if (overlay) overlay.style.display = "none";
      isTeasing = false;
      return;
    }

    // 3. Setup rendering state
    const logoState = await loadLogo();
    const snapState = createSnapshotState();

    // 4. Override Ghost Loop with Animation Rendering
    cancelAnimationFrame(streamLoopId);
    updateAnimationLoop(style, includeLogo, logoState, snapState);

    // 5. Preparation & Record
    await prepareFirstScene(pathSteps[0], label, style, config);
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
    recorder.stop();
    recorder.onstop = () => finalizeTeaser(recordedChunks, format, config.baseName, overlay);
  } catch (err) {
    console.error("Teaser Production Failed:", err);
    isTeasing = false;
    const overlay = document.getElementById("teaser-overlay");
    if (overlay) overlay.style.display = "none";
    if (window.notify) window.notify("Teaser Production Failed", "error");
    if (window.updateProgressBar) window.updateProgressBar(0, "Error", false);
  }
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
  let initialYaw = 0;
  let initialPitch = 0;

  if (style === "punchy") {
    // Punchy uses arrivalView (saved camera position)
    if (step.arrivalView) {
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

  store.setActiveScene(step.idx, initialYaw, initialPitch);
  if (label) label.innerText = `Preparing: ${store.state.scenes[step.idx].name}...`;
  if (window.updateProgressBar) {
    window.updateProgressBar(0, "Preparing...", true, "Creating property teaser");
  }

  await new Promise(r => setTimeout(r, SCENE_STABILIZATION_DELAY));
  await waitForViewerReady();

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
  const currentScene = store.state.scenes[step.idx];

  if (window.updateProgressBar) {
    const pct = ((i / pathSteps.length) * 100);
    window.updateProgressBar(pct, `Recording Shot ${i + 1}/${pathSteps.length}: ${currentScene.name}`);
  }
  if (label) label.innerText = `Shot ${i + 1}: ${currentScene.name}`;

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
  // 1. Snapshot (for dissolve overlay)
  const snapCtx = snapCanvas.getContext('2d');
  snapCtx.drawImage(ghostCanvas, 0, 0);
  fadeOpacity = 1;

  // 2. Determine orientation based on style
  const nextStep = pathSteps[i + 1];
  let nextYaw = 0;
  let nextPitch = 0;

  if (style === "punchy") {
    // PUNCHY: Use arrivalView (saved camera position from link)
    if (nextStep.arrivalView) {
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

  // 3. Switch scene with correct orientation from the start
  store.setActiveScene(nextStep.idx, nextYaw, nextPitch);

  // 4. Wait for viewer to be ready
  await waitForViewerReady();
  const viewer = window.pannellumViewer;

  // 5. Ensure orientation is set (backup) - use 0 duration to prevent animation
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

  // 6. Stabilization delay
  await new Promise(r => setTimeout(r, SCENE_STABILIZATION_DELAY));

  // 7. Reveal
  if (style === "punchy") {
    fadeOpacity = 0; // Instant cut
  } else {
    await doCrossDissolve(config.transitionDuration);
  }
}

/**
 * Robust helper to wait for the global pannellumViewer to be initialized and loaded.
 * Handles recreations during scene transitions.
 */
async function waitForViewerReady() {
  const timeout = 8000; // Increased timeout for 4K loads
  const start = Date.now();

  while (Date.now() - start < timeout) {
    const v = window.pannellumViewer;
    if (v && typeof v.isLoaded === 'function' && v.isLoaded()) {
      // ADDITIONAL CHECK: If we are using progressive loading (scenes: preview, master)
      // we MUST wait until the 'master' scene is actually the active one.
      const currentScene = v.getScene();
      const config = v.getConfig();
      
      // If the viewer has multiple scenes (progressive mode), wait for 'master'
      if (config.scenes && config.scenes.master && config.scenes.preview) {
        if (currentScene === 'master') {
          return true;
        }
        // If still on preview, continue waiting for the swap
      } else {
        // Standard single-scene mode
        return true;
      }
    }
    await new Promise(r => setTimeout(r, VIEWER_LOAD_CHECK_INTERVAL));
  }
  throw new Error("Viewer master texture ready timeout");
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
    return;
  }

  const webmBlob = new Blob(recordedChunks, { type: "video/webm" });

  if (format === "webm") {
    DownloadSystem.saveBlob(webmBlob, `${baseName}.webm`);
    if (window.updateProgressBar) {
      window.updateProgressBar(100, "Teaser Complete!", true);
    }
    isTeasing = false;
  } else if (format === "mp4") {
    try {
      await VideoEncoder.transcodeWebMToMP4(webmBlob, baseName, (pct) => {
        if (window.updateProgressBar) {
          window.updateProgressBar(pct, "Converting WebM to MP4...", true, "AI Encoder");
        }
      });
      if (window.updateProgressBar) {
        window.updateProgressBar(100, "Teaser Complete!", true);
      }
    } catch (err) {
      if (window.updateProgressBar) {
        window.updateProgressBar(0, "MP4 Conversion Failed", true, "Error");
      }
    } finally {
      isTeasing = false;
    }
  } else {
    isTeasing = false;
  }
}
