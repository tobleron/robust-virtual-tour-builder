# Task: Migrate Legacy JSON Handling to Rescript Schema

## 🚀 Objective
Migrate all identified legacy JSON handling patterns (manual `JSON.Decode`, `JSON.stringify`, `Obj.magic`, raw JS parsing) to the standardized `rescript-schema` library. This ensures type safety, consistent validation, and runtime correctness across the codebase.

## 🔍 Context
The following files have been identified as using legacy or unsafe JSON handling:
1.  `src/systems/ProjectManager.res`: Uses manual `JSON.Decode` and `Dict` manipulation.
2.  `src/utils/SessionStore.res`: Uses `JSON.parseOrThrow` and manual decoding.
3.  `src/systems/Api/ProjectApi.res` & `AuthenticatedClient.res`: Uses manual `JSON.stringify`.
4.  `src/utils/PersistenceLayer.res`: Uses unsafe casting for autosave.
5.  `src/systems/Exporter.res`: Uses raw JS for XHR and response parsing.

## 🛠️ Implementation Plan

### Phase 1: Session Store & Persistence
-   [ ] **Update `src/utils/SessionStore.res`**:
    -   Define a schema for `sessionState` using `S.object`.
    -   Replace `saveState` logic to use `S.serializeOrThrow`.
    -   Replace `loadState` logic to use `S.parseJson`.
-   [ ] **Update `src/utils/PersistenceLayer.res`**:
    -   Define a schema for `serializedSession`.
    -   Remove `external anyToJson: 'a => JSON.t = "%identity"`.
    -   Use `S.serialize` to prepare data for IndexedDB.
    -   Use `S.parse` to validate data retrieved from IndexedDB.

### Phase 2: Project Manager Refactor
-   [ ] **Refactor `src/systems/ProjectManager.res`**:
    -   Remove `Logic.validateProjectStructure` and manual decode logic.
    -   Use `Schemas.Domain.project` to parse and validate project data.
    -   Update `processLoadedProjectData` to work with the parsed `Types.project` type directly instead of `Dict.t` / `JSON.t`.
    -   Ensure `createSavePackage` uses `S.serialize` for generating the project JSON file.

### Phase 3: API Layer Hardening
-   [ ] **Update `src/systems/Api/AuthenticatedClient.res`**:
    -   Accept `S.t<'a>` or similar typed input for bodies where possible, or ensure callers serialize using schemas.
-   [ ] **Update `src/systems/Api/ProjectApi.res`**:
    -   Replace `JSON.stringify(JSON.Encode.object(...))` patterns with `S.serialize`.
    -   Ensure all endpoints use defined schemas for request bodies.

### Phase 4: Exporter Safety
-   [ ] **Refactor `src/systems/Exporter.res`**:
    -   Investigate removing the `%raw` XHR block if `Fetch` can handle progress (or keep it if strictly necessary for upload progress).
    -   If `%raw` must stay for progress, ensure the *response* is returned as a safe blob/text and parsed on the ReScript side using `Schemas`.
    -   Replace any `JSON.parse` inside the raw block with passing the string back to ReScript for safe parsing if possible.

## ✅ Completion Criteria
-   All identified files import and use `RescriptSchema`.
-   No manual `JSON.Decode` or `JSON.Encode` for complex objects in target files.
-   `npm run res:build` passes with **Zero Warnings**.
-   Project functionality (Save, Load, Export, Autosave) remains verified and operational.
