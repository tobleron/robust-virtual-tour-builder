// @efficiency: infra-adapter
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::time::Duration;

/// Manages graceful shutdown procedures
pub struct ShutdownManager {
    active_requests: Arc<AtomicUsize>,
    is_shutting_down: Arc<AtomicBool>,
    shutdown_timeout: Duration,
}

impl ShutdownManager {
    pub fn new(shutdown_timeout: Duration) -> Self {
        Self {
            active_requests: Arc::new(AtomicUsize::new(0)),
            is_shutting_down: Arc::new(AtomicBool::new(false)),
            shutdown_timeout,
        }
    }

    /// Mark shutdown as started. New requests should be rejected.
    pub fn begin_shutdown(&self) {
        self.is_shutting_down.store(true, Ordering::SeqCst);
        tracing::info!("Shutdown flag enabled");
    }

    pub fn is_shutting_down(&self) -> bool {
        self.is_shutting_down.load(Ordering::SeqCst)
    }

    /// Register a new active request
    pub fn register_request(&self) {
        let count = self.active_requests.fetch_add(1, Ordering::SeqCst) + 1;
        tracing::debug!(active_requests = count, "Request registered");
    }

    /// Unregister a completed request
    pub fn unregister_request(&self) {
        let mut current = self.active_requests.load(Ordering::SeqCst);
        loop {
            let next = current.saturating_sub(1);
            match self.active_requests.compare_exchange(
                current,
                next,
                Ordering::SeqCst,
                Ordering::SeqCst,
            ) {
                Ok(_) => {
                    tracing::debug!(active_requests = next, "Request unregistered");
                    break;
                }
                Err(actual) => current = actual,
            }
        }
    }

    /// Get current active request count
    pub fn active_count(&self) -> usize {
        self.active_requests.load(Ordering::SeqCst)
    }

    pub fn estimated_retry_after_secs(&self) -> u64 {
        let active = self.active_count() as u64;
        // Coarse estimate: at least 1s, up to timeout seconds.
        let estimate = (active / 5).max(1);
        estimate.min(self.shutdown_timeout.as_secs().max(1))
    }

    /// Wait for all active requests to complete (with timeout)
    pub async fn wait_for_completion(&self) -> bool {
        let start = std::time::Instant::now();
        let mut sleep_ms = 100_u64;

        loop {
            let count = self.active_count();

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

            tokio::time::sleep(Duration::from_millis(sleep_ms)).await;
            sleep_ms = (sleep_ms * 2).min(400);
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
            if let Ok(metadata) = fs::metadata(&path)
                && let Ok(modified) = metadata.modified()
                && let Ok(elapsed) = modified.elapsed()
                && elapsed > Duration::from_secs(3600)
                && fs::remove_file(&path).is_ok()
            {
                removed_count += 1;
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

            if path.is_dir()
                && let Ok(metadata) = fs::metadata(&path)
                && let Ok(modified) = metadata.modified()
                && let Ok(elapsed) = modified.elapsed()
                && elapsed > Duration::from_secs(86400)
            {
                // 24 hours
                if fs::remove_dir_all(&path).is_ok() {
                    removed_count += 1;
                }
            }
        }
        tracing::info!(removed_sessions = removed_count, "Old sessions cleaned");
    }

    Ok(())
}

/// Persist all caches to disk
#[cfg(feature = "builder-runtime")]
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

#[cfg(not(feature = "builder-runtime"))]
pub async fn persist_caches() -> Result<(), String> {
    Ok(())
}

#[cfg(feature = "builder-runtime")]
pub async fn persist_inflight_upload_sessions(
    import_manager: &crate::services::project::ChunkedProjectImportManager,
    export_manager: &crate::services::project::ChunkedProjectExportUploadManager,
) -> Result<(), String> {
    let import_count = import_manager.save_sessions_manifest().await?;
    let export_count = export_manager.save_sessions_manifest().await?;
    tracing::info!(
        import_sessions = import_count,
        export_sessions = export_count,
        "In-flight upload session manifests persisted"
    );
    Ok(())
}

/// Perform all shutdown cleanup tasks
#[cfg(feature = "builder-runtime")]
pub async fn perform_shutdown_cleanup(
    shutdown_manager: &ShutdownManager,
    import_manager: &crate::services::project::ChunkedProjectImportManager,
    export_manager: &crate::services::project::ChunkedProjectExportUploadManager,
) {
    tracing::info!("🛑 Initiating graceful shutdown...");
    let drain_started = std::time::Instant::now();

    // Wait for active requests to complete
    let all_completed = shutdown_manager.wait_for_completion().await;

    if !all_completed {
        tracing::warn!("Some requests did not complete in time");
    }

    // Persist caches
    if let Err(e) = persist_caches().await {
        tracing::error!(error = %e, "Cache persistence failed");
    }
    if let Err(e) = persist_inflight_upload_sessions(import_manager, export_manager).await {
        tracing::error!(error = %e, "In-flight upload session persistence failed");
    }

    // Clean up temporary files
    if let Err(e) = cleanup_temp_files().await {
        tracing::error!(error = %e, "Temp file cleanup failed");
    }

    tracing::info!(
        drain_ms = drain_started.elapsed().as_millis(),
        completed_all_requests = all_completed,
        remaining_requests = shutdown_manager.active_count(),
        "✅ Graceful shutdown complete"
    );
}

#[cfg(feature = "portal-runtime")]
pub async fn perform_portal_shutdown_cleanup(shutdown_manager: &ShutdownManager) {
    tracing::info!("🛑 Initiating portal graceful shutdown...");
    let drain_started = std::time::Instant::now();

    let all_completed = shutdown_manager.wait_for_completion().await;

    if !all_completed {
        tracing::warn!("Some portal requests did not complete in time");
    }

    if let Err(e) = cleanup_temp_files().await {
        tracing::error!(error = %e, "Portal temp file cleanup failed");
    }

    tracing::info!(
        drain_ms = drain_started.elapsed().as_millis(),
        completed_all_requests = all_completed,
        remaining_requests = shutdown_manager.active_count(),
        "✅ Portal graceful shutdown complete"
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn wait_for_completion_returns_false_on_timeout() {
        let manager = ShutdownManager::new(Duration::from_millis(50));
        manager.register_request();

        let completed = manager.wait_for_completion().await;
        assert!(!completed);
    }

    #[tokio::test]
    async fn begin_shutdown_blocks_new_requests() {
        let manager = ShutdownManager::new(Duration::from_secs(1));
        assert!(!manager.is_shutting_down());
        manager.begin_shutdown();
        assert!(manager.is_shutting_down());
    }
}
