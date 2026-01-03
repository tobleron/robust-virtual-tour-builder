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
function getWalkPath() {
  const scenes = store.state.scenes;
  if (scenes.length === 0) return [];

  let path = [];
  let visitedScenes = new Set();
  let currentIdx = 0;

  // Start at the beginning
  path.push({ idx: 0, transitionTarget: null }); // Start Scene
  visitedScenes.add(0);

  // Look ahead X steps
  for (let i = 0; i < 12; i++) {
    const currentScene = scenes[currentIdx];

    // Find a link that goes to a new, unvisited room
    const link = currentScene.hotspots.find(h => {
      const targetIdx = scenes.findIndex(s => s.name === h.target);
      return targetIdx !== -1 && !visitedScenes.has(targetIdx);
    });

    if (link) {
      const nextIdx = scenes.findIndex(s => s.name === link.target);

      // Update the PREVIOUS step to know where it's going (for the lookAt animation)
      path[path.length - 1].transitionTarget = {
        yaw: link.yaw,
        pitch: link.pitch || 0,
        targetName: link.target
      };

      // Add the next step
      path.push({ idx: nextIdx, transitionTarget: null });
      visitedScenes.add(nextIdx);
      currentIdx = nextIdx;
    } else {
      // No new path found, stop here
      break;
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
  await prepareFirstScene(pathSteps[0], label);
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
}

// --- MODULAR SUB-FUNCTIONS ---

function getTeaserConfig(style, timestamp) {
  if (style === "punchy") {
    return {
      ...TEASER_STYLE_PUNCHY,
      baseName: `Remax_Teaser_Punchy_${timestamp}`
    };
  }
  return {
    ...TEASER_STYLE_DISSOLVE,
    baseName: `Remax_Teaser_Dissolve_${timestamp}`
  };
}

function setupMediaRecorder(stream) {
  let options = { mimeType: "video/webm" };
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
    if (ghostCtx && sourceCanvas && sourceCanvas.width > 0) {
      renderBaseFrame(sourceCanvas);
      if (logoState.loaded && includeLogo) {
        renderWatermark(logoState.img);
      }
      if (style !== "punchy" && fadeOpacity > 0.01) {
        renderSnapshotOverlay(snapState.canvas);
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
  const lw = TEASER_LOGO.width;
  const lh = (logoImg.height / logoImg.width) * lw;
  const pad = TEASER_LOGO.padding;
  const rx = ghostCanvas.width - lw - pad;
  const ry = ghostCanvas.height - lh - pad;

  ghostCtx.save();
  ghostCtx.beginPath();
  if (ghostCtx.roundRect) {
    ghostCtx.roundRect(rx, ry, lw, lh, TEASER_LOGO.borderRadius);
  } else {
    ghostCtx.rect(rx, ry, lw, lh);
  }
  ghostCtx.clip();
  ghostCtx.drawImage(logoImg, rx, ry, lw, lh);
  ghostCtx.restore();
}

function renderSnapshotOverlay(snapCanvas) {
  ghostCtx.save();
  ghostCtx.globalAlpha = fadeOpacity;
  ghostCtx.drawImage(snapCanvas, 0, 0);
  ghostCtx.restore();
}

async function prepareFirstScene(step, label) {
  store.setActiveScene(step.idx, 0);
  if (label) label.innerText = `Preparing: ${store.state.scenes[step.idx].name}...`;
  if (window.updateProgressBar) {
    window.updateProgressBar(0, "Preparing...", true, "Creating property teaser");
  }

  await new Promise(r => setTimeout(r, SCENE_STABILIZATION_DELAY));
  while (!window.pannellumViewer || !window.pannellumViewer.isLoaded()) {
    await new Promise(r => setTimeout(r, VIEWER_LOAD_CHECK_INTERVAL));
  }

  const viewer = window.pannellumViewer;
  if (step.transitionTarget) {
    const yawOffset = (TEASER_STYLE_DISSOLVE.cameraPanOffset); // Use default offset for prep
    viewer.setYaw(step.transitionTarget.yaw - (TEASER_STYLE_DISSOLVE.cameraPanOffset));
    viewer.setPitch(step.transitionTarget.pitch);
  }
  await new Promise(r => setTimeout(r, SCENE_STABILIZATION_DELAY));
}

async function recordShot(i, pathSteps, style, config, label, snapCtx) {
  const step = pathSteps[i];
  const currentScene = store.state.scenes[step.idx];
  const viewer = window.pannellumViewer;

  if (window.updateProgressBar) {
    const pct = ((i / pathSteps.length) * 100);
    window.updateProgressBar(pct, `Recording Shot ${i + 1}/${pathSteps.length}: ${currentScene.name}`);
  }
  if (label) label.innerText = `Shot ${i + 1}: ${currentScene.name}`;

  const targetYaw = step.transitionTarget ? step.transitionTarget.yaw : viewer.getYaw();
  const targetPitch = step.transitionTarget ? step.transitionTarget.pitch : 0;
  const startYaw = (style === "punchy") ? targetYaw : (targetYaw - config.cameraPanOffset);

  const startTime = Date.now();
  while (Date.now() - startTime < config.clipDuration) {
    const p = (Date.now() - startTime) / config.clipDuration;
    if (style !== "punchy") {
      viewer.setYaw(startYaw + ((targetYaw - startYaw) * p));
    } else {
      viewer.setYaw(targetYaw);
    }
    viewer.setPitch(targetPitch);
    await new Promise(r => requestAnimationFrame(r));
  }

  viewer.setYaw(targetYaw);
  viewer.setPitch(targetPitch);
}

async function transitionToNextShot(i, pathSteps, style, config, snapCanvas) {
  const viewer = window.pannellumViewer;
  const snapCtx = snapCanvas.getContext('2d');

  // 1. Snapshot
  snapCtx.drawImage(ghostCanvas, 0, 0);
  fadeOpacity = 1;

  // 2. Switch
  const nextStep = pathSteps[i + 1];
  store.setActiveScene(nextStep.idx, 0);

  // 3. Wait
  await new Promise(r => setTimeout(r, VIEWER_LOAD_CHECK_INTERVAL));
  while (!viewer.isLoaded()) await new Promise(r => setTimeout(r, VIEWER_LOAD_CHECK_INTERVAL));

  // 4. Pre-orient
  if (nextStep.transitionTarget) {
    const nextTgt = nextStep.transitionTarget;
    const nextYaw = (style === "punchy") ? nextTgt.yaw : (nextTgt.yaw - config.cameraPanOffset);
    viewer.setYaw(nextYaw);
    viewer.setPitch(nextTgt.pitch);
  }

  // 5. Reveal
  if (style === "punchy") {
    fadeOpacity = 0;
  } else {
    await doCrossDissolve(config.transitionDuration);
  }
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
