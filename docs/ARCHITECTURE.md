# System Architecture & Technical Specifications

This document outlines the high-level architecture, performance strategies, security controls, and observability systems of the Robust Virtual Tour Builder.

---

## 1. High-Level Architecture

The project follows a **System 2 Thinking** architecture, partitioned between a logic-heavy ReScript frontend and a performance-critical Rust backend.

### Component Breakdown
- **Frontend (ReScript)**: Handles UI state management, user interactions, and orchestration of complex workflows (Simulation, Teaser Generation).
- **Backend (Rust)**: Executes CPU-intensive tasks including image processing (WebP encoding), parallel quality analysis, and project packaging (ZIP).
- **Security Logic**: Memory-safe Rust eliminates common vulnerabilities like buffer overflows.

---

## 2. Performance Engineering

### Optimization Highlights
- **Single-ZIP Project Loading**: Consolidates metadata and images into one request, improving load times by **70%**.
- **Parallel processing (Rayon)**: Backend batch operations (Batch Geocoding, Similarity Checks) are up to **5x faster** than sequential JS.
- **Resource-Aware Resizing**: Balancing speed and quality using `fast_image_resize` (Lanczos3 for 4K).
- **Progressive Texture Loading**: 512px blurred previews load instantly, followed by a hot-swap to full 4K panoramas.

### Key Performance Metrics
| Metric | Target | Result | Status |
|:---|:---|:---|:---|
| Initial Bundle (Gzipped) | < 300KB | ~280KB | 🟢 Pass |
| Project Load (50 scenes) | < 5s | ~4s | 🟢 Pass |
| Image Process (4K) | < 1s | ~500ms | 🟢 Pass |
| UI Responsiveness | 60 FPS | 60 FPS | 🟢 Pass |

---

## 3. Security & Stability Systems

### Defense-in-Depth Strategy
- **Rust Sanitization**: Strict `sanitize_filename()` rejects directory traversal and null bytes.
- **Upload Hardening**: 100MB file size limits and shell metacharacter validation for safe command execution.
- **Network Security**: Rate limiting (30 req/sec) and environment-aware CORS (restricted in production).
- **XSS Prevention**: Strict CSP meta-tags and mandatory use of `textContent` in the frontend.

### Error Handling Philosophy
- **ReScript/Rust Types**: Errors are handled as values (Result/Option), preventing runtime crashes.
- **Graceful Degradation**: Failures in non-critical systems (like caching) do not interrupt the primary application flow.

---

## 4. Observability & Metrics

### System Monitoring
- **Visual Performance**: Throttled rendering (20fps during simulation) minimizes resource contention.
- **Log Categorization**: Structured logs track the visual pipeline (SCENE_SWAP, CROSSFADE_TRIGGER) to debug race conditions.
- **Turtle Logs**: Console warnings (🐢) highlight operations taking >500ms for developer awareness.

---

## 5. Teaser System & Video Pipeline

### Native Integration
- **FFmpeg Transcoding**: Native integration for WebM to MP4 conversion.
- **FFmpeg Core Caching**: Large binaries are cached in IndexedDB, reducing warm-start times from 30 seconds to near-instant.
- **Quality Control**: Visual quality is maintained via named constants (e.g., `WEBP_QUALITY`, `FFMPEG_CRF_QUALITY`).

---
*Last Updated: 2026-01-21*
