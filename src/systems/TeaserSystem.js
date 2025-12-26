import { store } from "../store.js";

let isTeasing = false;
let ghostCanvas = null;
let ghostCtx = null;
let mediaRecorder = null;
let recordedChunks = [];
let streamLoopId = null;

let fadeOpacity = 0;

function initGhost() {
  if (ghostCanvas) return;
  ghostCanvas = document.createElement("canvas");
  ghostCanvas.width = 1920;
  ghostCanvas.height = 1080;
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

function getWalkPath() {
  const scenes = store.state.scenes;
  if (scenes.length === 0) return [];

  let path = [];
  let visited = new Set();
  let currentIdx = 0;

  // First room default
  path.push({ idx: 0, targetYaw: 0, targetPitch: 0, targetHfov: 60 });
  visited.add(0);

  for (let i = 0; i < 8; i++) {
    const currentScene = scenes[currentIdx];
    const link = currentScene.hotspots.find((h) => {
      const tIdx = scenes.findIndex((s) => s.name === h.target);
      return tIdx !== -1 && !visited.has(tIdx);
    });
    if (link) {
      const nextIdx = scenes.findIndex((s) => s.name === link.target);

      // --- LOGIC: USE SAVED DIRECTOR VIEW ---
      if (link.viewFrame) {
        // User saved a specific look
        path[path.length - 1].targetYaw = link.viewFrame.yaw;
        path[path.length - 1].targetPitch = link.viewFrame.pitch;
      } else {
        // Auto-generated or old link: Aim at the icon
        path[path.length - 1].targetYaw = link.yaw;
        path[path.length - 1].targetPitch = 0;
      }

      path.push({ idx: nextIdx, targetYaw: 0, targetPitch: 0 });
      visited.add(nextIdx);
      currentIdx = nextIdx;
    } else {
      break;
    }
  }
  return path;
}

export async function startAutoTeaser() {
  if (isTeasing) return;
  initGhost();

  const scenes = store.state.scenes;
  if (scenes.length === 0) {
    alert("No scenes.");
    return;
  }

  const overlay = document.getElementById("teaser-overlay");
  const bar = document.getElementById("teaser-progress");
  const label = document.getElementById("teaser-text");
  if (overlay) overlay.style.display = "flex";
  isTeasing = true;

  const pathIndices = getWalkPath();
  const clipDuration = 2500;
  const fadeDuration = 300;

  console.log(" Starting Director Teaser", pathIndices);

  startGhostLoop();

  const stream = ghostCanvas.captureStream(30);
  let options = { mimeType: "video/webm" };
  if (MediaRecorder.isTypeSupported("video/webm;codecs=vp9"))
    options.mimeType = "video/webm;codecs=vp9";

  try {
    mediaRecorder = new MediaRecorder(stream, options);
  } catch (e) {
    alert("Codec Error: " + e.message);
    overlay.style.display = "none";
    isTeasing = false;
    return;
  }

  recordedChunks = [];
  mediaRecorder.ondataavailable = (e) => {
    if (e.data.size > 0) recordedChunks.push(e.data);
  };
  mediaRecorder.start();

  for (let i = 0; i < pathIndices.length; i++) {
    const step = pathIndices[i];
    const currentScene = scenes[step.idx];

    let targetYaw = step.targetYaw;
    let targetPitch = step.targetPitch || 0;

    // Last scene default drift
    if (i === pathIndices.length - 1) {
      targetYaw = (store.state.activeYaw + 40) % 360;
    }

    // A. FADE IN & LOAD
    // Start EXACTLY at the Director's View
    store.setActiveScene(step.idx, targetYaw);

    // Wait for viewer to exist
    while (!window.pannellumViewer) await new Promise((r) => setTimeout(r, 50));

    // Set Initial Director Frame
    window.pannellumViewer.setYaw(targetYaw);
    window.pannellumViewer.setPitch(targetPitch);
    window.pannellumViewer.setHfov(110); // Start Wide

    // --- BLACK SCREEN FIX: Wait until image is actually loaded ---
    const loadStart = Date.now();
    while (!window.pannellumViewer.isLoaded()) {
      await new Promise((r) => setTimeout(r, 100));
      // Safety timeout 3s
      if (Date.now() - loadStart > 3000) break;
    }
    await new Promise((r) => setTimeout(r, 500)); // Extra buffer

    // Fade In (Black -> Clear)
    const fadeStart = Date.now();
    while (Date.now() - fadeStart < fadeDuration) {
      fadeOpacity = 1 - (Date.now() - fadeStart) / fadeDuration;
      await new Promise((r) => requestAnimationFrame(r));
    }
    fadeOpacity = 0;

    // B. ANIMATE (Pure Zoom / Tunnel Effect)
    if (bar) bar.style.width = (i / pathIndices.length) * 100 + "%";
    if (label) label.innerText = `Director Cam: ${currentScene.name}`;

    const moveStart = Date.now();

    while (Date.now() - moveStart < clipDuration) {
      if (window.pannellumViewer) {
        const p = (Date.now() - moveStart) / clipDuration;
        // Ease In (Accelerate into the link)
        const ease = p * p;

        // NO ROTATION (Lock to Director View)
        // Just Zoom: 110 -> 40 (Deep Zoom)
        window.pannellumViewer.setHfov(110 - 70 * ease);
      }
      await new Promise((r) => requestAnimationFrame(r));
    }

    // C. FADE OUT
    if (i < pathIndices.length - 1) {
      const fadeOutStart = Date.now();
      while (Date.now() - fadeOutStart < fadeDuration) {
        fadeOpacity = (Date.now() - fadeOutStart) / fadeDuration;
        await new Promise((r) => requestAnimationFrame(r));
      }
      fadeOpacity = 1;
    }
  }

  if (mediaRecorder.state !== "inactive") mediaRecorder.stop();

  mediaRecorder.onstop = () => {
    cancelAnimationFrame(streamLoopId);
    fadeOpacity = 0;
    if (recordedChunks.length === 0) return;

    const blob = new Blob(recordedChunks, { type: "video/webm" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.style.display = "none";
    a.href = url;
    a.download = `Remax_Director_Teaser.webm`;
    document.body.appendChild(a);
    a.click();

    if (overlay) overlay.style.display = "none";
    isTeasing = false;
    setTimeout(() => alert(" Teaser Ready."), 500);
  };
}
