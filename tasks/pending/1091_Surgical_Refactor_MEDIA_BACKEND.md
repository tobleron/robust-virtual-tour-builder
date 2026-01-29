# Task 1091: Surgical Refactor MEDIA BACKEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 2.00 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🚨 Hotspots (Focus Area)
The following regions are calculated to be the most confusing for AI:

## Tasks

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../backend/src/api/media/image_logic.rs** (Metric: [Nesting: 0.75, Density: 0.04, Deps: 0.00] | Drag: 2.46 | LOC: 290/238)

- [ ] - **../../backend/src/api/media/image_logic.rs** (Metric: [Nesting: 0.75, Density: 0.04, Deps: 0.00] | Drag: 2.36 | LOC: 290/245)

- [ ] - **../../backend/src/api/media/image_logic.rs** (Metric: [Nesting: 0.75, Density: 0.04, Deps: 0.00] | Drag: 2.36 | LOC: 290/250)


### 🔧 Action: Audit & Delete
**Directive:** De-bloat: Reduce module size by identifying and extracting independent domain logic.

- [ ] - **../../backend/src/api/media/image.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 198))

- [ ] - **../../backend/src/api/media/image_logic.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 290))

- [ ] - **../../backend/src/api/media/serve.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 72))

- [ ] - **../../backend/src/api/media/similarity.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 197))

- [ ] - **../../backend/src/api/media/video.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 173))

- [ ] - **../../backend/src/api/media/video_logic.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 200))

- [ ] - **../../backend/src/services/media/analysis.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 97))

- [ ] - **../../backend/src/services/media/analysis_exif.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 117))

- [ ] - **../../backend/src/services/media/analysis_quality.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 220))

- [ ] - **../../backend/src/services/media/mod.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 98))

- [ ] - **../../backend/src/services/media/naming.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 109))

- [ ] - **../../backend/src/services/media/resizing.rs** (Metric: Unreachable Module. Not referenced by any entry point. (LOC: 54))
