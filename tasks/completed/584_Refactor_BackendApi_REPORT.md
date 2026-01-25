# Task 584: Refactor BackendApi (Rust/Rescript Interface) - COMPLETED

## 🚨 Trigger
Project "Surgical Edit" Initiative.
File exceeds 360 line limit (663 lines). Handles extensive API error handling and type casting.

## Objective
Split by domain or extraction pattern.

## Technical Realization
1. **Split Responsibility**:
   - `src/systems/api/ApiTypes.res`: Centralized shared types, decoders, and `handleResponse` logic.
   - `src/systems/api/ProjectApi.res`: Encapsulates Project Import/Export/Validate, Navigation Path Calculation, and Reverse Geocoding.
   - `src/systems/api/MediaApi.res`: Encapsulates Image Processing, Metadata Extraction, and Similarity Calculation.

2. **Facade Pattern**:
   - Refactored `src/systems/BackendApi.res` to act as a strict facade using `include`. This preserves the existing API surface for all consumers (no call-site changes required).

3. **Safety & Standards**:
   - Preserved all `Logger` calls with updated module names (`ProjectApi`, `MediaApi`) for better debugging context.
   - Maintained strict type safety via `SharedTypes` and manual decoders.
