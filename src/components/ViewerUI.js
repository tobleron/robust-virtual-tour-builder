/**
 * ViewerUI Component
 * Handles the creation and management of UI overlays for the panorama viewer
 */

import { store } from "../store.js";
import { FLOOR_LEVELS } from "../constants.js";
import { createLabelMenu, toggleLabelMenu } from "./LabelMenu.js";
import {
    getIsSimulationMode,
    getIncomingLink,
    setPendingReturnSceneName
} from "../systems/NavigationSystem.js";
import {
    startAutoPilot,
    stopAutoPilot,
    isAutoPilotActive
} from "../systems/SimulationSystem.js";

/**
 * Setup all UI elements overlaying the viewer
 */
export function setupViewerUI(viewerStage, viewer) {
    if (!viewerStage) return;

    // Snapshot Overlay
    const snapshot = document.createElement("div");
    snapshot.id = "viewer-snapshot-overlay";
    snapshot.className = "absolute inset-0 bg-center bg-no-repeat z-[5000] pointer-events-none opacity-0 transition-opacity duration-300 ease-in-out";
    viewerStage.appendChild(snapshot);

    // Top Left Utility Bar - REMOVE EXISTING to prevent duplicates
    const existingBar = document.getElementById("viewer-utility-bar");
    if (existingBar) existingBar.remove();

    const utilityBar = document.createElement("div");
    utilityBar.id = "viewer-utility-bar";
    utilityBar.className = "absolute top-6 left-5 z-[5002] flex flex-col gap-3 items-start bg-transparent";

    // Link Mode FAB
    const fab = document.createElement("button");
    fab.id = "btn-add-link-fab";
    fab.innerHTML = "+";
    fab.title = "Add Link: Create a transition to another scene";
    fab.className = "w-[37px] h-[37px] text-white rounded-full font-ui text-[23px] font-bold flex items-center justify-center btn-viewer-pop leading-none pb-0.5";
    fab.style.backgroundColor = "#dc3545"; // RE/MAX Red default
    fab.onclick = (e) => {
        e.stopPropagation();
        store.state.isLinking = !store.state.isLinking;
        store.notify();
        window.notify(store.state.isLinking ? "Link Mode: ACTIVE" : "Link Mode: OFF", store.state.isLinking ? "success" : "warning");
    };
    utilityBar.appendChild(fab);

    // Simulation Mode Toggle (now controls Auto-Pilot)
    // Simulation Mode Toggle (now controls Auto-Pilot)
    const simToggle = document.createElement("button");
    simToggle.id = "v-scene-sim-toggle";
    simToggle.className = "w-[37px] h-[37px] text-white rounded-full font-ui flex items-center justify-center btn-viewer-pop";

    // Determine initial state based on auto-pilot status
    if (isAutoPilotActive()) {
        simToggle.innerHTML = '<span class="material-icons" style="font-size: 22px; color: white;">stop</span>';
        simToggle.style.setProperty('background-color', '#dc3545', 'important'); // RED
        simToggle.title = "Stop Auto-Pilot Simulation";
    } else {
        simToggle.innerHTML = '<span class="material-icons" style="font-size: 22px; color: white;">play_arrow</span>';
        simToggle.style.setProperty('background-color', '#10b981', 'important'); // GREEN
        simToggle.title = "Start Auto-Pilot Simulation";
    }

    simToggle.onclick = (e) => {
        e.stopPropagation();
        if (isAutoPilotActive()) {
            // Stop auto-pilot
            stopAutoPilot(true);
        } else {
            // Start auto-pilot
            startAutoPilot();
        }
    };
    utilityBar.appendChild(simToggle);

    // Category Toggle
    const catToggle = document.createElement("button");
    catToggle.id = "v-scene-cat-toggle";
    catToggle.title = "Toggle Category: Indoor vs Outdoor";
    catToggle.className = "w-[37px] h-[37px] text-white rounded-full flex items-center justify-center btn-viewer-pop";
    catToggle.style.backgroundColor = "#dc3545"; // RE/MAX Red default
    catToggle.onclick = (e) => {
        e.stopPropagation();
        const activeIdx = store.state.activeIndex;
        if (activeIdx < 0) return;
        const current = store.state.scenes[activeIdx].category || "indoor";
        const newCat = current === "indoor" ? "outdoor" : "indoor";
        store.updateSceneMetadata(activeIdx, { category: newCat });
        window.notify(newCat === "indoor" ? "Category: INDOOR" : "Category: OUTDOOR", newCat === "indoor" ? "warning" : "success");
    };
    utilityBar.appendChild(catToggle);

    // Label Button
    const lblBtn = document.createElement("button");
    lblBtn.id = "v-scene-label-btn";
    lblBtn.innerHTML = "#";
    lblBtn.title = "Scene Label: Tag this scene (e.g., Living Room)";
    lblBtn.className = "w-[37px] h-[37px] text-white rounded-full font-ui text-[21px] font-bold flex items-center justify-center btn-viewer-pop relative z-[6000] pointer-events-auto";
    lblBtn.style.backgroundColor = "#dc3545"; // RE/MAX Red default
    lblBtn.onclick = (e) => {
        e.stopPropagation();
        toggleLabelMenu(lblBtn);
    };
    utilityBar.appendChild(lblBtn);
    viewerStage.appendChild(utilityBar);

    // Persistent Label Overlay
    const pLabel = document.createElement("div");
    pLabel.id = "v-scene-persistent-label";
    pLabel.className = "hidden absolute top-6 left-1/2 -translate-x-1/2 z-[6005] text-white px-3 py-0.5 rounded-md text-[12px] font-black uppercase shadow-lg items-center justify-center transition-all duration-300 pointer-events-none border border-white/20 opacity-0 -translate-y-2 scale-95 tracking-wider";
    pLabel.style.backgroundColor = "#2563eb";
    viewerStage.appendChild(pLabel);

    // Quality Indicator
    const qIndicator = document.createElement("div");
    qIndicator.id = "v-scene-quality-indicator";
    qIndicator.className = "hidden absolute top-6 right-6 z-[6005] flex items-center gap-2 pointer-events-none transition-all duration-300 opacity-0 translate-x-2 scale-95";
    viewerStage.appendChild(qIndicator);

    // Label Menu
    createLabelMenu(viewerStage, lblBtn);

    // Logo Overlay
    const logo = document.createElement("div");
    logo.id = "viewer-logo";
    // Added overflow-hidden and Safari clipping fix (-webkit-mask-image)
    logo.className = "absolute bottom-6 right-6 z-[5002] bg-white rounded-xl shadow-xl p-[4px] flex items-center justify-center max-w-[120px] max-h-[60px] border border-black/5 overflow-hidden";
    logo.style.webkitMaskImage = "-webkit-radial-gradient(white, black)"; // Force Safari mask clipping
    logo.innerHTML = `<img src="images/logo.png" alt="Logo" class="w-full h-auto object-contain block">`;
    viewerStage.appendChild(logo);

    // Linking Cancel Hint (Bottom Center) - Status Bar
    const cancelHint = document.createElement("div");
    cancelHint.id = "linking-cancel-hint";
    cancelHint.style.cssText = `
        position: absolute;
        bottom: 40px;
        left: 50%;
        transform: translateX(-50%) translateY(8px);
        z-index: 9999;
        color: white;
        font-family: var(--font-ui, 'Inter', system-ui, sans-serif);
        font-size: 11px;
        font-weight: 800;
        text-transform: uppercase;
        letter-spacing: 0.25em;
        opacity: 0;
        pointer-events: none;
        transition: opacity 0.4s ease, transform 0.4s ease;
        text-shadow: 0 2px 8px rgba(0, 0, 0, 0.6);
        white-space: nowrap;
    `;
    cancelHint.innerHTML = "ESC to Cancel<br><span style='font-size:10px; opacity:0.8'>ENTER to Finish</span>";
    // Allow clicking on the text if needed, but usually it's just visual.
    // CSS text-align center is needed for the multi-line
    cancelHint.style.textAlign = "center";
    viewerStage.appendChild(cancelHint);

    // Floor Navigation
    const floorNav = document.createElement("div");
    floorNav.id = "viewer-floor-nav";
    floorNav.className = "absolute bottom-6 left-5 z-[5002] flex flex-col-reverse gap-2.5 items-center";
    FLOOR_LEVELS.forEach(f => {
        const c = document.createElement("div");
        c.className = "floor-circle w-[37px] h-[37px] rounded-full bg-floor-default border-2 border-transparent flex items-center justify-center font-ui text-[15px] font-bold text-white cursor-pointer transition-all hover:border-floor-hover";
        c.dataset.id = f.id;
        c.setAttribute("title", f.label);
        if (f.suffix) {
            c.innerHTML = `${f.short}<sup>${f.suffix}</sup>`;
        } else {
            c.textContent = f.short;
        }
        c.onclick = (e) => {
            e.stopPropagation();
            const activeIdx = store.state.activeIndex;
            if (activeIdx < 0) return;
            store.updateSceneMetadata(activeIdx, { floor: f.id });
            window.notify(`Floor: ${f.label || f.id}`, "success");
        };
        floorNav.appendChild(c);
    });
    viewerStage.appendChild(floorNav);

    // Return Link Prompt
    const returnPrompt = document.createElement("div");
    returnPrompt.id = "return-link-prompt";
    returnPrompt.className = "hidden fixed bottom-24 left-1/2 -translate-x-1/2 glass-panel rounded-full px-5 py-2.5 items-center gap-3 shadow-2xl z-[4000] border border-remax-gold/20 cursor-pointer transition-all hover:scale-105 active:scale-95 animate-fade-in-centered";
    returnPrompt.innerHTML = `
        <div class="w-6 h-6 bg-remax-gold rounded-full flex items-center justify-center text-black font-black text-xs shadow-sm">↩</div>
        <div class="return-link-text font-ui text-[13px] font-bold text-white">Add Return Link</div>
    `;
    returnPrompt.onclick = (e) => {
        e.stopPropagation();
        const v = window.pannellumViewer;
        const incoming = getIncomingLink();
        if (v && incoming) {
            const prevScene = store.state.scenes[incoming.sceneIndex];
            if (prevScene) {
                const currentYaw = v.getYaw();
                v.setYaw(currentYaw + 180, 1000);
                setPendingReturnSceneName(prevScene.name);
                window.notify("Turned around! NOW click '+' to place the link.", "success");
                returnPrompt.classList.remove("visible");
            }
        }
    };
    viewerStage.appendChild(returnPrompt);

    // Center Indicator (Visualization Support) - Explicitly visible
    console.log("[ViewerUI] Injecting center indicator...");
    const centerIndicator = document.createElement("div");
    centerIndicator.id = "viewer-center-indicator";
    centerIndicator.style.cssText = `
        position: absolute;
        top: 50%;
        left: 50%;
        width: 10px;
        height: 10px;
        background-color: white;
        border: 2px solid #ff0000;
        border-radius: 50%;
        transform: translate(-50%, -50%);
        z-index: 5001;
        pointer-events: none;
        display: none;
    `;
    viewerStage.appendChild(centerIndicator);

    // Hotspot Connecting Lines SVG Overlay
    const lineSvg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    lineSvg.id = "viewer-hotspot-lines";
    lineSvg.style.cssText = `
        position: absolute;
        inset: 0;
        width: 100%;
        height: 100%;
        z-index: 5000;
        pointer-events: none;
    `;
    viewerStage.appendChild(lineSvg);

    /*
    // Debug Controls (Bottom Center) - HIDDEN FOR NOW
    const debugBar = document.createElement("div");
    debugBar.id = "viewer-debug-bar";
    debugBar.className = "absolute bottom-6 left-1/2 -translate-x-1/2 z-[5002] flex gap-2 items-center";

    // Debug Toggle Button
    const debugToggle = document.createElement("button");
    debugToggle.id = "btn-debug-toggle";
    debugToggle.innerHTML = `<span class="material-icons text-[16px]">bug_report</span>`;
    debugToggle.title = "Toggle Debug Mode";
    debugToggle.className = "w-[32px] h-[32px] rounded-full flex items-center justify-center transition-all hover:scale-110 active:scale-95 shadow-lg border border-white/10";
    debugToggle.style.backgroundColor = "#6b7a6b"; // Muted Grey-Green (off)
    debugToggle.style.color = "#ffffff";

    // Check if debug is already enabled
    if (typeof window !== 'undefined' && window.DEBUG && window.DEBUG.isEnabled()) {
        debugToggle.style.backgroundColor = "#4d614d"; // Muted Green (on)
    }

    debugToggle.onclick = (e) => {
        e.stopPropagation();
        if (window.DEBUG) {
            const isNowEnabled = window.DEBUG.toggle();
            debugToggle.style.backgroundColor = isNowEnabled ? "#4d614d" : "#6b7a6b";
            window.notify(isNowEnabled ? "Debug Mode: ON" : "Debug Mode: OFF", isNowEnabled ? "success" : "warning");
        }
    };
    debugBar.appendChild(debugToggle);

    // Download Logs Button
    const debugDownload = document.createElement("button");
    debugDownload.id = "btn-debug-download";
    debugDownload.innerHTML = `<span class="material-icons text-[16px]">download</span>`;
    debugDownload.title = "Download Debug Logs";
    debugDownload.className = "w-[32px] h-[32px] rounded-full flex items-center justify-center transition-all hover:scale-110 active:scale-95 shadow-lg border border-white/10";
    debugDownload.style.backgroundColor = "#6b7a6b"; // Muted Grey-Green
    debugDownload.style.color = "#ffffff";

    debugDownload.onclick = (e) => {
        e.stopPropagation();
        if (window.DEBUG) {
            const count = window.DEBUG.entries.length;
            if (count === 0) {
                window.notify("No debug logs to download", "warning");
            } else {
                window.DEBUG.downloadLog();
                window.notify(`Downloaded ${count} log entries`, "success");
            }
        }
    };
    debugBar.appendChild(debugDownload);

    viewerStage.appendChild(debugBar);
    */
}
