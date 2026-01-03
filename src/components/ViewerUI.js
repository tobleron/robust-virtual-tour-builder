/**
 * ViewerUI Component
 * Handles the creation and management of UI overlays for the panorama viewer
 */

import { store } from "../store.js";
import { FLOOR_LEVELS } from "../constants.js";
import { createLabelMenu, toggleLabelMenu } from "./LabelMenu.js";
import {
    getIsSimulationMode,
    setSimulationMode,
    resetAutoForwardChain,
    getIncomingLink,
    setPendingReturnSceneName
} from "../systems/NavigationSystem.js";

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

    // Top Left Utility Bar
    const utilityBar = document.createElement("div");
    utilityBar.id = "viewer-utility-bar";
    utilityBar.className = "absolute top-6 left-5 z-[5002] flex flex-col gap-3 items-start bg-transparent";

    // Link Mode FAB
    const fab = document.createElement("button");
    fab.id = "btn-add-link-fab";
    fab.innerHTML = "+";
    fab.className = "w-[37px] h-[37px] text-white rounded-full font-ui text-[23px] font-bold flex items-center justify-center btn-viewer-pop leading-none pb-0.5";
    fab.style.backgroundColor = "#dc3545"; // RE/MAX Red default
    fab.onclick = (e) => {
        e.stopPropagation();
        store.state.isLinking = !store.state.isLinking;
        store.notify();
        window.notify(store.state.isLinking ? "Link Mode: ACTIVE" : "Link Mode: OFF", store.state.isLinking ? "success" : "warning");
    };
    utilityBar.appendChild(fab);

    // Simulation Mode Toggle
    const simToggle = document.createElement("button");
    simToggle.id = "v-scene-sim-toggle";
    simToggle.innerHTML = "▶";
    simToggle.title = "Simulation Mode: Test final tour navigation";
    simToggle.className = "w-[37px] h-[37px] text-white rounded-full font-ui text-[19px] font-bold flex items-center justify-center btn-viewer-pop";
    simToggle.style.backgroundColor = "#dc3545"; // RE/MAX Red default

    if (getIsSimulationMode()) {
        simToggle.classList.add("active");
    }

    simToggle.onclick = (e) => {
        e.stopPropagation();
        const newVal = !getIsSimulationMode();
        setSimulationMode(newVal);
        simToggle.classList.toggle("active", newVal);
        window.notify(newVal ? "Simulation Mode: ACTIVE" : "Simulation Mode: OFF", newVal ? "success" : "warning");
        store.notify();
    };
    utilityBar.appendChild(simToggle);

    // Category Toggle
    const catToggle = document.createElement("button");
    catToggle.id = "v-scene-cat-toggle";
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
    pLabel.className = "hidden absolute top-6 left-1/2 -translate-x-1/2 z-[6005] text-white px-3 py-1 rounded-md text-[13px] font-black uppercase shadow-lg items-center justify-center transition-all duration-300 pointer-events-none border border-white/20 opacity-0 -translate-y-2 scale-95 tracking-widest";
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
    logo.className = "absolute bottom-6 right-6 z-[5002] bg-white rounded-xl shadow-xl p-1 flex items-center justify-center max-w-[120px] max-h-[60px] border border-black/5";
    logo.innerHTML = `<img src="images/logo.png" alt="Logo" class="w-full h-auto object-contain">`;
    viewerStage.appendChild(logo);

    // Floor Navigation
    const floorNav = document.createElement("div");
    floorNav.id = "viewer-floor-nav";
    floorNav.className = "absolute bottom-6 left-5 z-[5002] flex flex-col-reverse gap-2.5 items-center";
    FLOOR_LEVELS.forEach(f => {
        const c = document.createElement("div");
        c.className = "floor-circle w-[37px] h-[37px] rounded-full bg-floor-default border-2 border-transparent flex items-center justify-center font-ui text-[15px] font-bold text-white cursor-pointer transition-all hover:border-floor-hover shadow-md";
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
}
