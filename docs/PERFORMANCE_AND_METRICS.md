# Performance & Metrics

## 🎯 Core Web Vitals Targets
To ensure a commercial-grade user experience, the Virtual Tour Builder targets the following performance thresholds:

| Metric | Target | Description |
| :--- | :--- | :--- |
| **LCP (Largest Contentful Paint)** | `< 2.5s` | Time until the main panorama viewer is visible. |
| **FID (First Input Delay)** | `< 100ms` | Responsiveness to the first user interaction (click/tap). |
| **CLS (Cumulative Layout Shift)** | `< 0.1` | Visual stability of the UI overlay during loading. |

## 📊 Telemetry & Logging
-   **Trace Level**: `Info` (default), `Debug/Trace` (configurable via `RUST_LOG`).
-   **Error Reporting**: Critical errors include a state snapshot for debugging.
-   **Metrics**: Prometheus endpoint exposed at `/metrics` (Backend).

## 🚀 Optimization Strategies
1.  **Lazy Loading**: Only the initial scene is fully loaded; neighbors are preloaded in the background.
2.  **WebP Fallback**: Images are automatically converted to WebP for reduced bandwidth usage.
3.  **Rust Backend**: Heavy image processing (resizing, encoding) is offloaded to the Rust thread pool.
