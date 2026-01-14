# Task 77 Recovery Report: Elimination of Obj.magic in BackendApi.res

## Status: ✅ COMPLETED
## Date: 2026-01-14

## Summary of Changes
Refactored `BackendApi.res` to replace unsafe `Obj.magic` usage and "object-style" types (JS objects with string keys) with proper ReScript record types. This improves type safety and allows for dot-notation field access, preventing runtime errors related to incorrect field names.

### 1. Type Refactoring
- Created `geocodeRequest` and `geocodeResponse` record types for the geocoding service.
- Created `pathRequest` record type for pathfinder calculations.
- Converted `similarityPair`, `similarityResult`, and `similarityResponse` from object types to record types.
- Moved and consolidated `transitionTarget`, `arrivalView`, and `step` types at the top of the file.

### 2. Implementation Improvements
- **`reverseGeocode`**: Replaced string-key access (`data["address"]`) with record field access (`data.address`).
- **`batchCalculateSimilarity`**: Replaced string-key access (`data["results"]`) with record field access (`data.results`).
- **`calculatePath`**: Typed the `payload` argument as `pathRequest` instead of generic `'a`.
- Removed several unnecessary `Obj.magic` calls where type inference or proper record literals could be used.
- Kept `Obj.magic` only at the strict boundaries of JSON stringification and parsing, where it is necessary for FFI with the standard ReScript `JSON` module.

### 3. Downstream Updates
- Updated `TeaserPathfinder.res` to use record literals for `calculatePath` calls.
- Updated `UploadProcessor.res` to construction similarity pairs as records and access similarity results using dot notation.
- Fixed scoping issues by adding explicit type annotations to arrays where record fields were ambiguous.

## Verification
- [x] Ran `npm run res:build`: Compilation successful.
- [x] Verified type safety: No more `data["string_key"]` access on records.
- [x] Verified imports: All modules correctly reference the updated types.

## Files Modified
- `src/systems/BackendApi.res`
- `src/systems/TeaserPathfinder.res`
- `src/systems/UploadProcessor.res`
