# Performance Optimization Analysis

This document outlines potential performance bottlenecks and recommended optimizations for the Remax Virtual Tour Builder, based on a comprehensive code analysis conducted on January 5, 2026.

---

## 🏎️ Backend Optimizations (Rust)

### 1. In-Memory Image Pipeline
**Current State**: Handlers like `process_image_full` write multi-megabyte temporary files to `/tmp` before processing.
**Optimization**: Stream multipart chunks directly into memory (`Vec<u8>` or `Cursor`) and process them without disk I/O.
**Impact**: Significant reduction in latency and disk wear, especially for high-volume uploads.

### 2. Analytical Optimization (No-Copy)
**Current State**: `perform_metadata_extraction` calls `analyzed_img.to_rgb8()`, which creates a full copy of the image.
**Optimization**: 
- Use `analyzed_img.as_rgb8()` (if applicable) or process pixels directly from the `DynamicImage` using `pixels()`.
- For luminance analysis, convert directly to Luma8 once instead of extracting from RGB.
**Impact**: Reduced memory pressure and CPU cycles.

### 3. Resizing Filter Calibration
**Current State**: `resize_image_batch` uses `Lanczos3` for all variants.
**Optimization**: Use `CatmullRom` for the 4K preview and HD variants. It offers a superior speed-to-quality ratio for web viewing compared to the computationally expensive `Lanczos3`.
**Impact**: 20-30% faster image processing in the batch resize pipeline.

---

## 🌐 Frontend Optimizations (JavaScript)

### 1. Progressive Texture Loading
**Current State**: `Viewer.js` loads the full 4K panorama immediately.
**Optimization**: Implement a two-phase load:
1. Load a tiny (e.g., 512px) blurred "low-res" preview first.
2. Initialize Pannellum with the low-res preview, then hot-swap the `panorama` source with the 4K version once loaded.
**Impact**: Near-instant perceived load time when switching scenes.

### 2. Snapshot Pre-calculation
**Current State**: `Viewer.js` captures a snapshot (`toBlob`) exactly when the user triggers a scene change.
**Optimization**: Capture the snapshot when the viewer is idle (e.g., 2 seconds after the last `viewchange` or `animatefinished`) and store it in the `store.js`.
**Impact**: Eliminates the 50-100ms "hiccup" during transition initiation.

### 3. Virtual Sidebar (Large Projects)
**Current State**: `SceneList.js` renders all scene thumbnails in the DOM.
**Optimization**: If the project grows beyond 50+ scenes, implement a "Virtual List" (using `IntersectionObserver`) to only render thumbnails visible in the viewport.
**Impact**: Maintains 60FPS UI responsiveness regardless of project size.

---

## 🛠️ Infrastructure & Build

### 1. Modern Bundling (Vite)
**Current State**: The project uses `npx live-server` and unbundled ES modules.
**Optimization**: Migrate to **Vite**. 
**Benefits**:
- Highly optimized production builds (tree-shaking, CSS minification).
- Faster HMR (Hot Module Replacement) for development.
- Built-in support for asset hashing (cache busting).

### 2. Web Worker Offloading
**Optimization**: Move `JSZip` operations (which are currently blocking the main thread during exports) into a **Web Worker**.
**Impact**: Prevents the UI from freezing during the export process.

---

*Analysis performed by AI Agent under the direction of Arto Kalishian.*
