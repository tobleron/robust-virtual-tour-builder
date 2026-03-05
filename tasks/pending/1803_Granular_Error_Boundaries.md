# Task 1803: Resilience: Granular Error Boundaries Per Subsystem

## 🤖 Agent Metadata
- **Assignee**: Jules (AI Agent)
- **Capacity Class**: A
- **Objective**: Prevent a single component crash from taking down the entire UI.
- **Boundary**: `src/components/`, `src/App.res`.
- **Owned Interfaces**: `AppErrorBoundary.res`.
- **No-Touch Zones**: State management logic.
- **Independent Verification**: 
  - [ ] Rendering crash in the Viewer component leaves the Sidebar and Navigation playable.
- **Depends On**: None

---

## 🛡️ Objective
Isolate feature-level crashes. Currently, a rendering error in any component triggers the global Error Boundary, killing the whole session. We need granular zones for Viewer, Editor, and Processing.

---

## 🛠️ Execution Roadmap
1. **Boundary Extraction**: Refactor `AppErrorBoundary` into a reusable `FeatureErrorBoundary` component.
2. **Subsystem Wrapping**: Wrap `ViewerManager`, `Sidebar`, `UploadProcessor`, and `TeaserRecorder` in dedicated boundaries.
3. **Fallback UI**: Design specific fallbacks (e.g., "Viewer crashed - [Reload Viewer]" button) instead of the global "Something went wrong" page.

---

## ✅ Acceptance Criteria
- [ ] Viewer crash does NOT reset the unsaved Sidebar state.
- [ ] Every boundary recovery sends a "FEATURE_CRASH" telemetry event with the component name.
