# Implement Backend Geocoding Proxy

## Objective
Move the reverse geocoding logic from the frontend (`ExifParser.res`) to a new backend endpoint to hide user IPs from external services, centralize rate limiting, and prepare for caching.

## Steps
1. Define `GeocodingRequest` and `GeocodingResponse` types in `backend/src/models/`.
2. Create a new service method in `backend/src/services/geocoding.rs` to handle external OSM API calls using `reqwest`.
3. Implement `POST /api/v1/reverse-geocode` in `backend/src/api/geocoding.rs`.
4. Update `src/systems/BackendApi.res` to include the new geocoding method.
5. Refactor `src/utils/ExifParser.res` to use the backend proxy instead of direct external calls.
6. Verify with integration tests.
