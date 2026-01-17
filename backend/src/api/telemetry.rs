use super::utils::{LOG_RETENTION_DAYS, MAX_LOG_FILES, MAX_LOG_SIZE};
use crate::models::{AppError, TelemetryEntry};
use actix_web::{HttpResponse, web};
use std::fs;
use std::time::Duration;

async fn rotate_log_file(path: &std::path::Path) -> std::io::Result<()> {
    let stem = path.file_stem().and_then(|s| s.to_str()).ok_or_else(|| {
        std::io::Error::new(std::io::ErrorKind::InvalidInput, "Invalid log file stem")
    })?;
    let ext = path.extension().and_then(|e| e.to_str()).unwrap_or("log");
    let dir = path.parent().ok_or_else(|| {
        std::io::Error::new(
            std::io::ErrorKind::InvalidInput,
            "Log file has no parent directory",
        )
    })?;

    // Shift existing rotated files
    for i in (1..MAX_LOG_FILES).rev() {
        let old = dir.join(format!("{}.{}.{}", stem, i, ext));
        let new = dir.join(format!("{}.{}.{}", stem, i + 1, ext));
        if let Ok(exists) = tokio::fs::try_exists(&old).await {
            if exists {
                tokio::fs::rename(&old, &new).await?;
            }
        }
    }

    // Rotate current file to .1
    let rotated = dir.join(format!("{}.1.{}", stem, ext));
    tokio::fs::rename(path, &rotated).await?;

    // Delete oldest if over limit
    let oldest = dir.join(format!("{}.{}.{}", stem, MAX_LOG_FILES, ext));
    if let Ok(exists) = tokio::fs::try_exists(&oldest).await {
        if exists {
            tokio::fs::remove_file(oldest).await?;
        }
    }

    Ok(())
}

#[allow(dead_code)] // Helper for rotation
async fn append_to_log(path: &str, content: &str) -> std::io::Result<()> {
    use tokio::fs::OpenOptions;
    use tokio::io::AsyncWriteExt;

    // Support configurable log directory via environment variable
    let log_dir_str = std::env::var("LOG_DIR").unwrap_or_else(|_| "../logs".to_string());
    let log_file_path = std::path::Path::new(&log_dir_str).join(path);

    // Check if rotation is needed
    if let Ok(metadata) = tokio::fs::metadata(&log_file_path).await {
        if metadata.len() > MAX_LOG_SIZE {
            if let Err(e) = rotate_log_file(&log_file_path).await {
                tracing::error!("Failed to rotate log file: {}", e);
            }
        }
    }

    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_file_path)
        .await?;

    file.write_all(content.as_bytes()).await?;
    file.flush().await?;

    Ok(())
}

#[tracing::instrument(name = "cleanup_logs")]
pub async fn cleanup_logs() -> impl actix_web::Responder {
    let log_dir_str = std::env::var("LOG_DIR").unwrap_or_else(|_| "../logs".to_string());

    // Use spawn_blocking for fs traversal as it's sync
    let result = web::block(move || -> std::io::Result<i32> {
        let logs_dir = std::path::Path::new(&log_dir_str);
        if !logs_dir.exists() {
            return Ok(0);
        }

        let mut count = 0;
        if let Ok(entries) = fs::read_dir(logs_dir) {
            for entry in entries {
                if let Ok(entry) = entry {
                    if let Ok(metadata) = entry.metadata() {
                        if let Ok(modified) = metadata.modified() {
                            if let Ok(age) = modified.elapsed() {
                                if age > Duration::from_secs(LOG_RETENTION_DAYS * 24 * 60 * 60) {
                                    fs::remove_file(entry.path()).ok();
                                    count += 1;
                                }
                            }
                        }
                    }
                }
            }
        }
        Ok(count)
    })
    .await;

    match result {
        Ok(Ok(count)) => HttpResponse::Ok().json(serde_json::json!({ "deleted": count })),
        _ => HttpResponse::InternalServerError().finish(),
    }
}

#[tracing::instrument(skip(entry), name = "log_telemetry")]
pub async fn log_telemetry(entry: web::Json<TelemetryEntry>) -> Result<HttpResponse, AppError> {
    println!("DEBUG: Received telemetry entry: {:?}", entry);
    // Append to telemetry.log as JSON line
    let line = serde_json::to_string(&entry.into_inner()).unwrap_or_default() + "\n";

    if let Err(e) = append_to_log("telemetry.log", &line).await {
        tracing::error!("Failed to write telemetry: {}", e);
    }

    Ok(HttpResponse::Ok().finish())
}

#[tracing::instrument(skip(entry), name = "log_error")]
pub async fn log_error(entry: web::Json<TelemetryEntry>) -> Result<HttpResponse, AppError> {
    println!("DEBUG: Received error entry: {:?}", entry);
    let entry_inner = entry.into_inner();

    // Append to error.log as plaintext
    let line = format!(
        "[{}] [{}] {} - {:?}\n",
        entry_inner.timestamp, entry_inner.module, entry_inner.message, entry_inner.data
    );

    if let Err(e) = append_to_log("error.log", &line).await {
        tracing::error!("Failed to write error log: {}", e);
    }

    // Also append to telemetry for completeness
    let json_line = serde_json::to_string(&entry_inner).unwrap_or_default() + "\n";
    let _ = append_to_log("telemetry.log", &json_line).await;

    Ok(HttpResponse::Ok().finish())
}

#[cfg(test)]
mod tests {
    #[test]
    fn placeholder() {}
}
