// @efficiency: infra-adapter
use lazy_static::lazy_static;
use prometheus::{
    Counter, CounterVec, Gauge, Histogram, HistogramOpts, Opts, register_counter,
    register_counter_vec, register_gauge, register_histogram,
};

lazy_static! {
    /*
     * Business Metrics
     */

    // Images processed by type (optimize, resize)
    pub static ref IMAGE_PROCESSING_TOTAL: Option<CounterVec> = match register_counter_vec!(
        "image_processing_total",
        "Total images processed",
        &["type"]
    ) {
        Ok(m) => Some(m),
        Err(e) => {
            tracing::error!("Failed to register IMAGE_PROCESSING_TOTAL metric: {}", e);
            CounterVec::new(Opts::new("image_processing_total", "Total images processed"), &["type"]).ok()
        }
    };

    // Image processing time
    pub static ref IMAGE_PROCESSING_DURATION: Option<Histogram> = match register_histogram!(
        "image_processing_duration_seconds",
        "Image processing duration in seconds"
    ) {
        Ok(m) => Some(m),
        Err(e) => {
            tracing::error!("Failed to register IMAGE_PROCESSING_DURATION metric: {}", e);
            Histogram::with_opts(HistogramOpts::new("image_processing_duration_seconds", "Image processing duration in seconds")).ok()
        }
    };

    // Total bytes uploaded
    pub static ref UPLOAD_BYTES_TOTAL: Option<Counter> = match register_counter!(
        "upload_bytes_total",
        "Total bytes uploaded"
    ) {
        Ok(m) => Some(m),
        Err(e) => {
            tracing::error!("Failed to register UPLOAD_BYTES_TOTAL metric: {}", e);
            Counter::with_opts(Opts::new("upload_bytes_total", "Total bytes uploaded")).ok()
        }
    };

    // Currently active sessions
    pub static ref ACTIVE_SESSIONS: Option<Gauge> = match register_gauge!(
        "active_sessions",
        "Currently active sessions"
    ) {
        Ok(m) => Some(m),
        Err(e) => {
            tracing::error!("Failed to register ACTIVE_SESSIONS metric: {}", e);
            Gauge::with_opts(Opts::new("active_sessions", "Currently active sessions")).ok()
        }
    };

    /*
     * Resource Metrics
     */

    // Current concurrent uploads
    pub static ref QUOTA_CURRENT_UPLOADS: Option<Gauge> = match register_gauge!(
        "quota_current_uploads",
        "Current concurrent uploads"
    ) {
        Ok(m) => Some(m),
        Err(e) => {
            tracing::error!("Failed to register QUOTA_CURRENT_UPLOADS metric: {}", e);
            Gauge::with_opts(Opts::new("quota_current_uploads", "Current concurrent uploads")).ok()
        }
    };

    // Current upload size in bytes
    pub static ref QUOTA_CURRENT_SIZE_BYTES: Option<Gauge> = match register_gauge!(
        "quota_current_size_bytes",
        "Current upload size in bytes"
    ) {
        Ok(m) => Some(m),
        Err(e) => {
            tracing::error!("Failed to register QUOTA_CURRENT_SIZE_BYTES metric: {}", e);
            Gauge::with_opts(Opts::new("quota_current_size_bytes", "Current upload size in bytes")).ok()
        }
    };

    // Cache hits for geocoding
    pub static ref GEOCODING_CACHE_HITS_TOTAL: Option<Counter> = match register_counter!(
        "geocoding_cache_hits_total",
        "Cache hits for geocoding"
    ) {
        Ok(m) => Some(m),
        Err(e) => {
            tracing::error!("Failed to register GEOCODING_CACHE_HITS_TOTAL metric: {}", e);
            Counter::with_opts(Opts::new("geocoding_cache_hits_total", "Cache hits for geocoding")).ok()
        }
    };

    // Cache misses for geocoding
    pub static ref GEOCODING_CACHE_MISSES_TOTAL: Option<Counter> = match register_counter!(
        "geocoding_cache_misses_total",
        "Cache misses for geocoding"
    ) {
        Ok(m) => Some(m),
        Err(e) => {
            tracing::error!("Failed to register GEOCODING_CACHE_MISSES_TOTAL metric: {}", e);
            Counter::with_opts(Opts::new("geocoding_cache_misses_total", "Cache misses for geocoding")).ok()
        }
    };

    // Scene switch latency
    pub static ref SCENE_SWITCH_DURATION: Option<Histogram> = match register_histogram!(
        "scene_switch_duration_seconds",
        "Scene switch duration in seconds"
    ) {
        Ok(m) => Some(m),
        Err(e) => {
            tracing::error!("Failed to register SCENE_SWITCH_DURATION metric: {}", e);
            Histogram::with_opts(HistogramOpts::new("scene_switch_duration_seconds", "Scene switch duration in seconds")).ok()
        }
    };

    // Project save latency
    pub static ref PROJECT_SAVE_DURATION: Option<Histogram> = match register_histogram!(
        "project_save_duration_seconds",
        "Project save duration in seconds"
    ) {
        Ok(m) => Some(m),
        Err(e) => {
            tracing::error!("Failed to register PROJECT_SAVE_DURATION metric: {}", e);
            Histogram::with_opts(HistogramOpts::new("project_save_duration_seconds", "Project save duration in seconds")).ok()
        }
    };

    // Project load latency
    pub static ref PROJECT_LOAD_DURATION: Option<Histogram> = match register_histogram!(
        "project_load_duration_seconds",
        "Project load duration in seconds"
    ) {
        Ok(m) => Some(m),
        Err(e) => {
            tracing::error!("Failed to register PROJECT_LOAD_DURATION metric: {}", e);
            Histogram::with_opts(HistogramOpts::new("project_load_duration_seconds", "Project load duration in seconds")).ok()
        }
    };

    // Error rate by type
    pub static ref ERRORS_TOTAL: Option<CounterVec> = match register_counter_vec!(
        "errors_total",
        "Total errors by module and type",
        &["module", "error_type"]
    ) {
        Ok(m) => Some(m),
        Err(e) => {
            tracing::error!("Failed to register ERRORS_TOTAL metric: {}", e);
            CounterVec::new(Opts::new("errors_total", "Total errors by module and type"), &["module", "error_type"]).ok()
        }
    };

    // Frontend long tasks (received via telemetry)
    pub static ref FE_LONG_TASKS_TOTAL: Option<Counter> = match register_counter!(
        "frontend_long_tasks_total",
        "Total frontend long tasks > 50ms"
    ) {
        Ok(m) => Some(m),
        Err(e) => {
            tracing::error!("Failed to register FE_LONG_TASKS_TOTAL metric: {}", e);
            Counter::with_opts(Opts::new("frontend_long_tasks_total", "Total frontend long tasks > 50ms")).ok()
        }
    };
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_metrics_initialization() {
        // Use the metrics to ensure they don't panic on initialization
        if let Some(m) = &*IMAGE_PROCESSING_TOTAL {
            m.with_label_values(&["test"]).inc();
        }
        if let Some(m) = &*ACTIVE_SESSIONS {
            m.inc();
        }
        if let Some(m) = &*QUOTA_CURRENT_UPLOADS {
            m.set(0.0);
        }

        // Success if no panic
        assert!(true);
    }
}
