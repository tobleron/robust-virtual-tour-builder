# [1339] Split Backend `models.rs` Into Domain Modules

## Priority: P2 (Medium)

## Context
`backend/src/models.rs` is **533 lines** — the largest Rust file in the backend. The second-largest (`video_logic.rs`) is 327 lines. `models.rs` likely contains all domain structs, enums, and `Serialize`/`Deserialize` implementations for every feature: projects, scenes, media, users, geocoding, etc.

## Objective
Split into domain-specific model files for better maintainability and discoverability.

## Proposed Structure

```
backend/src/models/
  mod.rs          — Re-exports all sub-modules (pub use)
  project.rs      — Project, Scene, Hotspot, Timeline structs
  media.rs        — Image metadata, quality analysis types
  upload.rs       — Upload quota, file handling types
  geocoding.rs    — GeoLocation, Address types
  pathfinder.rs   — Path request/response types
```

## Implementation

1. Create `backend/src/models/` directory
2. Identify struct groupings by scanning `models.rs`
3. Move each group to its domain file
4. Create `mod.rs` with `pub use` re-exports so existing imports (`use crate::models::*`) continue to work
5. Delete the original `models.rs`

## Key Constraint
All `use crate::models::StructName` imports throughout the backend must continue to resolve. The `pub use` re-exports in `mod.rs` ensure backward compatibility.

## Verification
- [ ] `cargo build` passes
- [ ] `cargo test` passes
- [ ] No file in `backend/src/models/` exceeds 200 lines
- [ ] All existing imports resolve without changes to consumer files

## Estimated Effort: 2-3 hours
