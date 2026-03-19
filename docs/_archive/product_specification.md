# Virtual Tour Builder — Product Specification

> **Version**: 1.0 — Derived 2026-02-26  
> **Source**: Systematic code analysis, 20 E2E spec files, 4 unit test suites, and product-owner clarification.

---

## 1. Product Overview

The Virtual Tour Builder is a browser-based tool that lets users create interactive 360° virtual tours from panoramic images. The builder outputs a self-contained HTML/JS package (ZIP) that can be deployed to any web server for end-user navigation.

### Core Value Proposition
- **Upload** panoramic images (JPEG/PNG/WebP)
- **Connect** scenes with navigational hotspot links  
- **Organize** scenes with labels, floor assignments, and categories
- **Preview** the tour in real-time with an integrated 360° viewer
- **Export** a deployable tour package as a ZIP file

---

## 2. Application Lifecycle (FSM)

The application operates as a finite state machine with these top-level modes:

```
Initializing ──────────► Interactive (on InitializeComplete)
Initializing ──────────► SystemBlocking(CriticalError) (on CriticalErrorOccurred)

Interactive(Viewing) ◄──► Interactive(EditingHotspots) (StartAuthoring/StopAuthoring)
Interactive ───────────► Interactive(Uploading) (on StartUpload)
Interactive ───────────► SystemBlocking(Summary) (on UploadComplete)

SystemBlocking(Summary) ──► SystemBlocking(ProjectLoading) (on StartAuthoring)
SystemBlocking(ProjectLoading) ──► Interactive(EditingHotspots) (on ProjectLoadComplete + pending)
SystemBlocking(CriticalError) ──► Initializing (on Reset)
```

### Rules
- **Interactive mode**: The user can freely navigate, edit hotspots, upload images, and export.
- **SystemBlocking mode**: All user interaction is locked (navigation, editing, uploading, exporting are disabled).
- **CriticalError**: Terminal state. Only `Reset` can escape it.
- **ProjectLoading**: Buffers incoming events (e.g., StartAuthoring) and replays them after load completes.

---

## 3. Scene Management

### 3.1 Uploading Images
- **Entry point**: The image upload area accepts JPEG, PNG, and WebP panoramic images.
- **Batch upload**: Multiple images can be selected at once. Processing uses chunked concurrency.
- **Client-side processing**: Multi-core OffscreenCanvas pipeline resizes images to optimized WebP with real-time ETA progress before sending.
- **Backend processing**: GPS extraction, histogram analysis, quality scoring.
- **Summary modal**: After a **multi-image upload** (2+ images), a Summary modal appears showing which files succeeded and which were skipped. Single-image uploads should auto-continue without a modal.
- **"Start Building" button**: Appears in the Summary modal. Clicking it transitions the app to Interactive mode.

### 3.2 Importing Projects
- **Format**: `.vt.zip` or `.zip` files containing scene data and metadata.
- **Flow**: Select ZIP file → processing → Summary modal → "Start Building" button.
- **Project name**: Extracted from the ZIP metadata and populated into the tour name field.
- **Session ID**: Backend assigns a session ID for the imported project.

### 3.3 Scene Sidebar (Linear List)
- **Layout**: Single linear list of scene items, no folders or grouping.
- **Scene item displays**:
  - Scene number badge (1-indexed)
  - Thumbnail image (with hover zoom effect)
  - Scene display name (label if set, else file name)
  - Link count indicator (chain icon + count, shown only if links > 0)
  - File format badge (WEBP, PNG, JPG)
  - File size
  - Quality score progress bar
- **Drag-and-drop**: Scenes can be reordered by dragging the grip handle.
- **Keyboard**: Enter/Space to select a scene.
- **Accessibility**: `role="button"`, `aria-label`, `aria-busy` on each item.

### 3.4 Scene Context Menu (Three-Dot Menu)
Each scene item has a MoreVertical (⋮) button in the right rail. Clicking it opens a dropdown with:

1. **Clear Links**: Removes all hotspots/links from the scene. Shows 800ms orange flicker animation, then dispatches action.
   - **Undo**: 9-second notification with "Undo" button and `U` keyboard shortcut.
   - If not undone within 9s, backend synchronization fires at 9.5s.
