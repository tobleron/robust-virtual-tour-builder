# Report: Implement Rust Backend Logging Endpoints

## Objective (Completed)
Add HTTP endpoints to the Rust backend for receiving frontend telemetry and persisting logs to disk files.

## Context
This is part of the hybrid logging architecture. The frontend (ReScript) catches and enriches errors, then forwards them to the backend for persistent storage. The backend ensures logs survive browser crashes and provides reliable persistence.

## Prerequisites
- None (can be done independently)

## Implementation Details

### 1. Add Logging Dependencies to Cargo.toml

```toml
[dependencies]
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
tokio = { version = "1", features = ["fs"] }
```

### 2. Create Log Entry Struct

In `src/handlers.rs` or a new `src/logging.rs`:

```rust
#[derive(Deserialize, Serialize, Debug)]
pub struct TelemetryEntry {
    pub level: String,
    pub module: String,
    pub message: String,
    pub data: Option<serde_json::Value>,
    pub timestamp: String,
}
```

### 3. Implement `/log-telemetry` Endpoint

```rust
pub async fn log_telemetry(Json(entry): Json<TelemetryEntry>) -> impl IntoResponse {
    // Append to telemetry.log as JSON line
    let line = serde_json::to_string(&entry).unwrap_or_default() + "\n";
    
    if let Err(e) = append_to_log("logs/telemetry.log", &line).await {
        eprintln!("Failed to write telemetry: {}", e);
    }
    
    StatusCode::OK
}
```

### 4. Implement `/log-error` Endpoint

```rust
pub async fn log_error(Json(entry): Json<TelemetryEntry>) -> impl IntoResponse {
    // Append to error.log as plaintext
    let line = format!("[{}] [{}] {} - {:?}\n", 
        entry.timestamp, entry.module, entry.message, entry.data);
    
    if let Err(e) = append_to_log("logs/error.log", &line).await {
        eprintln!("Failed to write error log: {}", e);
    }
    
    // Also append to telemetry for completeness
    let json_line = serde_json::to_string(&entry).unwrap_or_default() + "\n";
    let _ = append_to_log("logs/telemetry.log", &json_line).await;
    
    StatusCode::OK
}
```

### 5. Create Helper Function

```rust
async fn append_to_log(path: &str, content: &str) -> std::io::Result<()> {
    use tokio::fs::OpenOptions;
    use tokio::io::AsyncWriteExt;
    
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

### 6. Register Routes

In `src/main.rs`:

```rust
.route("/log-telemetry", post(handlers::log_telemetry))
.route("/log-error", post(handlers::log_error))
```

### 7. Ensure logs directory exists

Add to server startup:

```rust
std::fs::create_dir_all("logs").ok();
```

## Files to Modify

| File | Changes |
|------|---------|
| `backend/Cargo.toml` | Add tracing dependencies |
| `backend/src/handlers.rs` | Add TelemetryEntry struct and handlers |
| `backend/src/main.rs` | Register new routes, create logs dir |

## Testing Checklist

- [ ] `POST /log-telemetry` with valid JSON returns 200
- [ ] `POST /log-error` with valid JSON returns 200
- [ ] Entries appear in `logs/telemetry.log`
- [ ] Error entries appear in both `logs/error.log` and `logs/telemetry.log`
- [ ] Invalid JSON returns appropriate error (400)
- [ ] Server handles concurrent log writes without corruption

## Definition of Done

- Both endpoints implemented and registered
- Log files are created automatically if missing
- Logs are appended atomically (no corruption on concurrent writes)
- CORS headers allow frontend to call endpoints
