// @efficiency: domain-logic
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
        let is_production = std::env::var("NODE_ENV")
            .map(|v| v.eq_ignore_ascii_case("production"))
            .unwrap_or(false);

        if is_production {
            // Safe-by-default production limits.
            return Self {
                max_payload_size: 100 * 1024 * 1024, // 100MB
                max_concurrent_per_ip: 4,
                max_total_concurrent_size: 2 * 1024 * 1024 * 1024, // 2GB total
                min_free_disk_space: 2 * 1024 * 1024 * 1024,       // 2GB free required
                rate_limit_window: Duration::from_secs(3600),      // 1 hour
                max_uploads_per_window: 120,
            };
        }

        Self {
            max_payload_size: 2 * 1024 * 1024 * 1024, // 2GB (dev)
            max_concurrent_per_ip: 24,
            max_total_concurrent_size: 10 * 1024 * 1024 * 1024, // 10GB total (dev)
            min_free_disk_space: 5 * 1024 * 1024 * 1024,        // 5GB free required
            rate_limit_window: Duration::from_secs(3600),       // 1 hour
            max_uploads_per_window: 2000,
        }
    }
}

impl QuotaConfig {
    fn env_usize(key: &str, default: usize) -> usize {
        std::env::var(key)
            .ok()
            .and_then(|s| s.parse().ok())
            .filter(|v| *v > 0)
            .unwrap_or(default)
    }

    fn env_u64(key: &str, default: u64) -> u64 {
        std::env::var(key)
            .ok()
            .and_then(|s| s.parse().ok())
            .filter(|v| *v > 0)
            .unwrap_or(default)
    }

    /// Load configuration from environment variables
    pub fn from_env() -> Self {
        let defaults = Self::default();
        Self {
            max_payload_size: Self::env_usize("MAX_PAYLOAD_SIZE", defaults.max_payload_size),
            max_concurrent_per_ip: Self::env_usize(
                "MAX_CONCURRENT_PER_IP",
                defaults.max_concurrent_per_ip,
            ),
            max_total_concurrent_size: Self::env_usize(
                "MAX_TOTAL_CONCURRENT_SIZE",
                defaults.max_total_concurrent_size,
            ),
            min_free_disk_space: Self::env_u64("MIN_FREE_DISK_SPACE", defaults.min_free_disk_space),
            rate_limit_window: Duration::from_secs(Self::env_u64(
                "RATE_LIMIT_WINDOW_SECS",
                defaults.rate_limit_window.as_secs(),
            )),
            max_uploads_per_window: Self::env_usize(
                "MAX_UPLOADS_PER_WINDOW",
                defaults.max_uploads_per_window,
            ),
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

    /// Try to register an upload. Checks all quotas atomically (except disk space which is checked first).
    /// Returns Ok(upload_id) if successful, Err(reason) if rejected.
    pub async fn try_register_upload(&self, ip: &str, size: usize) -> Result<String, String> {
        // Check payload size
        if size > self.config.max_payload_size {
            return Err(format!(
                "Upload size ({} MB) exceeds maximum allowed ({} MB)",
                size / (1024 * 1024),
                self.config.max_payload_size / (1024 * 1024)
            ));
        }

        // Check disk space (IO, no lock)
        self.check_disk_space().await?;

        // Acquire active uploads write lock
        let mut active = self.active_uploads.write().await;

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

        // Acquire history write lock
        let mut history = self.upload_history.write().await;

        let now = Instant::now();
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

        // Register
        let upload_id = uuid::Uuid::new_v4().to_string();
        let tracker = UploadTracker {
            ip: ip.to_string(),
            size,
            started_at: now,
        };

        active
            .entry(ip.to_string())
            .or_insert_with(Vec::new)
            .push(tracker);

        user_history.add_upload(now);

        tracing::info!(
            ip = ip,
            size = size,
            upload_id = %upload_id,
            "Upload registered"
        );

        // Metrics
        if let Some(m) = &*QUOTA_CURRENT_UPLOADS {
            m.inc();
        }
        if let Some(m) = &*QUOTA_CURRENT_SIZE_BYTES {
            m.add(size as f64);
        }

        Ok(upload_id)
    }

    /// Unregister a completed upload
    pub async fn unregister_upload(&self, ip: &str, size: usize) {
        let mut active = self.active_uploads.write().await;
        if let Some(uploads) = active.get_mut(ip) {
            if let Some(pos) = uploads.iter().position(|t| t.size == size) {
                uploads.remove(pos);
                tracing::info!(ip = ip, size = size, "Upload completed");

                // Metrics
                if let Some(m) = &*QUOTA_CURRENT_UPLOADS {
                    m.dec();
                }
                if let Some(m) = &*QUOTA_CURRENT_SIZE_BYTES {
                    m.sub(size as f64);
                }
            }

            if uploads.is_empty() {
                active.remove(ip);
            }
        }
    }

    /// Check available disk space
    async fn check_disk_space(&self) -> Result<(), String> {
        use std::path::Path;

        let fail_open = std::env::var("ALLOW_DISK_CHECK_BYPASS")
            .map(|v| v == "1" || v.eq_ignore_ascii_case("true"))
            .unwrap_or(false);

        if fail_open {
            return Ok(());
        }

        // Get disk space for temp directory
        let temp_path = std::env::var("TEMP_DIR").unwrap_or_else(|_| "../tmp".to_string());

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
                Err("Failed to verify available disk space".to_string())
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
