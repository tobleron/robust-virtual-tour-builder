# Task 584: Refactor BackendApi (Rust/Rescript Interface)

## 🚨 Trigger
Project "Surgical Edit" Initiative.
File exceeds 360 line limit (663 lines). Handles extensive API error handling and type casting.

## Objective
Split by domain or extraction pattern.

## Required Refactoring
1. **ApiTypes.res**: Move all shared type definitions and decoders here.
2. **ProjectApi.res**: Project logic (Import/Export/Validate).
3. **MediaApi.res**: Image processing and metadata extraction logic.

## Safety & Constraints
- **Type Safety**: Ensure strict typed matching with Rust backend.
- **Error Handling**: Preserve the detailed error logging.
