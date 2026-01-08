/**
 * LabelMenu Component
 * Premium pill/chip grid selector for room labels
 * 
 * @module LabelMenu
 */

import { store } from "../store.js";
import { ROOM_LABEL_PRESETS } from "../constants.js";

// Label menu auto-close timer
let labelMenuTimeout = null;

/**
 * Create and attach the label menu to the DOM
 * @param {HTMLElement} viewerStage - The viewer stage container
 * @param {HTMLElement} labelButton - The button that triggers the menu
 */
export function createLabelMenu(viewerStage, labelButton) {
    // Remove existing menu if present
    const existingMenu = document.getElementById("v-scene-label-menu");
    if (existingMenu) existingMenu.remove();

    const lblMenu = document.createElement("div");
    lblMenu.id = "v-scene-label-menu";
    // Force rounded corners and hide ALL scrollbar tracks (Safari fix)
    lblMenu.className = "hidden fixed flex flex-col gap-4 z-[9999] pointer-events-auto transition-all duration-300 ease-out scale-95 opacity-0 overflow-hidden modal-box";
    lblMenu.style.position = "fixed";
    lblMenu.style.margin = "0";
    lblMenu.style.width = "95%";
    lblMenu.style.maxWidth = "360px";
    lblMenu.style.padding = "24px";
    lblMenu.style.overflow = "hidden";

    // Cross-browser scrollbar nuclear option
    const style = document.createElement('style');
    style.textContent = `
    #v-scene-label-menu ::-webkit-scrollbar {
      width: 4px;
    }
    #v-scene-label-menu ::-webkit-scrollbar-track {
      background: transparent;
    }
    #v-scene-label-menu ::-webkit-scrollbar-thumb {
      background: #e2e8f0;
      border-radius: 10px;
    }
    #v-scene-label-menu ::-webkit-scrollbar-thumb:hover {
      background: #cbd5e1;
    }
    
    .scroll-indicator-bottom {
      content: "";
      position: absolute;
      bottom: 84px; /* Above custom section */
      left: 24px;
      right: 24px;
      height: 30px;
      background: linear-gradient(to top, rgba(255,255,255,0.95), transparent);
      pointer-events: none;
      z-index: 10;
      transition: opacity 0.3s;
    }
  `;
    lblMenu.appendChild(style);

    // 2. Scrollable Presets Container
    const presetsWrapper = document.createElement("div");
    presetsWrapper.id = "label-presets-scroll";
    presetsWrapper.className = "flex-1 flex flex-col gap-4 overflow-y-auto pr-1 relative";
    presetsWrapper.style.maxHeight = "360px"; // Comfortable height for indoor list

    // Bottom fade indicator
    const scrollFade = document.createElement("div");
    scrollFade.className = "scroll-indicator-bottom";
    lblMenu.appendChild(scrollFade);

    presetsWrapper.onscroll = () => {
        const remaining = presetsWrapper.scrollHeight - presetsWrapper.scrollTop - presetsWrapper.clientHeight;
        scrollFade.style.opacity = remaining > 10 ? "1" : "0";
    };

    // Categorized Sections
    Object.entries(ROOM_LABEL_PRESETS).forEach(([category, labels]) => {
        const section = document.createElement("div");
        section.className = "label-section flex flex-col gap-2.5";
        section.dataset.category = category;

        // Header with subtle line
        const header = document.createElement("div");
        header.className = "flex items-center gap-2";
        header.innerHTML = `
      <span class="text-[9px] font-black text-slate-400 uppercase tracking-[2px]">${category}</span>
      <div class="h-[1px] flex-1 bg-slate-100"></div>
    `;
        section.appendChild(header);

        // 2-Column Grid for perfect alignment
        const grid = document.createElement("div");
        grid.className = "grid grid-cols-2 gap-1.5";

        labels.forEach(label => {
            const chip = document.createElement("button");
            chip.className = "label-pill px-3 py-2 font-ui text-[10px] font-bold uppercase text-slate-600 bg-slate-50 border border-slate-100 rounded-lg cursor-pointer transition-all hover:bg-remax-blue hover:text-white hover:border-remax-blue hover:shadow-md active:scale-95 text-left";
            chip.textContent = label;
            chip.dataset.val = label;
            chip.dataset.category = category;
            chip.onclick = (e) => {
                e.stopPropagation();
                store.updateSceneMetadata(store.state.activeIndex, { label: label });
                window.notify(`Label Set: ${label}`, "success");

                // 1.9s Delay before auto-closing
                scheduleMenuClose();
            };
            grid.appendChild(chip);
        });

        section.appendChild(grid);
        presetsWrapper.appendChild(section);
    });

    lblMenu.appendChild(presetsWrapper);

    // Custom Label Section
    const customSection = document.createElement("div");
    customSection.className = "flex flex-col gap-2 pt-4 mt-1 border-t border-slate-100 bg-white/50 backdrop-blur-sm sticky bottom-0";

    const customTitle = document.createElement("div");
    customTitle.className = "text-[9px] font-black text-slate-300 uppercase tracking-[1px]";
    customTitle.textContent = "Custom Label Entry";
    customSection.appendChild(customTitle);

    const inputWrapper = document.createElement("div");
    inputWrapper.className = "flex gap-2 items-center";

    const inp = document.createElement("input");
    inp.id = "v-scene-label-custom";
    inp.type = "text";
    inp.placeholder = "Enter custom name...";
    inp.className = "flex-1 px-4 py-2 bg-slate-50 border border-slate-200 text-slate-700 rounded-xl text-xs font-bold outline-none focus:ring-4 focus:ring-remax-blue/5 focus:border-remax-blue placeholder:text-slate-300 transition-all";
    inp.onclick = (e) => e.stopPropagation();

    const setBtn = document.createElement("button");
    setBtn.innerHTML = "SET";
    setBtn.className = "shrink-0 px-3 py-2 text-white text-[10px] font-black rounded-xl transition-all active:scale-95 shadow-sm";
    setBtn.style.backgroundColor = "#007BA7";

    const clearBtn = document.createElement("button");
    clearBtn.innerHTML = "CLEAR";
    clearBtn.className = "shrink-0 px-3 py-2 bg-slate-200 text-slate-600 text-[10px] font-black rounded-xl hover:bg-slate-300 transition-all active:scale-95";

    const applyCustom = () => {
        const val = inp.value.trim();
        if (val) {
            store.updateSceneMetadata(store.state.activeIndex, { label: val });
            window.notify(`Label Set: ${val}`, "success");
            scheduleMenuClose();
        }
    };

    const clearLabel = () => {
        store.updateSceneMetadata(store.state.activeIndex, { label: "" });
        inp.value = "";
        window.notify("Label Cleared", "warning");
        scheduleMenuClose();
    };

    setBtn.onclick = (e) => {
        e.stopPropagation();
        applyCustom();
    };

    clearBtn.onclick = (e) => {
        e.stopPropagation();
        clearLabel();
    };

    inp.onkeydown = (e) => {
        if (e.key === 'Enter') {
            e.stopPropagation();
            applyCustom();
        }
    };

    inputWrapper.appendChild(inp);
    inputWrapper.appendChild(setBtn);
    inputWrapper.appendChild(clearBtn);
    customSection.appendChild(inputWrapper);
    lblMenu.appendChild(customSection);

    document.body.appendChild(lblMenu);

    // Setup toggle behavior on the label button
    labelButton.onclick = (e) => {
        e.stopPropagation();
        toggleLabelMenu(labelButton);
    };

    // Close menu when clicking elsewhere
    document.addEventListener('click', (e) => {
        if (e.target.closest('#v-scene-label-menu') || e.target.closest('#v-scene-label-btn')) return;
        closeLabelMenu();
    });

    return lblMenu;
}

