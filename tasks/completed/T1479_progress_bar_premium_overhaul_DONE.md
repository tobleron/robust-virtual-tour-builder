# T1479 — Progress Bar Premium Overhaul

## Objective
Make the sidebar progress bar **phase-aware**, **monotonically advancing**, and **premium-feeling** during all long-running operations (Export, Upload, Save, Teaser). The user should always understand *what* is happening and *how far along* the operation is, with no 0→100 jumps, no repetitive oscillating language, and no dead-looking freezes.

---

## Problem Analysis

### Current Architecture (Two Progress Systems)
1. **`ProgressBar.res`** — DOM-based floating panel (`#processing-ui`). Uses direct DOM manipulation to update `#progress-bar` width, `#progress-text-content`, `#progress-title`, `#progress-percentage`. Driven by `ProgressBar.updateProgressBar(pct, text, ~visible, ~title)`.
2. **`SidebarProcessing.res`** — React sidebar component. Driven by `EventBus.dispatch(UpdateProcessing(payload))` via `SidebarLogic.updateProgress()`. Shows phase label, percentage, message, cancel button.

### Pain Points Identified

#### 🔴 Export (Critical)
- **Zero intermediate progress during preparation phases.** The export function calls `progress(0.0, 100.0, "Preparing assets...")` at start, then goes through LOGO, TEMPLATES, LIBRARIES, SCENES phases with ZERO progress callbacks until it hits the XHR upload phase.
- During XHR upload (lines 33-37 in `ExporterUpload.res`), upload progress covers 0–50% of a 0–100 total, then server processing jumps to "Processing on Server (Please Wait)..." at 50% with no further updates until 100% "Download Ready".
- Net user experience: **Sidebar progress sits at 0% → "Exporting..."** for potentially many seconds during asset packaging, then jumps to upload percentages, then freezes at 50% during server processing, then jumps to 100%.

#### 🟡 Upload (Moderate)
- Better coverage: Health Check → Scanning (0–18%) → Processing (20–95%) → Finalizing (98–100%).
- But messages like "Optimizing", "Processing images...", "Cleaning up scanning...", "Updating Sidebar..." are generic and repetitive.
- Phase label stays stuck on "Processing" for the bulk of the operation.

#### 🟡 Save (Moderate)
- Only two points reported: ~0% "Saving" and 100% "Saved". No intermediate states.

#### 🟡 Teaser (Server Cinematic)
- Uses the old `ProgressBar.res` (DOM panel) directly instead of the sidebar system. Phases: "Uploading" (0-50%) → "Processing" (50-100%).
- Inconsistent with the rest of the app which uses the sidebar system.

### Messaging Problems
- Generic terms: "Preparing assets...", "Processing images...", "Optimizing", "Checking backend..."
- The word "Processing" appears in multiple operations at multiple points — repetitive.
- No sense of what specific phase the user is in during export.

---

## Implementation Plan

### Phase 1: Export Progress Instrumentation (Primary Fix)
**Files:** `src/systems/Exporter.res`, `src/systems/Exporter/ExporterUpload.res`

The export pipeline has these phases. Assign budget percentages to each:

| Phase | Budget | Message |
|-------|--------|---------|
| Health Check | 0–2% | "Verifying connection..." |
| Logo | 2–5% | "Packaging logo..." |
| Templates | 5–10% | "Generating tour pages..." |
| Libraries | 10–15% | "Bundling viewer engine..." |
| Scenes | 15–40% | "Packaging scene N of M..." (per-scene sub-progress) |
| Upload | 40–75% | "Uploading: X MB sent..." |
| Server Processing | 75–95% | "Building your tour..." (with synthetic pulse if no XHR progress) |
| Finalize | 95–100% | "Preparing download..." |

**Changes:**
1. Add `progress()` calls at the start of each phase in `Exporter.exportTour`:
   - After `currentPhase := "HEALTH_CHECK"`: `progress(1.0, 100.0, "Verifying connection...")`
   - After `currentPhase := "LOGO"`: `progress(3.0, 100.0, "Packaging logo...")`
   - After `currentPhase := "TEMPLATES"`: `progress(7.0, 100.0, "Generating tour pages...")`
   - After `currentPhase := "LIBRARIES"`: `progress(12.0, 100.0, "Bundling viewer engine...")`
   - After `currentPhase := "SCENES"`: `progress(15.0, 100.0, "Packaging scenes...")`
   - Inside `appendScenes` per scene: `progress(15.0 +. 25.0 *. Float.fromInt(idx + 1) /. Float.fromInt(totalScenes), 100.0, "Packaging scene " ++ Int.toString(idx + 1) ++ " of " ++ Int.toString(totalScenes) ++ "...")`

