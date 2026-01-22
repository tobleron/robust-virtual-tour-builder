# Offload Image Similarity to Backend (Rayon)

## Objective
Migrate image similarity calculations from the frontend to the backend to take advantage of Rust's performance and Rayon's parallel iteration capabilities.

## Steps
1. Implement histogram calculation and intersection logic in `backend/src/api/media/similarity.rs`.
2. Use `rayon` to parallelize similarity checks when comparing multiple image pairs.
3. Create `POST /api/v1/batch-calculate-similarity` endpoint.
4. Update `src/systems/BackendApi.res` and the frontend similarity logic to call this endpoint for batches.
5. Benchmarking to confirm performance gains.