2. **Remove Scene**: Deletes the scene from the project. Shows 800ms red flicker animation, then dispatches action.
   - **No confirmation modal** (intentional — undo notification is sufficient).
   - **Undo**: 9-second notification with "Undo" button and `U` keyboard shortcut.
   - Undo mechanism: `StateSnapshot.capture()` before action → `StateSnapshot.rollback()` on undo → `AppContext.restoreState()`.
   - If not undone within 9s, backend synchronization fires at 9.5s.

### 3.5 Scene Labels
- **Purpose**: User-editable text label for each scene. Displayed as a room name/tag in exported tours.
- **Optional**: Scenes without labels show the file name instead.
- **Editing**: Via the sidebar or scene properties panel.
- **In exported tour**: The label appears as a persistent HUD element (`#v-scene-persistent-label`) showing `# Scene Name`.

### 3.6 Tour Name
- **Editing**: Via `#project-name-input` in the sidebar header.
- **Sanitization**: Spaces are replaced with underscores (e.g., "My awesome tour" → "My_awesome_tour").
- **Used in**: Export ZIP file name and embedded tour metadata.

---

## 4. 360° Viewer

### 4.1 Dual Viewport Architecture
- **panorama-a** (primary): The currently visible viewport.
- **panorama-b** (secondary): Preloads the next scene asynchronously for instant transitions.
- The `.active` CSS class marks which viewport is currently visible.
- **Pannellum**: The underlying WebGL-based panorama rendering library.

### 4.2 Navigation FSM
Scene transitions follow a strict state machine:

```
IdleFsm ──► Preloading (on UserClickedScene)
Preloading ──► Transitioning (on TextureLoaded)
Transitioning ──► Stabilizing (on TransitionComplete)
Stabilizing ──► IdleFsm (on StabilizeComplete)

Preloading(anticipatory) ──► IdleFsm (on TextureLoaded, no visible transition)
Preloading ──► ErrorFsm (on LoadTimeout)
ErrorFsm ──► Preloading (on RecoveryTriggered, attempt++)

ANY STATE ──► IdleFsm (on Reset)
ANY STATE ──► Preloading(new target) (on UserClickedScene — interruption)
```

### Rules
- **Scene switching is interruptible**: Clicking a new scene while navigating cancels the current navigation.
- **Anticipatory preloading**: Silently loads textures without triggering a visible transition.
- **Timeout retry**: Failed loads retry with incremented attempt count.
- **NavigationSupervisor**: Manages navigation tasks and auto-cancels previous operations.

### 4.3 Persistent Scene Label
- A HUD element (`#v-scene-persistent-label`) displays the current scene's label/name.
- Always visible over the viewer.

---

## 5. Hotspot / Link System

### 5.1 Creating Links (Two Entry Points)

#### Primary: "Add Link +" Button
1. Click "Add Link" button in the utility bar → enters **linking mode** (`state.isLinking = true`).
2. An interaction-lock overlay appears. Simulation button is disabled.
3. **First click** on panorama: Sets the hotspot position (yaw, pitch) and creates a link draft.
4. **Subsequent clicks**: Add intermediate **waypoints** to define a camera animation path.
5. **Enter key**: Finalizes the waypoints and opens the **Link Modal**.

#### Secondary: Alt+Click (Power-User Shortcut)
- Alt+Click on the viewer directly triggers the linking flow.
- Same behavior as the button method.

### 5.2 Link Modal
- **Title**: "Link Destination"
- **Content**: A `<select>` dropdown (`#link-target`) listing all scenes except the current one.
  - Options show scene label (if set) or file name.
  - Default selection: the next scene in order.
- **Buttons**:
  - **"Save Link"**: Creates the hotspot with all waypoint data, auto-registers in timeline, closes modal, exits linking mode.
  - **"Cancel"**: Hides draft lines, closes modal.
- **Cancel via X/Close**: Also exits linking mode and hides draft lines.
- **ESC**: Cancels linking mode entirely.

### 5.3 Link ID Generation
- Each link gets a unique alphanumeric ID (e.g., "A01", "A02", etc.) generated by `TourLogic.generateLinkId()`.
- IDs are globally unique across all scenes.

### 5.4 Hotspot Types
Every hotspot is one of:
- **Simple Link** (default): Navigates to the target scene on click.
- **Auto-Forward Link**: Automatically navigates to the target scene after a duration. Distinguished by emerald/green color.