2. Remap XHR upload progress in `ExporterUpload.res`:
   - Currently maps `e.loaded/e.total` to 0–50%. Change to map to 40–75% range.
   - Change `upload.onload` from reporting 50% to reporting 75%.
   - Change final success from 100% to 95%.
   - Add message: `"Uploading: " + MB + "MB of " + totalMB + "MB sent..."` (include total).
   
3. Add synthetic server-processing progress:
   - After XHR upload completes (onload), start a timer that increments from 75→95 slowly (e.g. every 2s add 2-3%) with message "Building your tour...".
   - When response arrives, jump to 95% → 100%.

### Phase 2: Premium Phase Labels in Sidebar
**Files:** `src/components/Sidebar/SidebarProcessing.res`, `src/components/Sidebar/SidebarLogic.res`

1. **Phase labels should be descriptive, not generic:**
   - Export: "Export" → dynamic phase labels like "Bundling", "Uploading", "Building"
   - Upload: "Processing" → "Analyzing", "Optimizing", "Finalizing"
   - Save: "Save" → "Saving Project"
   
2. **Monotonic progress enforcement** in `SidebarLogic.updateProgress`:
   - Track last reported percentage and never go backwards during an active operation.
   - Exception: when transitioning between operations (active flips to false then true).

### Phase 3: Upload Message Polish
**Files:** `src/systems/Upload/UploadScanner.res`, `src/systems/Upload/UploadFinalizer.res`, `src/systems/UploadProcessor.res`

Improve message text for clarity:
| Current | New |
|---------|-----|
| "Checking backend..." | "Connecting to server..." |
| "Scanning files..." | "Scanning images..." |
| "Cleaning up scanning..." | "Preparing batch..." |
| "Processing images..." | "Optimizing images..." |
| "Updating Sidebar..." | "Organizing scenes..." |
| "Completed" | "Upload complete" |

### Phase 4: Save Progress Instrumentation
**Files:** `src/components/Sidebar/UseSidebarProcessing.res`, `src/systems/ProjectManager.res`, `src/systems/ProjectManager/ProjectSave.res`

Add intermediate progress callbacks to the save flow:
- 0% "Encoding project data..."
- 30% "Packaging assets..."
- 60% "Uploading to server..."
- 100% "Saved"

### Phase 5: CSS Polish
**File:** `css/components/ui.css`

1. Add shimmer/glow effect to the progress bar fill when active:
   ```css
   .sidebar-progress-fill {
     background: linear-gradient(90deg, var(--primary), var(--primary-light, #6366f1), var(--primary));
     background-size: 200% 100%;
     animation: progress-shimmer 2s linear infinite;
   }
   @keyframes progress-shimmer {
     0% { background-position: 200% 0; }
     100% { background-position: -200% 0; }
   }
   ```

2. Add smooth easing to `#progress-bar` width transitions in the DOM version.

---

## Files Impacted
- `src/systems/Exporter.res` — Add per-phase progress calls
- `src/systems/Exporter/ExporterUpload.res` — Remap upload % range, add server-processing pulse  
- `src/components/Sidebar/SidebarLogic.res` — Monotonic enforcement, phase label improvements
- `src/components/Sidebar/SidebarProcessing.res` — UI polish (shimmer effect class)
- `src/systems/UploadProcessor.res` — Message text improvements
- `src/systems/Upload/UploadScanner.res` — Message text improvements
- `src/systems/Upload/UploadFinalizer.res` — Message text improvements
- `src/components/Sidebar/UseSidebarProcessing.res` — Save progress intermediate states
- `css/components/ui.css` — Progress bar shimmer animation
- `src/utils/ProgressBar.res` — (Review only, may add smooth easing)

## Success Criteria
- [x] Export progress bar advances smoothly from 0→100% across all phases (no long freeze at 0%)
- [x] Each export phase shows a descriptive, non-repetitive label
- [x] Upload messages are clear and phase-appropriate
- [x] Sidebar progress never goes backwards during an active operation
- [x] Progress bar has premium shimmer/glow animation
- [x] Server processing phase shows synthetic advancement (not a dead freeze)