/**
 * Toggle the label menu visibility
 * @param {HTMLElement} labelButton - The button that triggered the toggle
 */
export function toggleLabelMenu(labelButton) {
    const menu = document.getElementById("v-scene-label-menu");
    if (!menu) return;

    // Clear any pending auto-close timer when manually toggling
    if (labelMenuTimeout) {
        clearTimeout(labelMenuTimeout);
        labelMenuTimeout = null;
    }

    const isHidden = menu.classList.contains("hidden");
    if (isHidden) {
        // Calculate position dynamically BEFORE showing
        const rect = labelButton.getBoundingClientRect();
        const menuHeight = 500; // Estimated max height
        const spaceBelow = window.innerHeight - rect.top;

        menu.style.position = "fixed";
        if (spaceBelow < menuHeight) {
            menu.style.top = `${Math.max(20, rect.bottom - menuHeight)}px`;
        } else {
            menu.style.top = `${rect.top}px`;
        }
        menu.style.left = `${rect.right + 12}px`;

        menu.classList.remove("hidden");

        // Small timeout to trigger transition
        setTimeout(() => {
            menu.classList.remove("scale-95", "opacity-0");
            menu.classList.add("scale-100", "opacity-100");
        }, 10);
    } else {
        closeLabelMenu();
    }
}

/**
 * Close the label menu with animation
 */
export function closeLabelMenu() {
    const menu = document.getElementById("v-scene-label-menu");
    if (!menu || menu.classList.contains("hidden")) return;

    if (labelMenuTimeout) {
        clearTimeout(labelMenuTimeout);
        labelMenuTimeout = null;
    }

    menu.classList.add("scale-95", "opacity-0");
    menu.classList.remove("scale-100", "opacity-100");
    setTimeout(() => menu.classList.add("hidden"), 300);
}

/**
 * Schedule menu to close after delay
 */
function scheduleMenuClose() {
    if (labelMenuTimeout) clearTimeout(labelMenuTimeout);
    labelMenuTimeout = setTimeout(() => {
        closeLabelMenu();
        labelMenuTimeout = null;
    }, 1900);
}

/**
 * Sync label menu UI with current scene state
 * @param {Object} scene - Current scene object
 */
export function syncLabelMenu(scene) {
    const labelPills = document.querySelectorAll(".label-pill");
    const labelSections = document.querySelectorAll(".label-section");
    const inp = document.getElementById("v-scene-label-custom");
    const currentLabel = scene.label || "";
    const currentCategory = scene.category || "indoor";

    // Filter Section Visibility by Category
    labelSections.forEach(section => {
        if (section.dataset.category === currentCategory) section.style.display = "flex";
        else section.style.display = "none";
    });

    labelPills.forEach(pill => {
        const isActive = pill.dataset.val === currentLabel;
        if (isActive) {
            pill.classList.add("bg-remax-blue", "text-white", "border-remax-blue");
            pill.classList.remove("bg-slate-50", "text-slate-600", "border-slate-100");
        } else {
            pill.classList.remove("bg-remax-blue", "text-white", "border-remax-blue");
            pill.classList.add("bg-slate-50", "text-slate-600", "border-slate-100");
        }
    });

    // Handle custom input: show current label value
    if (inp) {
        inp.value = currentLabel || "";
    }
}
