# Migration to CSP-Friendly Validation (rescript-json-combinators)

## Problem Statement
The project currently uses `rescript-schema` (v9/v10) which relies on `unsafe-eval` (via `new Function`) for performance optimization. This violates the strict Content Security Policy (CSP) required for the tour builder application, causing `EvalError` at runtime.

Recent "Zero-Eval" hotfixes have replaced critical schema validation with `JSON.stringify` and `Obj.magic`. While this solves the immediate crash, it sacrifices type safety.

## Objective
Migrate the entire codebase from `rescript-schema` (and the temporary hotfixes) to **`glennsl/rescript-json-combinators`**. This utility provides pure functional parsing without `eval`, ensuring full CSP compliance while restoring type safety.

## Implementation Plan

### 1. Setup
- [ ] Install `@glennsl/rescript-json-combinators` via npm.
- [ ] Add to `bs-dependencies` in `rescript.json` (or `bsconfig.json`).
- [ ] Create a new module `src/core/JsonParsers.res` (or similar) to house the new combinators.

### 2. Create Decoders
Recreate strict decoders for core domain objects using `Json.Decode`.
*Reference `src/core/SchemaDefinitions.res` for current shapes.*

- [ ] `sessionState` decoder
- [ ] `project` decoder (and nested `scene`, `hotspot`, etc.)
- [ ] `importResponse` decoder
- [ ] `validationReport` decoder
- [ ] `metadataResponse` (Exif) decoder
- [ ] `steps` (Pathfinding) decoder
- [ ] `geocodeResponse` decoder

### 3. Migration (Module by Module)
Replace the temporary `JSON.stringifyAny/Obj.magic` hacks with proper decoders.

- [ ] **`src/utils/SessionStore.res`**
    - Replace `JSON.stringifyAny` in `saveState` with `Json.Encode`.
    - Replace `JSON.parseExn` + `Obj.magic` in `decodeSessionState` with `Json.Decode`.

- [ ] **`src/utils/PersistenceLayer.res`**
    - Replace direct casting in `performSave` and `checkRecovery`.

- [ ] **`src/systems/Api/ProjectApi.res`**
    - Update `importProject`, `loadProject`, `validateProject`, `saveProject`, `calculatePath`.
    - Remove `Js.Json.stringifyAny` usage for payloads.

- [ ] **`src/systems/Api/MediaApi.res`**
    - Update `processImageFull` and `batchCalculateSimilarity`.

- [ ] **`src/systems/ServerTeaser.res`**
    - Update `generateServerTeaser` serialization.

- [ ] **`src/systems/TourTemplates.res`**
    - Ensure template data injection uses proper encoding.

- [ ] **`src/utils/LoggerTelemetry.res`**
    - Ensure log entry serialization is safe.

### 4. Cleanup
- [ ] Remove `src/core/Schemas.res`, `src/core/SchemaDefinitions.res`, `src/core/SchemaParsers.res`.
- [ ] Uninstall `rescript-schema`.
- [ ] Run `npm run res:build` to ensure no "eval-like" dependencies remain.
- [ ] Test in strict CSP environment (verify no `EvalError`).

## Completion Criteria
- No `rescript-schema` imports usage.
- No `Obj.magic` used for JSON parsing.
- Application compiles and runs with strict CSP.
