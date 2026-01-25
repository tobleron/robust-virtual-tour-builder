# TASK: Technical Debt Cleanup & Type Safety Restoration

## 1. Safety Fix: Remove Rust `unwrap()`
- **File**: `backend/src/services/auth.rs`
- **Issue**: Presence of `unwrap()` on `AuthUrl::new` and `TokenUrl::new`.
- **Action**: Replace with `.expect("Static URL must be valid")` or proper error handling to prevent runtime panics.

## 2. Type Safety: Reduce `Obj.magic` Usage
- **Target**: Reduce count from 62 back toward the documented limit of 38.
- **Priority Areas**:
    - **`src/components/ViewerManager.res`**: Refactor event casting by creating proper DOM event bindings.
    - **`src/components/Sidebar.res`**: Replace result casting with explicit JSON type definitions and decoders.
    - **`src/systems/NavigationRenderer.res`**: Audit and remove unnecessary casts.

## 3. Style Cleanup
- **File**: `src/components/Sidebar.res`
- **Action**: Replace `makeStyle` inline styles (like `height: auto`) with Tailwind utility classes (`h-auto`) per project standards.

---
**Status**: Pending
**Source**: Jules Analysis Report (Jan 25, 2026)
