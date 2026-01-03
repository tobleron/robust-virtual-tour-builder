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
  initNavigation
} from "../systems/NavigationSystem.js";
import { setupViewerUI } from "./ViewerUI.js";

const GLOBAL_HFOV = 90;
let viewer = null;

// TRACKING for state management
let lastSceneId = null;
let lastHotspotCount = 0;
let lastIsLinking = false;
let lastCategory = "indoor";
let lastFloor = "ground";

// Viewport saving debounce to prevent accidental changes
let viewportSaveTimeout = null;

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
    setupViewerUI(viewerStage, viewer);
    // Initial Dimming State Check
    syncViewControls(store.state);
    if (store.state.scenes.length > 0) {
      syncUI(store.state, store.state.scenes[store.state.activeIndex]);
    }
  }

  // --- 2. LASER POINTER / CURSOR GUIDE ---
  const guide = document.getElementById("cursor-guide");
  if (viewerStage && guide) {
    viewerStage.addEventListener("mousemove", (e) => {
      if (!store.state.isLinking || !viewer) {
        guide.style.display = "none";
        return;
      }

      const rect = viewerStage.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;

      // --- PRECISION PERSPECTIVE PROJECTION ---
      const coords = viewer.mouseEventToCoords(e);
      const clickPitch = coords[0];
      const targetPitch = clickPitch - 15; // Matches LinkModal offset

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

      guide.style.display = "block";
      guide.style.left = x + "px";
      guide.style.top = y + "px";
      guide.style.height = Math.max(0, guideHeight) + "px";
    });

    viewerContainer.addEventListener("mouseleave", () => {
      guide.style.display = "none";
    });
  }

  // --- 3. STORE SUBSCRIPTION ---
  store.subscribe((state) => {
    syncViewControls(state);
    if (state.scenes.length === 0) {
      if (viewer) {
        try { viewer.destroy(); } catch (e) { }
        viewer = null;
        window.pannellumViewer = null;
      }
      // Also clear any stuck snapshot
      const snapshot = document.getElementById("viewer-snapshot-overlay");
      if (snapshot) {
        snapshot.classList.remove("snapshot-visible");
        snapshot.style.backgroundImage = 'none';
      }
      return;
    }

    const currentScene = state.scenes[state.activeIndex];
    syncUI(state, currentScene);
    const hasSceneChanged = currentScene.id !== lastSceneId;
    const hasHotspotsChanged = currentScene.hotspots.length !== lastHotspotCount;

    // IF SCENE CHANGED: Determine if it was a manual jump or a linked navigation
    if (hasSceneChanged) {
      const isLinkedNavigation = state.transition && (state.transition.type === 'link' || state.transition.type === 'drone');
      if (!isLinkedNavigation) {
        // Manual jump (Sidebar) - Clear stale history
        setIncomingLink(null);
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
      syncHotspots(viewer, state, currentScene, getIncomingLink(), getIsSimulationMode(), navigateToScene);
      lastIsLinking = state.isLinking;
      lastHotspotCount = currentScene.hotspots.length;
      return;
    }

    // SCENE RELOAD LOGIC
    lastSceneId = currentScene.id;
    lastHotspotCount = currentScene.hotspots.length;

    const snapshot = document.getElementById("viewer-snapshot-overlay");
    if (viewer) {
      if (snapshot) {
        try {
          const canvas = viewerContainer.querySelector("canvas");
          snapshot.style.backgroundImage = `url(${canvas.toDataURL("image/webp", 0.7)})`;
          snapshot.classList.add("snapshot-visible");
        } catch (e) { }
      }
      try { viewer.destroy(); } catch (e) { }
    }

    const reader = new FileReader();
    reader.onload = (e) => {
      viewer = pannellum.viewer("panorama", {
        type: "equirectangular",
        panorama: e.target.result,
        autoLoad: true,
        pitch: state.activePitch || 0,
        yaw: state.activeYaw || 0,
        hfov: GLOBAL_HFOV,
        minHfov: GLOBAL_HFOV,
        maxHfov: GLOBAL_HFOV,
        friction: 0.05,
        hotSpots: currentScene.hotspots.map((h, i) => createHotspotConfig(h, i, state, currentScene, getIncomingLink(), getIsSimulationMode(), navigateToScene)),
      });
      window.pannellumViewer = viewer;

      viewer.on('load', () => {
        if (snapshot) snapshot.classList.remove("snapshot-visible");
        handleAutoForward(currentScene, state, viewer);
      });

      viewer.on('mousedown', (e) => {
        const isLinking = store.state.isLinking;
        if (!isLinking) return;
        const coords = viewer.mouseEventToCoords(e);
        const pitch = coords[0];
        const yaw = coords[1];
        showLinkModal(pitch, yaw, getPendingReturnSceneName(), (targetSceneName, targetYaw, targetPitch) => {
          store.addHotspot(state.activeIndex, {
            target: targetSceneName,
            pitch: pitch - 15,
            yaw: yaw,
            targetYaw: targetYaw,
            viewFrame: { pitch: targetPitch }
          });
          setPendingReturnSceneName(null);
        });
      });

      // Bi-Directional View Saving
      viewer.on('animatefinished', () => {
        const incoming = getIncomingLink();
        if (incoming && viewportSaveTimeout === null) {
          if (state.transition && (state.transition.type === 'link' || state.transition.type === 'drone')) {
            const currentYaw = viewer.getYaw();
            store.updateHotspotTargetYaw(incoming.sceneIndex, incoming.hotspotIndex, currentYaw);
          }
        }
      });

      viewer.on('viewchange', () => {
        const incoming = getIncomingLink();
        if (incoming) {
          if (viewportSaveTimeout) {
            clearTimeout(viewportSaveTimeout);
          }
          viewportSaveTimeout = setTimeout(() => {
            const currentYaw = viewer.getYaw();
            store.updateHotspotTargetYaw(incoming.sceneIndex, incoming.hotspotIndex, currentYaw);
            viewportSaveTimeout = null;
          }, 800);
        }
      });
    };

    reader.readAsDataURL(currentScene.file);
  });
}

