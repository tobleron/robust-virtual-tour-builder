use std::sync::Arc;
use std::time::Duration;
use tokio::sync::RwLock;

/// Manages graceful shutdown procedures
pub struct ShutdownManager {
    active_requests: Arc<RwLock<usize>>,
    shutdown_timeout: Duration,
}

impl ShutdownManager {
    pub fn new(shutdown_timeout: Duration) -> Self {
        Self {
            active_requests: Arc::new(RwLock::new(0)),
            shutdown_timeout,
        }
    }

    /// Register a new active request
    pub async fn register_request(&self) {
        let mut count = self.active_requests.write().await;
        *count += 1;
        tracing::debug!(active_requests = *count, "Request registered");
    }

    /// Unregister a completed request
    pub async fn unregister_request(&self) {
        let mut count = self.active_requests.write().await;
        *count = count.saturating_sub(1);
        tracing::debug!(active_requests = *count, "Request unregistered");
    }

    /// Get current active request count
    pub async fn active_count(&self) -> usize {
        *self.active_requests.read().await
    }

    /// Wait for all active requests to complete (with timeout)
    pub async fn wait_for_completion(&self) -> bool {
        let start = std::time::Instant::now();

        loop {
            let count = self.active_count().await;

            if count == 0 {
                tracing::info!("All requests completed");
                return true;
            }

            if start.elapsed() >= self.shutdown_timeout {
                tracing::warn!(
                    remaining_requests = count,
                    "Shutdown timeout reached, {} requests still active",
                    count
                );
                return false;
            }

            tracing::info!(
                remaining_requests = count,
                elapsed_secs = start.elapsed().as_secs(),
                "Waiting for requests to complete..."
            );

            tokio::time::sleep(Duration::from_millis(500)).await;
        }
    }
}

/// Cleanup temporary files
pub async fn cleanup_temp_files() -> std::io::Result<()> {
    use std::fs;
    use std::path::Path;

    let temp_dir = std::env::var("TEMP_DIR").unwrap_or_else(|_| "../temp".to_string());
    let sessions_dir = std::env::var("SESSIONS_DIR").unwrap_or_else(|_| "../sessions".to_string());

    tracing::info!("Cleaning up temporary files...");

    // Clean temp directory
    if Path::new(&temp_dir).exists() {
        let mut removed_count = 0;
        for entry in fs::read_dir(&temp_dir)? {
            let entry = entry?;
            let path = entry.path();

            // Only remove files older than 1 hour (safety check)
            if let Ok(metadata) = fs::metadata(&path) {
                if let Ok(modified) = metadata.modified() {
                    if let Ok(elapsed) = modified.elapsed() {
                        if elapsed > Duration::from_secs(3600) {
                            if fs::remove_file(&path).is_ok() {
                                removed_count += 1;
                            }
                        }
                    }
                }
            }
        }
        tracing::info!(removed_files = removed_count, "Temp files cleaned");
    }

    // Clean old session directories (older than 24 hours)
    if Path::new(&sessions_dir).exists() {
        let mut removed_count = 0;
        for entry in fs::read_dir(&sessions_dir)? {
            let entry = entry?;
            let path = entry.path();

            if path.is_dir() {
                if let Ok(metadata) = fs::metadata(&path) {
                    if let Ok(modified) = metadata.modified() {
                        if let Ok(elapsed) = modified.elapsed() {
                            if elapsed > Duration::from_secs(86400) {
                                // 24 hours
                                if fs::remove_dir_all(&path).is_ok() {
                                    removed_count += 1;
                                }
                            }
                        }
                    }
                }
            }
        }
        tracing::info!(removed_sessions = removed_count, "Old sessions cleaned");
    }

    Ok(())
}

/// Persist all caches to disk
pub async fn persist_caches() -> Result<(), String> {
    tracing::info!("Persisting caches...");

    // Save geocoding cache
    if let Err(e) = crate::services::geocoding::save_cache_to_disk().await {
        tracing::error!(error = %e, "Failed to save geocoding cache");
        return Err(format!("Failed to save geocoding cache: {}", e));
    }

    tracing::info!("All caches persisted successfully");
    Ok(())
}

/// Perform all shutdown cleanup tasks
pub async fn perform_shutdown_cleanup(shutdown_manager: &ShutdownManager) {
    tracing::info!("🛑 Initiating graceful shutdown...");

    // Wait for active requests to complete
    let all_completed = shutdown_manager.wait_for_completion().await;

    if !all_completed {
        tracing::warn!("Some requests did not complete in time");
    }

    // Persist caches
    if let Err(e) = persist_caches().await {
        tracing::error!(error = %e, "Cache persistence failed");
    }

    // Clean up temporary files
    if let Err(e) = cleanup_temp_files().await {
        tracing::error!(error = %e, "Temp file cleanup failed");
    }

    tracing::info!("✅ Graceful shutdown complete");
}
