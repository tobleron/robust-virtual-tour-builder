import { notify } from "../utils/NotificationSystem.js";
import { store } from "../store.js";
import { calculateSimilarity } from "../systems/ExifParser.js";
import { cancelNavigation } from "../systems/NavigationSystem.js";
import { getGroupColor } from "../utils/ColorPalette.js";

/**
 * SceneList Component
 * 
 * Manages the rendering and interaction of the scene list in the sidebar.
 * Handles:
 * - Rendering scene items with quality indicators
 * - Scene selection and deletion
 * - Context menu management
 * - Drag and drop reordering
 */
export const SceneList = {
    container: null,
    contextMenu: null,
    targetContextIndex: -1,

    /**
     * Initialize the SceneList component.
     * 
     * @param {HTMLElement} container - The container where scenes are listed.
     * @param {HTMLElement} contextMenu - The context menu element.
     */
    init(container, contextMenu) {
        this.container = container;
        this.contextMenu = contextMenu;
        this.setupContextMenu();
    },

    setupContextMenu() {
        const btnDelete = document.getElementById("btn-delete-scene");
        const btnClearLinks = document.getElementById("btn-clear-links");

        document.addEventListener("click", (e) => {
            // Don't close if clicking the trigger button or the menu itself
            if (e.target.closest('.scene-more-btn') || e.target.closest('#context-menu')) return;
            this.hideContextMenu();
        });

        if (btnDelete) {
            btnDelete.addEventListener("click", (e) => {
                e.stopPropagation();
                if (this.targetContextIndex > -1) {
                    store.deleteScene(this.targetContextIndex);
                    notify("Image deleted", "info");
                }
                this.hideContextMenu();
            });
        }

        if (btnClearLinks) {
            btnClearLinks.addEventListener("click", (e) => {
                e.stopPropagation();
                if (this.targetContextIndex > -1) {
                    store.clearHotspots(this.targetContextIndex);
                    notify("All links cleared", "info");
                }
                this.hideContextMenu();
            });
        }
    },

    showContextMenu(trigger, index) {
        this.targetContextIndex = index;
        this.contextMenu.classList.remove("hidden");
        this.contextMenu.classList.add("flex");
        this.contextMenu.style.zIndex = "20000"; // Ensure it's on top of everything

        // Get dimensions
        const menuRect = this.contextMenu.getBoundingClientRect();
        const menuWidth = menuRect.width;
        const menuHeight = menuRect.height;

        let top, left;

        if (trigger instanceof Event) {
            // Mouse Event (Right click)
            top = trigger.clientY;
            left = trigger.clientX;
        } else {
            // Element (Button click)
            const rect = trigger.getBoundingClientRect();
            // Position: Top-right of menu aligns with Bottom-right of button
            top = rect.bottom + 4;
            left = rect.right - menuWidth;
        }

        // Screen Boundary Protection
        const padding = 10;
        if (left + menuWidth > window.innerWidth - padding) {
            left = window.innerWidth - menuWidth - padding;
        }
        if (left < padding) {
            left = padding;
        }
        if (top + menuHeight > window.innerHeight - padding) {
            // Flip upwards if running off bottom
            if (trigger instanceof Element) {
                const rect = trigger.getBoundingClientRect();
                top = rect.top - menuHeight - 4;
            } else {
                top = top - menuHeight;
            }
        }

        this.contextMenu.style.left = `${left}px`;
        this.contextMenu.style.top = `${top}px`;
    },

    hideContextMenu() {
        this.contextMenu.classList.add("hidden");
        this.contextMenu.classList.remove("flex");
    },

    /**
     * Render the list of scenes.
     * 
     * @param {Object} state - The current application state.
     */
    render(state) {
        if (!this.container) return;

        if (state.scenes.length === 0) {
            this.container.innerHTML = `
                <div class="flex flex-col items-center justify-center py-24 px-8 text-center animate-fade-in">
                    <span class="material-icons text-6xl text-slate-100 mb-4 scale-110 drop-shadow-sm">image_not_supported</span>
                    <p class="text-sm font-black text-slate-300 leading-tight uppercase tracking-widest">No scenes loaded</p>
                    <p class="text-[10px] text-slate-400 mt-3 font-semibold max-w-[180px] mx-auto leading-relaxed">Upload 360 images above to start building your project.</p>
                </div>
            `;
            return;
        }

        // OPTIMIZATION: Use a DocumentFragment to minimize reflows
        const fragment = document.createDocumentFragment();

        state.scenes.forEach((scene, index) => {
            // Re-use or create thumbnail URL on the scene object itself to prevent memory leaks
            if (!scene._thumbUrl) {
                scene._thumbUrl = URL.createObjectURL(scene.file);
            }

            const item = this.createSceneItem(scene, index, state.activeIndex, state.scenes);
            fragment.appendChild(item);
        });

        this.container.innerHTML = "";
        this.container.appendChild(fragment);

        // Re-attach delegation listener - ensures it survives re-renders
        this.container.onmousedown = (e) => {
            const item = e.target.closest('.scene-item');
            if (!item) return;

            const index = parseInt(item.dataset.index);
            if (isNaN(index)) return;

            const isMoreBtn = e.target.closest('.scene-more-btn');

            if (isMoreBtn) {
                e.stopPropagation();
                e.preventDefault();

                const isAlreadyOpen = !this.contextMenu.classList.contains("hidden") && this.targetContextIndex === index;

                if (isAlreadyOpen) {
                    this.hideContextMenu();
                } else {
                    console.log(`[SceneList] Context menu triggered for index ${index}`);
                    this.showContextMenu(isMoreBtn, index);
                }
                return;
            }

            console.log(`[SceneList] mousedown delegation triggered for index ${index}`);

            // Force-disable any stuck processing UI
            const procUi = document.getElementById("processing-ui");
            if (procUi) procUi.style.display = "none";

            // Cancel any ongoing navigation or linking state
            cancelNavigation();
            if (store.state.isLinking) {
                store.state.isLinking = false;
                store.state.linkDraft = null;
            }

            // Perform selection with CUT transition (instant, no crossfade)
            store.setActiveTimelineStep(null);
            store.setActiveScene(index, 0, 0, { type: 'cut' });
        };
    },

    createSceneItem(scene, index, activeIndex, allScenes = []) {
        const item = document.createElement("div");
        const qualityScore = scene.quality?.score || 10.0;
        const isLowQuality = qualityScore < 6.5;
        const isActive = index === activeIndex;


        item.className = `scene-item group relative flex items-stretch bg-white border rounded-xl mb-3 overflow-hidden transition-all duration-200 select-none touch-pan-y shadow-sm hover:shadow-md ${isActive ? "border-remax-blue ring-1 ring-remax-blue shadow-remax-blue/5 scale-[1.02] z-10" : "border-slate-200"}`;
        item.draggable = true;

        if (isLowQuality) {
            item.classList.add("bg-red-50/50", "border-red-200");
        }

        const groupColor = getGroupColor(scene.colorGroup);

        item.dataset.index = index;
        item.innerHTML = `
        <!-- Thumbnail Section -->
        <div class="w-16 min-w-[64px] relative bg-slate-900 overflow-hidden cursor-pointer" id="thumb-${index}">
            <img src="${scene._thumbUrl}" class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110 opacity-90 group-hover:opacity-100" loading="lazy">
            <div class="absolute inset-0 bg-gradient-to-r from-black/20 to-transparent"></div>
            ${isActive ? '<div class="absolute inset-0 border-2 border-remax-blue/30 animate-pulse" style="pointer-events: none;"></div>' : ""}
            
            <!-- Index Badge -->
            <div class="absolute top-1 left-1 px-1.5 py-0.5 rounded-md bg-black/60 backdrop-blur-md text-[9px] font-black text-white/90 border border-white/10 z-10">
                ${index + 1}
            </div>

            <!-- Color Grouping Bar (Right Side) -->
            <div class="absolute top-0 right-0 h-full z-20 transition-colors duration-500" 
                 style="width: 6px; background-color: ${groupColor}"
                 title="Cluster Group: ${scene.colorGroup || 'None'}">
            </div>
        </div>

        <!-- Info Section -->
        <div class="flex-1 min-w-0 p-2.5 flex flex-col justify-center cursor-pointer" id="info-${index}">
            <div class="flex items-center justify-between mb-0.5">
                <h4 class="text-[11px] font-black ${isActive ? "text-remax-blue" : "text-slate-800"} truncate pr-2 uppercase tracking-tight">${scene.name}</h4>
                <div class="flex flex-col items-end gap-0.5 shrink-0">
                    <div class="flex items-center gap-1.5">
                        <span class="flex items-center gap-0.5 text-[10px] font-bold ${scene.hotspots.length > 0 ? "text-remax-blue" : "text-slate-300"} transition-colors">
                            <span class="material-icons text-[12px]">link</span>
                            <span class="text-[9px]">${scene.hotspots.length}</span>
                        </span>
                        ${isLowQuality ? '<span class="text-[10px]" title="Technical review recommended">🚩</span>' : ""}
                    </div>
                </div>
            </div>
            
            <div class="flex items-center justify-between mt-1">
                <div class="flex-1 pr-4">
                    <div class="w-full bg-slate-100 h-1 rounded-full overflow-hidden">
                        <div class="h-full ${isLowQuality ? "bg-red-400" : "bg-emerald-400"} transition-all duration-500" style="width: ${qualityScore * 10}%"></div>
                    </div>
                </div>
                <span class="text-[14px] font-black ${isLowQuality ? "text-red-500" : "text-slate-400"} uppercase tracking-tight leading-none">${qualityScore.toFixed(1)}</span>
            </div>
        </div>

        <!-- Drag Handle / Action Area -->
        <div class="w-10 flex flex-col items-center justify-center gap-1 border-l border-slate-50 bg-slate-50/30 group-hover:bg-slate-50 transition-colors">
             <button class="scene-more-btn w-6 h-6 rounded-lg flex items-center justify-center hover:bg-white hover:shadow-sm transition-all text-slate-300 hover:text-remax-blue" id="more-${index}">
                 <span class="material-icons text-sm">more_vert</span>
             </button>
             <div class="drag-handle w-5 h-7 flex flex-col justify-center gap-0.5 opacity-20 group-hover:opacity-40 cursor-grab active:cursor-grabbing">
                 <div class="w-full h-0.5 bg-slate-900 rounded-full"></div>
                 <div class="w-full h-0.5 bg-slate-900 rounded-full"></div>
                 <div class="w-full h-0.5 bg-slate-900 rounded-full"></div>
             </div>
        </div>
    `;

        // Interaction Events - NOW HANDLED BY DELEGATION IN RENDER()
        // Removed individual onclick handlers to prevent double-firing and improve performance.



        // Explicitly disable browser context menu
        item.oncontextmenu = (e) => {
            e.preventDefault();
            e.stopPropagation();
            return false;
        };

        // Drag-and-Drop Reordering Logic
        item.addEventListener("dragstart", (e) => {
            e.dataTransfer.setData("text/plain", index);
            item.classList.add("opacity-50", "scale-95");
            setTimeout(() => item.classList.add("invisible"), 0);
        });

        item.addEventListener("dragend", () => {
            item.classList.remove("opacity-50", "scale-95", "invisible");
        });

        item.addEventListener("dragover", (e) => {
            e.preventDefault();
            // Enhanced "Snapping" Visuals
            item.classList.add("ring-2", "ring-remax-blue", "z-30", "scale-[1.02]");
            item.style.backgroundColor = "rgba(0, 61, 165, 0.05)"; // Manual remax-blue/5
        });

        item.addEventListener("dragleave", () => {
            if (!isActive) {
                item.classList.remove("ring-2", "ring-remax-blue", "z-30", "scale-[1.02]");
                item.style.backgroundColor = ""; // Reset
            } else {
                // Determine if we need to reset based on active state logic if needed
                // For now, just reset the drag-specific overrides
                item.classList.remove("ring-2", "ring-remax-blue", "z-30");
                item.style.backgroundColor = "";
            }
        });

        item.addEventListener("drop", (e) => {
            e.preventDefault();
            item.classList.remove("ring-2", "ring-remax-blue", "z-30", "scale-[1.02]");
            item.style.backgroundColor = "";

            const fromIndex = parseInt(e.dataTransfer.getData("text/plain"));
            if (fromIndex !== index) {
                store.reorderScenes(fromIndex, index);
            }
        });

        return item;
    }
};