/**
 * UI Synchronization
 */
export function syncUI(state, scene) {
  const fab = document.getElementById("btn-add-link-fab");
  const simToggle = document.getElementById("v-scene-sim-toggle");
  const catToggle = document.getElementById("v-scene-cat-toggle");
  const lblBtn = document.getElementById("v-scene-label-btn");
  const circles = document.querySelectorAll(".floor-circle");

  if (fab) {
    if (state.isLinking) {
      fab.style.background = "#ffcc00"; // Yellow Background
      fab.style.color = "#000000"; // Black Plus
      fab.classList.add("active");
    } else {
      fab.style.background = "#dc3545"; // RE/MAX Red
      fab.style.color = "#ffffff"; // White Plus
      fab.classList.remove("active");
    }
  }

  if (simToggle) {
    const isSim = getIsSimulationMode();
    if (isSim) {
      simToggle.style.background = "#10b981"; // Success Green
    } else {
      simToggle.style.background = "#dc3545"; // RE/MAX Red
    }
    simToggle.classList.toggle("active", isSim);
  }

  if (catToggle) {
    const isOutdoor = scene.category === "outdoor";
    catToggle.innerHTML = isOutdoor ? '<span class="material-icons text-[21px]">park</span>' : '<span class="material-icons text-[21px]">home</span>';

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
        <span class="text-white text-[13px] font-black px-3 py-1 rounded-md tracking-widest leading-none shadow-lg border border-white/20" style="background: ${b.bg};">${b.text}</span>
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
    if (!hasScenes) utilityBar.classList.add("viewer-utility-dimmed");
    else utilityBar.classList.remove("viewer-utility-dimmed");
  }
  if (floorNav) {
    if (!hasScenes) floorNav.classList.add("viewer-utility-dimmed");
    else floorNav.classList.remove("viewer-utility-dimmed");
  }
}
