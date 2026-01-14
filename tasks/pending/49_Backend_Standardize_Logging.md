# Task: Standardize Rust Backend Logging Format

## Objective
Update all `tracing` calls in the Rust backend to use structured fields consistent with the frontend logging system.

## Context
The frontend uses standardized logging with `module`, `message`, and `data` fields. The backend should follow the same pattern for consistency in log analysis.

## Current State

Inconsistent logging patterns:
```rust
// Some use plain messages
tracing::info!("Tour package created successfully, size: {} bytes", zip_bytes.len());

// Some use structured fields
tracing::info!(error = ?self, "Request failed");
```

## Target State

All logs should use structured fields:
```rust
tracing::info!(
    module = "Exporter",
    message = "TOUR_PACKAGE_COMPLETE", 
    size_bytes = zip_bytes.len(),
    "Tour package created"
);
```

## Implementation Steps

### 1. Define Standard Log Points

| Handler | Log Points |
|---------|------------|
| `process_image_full` | `IMAGE_PROCESS_START`, `IMAGE_PROCESS_COMPLETE`, `IMAGE_ALREADY_OPTIMIZED` |
| `optimize_image` | `OPTIMIZE_START`, `OPTIMIZE_COMPLETE` |
| `resize_image_batch` | `BATCH_RESIZE_START`, `BATCH_RESIZE_COMPLETE` |
| `create_tour_package` | `TOUR_EXPORT_START`, `TOUR_EXPORT_COMPLETE` |
| `save_project` | `PROJECT_SAVE_START`, `PROJECT_SAVE_COMPLETE` |
| `load_project` | `PROJECT_LOAD_START`, `PROJECT_LOAD_COMPLETE` |
| `validate_project` | `VALIDATION_START`, `VALIDATION_COMPLETE` |
| `log_telemetry` | `TELEMETRY_RECEIVED` |

### 2. Update Each Handler

Example for `process_image_full`:
```rust
#[tracing::instrument(skip(payload), name = "process_image_full")]
pub async fn process_image_full(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "ImageProcessor", "IMAGE_PROCESS_START");
    
    // ... processing ...
    
    tracing::info!(
        module = "ImageProcessor",
        decode_ms = decode_time.as_millis(),
        resize_ms = opt_time.as_millis(),
        total_ms = total_start.elapsed().as_millis(),
        "IMAGE_PROCESS_COMPLETE"
    );
}
```

### 3. Update Error Logging in AppError

```rust
impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        // ... existing code ...
        
        // Structured error logging
        tracing::error!(
            module = "ErrorHandler",
            error_type = ?std::mem::discriminant(self),
            details = %self,
            "REQUEST_FAILED"
        );
        
        // ... rest
    }
}
```

### 4. Performance Warnings

Add performance warnings for slow operations:
```rust
let duration = start.elapsed();
if duration.as_millis() > 500 {
    tracing::warn!(
        module = "ImageProcessor",
        duration_ms = duration.as_millis(),
        "SLOW_OPERATION"
    );
} else {
    tracing::info!(
        module = "ImageProcessor", 
        duration_ms = duration.as_millis(),
        "IMAGE_PROCESS_COMPLETE"
    );
}
```

## Files to Modify

| File | Changes |
|------|---------|
| `backend/src/handlers.rs` | Update all tracing calls |
| `backend/src/main.rs` | Add structured logging initialization |

## Testing Checklist

- [ ] All handlers log start/complete events
- [ ] Error responses log with structured fields
- [ ] Log output includes module names
- [ ] Performance warnings trigger for operations >500ms
- [ ] RUST_LOG=debug shows all structured fields

## Definition of Done

- All tracing calls use structured fields
- Module names match frontend conventions
- Message names follow UPPER_SNAKE_CASE pattern
- Consistent format enables log aggregation and analysis