### 5.5 Auto-Forward Rules
- **One per scene**: Each scene can have at most **one** auto-forward link (it represents the exit path).
- **Enforcement location**: `HotspotActionMenu.res` validates before toggling. **⚠️ Not enforced in `PreviewArrow.res` inline toggle — hardening gap.**
- **Error toast**: "Only one auto-forward link per scene" if violation attempted.
- **Visual**: Auto-forward links have emerald green color (`#059669`).

### 5.6 Hub Scenes
- A scene with **2 or more** links is a "hub scene."
- Hub scenes give the end user a choice of where to navigate.

---

## 6. Hotspot Interaction (Hover Menu)

When hovering over a hotspot in the 360° viewer, a 4-button menu appears:

### Layout (CSS group reveal with delays)
```
[CENTER] ← Main button (always visible)
[RIGHT]  ← Slides right on hover (auto-forward toggle)
[BOTTOM] ← Slides down on hover (move)
[FAR BOTTOM] ← Slides further down (delete)
```

### Button Behaviors

| Button | Normal State | During Move Mode |
|--------|-------------|-----------------|
| **Center** | Navigate to target scene | Cancel move (X icon) |
| **Right** | Toggle auto-forward (emerald=ON, orange=OFF) | Disabled |
| **Bottom** | Start hotspot move (yellow) | Shows X (cancel) |
| **Far Bottom** | Delete hotspot (red, 800ms flicker, no undo) | Disabled |

### Visual Feedback
- **Auto-forward toggle**: Yellow flicker animation (800ms), then icon swap animation.
- **Delete**: Red flicker animation (800ms), then removal.  
- **Move commit**: Yellow flat blink animation after successful placement.
- **Diagonal sweep**: Subtle gradient animation across the center button.

---

## 7. Hotspot Move Feature

### Flow
1. Click **Move button** (yellow, bottom of hover menu) → dispatches `StartMovingHotspot`.
2. Center button turns **yellow** with Move icon. Bottom button shows **X** (cancel).
3. All other hotspot actions disabled on all hotspots (`isMovingAny` guard).
4. Notification: "Move Mode Active — Click anywhere on the panorama to place the link. ESC to cancel."
5. **Click on panorama**: Fires `viewer-click` event → `CommitHotspotMove(sceneIndex, hotspotIndex, yaw, pitch)`.
6. **Commit behavior**: Yaw and pitch updated. **Waypoints (viewFrame, waypoints) are preserved exactly.** `displayPitch` is cleared for exact placement.
7. Center button blinks yellow (`animate-flicker-yellow-flat`, 800ms).
8. `movingHotspot` state cleared.

### Cancel
- **ESC key**: Dispatches `StopMovingHotspot` + "Move Cancelled" notification.
- **Click center button** during move: Same as ESC.

---

## 8. Floor Assignment

### Available Floors
| Code | Label |
|------|-------|
| B-2 | Basement Level 2 |
| B-1 | Basement Level 1 |
| G | Ground Floor |
| +1 | First Floor |
| +2 | Second Floor |
| +3 | Third Floor |
| +4 | Fourth Floor |
| R | Roof |

### Behavior
- Floor is assigned per-scene via viewer floor buttons.
- Active floor button has orange highlight (`bg-[#ea580c]`).
- Floor value stored in `scene.floor` metadata.
- Used for organizing scenes in the exported tour.

---

## 9. Visual Pipeline (Timeline)

### Current State (V3)
- **Architecture**: Floor-grouped squares with deterministic PCB-style routing connections.
- **Automatic ordering**: Pipeline items are generated unifying Canonical Traversal generation (`CanonicalTraversal.res`).
- **Hover/Tooltips**: Hovering over squares reveals a tooltip with the scene tag/name and a preview thumbnail (dimming the current viewport).
- **Home + linked-target model**: The first square is the home scene. Isolated floors automatically render their own home button.
- **Auto-forward indication**: Active items have a yellow sync ring; auto-forward items use Emerald/Indigo highlights.
- **Click to navigate**: Clicking a pipeline square or active route navigates to the target scene.

---

## 10. Simulation / Tour Preview

### Starting
- Click **"Tour Preview"** button → enters autopilot mode.
- The simulation follows links automatically, navigating scene-to-scene.

### Auto-Forward Chain
- Tracks visited scenes to prevent infinite loops in auto-forward chains.
- If a scene is visited twice, the chain breaks.

### Stopping
- Click **"Stop Tour Preview"** button.
- **ESC key**: Cancels navigation and stops simulation.
- Simulation status: `Idle`, `Running`, `Paused`, `Stopping`.

