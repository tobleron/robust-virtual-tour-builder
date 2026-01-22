# Task 018: Offload Image Similarity to Backend (Rayon)

## 🎯 Objective
Migrate image similarity calculations from the frontend to the backend to take advantage of Rust's performance and Rayon's parallel iteration capabilities.

## 🛠 Technical Implementation
- **Backend Implementation**:
  - Implemented `histogram_intersection` and `calculate_similarity` in `backend/src/api/media/similarity.rs`.
  - Used `rayon` for parallel processing of similarity pairs in the `batch_calculate_similarity` handler.
  - Added `POST /api/media/similarity` endpoint to handle batch requests.
- **Frontend Integration**:
  - Updated `src/systems/BackendApi.res` with `batchCalculateSimilarity` to interface with the new backend endpoint.
  - Refactored `src/systems/UploadProcessor.res` to build batches of image pairs and offload the calculation to the backend.
- **Verification**:
  - Verified backend unit tests for histogram binning and intersection logic.
  - Confirmed the frontend correctly calls the backend API and processes the results.
  - Verified that timing telemetry is included in backend logs for performance monitoring.

## 📝 Notes
- The implementation was found to be already completed in the codebase. This task served as a verification of the offloading strategy and parallel performance optimizations.