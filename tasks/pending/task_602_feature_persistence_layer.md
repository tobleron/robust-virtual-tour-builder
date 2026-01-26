# Feature: Hybrid Persistence Layer (Crash-Proofing)

## 🚀 Context & Motivation
Currently, the application operates on a "Tool" model where state is purely in-memory until the user manually triggers a "Save" or "Export". If the browser crashes, the tab is closed, or the OS restarts, all unsaved progress is lost. To reach "Commercial Grade" reliability, the application must adopt a "Platform" behavior with robust, local-first autosaving.

## 🎯 Goals
- Achieve resilient data persistence that survives browser crashes.
- Transparently background-save specific slices of state (Scenes, Settings) without user intervention.
- Provide a recovery mechanism upon application restart ("We found an unsaved session...").
- Minimize performance impact on the main thread during persistence operations.

## 🛠️ Implementation Plan

### 1. Identify Critical State Slices
Analyze `State.res` to determine which fields must be persisted.
- **Must Have**: `scenes` (including all hotspot data), `tourName`, `timeline`.
- **Transient (Do Not Persist)**: `isLinking`, `transition`, `activeViewerKey`, `loadingSceneId`.

### 2. Implement the Shadow Store (IndexedDB)
Use a specialized module (wrapping `idb-keyval` or similar) to interface with IndexedDB.
- **Key**: `autosave_session_latest`
- **Structure**: `{ timestamp: float, projectData: JSON.t }`
- **Constraint**: Ensure strict type safety when serializing/deserializing ReScript records.

### 3. Background Persistence Worker
Create a subscriber to the `GlobalStateBridge` or `Reducer` that monitors changes.
- **Trigger**: Actions of type `AddScene`, `UpdateHotspot`, `DeleteScene`, etc.
- **Debounce**: Wait for 2-5 seconds of inactivity to prevent thrashing during rapid edits.
- **Optimization**: Use `requestIdleCallback` (if available) to serialize and write data to IndexedDB without blocking the UI frame.

### 4. Session Restoration (`src/systems/SessionRecovery.res`)
Implement logic in `Main.res` or `App.res` to check for saved sessions on boot.
- **Check**: Is there data in `autosave_session_latest`?
- **Validate**: Is the data structure valid? Is strictly newer than the empty initial state?
- **Prompt**: If valid data exists, show a non-blocking "Toast" or "Modal" asking the user if they want to restore the previous session.

## ✅ Definition of Done
- [ ] IndexedDB bindings/helpers implemented.
- [ ] Background save logic implemented with debouncing.
- [ ] "Session Restored" flow implemented on app initialization.
- [ ] Performance validated: Typing text or moving hotspots rapidly does not stutter due to serialization.
- [ ] Privacy: Ensure sensitive data (if any) is handled appropriately (local only).
