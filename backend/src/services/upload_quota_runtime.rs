// @efficiency-role: domain-logic
use crate::metrics::{QUOTA_CURRENT_SIZE_BYTES, QUOTA_CURRENT_UPLOADS};
use std::time::Instant;

use super::{QuotaStats, UploadHistory, UploadQuotaManager, UploadTracker};

pub(super) async fn try_register_upload(
    manager: &UploadQuotaManager,
    ip: &str,
    size: usize,
) -> Result<String, String> {
    if size > manager.config.max_payload_size {
        return Err(format!(
            "Upload size ({} MB) exceeds maximum allowed ({} MB)",
            size / (1024 * 1024),
            manager.config.max_payload_size / (1024 * 1024)
        ));
    }

    check_disk_space(manager).await?;

    let mut active = manager.active_uploads.write().await;

    if let Some(uploads) = active.get(ip)
        && uploads.len() >= manager.config.max_concurrent_per_ip
    {
        return Err(format!(
            "Too many concurrent uploads from your IP. Maximum: {}",
            manager.config.max_concurrent_per_ip
        ));
    }

    let total_size: usize = active
        .values()
        .flat_map(|uploads| uploads.iter())
        .map(|tracker| tracker.size)
        .sum();

    if total_size + size > manager.config.max_total_concurrent_size {
        return Err(
            "Server is currently processing too many uploads. Please try again later.".to_string(),
        );
    }

    let mut history = manager.upload_history.write().await;

    let now = Instant::now();
    let user_history = history
        .entry(ip.to_string())
        .or_insert_with(UploadHistory::new);

    user_history.cleanup_old(manager.config.rate_limit_window, now);

    if user_history.count_in_window(manager.config.rate_limit_window, now)
        >= manager.config.max_uploads_per_window
    {
        return Err(format!(
            "Upload rate limit exceeded. Maximum {} uploads per hour.",
            manager.config.max_uploads_per_window
        ));
    }

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

    if let Some(metric) = &*QUOTA_CURRENT_UPLOADS {
        metric.inc();
    }
    if let Some(metric) = &*QUOTA_CURRENT_SIZE_BYTES {
        metric.add(size as f64);
    }

    Ok(upload_id)
}

pub(super) async fn unregister_upload(manager: &UploadQuotaManager, ip: &str, size: usize) {
    let mut active = manager.active_uploads.write().await;
    if let Some(uploads) = active.get_mut(ip) {
        if let Some(position) = uploads.iter().position(|tracker| tracker.size == size) {
            uploads.remove(position);
            tracing::info!(ip = ip, size = size, "Upload completed");

            if let Some(metric) = &*QUOTA_CURRENT_UPLOADS {
                metric.dec();
            }
            if let Some(metric) = &*QUOTA_CURRENT_SIZE_BYTES {
                metric.sub(size as f64);
            }
        }

        if uploads.is_empty() {
            active.remove(ip);
        }
    }
}

pub(super) async fn check_disk_space(manager: &UploadQuotaManager) -> Result<(), String> {
    use std::path::Path;

    let fail_open = std::env::var("ALLOW_DISK_CHECK_BYPASS")
        .map(|value| value == "1" || value.eq_ignore_ascii_case("true"))
        .unwrap_or(false);

    if fail_open {
        return Ok(());
    }

    let temp_path = std::env::var("TEMP_DIR").unwrap_or_else(|_| "../tmp".to_string());

    match fs2::available_space(Path::new(&temp_path)) {
        Ok(available) => {
            if available < manager.config.min_free_disk_space {
                Err(format!(
                    "Insufficient disk space. Available: {} GB, Required: {} GB",
                    available / (1024 * 1024 * 1024),
                    manager.config.min_free_disk_space / (1024 * 1024 * 1024)
                ))
            } else {
                Ok(())
            }
        }
        Err(error) => {
            tracing::warn!("Failed to check disk space: {}", error);
            Err("Failed to verify available disk space".to_string())
        }
    }
}

pub(super) async fn get_stats(manager: &UploadQuotaManager) -> QuotaStats {
    let active = manager.active_uploads.read().await;
    let total_active: usize = active.values().map(|uploads| uploads.len()).sum();
    let total_size: usize = active
        .values()
        .flat_map(|uploads| uploads.iter())
        .map(|tracker| tracker.size)
        .sum();

    QuotaStats {
        active_uploads: total_active,
        total_active_size: total_size,
        max_total_size: manager.config.max_total_concurrent_size,
        utilization_percent: (total_size as f64 / manager.config.max_total_concurrent_size as f64
            * 100.0) as u32,
    }
}
