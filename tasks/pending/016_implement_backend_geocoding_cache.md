# Implement Backend Geocoding Cache

## Objective
Add a caching layer to the backend geocoding service to store previously resolved coordinates, reducing external API calls and improving performance.

## Steps
1. Create a cache structure (e.g., `DashMap` or `RwLock<HashMap>`) in `backend/src/services/geocoding.rs`.
2. Implement logic to check the cache before making an external request.
3. Implement logic to persist the cache to `cache/geocoding.json` on shutdown and load it on startup.
4. Add telemetry to track cache hits vs. misses.
5. Add unit tests for the caching logic.