---

## 11. Teaser Generation

### Current Implementation
- **Format**: WebM video (frontend-generated via MediaRecorder API).
- **Style**: Cinematic only (Fast Shots and Simple Crossfade are future features).
  - Style registry: `TeaserStyleCatalog.res` defines available styles; `TeaserRendererRegistry.res` dispatches to the correct manifest builder.
  - Manifest-driven rendering: `TeaserManifest.res` generates deterministic `motion-spec-v1` manifests; `TeaserOfflineCfrRenderer.res` renders frame-by-frame at constant frame rate.
- **Duration**: Auto-determined by number of scenes/waypoints (not user-configurable).
- **Progress**: Progress bar with ETA shown during recording. ETA calculation uses `EtaSupport.res` (median-of-three blending, EMA smoothing).
- **Cancel**: Cancel button or ESC key.

### Future Features (Not Implemented)
- MP4 format (requires backend rendering engine).
- Server-side/cloud rendering.
- Multiple teaser styles.

---

## 12. Export System

### Flow
1. Click **"Export Tour"** button → opens **Publish Modal** with quality/format options.
2. Select desired output: **HD**, **2K**, **4K**, or **2K-standalone** (offline package).
3. Progress bar with ETA toast notifications (EMA-based estimation with scene/upload rate blending).
4. Download triggers automatically on completion.
4. **Cancel**: ESC key or Cancel button during export.

### Output Structure
```
tour_export.zip/
├── standalone/
│   └── tour_hd/
│       └── index.html (embedded Pannellum viewer)
├── (other quality tiers auto-included: HD, 2K, 4K)
└── metadata/
```

### Logo
- Custom logo upload supported (auto-resize/compress).
- Falls back to default logo if none uploaded.
- Logo persists through save/reload cycles.

---

## 13. Save / Load / Persistence

### Manual Save
- Downloads the current project as a `.vt.zip` file.
- Can be re-imported later via the file upload area.

### Auto-Save (IndexedDB)
- **Active**: Writes to IndexedDB key `autosave_session_latest`.
- **Debounced**: 2-second debounce interval.
- **Trigger**: Any `structuralRevision` change. Only actions listed in `Reducer.isStructuralMutation()` increment the revision counter.
- **Scheduling**: Uses `requestIdleCallback` when available.
- **Schema versioning**: Currently v2, with forward-compatibility checks.
- **⚠️ Recovery UI disabled**: The "Unsaved Session Found — Restore or Discard?" modal is commented out in `Main.res`. Auto-save writes data but recovery prompt never appears on reload.
- **⚠️ Missing triggers**: `CommitHotspotMove` and `UpdateHotspotMetadata` are NOT in `isStructuralMutation` — hotspot position changes and auto-forward toggles are NOT auto-saved. This is a **known data loss bug**.

### beforeunload Handler
- Flushes the operation journal emergency queue.
- Performs any pending auto-save.

---

## 14. Capability Policy (Permission System)

The `Capability.Policy` module gates actions based on app mode and active operations:

| Capability | Interactive + Idle | SystemBlocking | Active Navigation | Active Upload | Active Simulation |
|-----------|-------------------|---------------|-------------------|--------------|-------------------|
| CanNavigate | ✅ | ❌ | ✅ (interruptible) | ✅ | ✅ |
| CanEditHotspots | ✅ | ❌ | ❌ | ✅ | ✅ |
| CanUpload | ✅ | ❌ | ✅ | ❌ | ✅ |
| CanExport | ✅ | ❌ | ✅ | ❌ | ✅ |
| CanMutateProject | ✅ | ❌ | ❌ | ❌ | ❌ |
| CanStartSimulation | ✅ | ❌ | ✅ | ✅ | ❌ |
| CanInteractWithViewer | ✅ | ❌ | ❌ | ✅ | ✅ |

### Critical Operation Lock
- `ProjectLoad` operation type enforces system lock even if app mode is Interactive.

---

## 15. Error Recovery & Resilience

### Circuit Breaker
- After 6+ consecutive API failures → "Connection issues" notification.
- Subsequent API calls immediately rejected until circuit resets.

### Retry with Backoff
- Failed save/upload operations retry up to 3 times with exponential backoff.

### Optimistic Rollback
- Destructive operations (scene deletion) apply optimistically to local state.
- If backend API call fails, state is rolled back and "Changes have been reverted" notification appears.

