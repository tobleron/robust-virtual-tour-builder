# Task: Add log-error Endpoint to Backend

## Objective
Implement the `/log-error` endpoint in the Rust backend for persistent critical error logging, as specified in the hybrid logging architecture.

## Context
The logging architecture specifies two endpoints:
- `/log-telemetry` - All logs at or above threshold ✅ (exists)
- `/log-error` - Critical errors, written to dedicated error.log ❌ (missing)

## Current State

Only `/log-telemetry` exists (line 87 in main.rs):
```rust
.route("/log-telemetry", web::post().to(handlers::log_telemetry))
```

## Implementation Steps

### 1. Add Route in main.rs

```rust
.route("/log-telemetry", web::post().to(handlers::log_telemetry))
.route("/log-error", web::post().to(handlers::log_error))  // Add this
```

### 2. Implement Handler in handlers.rs

```rust
/// Handle critical error logs - written to dedicated error.log
#[tracing::instrument(skip(payload), name = "log_error")]
pub async fn log_error(payload: web::Json<TelemetryPayload>) -> impl actix_web::Responder {
    let entry = payload.into_inner();
    
    // Format for error.log (plaintext)
    let error_line = format!(
        "[{}] [{}] {} - {:?}\n",
        entry.timestamp, entry.module, entry.message, entry.data
    );
    
    // Append to error.log
    if let Err(e) = append_to_log("logs/error.log", &error_line).await {
        tracing::error!(error = %e, "Failed to write to error.log");
    }
    
    // Also append to telemetry.log for completeness
    if let Ok(json_line) = serde_json::to_string(&entry) {
        let _ = append_to_log("logs/telemetry.log", &format!("{}\n", json_line)).await;
    }
    
    HttpResponse::Ok().finish()
}
```

### 3. Create append_to_log Helper

```rust
async fn append_to_log(path: &str, content: &str) -> std::io::Result<()> {
    use tokio::fs::OpenOptions;
    use tokio::io::AsyncWriteExt;
    
    // Ensure logs directory exists
    tokio::fs::create_dir_all("logs").await.ok();
    
    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(path)
        .await?;
    
    file.write_all(content.as_bytes()).await?;
    file.flush().await?;
    
    Ok(())
}
```

### 4. Update Cargo.toml

Ensure tokio has fs feature:
```toml
tokio = { version = "1", features = ["full"] }
```

### 5. Create logs Directory on Startup

In main.rs:
```rust
#[actix_web::main]
async fn main() -> io::Result<()> {
    // Create logs directory
    std::fs::create_dir_all("logs").ok();
    
    // ... rest of main
}
```

## Files to Modify

| File | Changes |
|------|---------|
| `backend/src/main.rs` | Add route and create logs dir |
| `backend/src/handlers.rs` | Add log_error handler and append_to_log helper |
| `backend/Cargo.toml` | Verify tokio features |

## Testing Checklist

- [ ] POST to /log-error with valid JSON returns 200
- [ ] Error entries appear in logs/error.log
- [ ] Error entries also appear in logs/telemetry.log
- [ ] logs directory is created automatically
- [ ] Invalid JSON returns appropriate error

## Definition of Done

- /log-error endpoint implemented
- Writes to both error.log (plaintext) and telemetry.log (JSON)
- Logs directory created on startup
- Frontend Debug.js appendToErrorLog() works correctly
