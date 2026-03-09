#[path = "upload_quota_config.rs"]
mod upload_quota_config;
#[path = "upload_quota_runtime.rs"]
mod upload_quota_runtime;

// @efficiency: domain-logic
use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::RwLock;

/// Configuration for upload quotas
#[derive(Clone)]
pub struct QuotaConfig {
    /// Maximum payload size per request (bytes)
    pub max_payload_size: usize,

    /// Maximum concurrent uploads per IP
    pub max_concurrent_per_ip: usize,

    /// Maximum total concurrent upload size across all users (bytes)
    pub max_total_concurrent_size: usize,

    /// Minimum free disk space required (bytes)
    pub min_free_disk_space: u64,

    /// Time window for rate limiting (seconds)
    pub rate_limit_window: Duration,

    /// Maximum uploads per IP in time window
    pub max_uploads_per_window: usize,
}

impl Default for QuotaConfig {
    fn default() -> Self {
        upload_quota_config::default_config()
    }
}

impl QuotaConfig {
    #[allow(dead_code)]
    fn env_usize(key: &str, default: usize) -> usize {
        upload_quota_config::env_usize(key, default)
    }

    #[allow(dead_code)]
    fn env_u64(key: &str, default: u64) -> u64 {
        upload_quota_config::env_u64(key, default)
    }

    /// Load configuration from environment variables
    pub fn from_env() -> Self {
        upload_quota_config::from_env_config()
    }
}

/// Tracks active uploads
#[derive(Clone)]
struct UploadTracker {
    #[allow(dead_code)]
    ip: String,
    size: usize,
    #[allow(dead_code)]
    started_at: Instant,
}

/// Upload history for rate limiting
struct UploadHistory {
    uploads: Vec<Instant>,
}

impl UploadHistory {
    fn new() -> Self {
        Self {
            uploads: Vec::new(),
        }
    }

    fn add_upload(&mut self, now: Instant) {
        self.uploads.push(now);
    }

    fn count_in_window(&self, window: Duration, now: Instant) -> usize {
        self.uploads
            .iter()
            .filter(|&&time| now.duration_since(time) < window)
            .count()
    }

    fn cleanup_old(&mut self, window: Duration, now: Instant) {
        self.uploads
            .retain(|&time| now.duration_since(time) < window);
    }
}

/// Manages upload quotas and limits
pub struct UploadQuotaManager {
    config: QuotaConfig,
    active_uploads: Arc<RwLock<HashMap<String, Vec<UploadTracker>>>>,
    upload_history: Arc<RwLock<HashMap<String, UploadHistory>>>,
}

impl UploadQuotaManager {
    pub fn new(config: QuotaConfig) -> Self {
        Self {
            config,
            active_uploads: Arc::new(RwLock::new(HashMap::new())),
            upload_history: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Try to register an upload. Checks all quotas atomically (except disk space which is checked first).
    /// Returns Ok(upload_id) if successful, Err(reason) if rejected.
    pub async fn try_register_upload(&self, ip: &str, size: usize) -> Result<String, String> {
        upload_quota_runtime::try_register_upload(self, ip, size).await
    }

    /// Unregister a completed upload
    pub async fn unregister_upload(&self, ip: &str, size: usize) {
        upload_quota_runtime::unregister_upload(self, ip, size).await
    }

    /// Check available disk space
    #[allow(dead_code)]
    async fn check_disk_space(&self) -> Result<(), String> {
        upload_quota_runtime::check_disk_space(self).await
    }

    /// Get current quota statistics
    pub async fn get_stats(&self) -> QuotaStats {
        upload_quota_runtime::get_stats(self).await
    }
}

#[derive(serde::Serialize)]
pub struct QuotaStats {
    pub active_uploads: usize,
    pub total_active_size: usize,
    pub max_total_size: usize,
    pub utilization_percent: u32,
}