### Operation Journal
- In-flight operations are tracked in `operation_journal_emergency_queue` in localStorage.
- On page reload with interrupted operations, a recovery prompt appears.

### Save Debouncing
- 10 rapid save clicks → at most 2 actual API calls (debounced).

---

## 16. Keyboard Shortcuts

| Key | Context | Action |
|-----|---------|--------|
| ESC | Linking mode | Cancel link creation |
| ESC | Moving hotspot | Cancel hotspot move |
| ESC | Navigation in progress | Abort navigation |
| ESC | Simulation running | Stop tour preview |
| ESC | Teaser recording | Cancel teaser |
| ESC | Modal open | Close modal |
| ESC | Context menu open | Hide context menu |
| ESC | Any progress bar op | Cancel active operation |
| Enter | Linking mode | Finalize waypoints → open Link Modal |
| U | Notification with undo | Trigger undo action |
| Ctrl+Shift+D | Any | Toggle debug mode |

---

## 17. Notification System

### Types
- **Info**: Blue, used for status updates (e.g., "Link Cancelled").
- **Success**: Green, used for completed actions (e.g., "Scene deleted").
- **Warning**: Yellow, used for non-blocking issues.
- **Error**: Red, used for failures and validation errors.

### Features
- Dismissible with X button.
- Auto-dismiss after type-specific timeout.
- Some notifications include an **action button** (e.g., "Undo") with optional keyboard shortcut.
- Archived notifications (max 10) for undo/history support.
- ETA toasts show estimated time remaining for long operations.

---

## 18. State Inspection (Debug)

### window.store (Development Only)
| Property/Method | Returns | Notes |
|----------------|---------|-------|
| `.state` | Snapshot: tourName, sceneCount, activeIndex, isLinking, simulation status | Read-only, via getter |
| `.getState()` | Full raw state object | E2E test compatibility |
| `.getFullState()` | Full state (Object.freeze) | Debug only, console warning |
| `.loadProject(data)` | void | Headless automation |

### window.__RE_STATE__
- Live raw state export, updated on every render cycle.
- Set in `App.res` via `%raw`.

---

## 19. Known Limitations & Future Features

### Not Implemented (Tests Skipped)
- Return links (deprecated)
- Director view (not user-configurable)
- Hotspot transition type selection
- Hotspot duration configuration
- Hotspot labels
- Teaser duration configuration
- Server-side teaser rendering (MP4)
- Floor filtering in sidebar
- Fast Shots teaser style (stub exists, returns `Error("not implemented")`)
- Simple Crossfade teaser style (stub exists, returns `Error("not implemented")`)

### Active Bugs
- **Hotspot overlap**: Waypoint/arrow SVG elements can overlap hotspot action buttons, making them unclickable.
- **Auto-save gap**: `CommitHotspotMove` and `UpdateHotspotMetadata` are not in `isStructuralMutation` — changes are not auto-saved.

### Code Quality Issues
- 2 usages of `Belt.Array.getExn` (unsafe, could crash at runtime) in `EtaSupport.res` and `StateSnapshot.res`.
- Duplicate `formatEta` implementations in `EtaSupport.res` and `TeaserOfflineCfrRenderer.res`.
- `Reducer.Batch(actions)` has no recursion depth guard.

---

## Appendix A: Hub Scene Rules

**Hub Scene** = any scene with 2 or more exit links (hotspots).

### Behavior (managed by `HubScene.res`)
- **First-visit animation**: Hub scenes animate on first visit only. Subsequent visits skip the animation to prevent fatigue.
- **Visited tracking**: `state.visitedScenes: array<string>` tracks which scenes have animated.
- **Reset**: `HubScene.resetVisitedScenes()` clears tracking on the `Reset` action.

---

## Appendix B: Timeline Cleanup

`TimelineCleanup.res` handles maintenance of the timeline data structure:

1. **Scene-level auto-forward migration**: Old projects stored `isAutoForward` at the scene level; the migrator pushes it down to each hotspot's `isAutoForward: Some(true)`.
2. **Orphan removal**: Timeline items referencing deleted hotspot `linkId`s are purged.
3. **Deduplication**: Keeps only the LAST timeline item for each unique `linkId`.
4. **Reordering**: Re-sorts timeline by simulated tour traversal order (same logic as `SimulationNavigation`).
5. **Triggered by**: `CleanupTimeline` action dispatched after project load or significant edits.
