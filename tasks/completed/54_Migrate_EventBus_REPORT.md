# Task 54 Completion Report: Migrate EventBus

**Status**: ✅ COMPLETED  
**Date**: 2026-01-14  
**Commit**: (Pending)

## Objective
Migrate the loose, string-based `src/utils/PubSub.js` system to a strictly typed `src/systems/EventBus.res` using ReScript variants, ensuring type safety for navigation events.

## Changes Made

### 1. Created `EventBus` Module
**File**: `src/systems/EventBus.res`
- Defined `event` variant type covering:
  - `NavStart(navStartPayload)`
  - `NavCompleted(journeyData)`
  - `NavCancelled`
  - `ClearSimUi`
  - etc.
- Leveraged `Types.res` for payload definitions (`journeyData`, `pathData`), eliminating duplicate/loose types.
- Implemented `subscribe` and `dispatch` using `Belt.Array`.

### 2. Refactored Navigation System
**File**: `src/systems/Navigation.res`
- Replaced `ReBindings.PubSub.publish` with `EventBus.dispatch(NavStart(...))`.
- Replaced subscribers for `navCompleted` and `navCancelled` with `EventBus.subscribe`.
- Removed legacy JS object payload construction.

### 3. Refactored Navigation Renderer
**File**: `src/systems/NavigationRenderer.res`
- **Major Refactor**: Switched from loose ReScript object types (`{"dist": float}`) to shared `Types.*` records (`pathData`, `journeyData`).
- Integrated `EventBus.subscribe` loop in `init()`.
- Added logic to handle `NavStart`, `NavCancelled`, and `ClearSimUi` via pattern matching.

### 4. Cleanup
- **Deleted**: `src/utils/PubSub.js`.
- **Cleaned**: Removed `PubSub` module definition from `src/ReBindings.res`.

## Verification

- **Build**: `npm run res:build` passed successfully.
- **Dependency Scan**: `grep` confirmed no other files (e.g., `App.res`, `Sidebar.res`) were using the legacy `PubSub`.

## Definition of Done
- [x] Create `src/systems/EventBus.res`
- [x] Refactored Navigation to dispatch typed events
- [x] Refactored NavigationRenderer to subscribe to typed events
- [x] Deleted `src/utils/PubSub.js`
- [x] Verified build passes

## Impact
This migration removes a major source of runtime unsafety (string-based events and untyped JS payloads). The navigation system now uses shared, compile-time checked ReScript records for all data flow between logic and renderer.
