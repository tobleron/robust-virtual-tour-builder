// @efficiency: util-pure
use super::utils::{LOG_RETENTION_DAYS, MAX_LOG_FILES, MAX_LOG_SIZE};
use std::fs;
use std::time::Duration;

pub async fn rotate_log_file(path: &std::path::Path) -> std::io::Result<()> {
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
        if let Ok(exists) = tokio::fs::try_exists(&old).await
            && exists
        {
            tokio::fs::rename(&old, &new).await?;
        }
    }

    // Rotate current file to .1
    let rotated = dir.join(format!("{}.1.{}", stem, ext));
    tokio::fs::rename(path, &rotated).await?;

    // Delete oldest if over limit
    let oldest = dir.join(format!("{}.{}.{}", stem, MAX_LOG_FILES, ext));
    if let Ok(exists) = tokio::fs::try_exists(&oldest).await
        && exists
    {
        tokio::fs::remove_file(oldest).await?;
    }

    Ok(())
}

pub async fn append_to_log(path: &str, content: &str) -> std::io::Result<()> {
    use tokio::fs::OpenOptions;
    use tokio::io::AsyncWriteExt;

    // Support configurable log directory via environment variable
    let log_dir_str = std::env::var("LOG_DIR").unwrap_or_else(|_| "../logs".to_string());
    let log_file_path = std::path::Path::new(&log_dir_str).join(path);

    // Check if rotation is needed
    if let Ok(metadata) = tokio::fs::metadata(&log_file_path).await
        && metadata.len() > MAX_LOG_SIZE
        && let Err(e) = rotate_log_file(&log_file_path).await
    {
        tracing::error!("Failed to rotate log file: {}", e);
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

pub fn cleanup_logs_sync(log_dir_str: &str) -> std::io::Result<i32> {
    let logs_dir = std::path::Path::new(&log_dir_str);
    if !logs_dir.exists() {
        return Ok(0);
    }

    let mut count = 0;
    if let Ok(entries) = fs::read_dir(logs_dir) {
        for entry in entries {
            if let Ok(entry) = entry
                && let Ok(metadata) = entry.metadata()
                && let Ok(modified) = metadata.modified()
                && let Ok(age) = modified.elapsed()
                && age > Duration::from_secs(LOG_RETENTION_DAYS * 24 * 60 * 60)
            {
                fs::remove_file(entry.path()).ok();
                count += 1;
            }
        }
    }
    Ok(count)
}
