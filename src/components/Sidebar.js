import { store } from "../store.js";
import { exportTour } from "../systems/Exporter.js";
import { startAutoTeaser } from "../systems/TeaserSystem.js";
import { saveProject, loadProject } from "../systems/ProjectManager.js";
import { VERSION, BUILD_INFO } from "../version.js";
import { DownloadSystem } from "../systems/DownloadSystem.js";
import { UploadProcessor } from "../systems/UploadProcessor.js";
import { UploadReport } from "./UploadReport.js";
import { SceneList } from "./SceneList.js";
import { getIsSimulationMode } from "../systems/NavigationSystem.js";

export function initSidebar() {
    const container = document.getElementById("sidebar");
    const topBar = document.getElementById("top-bar");
    if (!container || !topBar) return;

    // 1. Deactivate Top Bar (Migrated to Sidebar)
    topBar.style.display = "none";

    // 2. Inject Sidebar HTML (Tailwind optimized)
    container.className = "relative w-[320px] min-w-[320px] bg-white flex flex-col z-[15000] shrink-0 h-full overflow-hidden font-ui shadow-2xl";

    container.innerHTML = `
        <!-- Sidebar Branding Header -->
        <div class="relative w-full flex flex-col z-30 text-white shrink-0" style="border-top: 2px solid #dc3545; background: linear-gradient(to bottom, #001a38 0%, #002a70 50%, #003da5 100%);">
            
            <!-- Header Content - Premium Sizing -->
            <div class="flex flex-col items-center px-5 pb-4" style="padding-top: 23px;">
                <!-- House Icon - Top Centered with Extra Padding -->
                <span class="material-icons text-white drop-shadow-lg mb-0.5 mt-1" style="font-size: 36px;">home</span>
                <!-- Brand Title -->
                <h1 class="font-black text-white tracking-tight drop-shadow-sm text-center" style="font-size: 24px;">Virtual Tour Builder</h1>
                <!-- Version Info -->
                <div class="flex items-center gap-2 text-white/50">
                    <span class="text-[11px] font-bold">v${VERSION}</span>
                    <span class="text-[11px]">•</span>
                    <span class="text-[11px] font-medium">${BUILD_INFO}</span>
                </div>
            </div>
            
            <!-- Direct Action Buttons Grid -->
            <style>
                .sidebar-action-btn {
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    gap: 2px;
                    padding: 10px 4px;
                    background: rgba(255,255,255,0.08);
                    border: none;
                    border-radius: 10px;
                    color: white;
                    cursor: pointer;
                    transition: all 0.15s ease;
                    box-shadow: 
                        0 2px 4px rgba(0,0,0,0.3),
                        inset 0 1px 0 rgba(255,255,255,0.08);
                }
                .sidebar-action-btn:hover {
                    background: rgba(255,255,255,0.15);
                    transform: translateY(-2px);
                    box-shadow: 
                        0 4px 12px rgba(0,0,0,0.4),
                        inset 0 1px 0 rgba(255,255,255,0.12);
                }
                .sidebar-action-btn:active {
                    transform: translateY(1px);
                    background: rgba(255,255,255,0.05);
                    box-shadow: 
                        inset 0 2px 6px rgba(0,0,0,0.3);
                }
                .sidebar-action-btn:disabled {
                    cursor: not-allowed;
                    filter: grayscale(100%);
                    opacity: 0.3 !important;
                }
                .sidebar-action-btn .material-icons {
                    font-size: 22px;
                    opacity: 0.95;
                }
                .sidebar-action-btn span:last-child {
                    font-size: 9px;
                    font-weight: 700;
                    text-transform: uppercase;
                    letter-spacing: 0.04em;
                    opacity: 0.7;
                }
                .sidebar-action-btn-wide {
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    gap: 8px;
                    padding: 10px 12px;
                    background: rgba(255,255,255,0.08);
                    border: none;
                    border-radius: 10px;
                    color: white;
                    cursor: pointer;
                    transition: all 0.15s ease;
                    box-shadow: 
                        0 2px 4px rgba(0,0,0,0.3),
                        inset 0 1px 0 rgba(255,255,255,0.08);
                }
                .sidebar-action-btn-wide:hover:not(:disabled) {
                    background: rgba(255,255,255,0.15);
                    transform: translateY(-2px);
                    box-shadow: 
                        0 4px 12px rgba(0,0,0,0.4),
                        inset 0 1px 0 rgba(255,255,255,0.12);
                }
                .sidebar-action-btn-wide:active:not(:disabled) {
                    transform: translateY(1px);
                    background: rgba(255,255,255,0.05);
                    box-shadow: 
                        inset 0 2px 6px rgba(0,0,0,0.3);
                }
                .sidebar-action-btn-wide .material-icons {
                    font-size: 18px;
                    opacity: 0.95;
                }
                .sidebar-action-btn-wide span:last-child {
                    font-size: 11px;
                    font-weight: 700;
                    text-transform: uppercase;
                    letter-spacing: 0.04em;
                }
                .sidebar-action-btn-wide:disabled {
                    cursor: not-allowed;
                    filter: grayscale(100%);
                    opacity: 0.4 !important;
                }

                /* Premium Modal Styling */
                .modal-box-premium {
                    background: linear-gradient(to bottom, #001a38 0%, #002a70 50%, #003da5 100%) !important;
                    border: 1px solid rgba(255, 255, 255, 0.1) !important;
                    color: white !important;
                    padding: 24px 24px !important;
                    border-radius: 20px !important;
                    text-align: center;
                    box-shadow: 0 30px 60px -12px rgba(0, 0, 0, 0.6) !important;
                    width: 100%;
                    max-width: 340px;
                }
                .modal-box-premium h2, .modal-box-premium h3 {
                    color: white !important;
                    font-family: var(--font-heading) !important;
                    margin-bottom: 8px !important;
                }
                .modal-box-premium p {
                    color: rgba(255, 255, 255, 0.7) !important;
                    font-size: 13px !important;
                    line-height: 1.5 !important;
                    margin-bottom: 24px !important;
                }
                .modal-btn-premium {
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    gap: 10px;
                    padding: 14px 16px;
                    background: rgba(255, 255, 255, 0.08);
                    border: none;
                    border-radius: 12px;
                    color: white;
                    cursor: pointer;
                    transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
                    font-family: var(--font-ui);
                    font-weight: 700;
                    font-size: 12px;
                    text-transform: uppercase;
                    letter-spacing: 0.04em;
                    box-shadow: 
                        0 4px 6px rgba(0, 0, 0, 0.2),
                        inset 0 1px 0 rgba(255, 255, 255, 0.1);
                }
                .modal-btn-premium:hover {
                    background: rgba(255, 255, 255, 0.15);
                    transform: translateY(-2px);
                    box-shadow: 
                        0 8px 15px rgba(0, 0, 0, 0.3),
                        inset 0 1px 0 rgba(255, 255, 255, 0.15);
                }
                .modal-btn-premium:active {
                    transform: translateY(1px);
                    background: rgba(255, 255, 255, 0.05);
                    box-shadow: inset 0 2px 5px rgba(0, 0, 0, 0.3);
                }
                .modal-btn-premium.btn-blue {
                    background: #1e40af; /* Darker Blue */
                    border: 1px solid rgba(255, 255, 255, 0.1);
                }
                .modal-btn-premium.btn-blue:hover {
                    background: #3b82f6; /* Lightens up */
                }
                .modal-btn-premium.btn-teal {
                    background: #0d9488; /* Teal 600 */
                    border: 1px solid rgba(255, 255, 255, 0.1);
                }
                .modal-btn-premium.btn-teal:hover {
                    background: #14b8a6; /* Teal 500 - Brighter */
                }
                .modal-btn-premium.btn-red {
                    background: #9b1c2e; /* Darker RE/MAX Red */
                    border: 1px solid rgba(255, 255, 255, 0.1);
                }
                .modal-btn-premium.btn-red:hover {
                    background: #dc3545; /* True RE/MAX Red */
                }
                .modal-btn-premium.btn-green {
                    background: #065f46; /* Darker Green */
                    border: 1px solid rgba(255, 255, 255, 0.1);
                }
                .modal-btn-premium.btn-green:hover {
                    background: #10b981; /* Lightens up */
                }
                .modal-btn-premium.btn-orange {
                    background: #c2410c; /* Darker Orange */
                    border: 1px solid rgba(255, 255, 255, 0.1);
                }
                .modal-btn-premium.btn-orange:hover {
                    background: #f97316; /* Bright Orange */
                }
                .modal-btn-premium.btn-purple {
                    background: #7e22ce; /* Purple 700 */
                    border: 1px solid rgba(255, 255, 255, 0.1);
                }
                .modal-btn-premium.btn-purple:hover {
                    background: #a855f7; /* Purple 500 - Brighter */
                }
                .modal-btn-premium.btn-secondary {
                    background: transparent;
                    border: 1px solid rgba(255, 255, 255, 0.1);
                    opacity: 0.7;
                    box-shadow: none;
                }
                .modal-btn-premium.btn-secondary:hover {
                    opacity: 1;
                    background: rgba(255, 255, 255, 0.05);
                }
            </style>
            <div style="padding: 0 16px 14px 16px;">
                <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 6px;">
                    <button id="btn-new-project" class="sidebar-action-btn" title="New Project">
                        <span class="material-icons">note_add</span>
                        <span>New</span>
                    </button>
                    <button id="btn-save-project" class="sidebar-action-btn" title="Save Project">
                        <span class="material-icons">save</span>
                        <span>Save</span>
                    </button>
                    <button id="btn-load-project" class="sidebar-action-btn" title="Load Project">
                        <span class="material-icons">folder_open</span>
                        <span>Load</span>
                    </button>
                    <button id="btn-about" class="sidebar-action-btn" title="About App">
                        <span class="material-icons">info</span>
                        <span>About</span>
                    </button>
                </div>
                <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 6px; margin-top: 6px;">
                    <button id="btn-export" class="sidebar-action-btn-wide" disabled title="Export Tour" style="opacity: 0.4;">
                        <span class="material-icons" style="color: #10b981;">inventory_2</span>
                        <span>Export</span>
                    </button>
                    <button id="btn-teaser" class="sidebar-action-btn-wide" disabled title="Auto-Teaser" style="opacity: 0.4;">
                        <span class="material-icons" style="color: #f97316;">movie</span>
                        <span>Teaser</span>
                    </button>
                </div>
            </div>

            <input type="file" id="project-file-input" accept=".zip,.vt.zip" hidden>
        </div>

        <!-- Sidebar Body: Project Name & Upload -->
        <div class="flex flex-col bg-slate-50 border-b border-slate-200 shadow-sm shrink-0">
            <div class="p-4 pt-5 pb-3">
                <div class="flex items-center justify-between mb-1.5 px-1">
                    <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Project Name</label>
                    <span class="text-[9px] font-bold text-remax-blue/60 uppercase">Draft Mode</span>
                </div>
                <input type="text" id="tour-name-input" value="" 
                    placeholder="Tour Name..." 
                    class="w-full px-3 h-10 bg-white border border-slate-200 rounded-lg font-ui font-normal text-[10px] text-slate-700 focus:outline-none focus:ring-2 focus:ring-remax-blue/10 focus:border-remax-blue transition-all truncate shadow-sm placeholder:text-slate-300">
            </div>
            
            <div class="px-4 pb-4">
                <label class="w-full h-10 bg-white border border-slate-200 rounded-lg flex items-center justify-center gap-2.5 cursor-pointer transition-all hover:bg-remax-blue hover:text-white hover:border-remax-blue hover:shadow-lg hover:shadow-remax-blue/20 group active:scale-95 shadow-sm overflow-hidden" id="upload-label">
                    <div class="w-6 h-6 rounded-full bg-remax-blue/10 flex items-center justify-center group-hover:bg-white/20 transition-colors">
                        <span class="material-icons text-[15px] text-remax-blue group-hover:text-white transition-colors">cloud_upload</span>
                    </div>
                    <strong class="text-[11px] font-bold tracking-tight text-slate-600 group-hover:text-white">Upload 360 Images</strong>
                    <input type="file" id="file-input" multiple accept="image/*" hidden>
                </label>
            </div>
        </div>

        <!-- Sidebar Content Area -->
        <div class="sidebar-content flex-1 overflow-y-auto overflow-x-hidden hide-scrollbar flex flex-col bg-white">
            <!-- Processing UI -->
            <div id="processing-ui" class="hidden m-4 bg-white border border-slate-100 rounded-xl p-4 shadow-xl ring-1 ring-remax-blue/5">
                <div class="flex items-center justify-between mb-3">
                    <div class="flex items-center gap-2">
                        <div id="progress-spinner" class="w-3 h-3 border-2 border-slate-100 border-t-remax-blue rounded-full animate-spin"></div>
                        <div id="progress-title" class="font-bold text-slate-800 text-[10px] uppercase tracking-wide">Processing</div>
                    </div>
                    <div id="progress-percentage" class="font-black text-remax-blue text-xs font-heading">0%</div>
                </div>
                <div class="bg-slate-100 h-1.5 rounded-full overflow-hidden relative">
                    <div id="progress-bar" class="w-0 h-full bg-remax-blue transition-all duration-300 rounded-full relative">
                         <div class="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-shimmer"></div>
                    </div>
                </div>
                <div id="progress-text" class="text-[9px] text-slate-400 mt-2 font-bold uppercase tracking-tighter flex items-center gap-1.5">
                    <span class="w-1 h-1 bg-remax-success rounded-full animate-pulse"></span>
                    <span id="progress-text-content">System Ready</span>
                </div>
            </div>

            <div id="scene-list-container" class="p-3 pt-4 flex-1"></div>
        </div>



        <!-- TEASER STYLE MODAL -->
        <div id="style-modal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.7); backdrop-filter:blur(12px); z-index:11000; justify-content:center; align-items:center; padding:16px; transition:opacity 0.3s ease-in-out; opacity:0;">
            <div class="modal-box-premium" style="transform:scale(0.95); transition:all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);">
                <div style="margin-bottom: 12px;">
                    <span class="material-icons" style="font-size: 40px; color: #f97316; filter: drop-shadow(0 0 12px rgba(249, 115, 22, 0.4));">movie</span>
                </div>
                <h3 style="margin-top:0; font-size: 20px; font-weight: 800; letter-spacing: -0.02em;">Select Teaser Style</h3>
                <p>Choose how the video should be recorded.</p>
                
                <label style="display:flex; align-items:center; justify-content:center; gap:8px; margin-bottom:12px; font-size:12px; font-weight:600; color:rgba(255,255,255,0.8); cursor:pointer;">
                    <input type="checkbox" id="chk-teaser-watermark" checked style="width:16px; height:16px; border-radius:4px; accent-color: #3b82f6;">
                    Include logo watermark
                </label>
                
                <div style="margin-bottom:16px; padding:12px; border-radius:12px; border:1px solid rgba(255,255,255,0.1); background:rgba(255,255,255,0.05); text-align:left;">
                    <div style="font-size:10px; font-weight:800; color:rgba(255,255,255,0.4); text-transform:uppercase; letter-spacing:0.1em; margin-bottom:8px;">Choose Video Format:</div>
                    <select id="sel-teaser-format" style="width:100%; height: 36px; background:rgba(0,0,0,0.3); border:1px solid rgba(255,255,255,0.1); border-radius:8px; padding:0 12px; font-weight:700; color:white; font-size:11px; outline:none; cursor:pointer;">
                        <option value="webm">WebM (Standard - Faster)</option>
                        <option value="mp4">MP4 (Experimental - High Quality)</option>
                    </select>
                    <p style="font-size:9px; color:rgba(255,255,255,0.4); margin-top: 8px; margin-bottom: 0; line-height:1.2;">Note: MP4 encoding happens in-browser and is hardware intensive.</p>
                </div>

                <label style="display:flex; align-items:center; justify-content:center; gap:8px; margin-bottom:12px; font-size:12px; font-weight:600; color:rgba(255,255,255,0.8); cursor:pointer;">
                    <input type="checkbox" id="chk-teaser-skip-auto" checked style="width:16px; height:16px; border-radius:4px; accent-color: #3b82f6;">
                    Skip Auto-Forward Scenes
                </label>

                
                <div style="display: flex; flex-direction: column; gap: 8px;">
                    <button id="btn-style-dissolve" class="modal-btn-premium btn-teal" style="width: 100%; flex-direction: column; padding: 12px;">
                        <span style="font-size: 13px;">Cross Dissolve Scenes</span>
                        <span style="font-size: 12px; opacity: 0.6; text-transform: none; font-weight: 500;">Micro-panning with smooth transitions</span>
                    </button>
                    
                    <button id="btn-style-punchy" class="modal-btn-premium btn-orange" style="width: 100%; flex-direction: column; padding: 12px;">
                        <span style="font-size: 13px;">Fast Cut Scenes</span>
                        <span style="font-size: 12px; opacity: 0.6; text-transform: none; font-weight: 500;">Fast, dynamic cuts focused on links</span>
                    </button>
                    
                    <button id="btn-style-cinematic" class="modal-btn-premium btn-purple" style="width: 100%; flex-direction: column; padding: 12px;">
                        <span style="font-size: 13px;">Cinematic Scenes</span>
                        <span style="font-size: 12px; opacity: 0.6; text-transform: none; font-weight: 500;">Exact recording of simulation path</span>
                    </button>
                </div>
                
                <button id="btn-close-style" class="modal-btn-premium btn-secondary" style="width:100%; margin-top: 16px;">
                    Dismiss
                </button>
            </div>
        </div>

        <!-- NEW PROJECT MODAL -->
        <div id="new-project-modal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.7); backdrop-filter:blur(12px); z-index:11000; justify-content:center; align-items:center; padding:16px; transition:opacity 0.3s ease-in-out; opacity:0;">
            <div class="modal-box-premium" style="transform:scale(0.95); transition:all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);">
                <div style="margin-bottom: 20px;">
                    <span class="material-icons" style="font-size: 48px; color: #3b82f6; filter: drop-shadow(0 0 12px rgba(59, 130, 246, 0.4));">construction</span>
                </div>
                <h2 style="margin-top:0; font-size: 22px; font-weight: 800; letter-spacing: -0.02em;">Start New Project?</h2>
                <p>Your current virtual tour will be cleared. Do you want to save it first or start fresh?</p>
                
                <div style="display:grid; grid-template-columns: 1fr; gap: 10px; margin-bottom: 12px;">
                    <button id="btn-new-save" class="modal-btn-premium btn-green">
                        <span class="material-icons" style="font-size: 18px;">save</span>
                        <span>Save & Start New</span>
                    </button>
                    <button id="btn-new-discard" class="modal-btn-premium btn-red">
                        <span class="material-icons" style="font-size: 18px;">delete_forever</span>
                        <span>Discard All Changes</span>
                    </button>
                    <button id="btn-new-cancel" class="modal-btn-premium btn-blue">
                        <span class="material-icons" style="font-size: 18px;">edit</span>
                        <span>Continue Editing</span>
                    </button>
                </div>
            </div>
        </div>

        <!-- ABOUT MODAL -->
        <div id="about-modal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.7); backdrop-filter:blur(12px); z-index:11000; justify-content:center; align-items:center; padding:16px; transition:opacity 0.3s ease-in-out; opacity:0;">
            <div class="modal-box-premium" style="transform:scale(0.95); transition:all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1); max-width: 320px;">
                <div style="margin-bottom: 20px;">
                    <span class="material-icons" style="font-size: 56px; color: #3b82f6; filter: drop-shadow(0 0 15px rgba(59, 130, 246, 0.5));">home</span>
                </div>
                <h2 style="margin-top:0; font-size: 24px; font-weight: 800; letter-spacing: -0.02em;">Tour Builder</h2>
                
                <div style="margin: 24px 0; padding: 20px; background: rgba(255,255,255,0.05); border-radius: 16px; border: 1px solid rgba(255,255,255,0.1); text-align: left;">
                    <div style="margin-bottom: 16px;">
                        <span style="font-size: 10px; font-weight: 800; color: rgba(255,255,255,0.4); text-transform: uppercase; letter-spacing: 0.05em; display: block;">Developer</span>
                        <span style="font-size: 15px; font-weight: 700; color: white;">Arto Kalishian</span>
                    </div>
                    <div style="margin-bottom: 16px;">
                        <span style="font-size: 10px; font-weight: 800; color: rgba(255,255,255,0.4); text-transform: uppercase; letter-spacing: 0.05em; display: block;">Release Date</span>
                        <span style="font-size: 15px; font-weight: 700; color: white;">December 30, 2025</span>
                    </div>
                    <div>
                        <span style="font-size: 10px; font-weight: 800; color: rgba(255,255,255,0.4); text-transform: uppercase; letter-spacing: 0.05em; display: block;">Current Version</span>
                        <span style="font-size: 15px; font-weight: 700; color: white;">v${VERSION}</span>
                        <span style="font-size: 11px; font-weight: 500; color: rgba(255,255,255,0.6); display: block; margin-top: 4px;">${BUILD_INFO}</span>
                    </div>
                </div>
                
                <button id="btn-close-about" class="modal-btn-premium btn-blue" style="width:100%;">
                    <span>Close</span>
                </button>
            </div>
        </div>

        <!-- LOAD CONFIRMATION MODAL -->
        <div id="load-confirm-modal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.7); backdrop-filter:blur(12px); z-index:11000; justify-content:center; align-items:center; padding:16px; transition:opacity 0.3s ease-in-out; opacity:0;">
            <div class="modal-box-premium" style="transform:scale(0.95); transition:all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);">
                <div style="margin-bottom: 20px;">
                    <span class="material-icons" style="font-size: 48px; color: #f97316; filter: drop-shadow(0 0 12px rgba(249, 115, 22, 0.4));">folder_open</span>
                </div>
                <h2 style="margin-top:0; font-size: 22px; font-weight: 800; letter-spacing: -0.02em;">Load Project?</h2>
                <p>Loading will replace your current work. Any unsaved changes will be lost.</p>
                
                <div style="display:grid; grid-template-columns: 1fr; gap: 10px; margin-bottom: 12px;">
                    <button id="btn-load-continue" class="modal-btn-premium btn-orange">
                        <span class="material-icons" style="font-size: 18px;">check</span>
                        <span>Continue</span>
                    </button>
                    <button id="btn-load-cancel" class="modal-btn-premium btn-secondary">
                        <span>Cancel</span>
                    </button>
                </div>
            </div>
        </div>
    `;

    // Action buttons are now directly visible - no menu toggle needed

    // --- CONTEXT MENU CREATION (Moved to Body) ---
    const existingMenu = document.getElementById("context-menu");
    if (existingMenu) existingMenu.remove();

    const contextMenu = document.createElement("div");
    contextMenu.id = "context-menu";
    contextMenu.className = "hidden fixed z-[10000] bg-white border border-slate-200 rounded-xl shadow-2xl p-1.5 min-w-[180px] flex-col divide-y divide-slate-100 font-ui transform transition-all duration-100 ease-out origin-top-right";
    contextMenu.innerHTML = `
        <div id="btn-clear-links" class="px-3 py-2.5 cursor-pointer text-slate-600 font-bold text-[10px] uppercase tracking-wider hover:bg-blue-50 hover:text-remax-blue rounded-lg transition-all flex items-center justify-between group">
            <div class="flex items-center gap-2.5">
                <span class="material-icons text-[14px]">link_off</span>
                <span>Clear Links</span>
            </div>
        </div>
        <div id="btn-delete-scene" class="px-3 py-2.5 cursor-pointer text-slate-500 font-bold text-[10px] uppercase tracking-wider hover:bg-red-50 hover:text-remax-red rounded-lg transition-all flex items-center justify-between group mt-0.5">
            <div class="flex items-center gap-2.5">
                <span class="material-icons text-[14px]">delete_outline</span>
                <span>Remove</span>
            </div>
        </div>
  `;
    document.body.appendChild(contextMenu);

    // --- ELEMENTS ---
    const fileInput = document.getElementById("file-input");
    const tourNameInput = document.getElementById("tour-name-input");
    const processingUi = document.getElementById("processing-ui");
    const progressTitle = document.getElementById("progress-title");
    const progressBar = document.getElementById("progress-bar");
    const progressText = document.getElementById("progress-text");
    const list = document.getElementById("scene-list-container");
    // contextMenu is already defined above
    const btnDelete = document.getElementById("btn-delete-scene");
    const btnClearLinks = document.getElementById("btn-clear-links");

    // Buttons
    const btnExport = document.getElementById("btn-export");
    const btnTeaser = document.getElementById("btn-teaser");
    const btnNewProject = document.getElementById("btn-new-project");
    const btnSaveProject = document.getElementById("btn-save-project");
    const btnLoadProject = document.getElementById("btn-load-project");
    const btnAbout = document.getElementById("btn-about");
    const projectFileInput = document.getElementById("project-file-input");
    const viewerContainer = document.getElementById("viewer-container");
    const placeholderText = document.getElementById("placeholder-text");

    // Logger, NotificationSystem, and ProgressBar are now in src/utils/
    // They are initialized in main.js before this component loads



    // --- COMPONENT INITIALIZATION ---
    SceneList.init(list, contextMenu);

    // --- MODAL HELPERS ---
    const styleModal = document.getElementById("style-modal");
    const btnStyleDissolve = document.getElementById("btn-style-dissolve");
    const btnStylePunchy = document.getElementById("btn-style-punchy");
    const btnStyleCinematic = document.getElementById("btn-style-cinematic");
    const btnCloseStyle = document.getElementById("btn-close-style");
    const chkTeaserWatermark = document.getElementById("chk-teaser-watermark");
    const chkTeaserSkipAuto = document.getElementById("chk-teaser-skip-auto");
    const selTeaserFormat = document.getElementById("sel-teaser-format");

    const newProjectModal = document.getElementById("new-project-modal");
    const btnNewSave = document.getElementById("btn-new-save");
    const btnNewDiscard = document.getElementById("btn-new-discard");
    const btnNewCancel = document.getElementById("btn-new-cancel");

    const aboutModal = document.getElementById("about-modal");
    const btnCloseAbout = document.getElementById("btn-close-about");

    const loadConfirmModal = document.getElementById("load-confirm-modal");
    const btnLoadContinue = document.getElementById("btn-load-continue");
    const btnLoadCancel = document.getElementById("btn-load-cancel");

    const showModal = (el) => {
        el.style.display = "flex";
        setTimeout(() => { el.style.opacity = "1"; }, 10);
    };
    const hideModal = (el) => {
        el.style.opacity = "0";
        setTimeout(() => { el.style.display = "none"; }, 300);
    };

    if (btnTeaser) {
        btnTeaser.addEventListener("click", () => showModal(styleModal));
    }
    if (btnCloseStyle) {
        btnCloseStyle.addEventListener("click", () => hideModal(styleModal));
    }
    if (btnStyleDissolve) {
        btnStyleDissolve.addEventListener("click", () => {
            hideModal(styleModal);
            const includeLogo = chkTeaserWatermark ? chkTeaserWatermark.checked : true;
            const skipAuto = chkTeaserSkipAuto ? chkTeaserSkipAuto.checked : true;
            const format = selTeaserFormat ? selTeaserFormat.value : "webm";
            startAutoTeaser("dissolve", includeLogo, format, skipAuto);
        });
    }
    if (btnStylePunchy) {
        btnStylePunchy.addEventListener("click", () => {
            hideModal(styleModal);
            const includeLogo = chkTeaserWatermark ? chkTeaserWatermark.checked : true;
            const skipAuto = chkTeaserSkipAuto ? chkTeaserSkipAuto.checked : true;
            const format = selTeaserFormat ? selTeaserFormat.value : "webm";
            startAutoTeaser("punchy", includeLogo, format, skipAuto);
        });
    }

    if (btnStyleCinematic) {
        btnStyleCinematic.addEventListener("click", () => {
            hideModal(styleModal);
            const includeLogo = chkTeaserWatermark ? chkTeaserWatermark.checked : true;
            const skipAuto = chkTeaserSkipAuto ? chkTeaserSkipAuto.checked : true;
            const format = selTeaserFormat ? selTeaserFormat.value : "webm";
            startAutoTeaser("cinematic", includeLogo, format, skipAuto); // Note: Cinematic might ignore this if it follows simulation exactly, but passing for consistency
        });
    }



    // --- CORE EVENTS ---

    // Smart content-based font sizing for Project ID input
    // Scales font down when text is long to fit more content
    function adjustInputFontSize() {
        const input = tourNameInput;
        const text = input.value || input.placeholder;
        const containerWidth = input.offsetWidth - 24; // Subtract padding (12px * 2)

        // Calculate approximate character width at 16px
        const baseCharWidth = 9; // Average character width in Inter font at 16px
        const maxCharsAt16px = Math.floor(containerWidth / baseCharWidth);

        // Determine optimal font size based on text length
        let fontSize;
        if (text.length <= maxCharsAt16px) {
            fontSize = 16; // Full size when text fits
        } else if (text.length <= maxCharsAt16px * 1.15) {
            fontSize = 15; // Slightly smaller
        } else if (text.length <= maxCharsAt16px * 1.3) {
            fontSize = 14; // WCAG minimum
        } else {
            fontSize = 14; // Never go below 14px (WCAG compliant)
        }

        input.style.fontSize = `${fontSize}px`;

        // Also adjust placeholder font size
        if (text === input.placeholder) {
            input.style.fontSize = '14px'; // Smaller placeholder for long text
        }
    }

    // Update on input
    tourNameInput.addEventListener("input", (e) => {
        store.setTourName(e.target.value);
        e.target.title = e.target.value || "Click to edit project name";
        adjustInputFontSize();
    });

    // Adjust on load and window resize
    adjustInputFontSize();
    window.addEventListener('resize', adjustInputFontSize);

    fileInput.addEventListener("change", async (e) => {
        const files = Array.from(e.target.files);
        if (files.length === 0) return;

        const result = await UploadProcessor.processUploads(files, (pct, msg, isProc, phase) => {
            window.updateProgressBar(pct, msg, isProc, phase);
        });

        fileInput.value = "";

        // Show Report Dialog
        UploadReport.show(store.state.lastUploadReport, result.qualityResults);
    });


    // Context menu actions are now handled in SceneList.js

    btnExport.addEventListener("click", async () => {
        btnExport.disabled = true;
        window.updateProgressBar(0, "Initializing Export...", true, "Exporting...");
        await exportTour(store.state.scenes, (done, total, message) => {
            window.updateProgressBar(Math.round((done / total) * 100), message);
        });
        window.updateProgressBar(100, "Export Complete!", true);
        btnExport.disabled = false;
    });

    btnNewProject.addEventListener("click", () => {
        if (store.state.scenes.length === 0) { location.reload(); return; }
        showModal(newProjectModal);
    });

    btnNewSave.addEventListener("click", async () => {
        hideModal(newProjectModal);
        try {
            await saveProject(store.state, (pct, total, message) => window.updateProgressBar(pct, message, true, "Saving Project..."));
            window.notify("Project saved! Starting new project...", "success");
            setTimeout(() => location.reload(), 1500);
        } catch (err) {
            if (err.message === 'USER_CANCELLED') window.notify("Save cancelled.", "info");
            else window.notify("Save failed.", "error");
            window.updateProgressBar(0, "", false);
        }
    });

    btnNewDiscard.addEventListener("click", () => { hideModal(newProjectModal); location.reload(); });
    btnNewCancel.addEventListener("click", () => hideModal(newProjectModal));

    btnSaveProject.addEventListener("click", async () => {
        if (store.state.scenes.length === 0) { window.notify("Nothing to save.", "warning"); return; }
        try {
            btnSaveProject.disabled = true;
            await saveProject(store.state, (pct, total, message) => window.updateProgressBar(pct, message, true, "Saving Project..."));
        } catch (error) {
            if (error.message === 'USER_CANCELLED') window.notify("Save cancelled.", "info");
            else window.notify("Failed to save: " + error.message, "error");
        }
        finally { window.updateProgressBar(0, "", false); btnSaveProject.disabled = false; }
    });

    if (btnAbout) {
        btnAbout.addEventListener("click", () => showModal(aboutModal));
    }
    if (btnCloseAbout) {
        btnCloseAbout.addEventListener("click", () => hideModal(aboutModal));
    }

    // Load confirmation modal handlers
    if (btnLoadContinue) {
        btnLoadContinue.addEventListener("click", () => {
            hideModal(loadConfirmModal);
            projectFileInput.click();
        });
    }
    if (btnLoadCancel) {
        btnLoadCancel.addEventListener("click", () => hideModal(loadConfirmModal));
    }

    btnLoadProject.addEventListener("click", () => {
        if (store.state.scenes.length > 0) {
            showModal(loadConfirmModal);
            return;
        }
        projectFileInput.click();
    });

    projectFileInput.addEventListener("change", async (e) => {
        const file = e.target.files[0];
        if (!file) return;
        try {
            btnLoadProject.disabled = true;
            const loadedData = await loadProject(file, (pct, total, message) => window.updateProgressBar(pct, message, true, "Loading Project..."));
            store.loadProject(loadedData);
            if (loadedData.scenes.length > 0) store.setActiveScene(store.state.activeIndex, 0, 0);
            window.updateProgressBar(100, `✅ Loaded!`, true, "Project Ready");
        } catch (err) { window.notify("Load failed: " + err.message, "error"); }
        finally { window.updateProgressBar(0, "", false); btnLoadProject.disabled = false; }
        projectFileInput.value = "";
    });

    // --- STORE SUBSCRIPTION ---
    let lastSceneCount = -1;
    let lastActiveIndex = -1;
    let lastHotspotDataStr = "";
    let lastIsLinkingGlobal = false;
    let lastIsSimGlobal = false;

    const updateSidebar = (state) => {
        // 1. Sync Project Name (Always do this first, even if no scenes)
        if (tourNameInput && state.tourName !== tourNameInput.value) {
            console.log(`🔄 [Sidebar] Syncing input value to: "${state.tourName}"`);
            tourNameInput.value = state.tourName || "";
            if (typeof adjustInputFontSize === 'function') adjustInputFontSize();
        }

        if (viewerContainer) {
            if (state.isLinking) viewerContainer.classList.add("linking-mode");
            else viewerContainer.classList.remove("linking-mode");
        }

        if (state.scenes.length === 0) {
            list.innerHTML = `
        <div class="flex flex-col items-center justify-center py-24 px-8 text-center animate-fade-in">
            <span class="material-icons text-6xl text-slate-100 mb-4 scale-110 drop-shadow-sm">image_not_supported</span>
            <p class="text-sm font-black text-slate-300 leading-tight uppercase tracking-widest">No scenes loaded</p>
            <p class="text-[10px] text-slate-400 mt-3 font-semibold max-w-[180px] mx-auto leading-relaxed">Upload 360 images above to start building your project.</p>
        </div>
      `;
            btnExport.disabled = true; btnExport.style.opacity = 0.5;
            btnTeaser.disabled = true; btnTeaser.style.opacity = 0.5;
            btnSaveProject.disabled = true; btnSaveProject.style.opacity = 0.5;
            tourNameInput.disabled = true; tourNameInput.style.opacity = 0.5;
            lastSceneCount = 0;
            if (placeholderText) placeholderText.style.display = "flex";
            return;
        }

        // Hide Placeholder
        if (placeholderText) placeholderText.style.display = "none";

        // Restore states when images are present
        tourNameInput.disabled = false; tourNameInput.style.opacity = 1;
        btnSaveProject.disabled = false; btnSaveProject.style.opacity = 1;

        const currentHotspotDataStr = JSON.stringify(state.scenes.map(s => s.hotspots.length));
        const totalHotspots = state.scenes.reduce((acc, s) => acc + s.hotspots.length, 0);
        const teaserReady = totalHotspots >= 3;
        const exportReady = totalHotspots > 0;

        if (teaserReady) { btnTeaser.disabled = false; btnTeaser.style.opacity = 1; }
        else { btnTeaser.disabled = true; btnTeaser.style.opacity = 0.5; }

        if (exportReady) { btnExport.disabled = false; btnExport.style.opacity = 1; }
        else { btnExport.disabled = true; btnExport.style.opacity = 0.5; }

        if (state.scenes.length === lastSceneCount &&
            state.activeIndex === lastActiveIndex &&
            currentHotspotDataStr === lastHotspotDataStr &&
            state.isLinking === lastIsLinkingGlobal &&
            getIsSimulationMode() === lastIsSimGlobal) return;

        lastSceneCount = state.scenes.length;
        lastActiveIndex = state.activeIndex;
        lastHotspotDataStr = currentHotspotDataStr;
        lastIsLinkingGlobal = state.isLinking;
        lastIsSimGlobal = getIsSimulationMode();

        // Delegate scene list rendering to specialized component
        SceneList.render(state);
    };

    store.subscribe(updateSidebar);
    updateSidebar(store.state);
}
