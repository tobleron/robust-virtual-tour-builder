# Task 121: Add Prometheus Metrics Endpoint

## Priority: LOW

## Context
The backend has good logging via `tracing`, but lacks exportable metrics for:
- Monitoring dashboards (Grafana)
- Alerting systems (PagerDuty, OpsGenie)
- Performance trending over time

Adding a `/metrics` endpoint enables integration with industry-standard monitoring.

## Objective
Add Prometheus-compatible metrics endpoint exposing key backend statistics.

## Proposed Metrics

### Request Metrics
| Metric | Type | Description |
|--------|------|-------------|
| `http_requests_total` | Counter | Total HTTP requests by method, path, status |
| `http_request_duration_seconds` | Histogram | Request latency distribution |
| `http_requests_in_flight` | Gauge | Currently processing requests |

### Business Metrics
| Metric | Type | Description |
|--------|------|-------------|
| `image_processing_total` | Counter | Images processed by type (optimize, resize) |
| `image_processing_duration_seconds` | Histogram | Image processing time |
| `upload_bytes_total` | Counter | Total bytes uploaded |
| `active_sessions` | Gauge | Currently active sessions |

### Resource Metrics
| Metric | Type | Description |
|--------|------|-------------|
| `quota_current_uploads` | Gauge | Current concurrent uploads |
| `quota_current_size_bytes` | Gauge | Current upload size in bytes |
| `geocoding_cache_hits_total` | Counter | Cache hits for geocoding |
| `geocoding_cache_misses_total` | Counter | Cache misses for geocoding |

## Implementation

### 1. Add Dependency
```toml
# backend/Cargo.toml
actix-web-prom = "0.7"
prometheus = "0.13"
```

### 2. Initialize Metrics Middleware
```rust
// backend/src/main.rs
use actix_web_prom::PrometheusMetricsBuilder;

let prometheus = PrometheusMetricsBuilder::new("vtb_api")
    .endpoint("/metrics")
    .build()
    .unwrap();

App::new()
    .wrap(prometheus.clone())
    // ... rest of app
```

### 3. Add Custom Business Metrics
```rust
// backend/src/metrics.rs
use prometheus::{Counter, Histogram, register_counter, register_histogram};
use lazy_static::lazy_static;

lazy_static! {
    pub static ref IMAGE_PROCESSING_TOTAL: Counter = register_counter!(
        "image_processing_total",
        "Total images processed"
    ).unwrap();
    
    pub static ref IMAGE_PROCESSING_DURATION: Histogram = register_histogram!(
        "image_processing_duration_seconds",
        "Image processing duration in seconds"
    ).unwrap();
}

// Usage in handlers:
IMAGE_PROCESSING_TOTAL.inc();
let timer = IMAGE_PROCESSING_DURATION.start_timer();
// ... process image ...
timer.observe_duration();
```

## Acceptance Criteria
- [ ] `/metrics` endpoint returns Prometheus-format text
- [ ] HTTP request metrics auto-collected via middleware
- [ ] At least 3 custom business metrics implemented
- [ ] Metrics don't impact request latency significantly (<5ms overhead)
- [ ] Endpoint excluded from CORS (internal only)

## Sample Output
```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="POST",path="/api/media/optimize",status="200"} 1547

# HELP image_processing_duration_seconds Image processing duration
# TYPE image_processing_duration_seconds histogram
image_processing_duration_seconds_bucket{le="0.1"} 234
image_processing_duration_seconds_bucket{le="0.5"} 1123
image_processing_duration_seconds_bucket{le="1.0"} 1445
```

## Verification
1. Start backend: `cargo run`
2. `curl http://localhost:8080/metrics`
3. Verify Prometheus format output
4. (Optional) Connect to Grafana and create dashboard

## Future Enhancements
- Grafana dashboard JSON template
- Alerting rules for high error rates
- Custom labels for session tracking

## Estimated Effort
4-6 hours
