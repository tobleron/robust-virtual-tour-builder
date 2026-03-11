use std::time::Duration;

use super::QuotaConfig;

pub(super) fn default_config() -> QuotaConfig {
    let is_production = std::env::var("NODE_ENV")
        .map(|value| value.eq_ignore_ascii_case("production"))
        .unwrap_or(false);

    if is_production {
        return QuotaConfig {
            max_payload_size: 100 * 1024 * 1024,
            max_concurrent_per_ip: 4,
            max_total_concurrent_size: 2 * 1024 * 1024 * 1024,
            min_free_disk_space: 2 * 1024 * 1024 * 1024,
            rate_limit_window: Duration::from_secs(3600),
            max_uploads_per_window: 120,
        };
    }

    QuotaConfig {
        max_payload_size: 2 * 1024 * 1024 * 1024,
        max_concurrent_per_ip: 24,
        max_total_concurrent_size: 10 * 1024 * 1024 * 1024,
        min_free_disk_space: 5 * 1024 * 1024 * 1024,
        rate_limit_window: Duration::from_secs(3600),
        max_uploads_per_window: 2000,
    }
}

pub(super) fn env_usize(key: &str, default: usize) -> usize {
    std::env::var(key)
        .ok()
        .and_then(|value| value.parse().ok())
        .filter(|value| *value > 0)
        .unwrap_or(default)
}

pub(super) fn env_u64(key: &str, default: u64) -> u64 {
    std::env::var(key)
        .ok()
        .and_then(|value| value.parse().ok())
        .filter(|value| *value > 0)
        .unwrap_or(default)
}

pub(super) fn from_env_config() -> QuotaConfig {
    let defaults = default_config();
    QuotaConfig {
        max_payload_size: env_usize("MAX_PAYLOAD_SIZE", defaults.max_payload_size),
        max_concurrent_per_ip: env_usize("MAX_CONCURRENT_PER_IP", defaults.max_concurrent_per_ip),
        max_total_concurrent_size: env_usize(
            "MAX_TOTAL_CONCURRENT_SIZE",
            defaults.max_total_concurrent_size,
        ),
        min_free_disk_space: env_u64("MIN_FREE_DISK_SPACE", defaults.min_free_disk_space),
        rate_limit_window: Duration::from_secs(env_u64(
            "RATE_LIMIT_WINDOW_SECS",
            defaults.rate_limit_window.as_secs(),
        )),
        max_uploads_per_window: env_usize(
            "MAX_UPLOADS_PER_WINDOW",
            defaults.max_uploads_per_window,
        ),
    }
}
