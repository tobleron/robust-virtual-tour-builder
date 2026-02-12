// @efficiency: infra-adapter
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
    ).expect("Failed to register IMAGE_PROCESSING_TOTAL metric");

    // Image processing time
    pub static ref IMAGE_PROCESSING_DURATION: Histogram = register_histogram!(
        "image_processing_duration_seconds",
        "Image processing duration in seconds"
    ).expect("Failed to register IMAGE_PROCESSING_DURATION metric");

    // Total bytes uploaded
    pub static ref UPLOAD_BYTES_TOTAL: Counter = register_counter!(
        "upload_bytes_total",
        "Total bytes uploaded"
    ).expect("Failed to register UPLOAD_BYTES_TOTAL metric");

    // Currently active sessions
    pub static ref ACTIVE_SESSIONS: Gauge = register_gauge!(
        "active_sessions",
        "Currently active sessions"
    ).expect("Failed to register ACTIVE_SESSIONS metric");

    /*
     * Resource Metrics
     */

    // Current concurrent uploads
    pub static ref QUOTA_CURRENT_UPLOADS: Gauge = register_gauge!(
        "quota_current_uploads",
        "Current concurrent uploads"
    ).expect("Failed to register QUOTA_CURRENT_UPLOADS metric");

    // Current upload size in bytes
    pub static ref QUOTA_CURRENT_SIZE_BYTES: Gauge = register_gauge!(
        "quota_current_size_bytes",
        "Current upload size in bytes"
    ).expect("Failed to register QUOTA_CURRENT_SIZE_BYTES metric");

    // Cache hits for geocoding
    pub static ref GEOCODING_CACHE_HITS_TOTAL: Counter = register_counter!(
        "geocoding_cache_hits_total",
        "Cache hits for geocoding"
    ).expect("Failed to register GEOCODING_CACHE_HITS_TOTAL metric");

    // Cache misses for geocoding
    pub static ref GEOCODING_CACHE_MISSES_TOTAL: Counter = register_counter!(
        "geocoding_cache_misses_total",
        "Cache misses for geocoding"
    ).expect("Failed to register GEOCODING_CACHE_MISSES_TOTAL metric");
    // Scene switch latency
    pub static ref SCENE_SWITCH_DURATION: Histogram = register_histogram!(
        "scene_switch_duration_seconds",
        "Scene switch duration in seconds"
    ).expect("Failed to register SCENE_SWITCH_DURATION metric");

    // Project save latency
    pub static ref PROJECT_SAVE_DURATION: Histogram = register_histogram!(
        "project_save_duration_seconds",
        "Project save duration in seconds"
    ).expect("Failed to register PROJECT_SAVE_DURATION metric");

    // Project load latency
    pub static ref PROJECT_LOAD_DURATION: Histogram = register_histogram!(
        "project_load_duration_seconds",
        "Project load duration in seconds"
    ).expect("Failed to register PROJECT_LOAD_DURATION metric");

    // Error rate by type
    pub static ref ERRORS_TOTAL: CounterVec = register_counter_vec!(
        "errors_total",
        "Total errors by module and type",
        &["module", "error_type"]
    ).expect("Failed to register ERRORS_TOTAL metric");

    // Frontend long tasks (received via telemetry)
    pub static ref FE_LONG_TASKS_TOTAL: Counter = register_counter!(
        "frontend_long_tasks_total",
        "Total frontend long tasks > 50ms"
    ).expect("Failed to register FE_LONG_TASKS_TOTAL metric");
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
