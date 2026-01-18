use crate::metrics::{QUOTA_CURRENT_SIZE_BYTES, QUOTA_CURRENT_UPLOADS};
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
        Self {
            max_payload_size: 2 * 1024 * 1024 * 1024, // 2GB
            max_concurrent_per_ip: 24,
            max_total_concurrent_size: 10 * 1024 * 1024 * 1024, // 10GB total
            min_free_disk_space: 5 * 1024 * 1024 * 1024,        // 5GB free required
            rate_limit_window: Duration::from_secs(3600),       // 1 hour
            max_uploads_per_window: 500,
        }
    }
}

impl QuotaConfig {
    /// Load configuration from environment variables
    pub fn from_env() -> Self {
        Self {
            max_payload_size: std::env::var("MAX_PAYLOAD_SIZE")
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(2 * 1024 * 1024 * 1024),

            max_concurrent_per_ip: std::env::var("MAX_CONCURRENT_PER_IP")
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(24),

            max_total_concurrent_size: std::env::var("MAX_TOTAL_CONCURRENT_SIZE")
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(10 * 1024 * 1024 * 1024),

            min_free_disk_space: std::env::var("MIN_FREE_DISK_SPACE")
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(5 * 1024 * 1024 * 1024),

            rate_limit_window: Duration::from_secs(
                std::env::var("RATE_LIMIT_WINDOW_SECS")
                    .ok()
                    .and_then(|s| s.parse().ok())
                    .unwrap_or(3600),
            ),

            max_uploads_per_window: std::env::var("MAX_UPLOADS_PER_WINDOW")
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(500),
        }
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

    /// Check if an upload can proceed
    pub async fn can_upload(&self, ip: &str, size: usize) -> Result<(), String> {
        // Check payload size
        if size > self.config.max_payload_size {
            return Err(format!(
                "Upload size ({} MB) exceeds maximum allowed ({} MB)",
                size / (1024 * 1024),
                self.config.max_payload_size / (1024 * 1024)
            ));
        }

        // Check disk space
        self.check_disk_space().await?;

        let active = self.active_uploads.read().await;

        // Check per-IP concurrent limit
        if let Some(uploads) = active.get(ip)
            && uploads.len() >= self.config.max_concurrent_per_ip
        {
            return Err(format!(
                "Too many concurrent uploads from your IP. Maximum: {}",
                self.config.max_concurrent_per_ip
            ));
        }

        // Check global concurrent size
        let total_size: usize = active.values().flat_map(|v| v.iter()).map(|t| t.size).sum();

        if total_size + size > self.config.max_total_concurrent_size {
            return Err(
                "Server is currently processing too many uploads. Please try again later."
                    .to_string(),
            );
        }

        drop(active);

        // Check rate limit
        let now = Instant::now();
        let mut history = self.upload_history.write().await;
        let user_history = history
            .entry(ip.to_string())
            .or_insert_with(UploadHistory::new);

        user_history.cleanup_old(self.config.rate_limit_window, now);

        if user_history.count_in_window(self.config.rate_limit_window, now)
            >= self.config.max_uploads_per_window
        {
            return Err(format!(
                "Upload rate limit exceeded. Maximum {} uploads per hour.",
                self.config.max_uploads_per_window
            ));
        }

        Ok(())
    }

    /// Register a new upload
    pub async fn register_upload(&self, ip: &str, size: usize) -> String {
        let upload_id = uuid::Uuid::new_v4().to_string();
        let tracker = UploadTracker {
            ip: ip.to_string(),
            size,
            started_at: Instant::now(),
        };

        let mut active = self.active_uploads.write().await;
        active
            .entry(ip.to_string())
            .or_insert_with(Vec::new)
            .push(tracker);

        let mut history = self.upload_history.write().await;
        history
            .entry(ip.to_string())
            .or_insert_with(UploadHistory::new)
            .add_upload(Instant::now());

        tracing::info!(
            ip = ip,
            size = size,
            upload_id = %upload_id,
            "Upload registered"
        );

        // Metrics
        QUOTA_CURRENT_UPLOADS.inc();
        QUOTA_CURRENT_SIZE_BYTES.add(size as f64);

        upload_id
    }

    /// Unregister a completed upload
    pub async fn unregister_upload(&self, ip: &str, size: usize) {
        let mut active = self.active_uploads.write().await;
        if let Some(uploads) = active.get_mut(ip) {
            if let Some(pos) = uploads.iter().position(|t| t.size == size) {
                uploads.remove(pos);
                tracing::info!(ip = ip, size = size, "Upload completed");

                // Metrics
                QUOTA_CURRENT_UPLOADS.dec();
                QUOTA_CURRENT_SIZE_BYTES.sub(size as f64);
            }

            if uploads.is_empty() {
                active.remove(ip);
            }
        }
    }

    /// Check available disk space
    async fn check_disk_space(&self) -> Result<(), String> {
        use std::path::Path;

        // Get disk space for temp directory
        let temp_path = std::env::var("TEMP_DIR").unwrap_or_else(|_| "../temp".to_string());

        match fs2::available_space(Path::new(&temp_path)) {
            Ok(available) => {
                if available < self.config.min_free_disk_space {
                    Err(format!(
                        "Insufficient disk space. Available: {} GB, Required: {} GB",
                        available / (1024 * 1024 * 1024),
                        self.config.min_free_disk_space / (1024 * 1024 * 1024)
                    ))
                } else {
                    Ok(())
                }
            }
            Err(e) => {
                tracing::warn!("Failed to check disk space: {}", e);
                Ok(()) // Don't block uploads if we can't check
            }
        }
    }

    /// Get current quota statistics
    pub async fn get_stats(&self) -> QuotaStats {
        let active = self.active_uploads.read().await;
        let total_active: usize = active.values().map(|v| v.len()).sum();
        let total_size: usize = active.values().flat_map(|v| v.iter()).map(|t| t.size).sum();

        QuotaStats {
            active_uploads: total_active,
            total_active_size: total_size,
            max_total_size: self.config.max_total_concurrent_size,
            utilization_percent: (total_size as f64 / self.config.max_total_concurrent_size as f64
                * 100.0) as u32,
        }
    }
}

#[derive(serde::Serialize)]
pub struct QuotaStats {
    pub active_uploads: usize,
    pub total_active_size: usize,
    pub max_total_size: usize,
    pub utilization_percent: u32,
}
