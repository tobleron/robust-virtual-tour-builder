# Architecture Diagram: Frontend vs Backend Responsibilities

## Current Architecture (Optimal)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FRONTEND (Browser)                          │
│                    JavaScript/ReScript (970KB)                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ UI LAYER (90% ReScript)                                      │  │
│  │ • Viewer (Pannellum integration)                             │  │
│  │ • Sidebar, SceneList, LinkModal                              │  │
│  │ • Visual Pipeline (drag-drop timeline)                       │  │
│  │ • HotspotManager                                             │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ STATE MANAGEMENT (100% ReScript)                             │  │
│  │ • Global Store + Reducer                                     │  │
│  │ • Navigation Logic                                           │  │
│  │ • Simulation System                                          │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ COORDINATION LAYER (JavaScript)                              │  │
│  │ • Upload Orchestration (UploadProcessor.res)                 │  │
│  │ • Progress Tracking                                          │  │
│  │ • Cache Management (IndexedDB)                               │  │
│  │ • Template Generation (TourHTMLTemplate.js) ⚡ One-time      │  │
│  │ • EXIF Report (ExifReportGenerator.js) ⚡ One-time           │  │
│  │ • Image Similarity (ImageAnalysis.res) ⚡ Lightweight        │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTP/REST
                                    │ (FormData, JSON)
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      BACKEND (Rust/Actix-web)                       │
│                         handlers.rs (1,879 lines)                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ IMAGE PROCESSING PIPELINE 🚀 HEAVY COMPUTATION               │  │
│  │ • Decode (image crate) ~50-100ms                             │  │
│  │ • EXIF Extraction (kamadak-exif) ~10-20ms                    │  │
│  │ • Quality Analysis (histogram, sharpness) ~30-50ms           │  │
│  │ • Multi-resolution Resize (fast_image_resize) ~100-200ms     │  │
│  │ • WebP Encoding (libwebp) ~150-300ms                         │  │
│  │ • SHA-256 Checksum (sha2) ~20-40ms                           │  │
│  │ • Metadata Injection (img-parts) ~10ms                       │  │
│  │ TOTAL: ~350-700ms per image                                  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ VIDEO PROCESSING 🚀 HEAVY COMPUTATION                        │  │
│  │ • FFmpeg Transcoding (WebM → MP4) ~2-5 seconds               │  │
│  │ • Native binary execution                                    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ PROJECT MANAGEMENT 🚀 OPTIMIZED                              │  │
│  │ • Single-ZIP Load (eliminates N+1 requests)                  │  │
│  │ • Validation (broken links, orphaned scenes)                 │  │
│  │ • Session Management                                         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ TOUR EXPORT 🚀 PARALLEL PROCESSING                           │  │
│  │ • Multi-resolution batch (4K, 2K, HD)                        │  │
│  │ • Parallel image processing (rayon)                          │  │
│  │ • ZIP compression                                            │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ TEASER GENERATION 🚀 AUTOMATED                               │  │
│  │ • Headless Chrome rendering                                  │  │
│  │ • Automated tour recording                                   │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Performance Characteristics

### ✅ Already Backend-Optimized (100%)
- **Image Processing**: 10-50x faster than browser
- **Video Encoding**: Native FFmpeg (impossible in browser without 30MB WASM)
- **Checksum Calculation**: 10x faster than JavaScript
- **Parallel Processing**: Multi-core utilization via rayon

### ✅ Correctly Frontend-Placed
- **UI Rendering**: Must be in browser
- **State Management**: Type-safe ReScript, no network latency
- **Template Generation**: One-time operation, easier to maintain in JS
- **Image Similarity**: Operates on pre-computed data, 5-10ms

### ⚠️ Potential Optimizations (Not Backend Migration)
1. **Code Splitting**: Lazy load Pannellum (~150KB) and JSZip (~100KB)
   - Expected gain: 40% faster initial load
2. **Service Worker**: Cache static assets
   - Expected gain: Instant repeat loads
3. **Progressive Web App**: Offline capability

## Migration Analysis Summary

| Component | Current | Should Move? | Reason |
|-----------|---------|--------------|--------|
| Image Processing | Backend ✅ | No | Already optimal |
| Video Encoding | Backend ✅ | No | Already optimal |
| EXIF Extraction | Backend ✅ | No | Already optimal |
| Quality Analysis | Backend ✅ | No | Already optimal |
| Project Validation | Backend ✅ | No | Already optimal |
| EXIF Report Gen | Frontend | Maybe ⏸️ | Low priority, 12KB savings |
| HTML Templates | Frontend | No ❌ | One-time, easier in JS |
| Image Similarity | Frontend | No ❌ | Lightweight, correct placement |
| State Management | Frontend | No ❌ | Must be in browser |
| UI Components | Frontend | No ❌ | Must be in browser |

## Conclusion

**Current architecture is optimal.** All heavy computation is already in the Rust backend. The remaining frontend code is either:
- UI logic (must be in browser)
- One-time operations (templates, reports)
- Lightweight coordination (similarity checks)
- Correctly placed for latency reasons

**Performance gain from additional backend migration: ~0-2%**

**Better optimization strategies:**
1. Code splitting (40% faster initial load)
2. Service worker caching (instant repeat loads)
3. Continue ReScript migration for type safety (not performance)
