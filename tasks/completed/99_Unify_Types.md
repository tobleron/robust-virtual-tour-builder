# Task: Unify Frontend/Backend Types
**Priority:** Low (Code Quality)
**Status:** Pending

## Objective
Eliminate type duplication between Frontend (`ExifParser.res` `gPano` type) and Backend (Rust structs).

## Context
Currently, `gPano` fields are defined manually in ReScript. If the Backend struct changes, the Frontend breaks silently or misbehaves.

## Requirements
1. **Analyze** `backend/src/models/` and `src/types/`.
2. **Create** a shared definition strategy (or at least strictly comment/align them).
   - In ReScript: Define a `Types.res` or specific module that exactly mirrors the JSON response from backend.
3. **Refactor** `ExifParser.res` to use this shared type definition instead of a local `type gPano = ...`.

## Verification
- Code compilation.
- Manual verification that JSON decoding matches the Rust struct serialization.
