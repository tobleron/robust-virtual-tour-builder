use lazy_static::lazy_static;
use prometheus::{
    Counter, CounterVec, Gauge, Histogram, register_counter, register_counter_vec, register_gauge,
    register_histogram,
};

lazy_static! {
    /*
     * Business Metrics
     */

    // Images processed by type (optimize, resize)
    pub static ref IMAGE_PROCESSING_TOTAL: CounterVec = register_counter_vec!(
        "image_processing_total",
        "Total images processed",
        &["type"]
    ).unwrap();

    // Image processing time
    pub static ref IMAGE_PROCESSING_DURATION: Histogram = register_histogram!(
        "image_processing_duration_seconds",
        "Image processing duration in seconds"
    ).unwrap();

    // Total bytes uploaded
    pub static ref UPLOAD_BYTES_TOTAL: Counter = register_counter!(
        "upload_bytes_total",
        "Total bytes uploaded"
    ).unwrap();

    // Currently active sessions
    pub static ref ACTIVE_SESSIONS: Gauge = register_gauge!(
        "active_sessions",
        "Currently active sessions"
    ).unwrap();

    /*
     * Resource Metrics
     */

    // Current concurrent uploads
    pub static ref QUOTA_CURRENT_UPLOADS: Gauge = register_gauge!(
        "quota_current_uploads",
        "Current concurrent uploads"
    ).unwrap();

    // Current upload size in bytes
    pub static ref QUOTA_CURRENT_SIZE_BYTES: Gauge = register_gauge!(
        "quota_current_size_bytes",
        "Current upload size in bytes"
    ).unwrap();

    // Cache hits for geocoding
    pub static ref GEOCODING_CACHE_HITS_TOTAL: Counter = register_counter!(
        "geocoding_cache_hits_total",
        "Cache hits for geocoding"
    ).unwrap();

    // Cache misses for geocoding
    pub static ref GEOCODING_CACHE_MISSES_TOTAL: Counter = register_counter!(
        "geocoding_cache_misses_total",
        "Cache misses for geocoding"
    ).unwrap();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_metrics_initialization() {
        // Use the metrics to ensure they don't panic on initialization
        IMAGE_PROCESSING_TOTAL.with_label_values(&["test"]).inc();
        ACTIVE_SESSIONS.inc();
        QUOTA_CURRENT_UPLOADS.set(0.0);

        // Success if no panic
        assert!(true);
    }
}
