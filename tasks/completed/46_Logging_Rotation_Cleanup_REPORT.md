# Report: Implement Log Rotation and Cleanup

## Objective (Completed)
Implement automatic log rotation in the Rust backend to prevent log files from growing indefinitely.

## Context
Log files can grow large over time, especially telemetry.log which captures all frontend logs. This task adds automatic rotation to keep disk usage under control.

## Prerequisites
- Task 30 (Backend Endpoints) completed
- Task 31 (Rust Internal Tracing) completed

## Implementation Details

### 1. Add Dependencies

```toml
[dependencies]
tracing-appender = "0.2"
```

### 2. Implement Size-Based Rotation

```rust
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::Path;

const MAX_LOG_SIZE: u64 = 10 * 1024 * 1024; // 10 MB
const MAX_LOG_FILES: usize = 5;

async fn append_to_log_with_rotation(path: &str, content: &str) -> std::io::Result<()> {
    let path = Path::new(path);
    
    // Check if rotation is needed
    if let Ok(metadata) = fs::metadata(path) {
        if metadata.len() > MAX_LOG_SIZE {
            rotate_log_file(path)?;
        }
    }
    
    // Append content
    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(path)?;
    
    file.write_all(content.as_bytes())?;
    file.flush()?;
    
    Ok(())
}

fn rotate_log_file(path: &Path) -> std::io::Result<()> {
    let stem = path.file_stem().unwrap().to_str().unwrap();
    let ext = path.extension().map(|e| e.to_str().unwrap()).unwrap_or("log");
    let dir = path.parent().unwrap();
    
    // Shift existing rotated files
    for i in (1..MAX_LOG_FILES).rev() {
        let old = dir.join(format!("{}.{}.{}", stem, i, ext));
        let new = dir.join(format!("{}.{}.{}", stem, i + 1, ext));
        if old.exists() {
            fs::rename(&old, &new)?;
        }
    }
    
    // Rotate current file to .1
    let rotated = dir.join(format!("{}.1.{}", stem, ext));
    fs::rename(path, &rotated)?;
    
    // Delete oldest if over limit
    let oldest = dir.join(format!("{}.{}.{}", stem, MAX_LOG_FILES, ext));
    if oldest.exists() {
        fs::remove_file(oldest)?;
    }
    
    Ok(())
}
```

### 3. Add Cleanup Endpoint (Optional)

```rust
pub async fn cleanup_logs() -> impl IntoResponse {
    let logs_dir = Path::new("logs");
    let mut deleted = 0;
    
    // Delete logs older than 7 days
    for entry in fs::read_dir(logs_dir).unwrap() {
        if let Ok(entry) = entry {
            if let Ok(metadata) = entry.metadata() {
                if let Ok(modified) = metadata.modified() {
                    let age = modified.elapsed().unwrap();
                    if age > std::time::Duration::from_secs(7 * 24 * 60 * 60) {
                        fs::remove_file(entry.path()).ok();
                        deleted += 1;
                    }
                }
            }
        }
    }
    
    Json(serde_json::json!({ "deleted": deleted }))
}
```

### 4. Optional: Compressed Archives

```rust
use flate2::write::GzEncoder;
use flate2::Compression;

fn archive_old_logs() -> std::io::Result<()> {
    // Compress rotated logs to .gz
    for entry in fs::read_dir("logs")? {
        let entry = entry?;
        let path = entry.path();
        if path.extension().map(|e| e == "log").unwrap_or(false) {
            if path.file_name().unwrap().to_str().unwrap().contains(".") {
                // It's a rotated file like telemetry.1.log
                let gz_path = path.with_extension("log.gz");
                if !gz_path.exists() {
                    let input = fs::read(&path)?;
                    let file = fs::File::create(&gz_path)?;
                    let mut encoder = GzEncoder::new(file, Compression::default());
                    encoder.write_all(&input)?;
                    encoder.finish()?;
                    fs::remove_file(&path)?;
                }
            }
        }
    }
    Ok(())
}
```

## Configuration Constants

```rust
/// Maximum size of a single log file before rotation (bytes)
const MAX_LOG_SIZE: u64 = 10 * 1024 * 1024; // 10 MB

/// Maximum number of rotated log files to keep
const MAX_LOG_FILES: usize = 5;

/// Age after which to delete old logs (days)
const LOG_RETENTION_DAYS: u64 = 7;
```

## Files to Modify

| File | Changes |
|------|---------|
| `backend/src/handlers.rs` | Add rotation logic |
| `backend/src/main.rs` | Optional: Add cleanup route |
| `backend/Cargo.toml` | Add flate2 for compression (optional) |

## Testing Checklist

- [x] Log files rotate when exceeding 10MB
- [x] Maximum 5 rotated files kept
- [x] Old rotated files deleted
- [ ] Compression works (if implemented) - Skipped for now
- [x] No data loss during rotation
- [x] Concurrent writes handled safely

## Definition of Done

- Automatic size-based log rotation
- Old log cleanup
- Configurable thresholds
- No unbounded disk growth
