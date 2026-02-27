# Task: Backend Image Processing Pipeline Streaming & Memory Optimization

## Objective
Convert the backend image processing pipeline from load-entire-file-in-memory to streaming architecture with bounded memory usage, enabling processing of ultra-high-resolution panoramas (16K+, 100MB+) without OOM risk.

## Problem Statement
`backend/src/services/media/resizing.rs` loads the entire source image into memory as `DynamicImage`, then converts to RGBA (`to_rgba8()`) which doubles memory usage. For a 16384×8192 panorama, this requires ~512MB RAM per image (source + RGBA buffer + resize target). Under concurrent uploads, the backend can easily exhaust available memory. The `image_tasks.rs` processes images sequentially per upload but multiple uploads run concurrently.

## Acceptance Criteria
- [ ] Implement streaming JPEG decode using `image::io::Reader` with configurable decode limits (`max_dimensions`, `max_alloc`)
- [ ] Add a memory budget semaphore: limit total in-flight image memory to a configurable threshold (default: 1GB), queue subsequent tasks
- [ ] Use `tokio::task::spawn_blocking` for CPU-bound resize operations with a bounded thread pool
- [ ] Add progressive resize: for very large images, downscale in 2x steps (e.g., 16K → 8K → 4K) to reduce peak memory
- [ ] Implement streaming WebP encoding instead of materializing the entire resized buffer
- [ ] Add per-request memory high-water-mark logging for diagnostics
- [ ] Enforce `max_upload_size` at the Actix multipart boundary to reject oversized files early

## Technical Notes
- **Files**: `backend/src/services/media/resizing.rs`, `backend/src/api/media/image_logic.rs`, `backend/src/api/media/image_tasks.rs`
- **Pattern**: `tokio::sync::Semaphore` for memory budget, `spawn_blocking` for CPU work
- **Risk**: Medium — must ensure resize quality is maintained with progressive approach
- **Measurement**: Peak RSS during 10 concurrent 50MB panorama uploads should stay ≤ 2GB
