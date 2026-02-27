# T1574 - Troubleshoot geocoding cache JSON key panic

## Hypothesis (Ordered Expected Solutions)
- [x] Replace tuple-key JSON object persistence with key-safe serialized entries (`[{lat, lon, ...}]`) to eliminate `key must be a string` panic path.
- [x] Add backward-compatible loader path for both new `entries` and legacy `cache` payloads; on malformed payload, log warning and start with empty cache.
- [x] Add regression tests to ensure save/load never panics on tuple-key cache and malformed payload does not crash.

## Activity Log
- [x] Create focused fix in `backend/src/services/geocoding/cache.rs`.
- [x] Add/adjust tests in geocoding modules.
- [x] Run targeted backend tests and full backend tests.
- [x] Verify frontend build unaffected.

## Code Change Ledger
- [x] `backend/src/services/geocoding/cache.rs`: replaced tuple-key object persistence with `PersistedCachePayload.entries` list format; added resilient decoding (`decode_cache_payload`) with malformed-payload fallback.
- [x] `backend/src/services/geocoding/cache.rs`: added unit regression tests for malformed legacy payload and valid entries payload decoding.

## Rollback Check
- [x] Confirmed CLEAN (all implemented changes are required for the successful fix; no non-working edits left).

## Context Handoff
- Root cause was JSON serialization of tuple-key `HashMap<GeocodeKey, CachedGeocode>` in `save_cache_to_disk`, which produced panic during API test flows touching cache persistence. Cache persistence now writes `entries` with explicit `lat/lon` fields and loader handles malformed payloads gracefully without panicking. Full backend tests now pass, and frontend build remains green.
