---
title: Implement ReScript Schema for Robust JSON Validation
status: pending
priority: high
tags: [refactor, security, reliability, json, schema]
assignee: unassigned
---

# 🛡️ Implement ReScript Schema for Robust JSON Validation

## 🎯 Objective
Replace the current "Type Lie" pattern (using `Obj.magic` in `JsonTypes.res`) with `rescript-schema`. This will introduce strict runtime validation for strictly typed API responses, eliminating a major source of potential runtime crashes ("undefined is not a function").

## 📋 Context
Currently, the codebase uses unsafe casting for complex JSON structures like `Project`, `Scene`, and `Hotspot`. This offers 0% runtime protection. We are switching to `rescript-schema` to gain 100% type safety at the IO boundary with a negligible performance cost.

## 🛠️ Implementation Plan

### Phase 1: Setup
1. [ ] Install `rescript-schema`:
   ```bash
   npm install rescript-schema
   ```
2. [ ] Add `rescript-schema` to `dependencies` in `rescript.json`.

### Phase 2: Schema Definition
3. [ ] Create a new module `src/core/Schemas.res`.
4. [ ] Implement schemas for leaf nodes first:
   - `ViewFrame`
   - `Transition`
   - `Hotspot` (Handle strict validation of `target`, `yaw`, `pitch`)
5. [ ] Implement schemas for composite nodes:
   - `File/Asset` types
   - `Scene` (and `ImportScene`)
   - `Project`
   - `Timeline` step types

### Phase 3: Integration
6. [ ] Update `src/core/SceneHelpersParser.res`:
   - Replace manual mapping logic with `S.parseAnyOrRaiseWith` or `S.parseWith`.
   - Ensure explicit error handling is preserved (wrapping schema errors in friendly logs).
7. [ ] Update `src/systems/api/ProjectApi.res`:
   - Replace manual/unsafe decoders with Schema parsers.
8. [ ] Update `src/core/Types.res` if necessary to align with Schema outputs (likely staying the same, but verifying structural compatibility).

### Phase 4: Cleanup & Verification
9. [ ] Remove obsolete manual decoders from `src/core/JsonTypes.res`.
10. [ ] Remove `src/core/JsonTypes.res` if fully emptied, or rename to `LegacyJsonTypes.res` if partial compatibility is needed temporarily.
11. [ ] Run `npm test` to ensure no regression in project loading.
12. [ ] Verify "Project Load" in the browser with a known good project.
13. [ ] Verify "Project Load" with a known bad project (missing fields) to test error reporting.

## 📝 Success Criteria
- [ ] No `Obj.magic` used for `Project`, `Scene`, or `Hotspot` decoding.
- [ ] `npm run res:build` passes.
- [ ] `npm test` passes.
- [ ] Runtime errors for malformed JSON provide specific field paths (e.g. `Failed to parse scenes[0].hotspots[1].target`).
