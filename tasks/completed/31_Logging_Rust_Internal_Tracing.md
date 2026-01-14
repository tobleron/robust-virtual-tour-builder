# Task: Add Rust Internal Logging with Tracing

## Objective
Instrument the Rust backend handlers with structured logging using the `tracing` crate for server-side observability.

## Context
The backend processes images, creates ZIP packages, and handles file I/O. These operations can fail or be slow. Internal logging helps diagnose issues that occur purely on the server side.

## Prerequisites
- Task 30 (Backend Endpoints) should be completed first

## Implementation Steps

### 1. Initialize Tracing Subscriber

In `src/main.rs`:

```rust
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

fn main() {
    tracing_subscriber::registry()
        .with(tracing_subscriber::fmt::layer())
        .with(tracing_subscriber::EnvFilter::from_default_env()
            .add_directive("backend=debug".parse().unwrap()))
        .init();
    
    // ... rest of main
}
```

### 2. Add Logging to resize_handler

```rust
use tracing::{info, warn, error, instrument};

#[instrument(skip(multipart))]
pub async fn resize_handler(multipart: Multipart) -> impl IntoResponse {
    info!(module = "Resizer", "RESIZE_START");
    
    let start = std::time::Instant::now();
    
    match process_images(multipart).await {
        Ok(result) => {
            let duration = start.elapsed().as_millis();
            info!(module = "Resizer", duration_ms = duration, "RESIZE_COMPLETE");
            Ok(Json(result))
        }
        Err(e) => {
            error!(module = "Resizer", error = %e, "RESIZE_FAILED");
            Err(ApiError::ProcessingFailed(e.to_string()))
        }
    }
}
```

### 3. Add Logging to create_tour_package

```rust
#[instrument(skip(multipart))]
pub async fn create_tour_package(multipart: Multipart) -> impl IntoResponse {
    info!(module = "Exporter", "EXPORT_RECEIVED");
    
    let start = std::time::Instant::now();
    
    // ... processing steps with info! logs
    info!(module = "Exporter", step = "extracting", "Processing multipart data");
    info!(module = "Exporter", step = "resizing", scenes = scenes.len(), "Resizing scenes");
    info!(module = "Exporter", step = "zipping", "Creating ZIP archive");
    
    match result {
        Ok(zip) => {
            let duration = start.elapsed().as_millis();
            info!(module = "Exporter", duration_ms = duration, "EXPORT_COMPLETE");
            Ok(zip)
        }
        Err(e) => {
            error!(module = "Exporter", error = %e, "EXPORT_FAILED");
            Err(e)
        }
    }
}
```

### 4. Add Logging to load_project

```rust
#[instrument(skip(body))]
pub async fn load_project(body: Bytes) -> impl IntoResponse {
    info!(module = "ProjectLoader", "PROJECT_LOAD_START");
    
    match parse_and_load(body).await {
        Ok(project) => {
            info!(module = "ProjectLoader", scenes = project.scenes.len(), "PROJECT_LOAD_COMPLETE");
            Ok(Json(project))
        }
        Err(e) => {
            error!(module = "ProjectLoader", error = %e, "PROJECT_LOAD_FAILED");
            Err(e)
        }
    }
}
```

### 5. Add Logging to Quality Analysis

```rust
pub fn analyze_quality(image: &DynamicImage) -> QualityStats {
    let start = std::time::Instant::now();
    
    // ... analysis
    
    let duration = start.elapsed().as_millis();
    if duration > 500 {
        warn!(module = "QualityAnalyzer", duration_ms = duration, "SLOW_ANALYSIS");
    } else {
        info!(module = "QualityAnalyzer", duration_ms = duration, "QUALITY_ANALYZED");
    }
    
    stats
}
```

## Files to Modify

| File | Changes |
|------|---------|
| `backend/src/main.rs` | Initialize tracing subscriber |
| `backend/src/handlers.rs` | Add #[instrument] and logging to handlers |
| `backend/src/quality.rs` | Add performance logging |
| `backend/src/resize.rs` | Add logging to resize operations |

## Testing Checklist

- [ ] Server startup shows tracing initialization
- [ ] Image resize operations log start/complete/failed
- [ ] Export operations log each step
- [ ] Slow operations (>500ms) log as warnings
- [ ] Error messages include relevant context
- [ ] RUST_LOG=debug shows more verbose output

## Definition of Done

- All major handlers instrumented with tracing
- Performance metrics logged for slow operations
- Errors logged with full context
- Configurable log level via RUST_LOG environment variable
