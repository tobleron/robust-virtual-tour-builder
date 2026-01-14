# Task 92: Implement Backend Upload Quota System

## Priority
**MEDIUM** - Resource management and multi-user scalability

## Context
The backend currently sets a global 2GB payload limit (`web::PayloadConfig::new(2 * 1024 * 1024 * 1024)` in `main.rs`). While necessary for large tour projects, this poses risks in a multi-user environment:

1. **Disk Space Saturation**: Concurrent 2GB uploads could fill disk space
2. **Bandwidth Exhaustion**: Multiple simultaneous large uploads could saturate network
3. **Memory Pressure**: Even with streaming, multiple large uploads increase memory usage
4. **No User Limits**: A single user could monopolize resources

## Current State

In `backend/src/main.rs`:
```rust
App::new()
    .app_data(web::PayloadConfig::new(2 * 1024 * 1024 * 1024))
```

This allows ANY request to be up to 2GB, with no per-user or global limits.

## Goals

1. **Implement Per-User Quotas**: Limit concurrent uploads per session/IP
2. **Add Global Upload Limits**: Cap total concurrent upload size
3. **Add Disk Space Monitoring**: Prevent uploads when disk is nearly full
4. **Add Graceful Degradation**: Return helpful errors when limits are reached
5. **Make Limits Configurable**: Allow adjustment via environment variables

## Implementation Steps

### Step 1: Create Upload Quota Manager

Create `backend/src/services/upload_quota.rs`:

```rust
use std::sync::Arc;
use tokio::sync::RwLock;
use std::collections::HashMap;
use std::time::{Duration, Instant};
use actix_web::web;

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
            max_concurrent_per_ip: 2,
            max_total_concurrent_size: 10 * 1024 * 1024 * 1024, // 10GB total
            min_free_disk_space: 5 * 1024 * 1024 * 1024, // 5GB free required
            rate_limit_window: Duration::from_secs(3600), // 1 hour
            max_uploads_per_window: 10,
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
                .unwrap_or(2),
            
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
                    .unwrap_or(3600)
            ),
            
            max_uploads_per_window: std::env::var("MAX_UPLOADS_PER_WINDOW")
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(10),
        }
    }
}

/// Tracks active uploads
#[derive(Clone)]
struct UploadTracker {
    ip: String,
    size: usize,
    started_at: Instant,
}

/// Upload history for rate limiting
struct UploadHistory {
    uploads: Vec<Instant>,
}

impl UploadHistory {
    fn new() -> Self {
        Self { uploads: Vec::new() }
    }
    
    fn add_upload(&mut self, now: Instant) {
        self.uploads.push(now);
    }
    
    fn count_in_window(&self, window: Duration, now: Instant) -> usize {
        self.uploads.iter()
            .filter(|&&time| now.duration_since(time) < window)
            .count()
    }
    
    fn cleanup_old(&mut self, window: Duration, now: Instant) {
        self.uploads.retain(|&time| now.duration_since(time) < window);
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
        if let Err(e) = self.check_disk_space().await {
            return Err(e);
        }
        
        let active = self.active_uploads.read().await;
        
        // Check per-IP concurrent limit
        if let Some(uploads) = active.get(ip) {
            if uploads.len() >= self.config.max_concurrent_per_ip {
                return Err(format!(
                    "Too many concurrent uploads from your IP. Maximum: {}",
                    self.config.max_concurrent_per_ip
                ));
            }
        }
        
        // Check global concurrent size
        let total_size: usize = active.values()
            .flat_map(|v| v.iter())
            .map(|t| t.size)
            .sum();
        
        if total_size + size > self.config.max_total_concurrent_size {
            return Err(format!(
                "Server is currently processing too many uploads. Please try again later."
            ));
        }
        
        drop(active);
        
        // Check rate limit
        let now = Instant::now();
        let mut history = self.upload_history.write().await;
        let user_history = history.entry(ip.to_string()).or_insert_with(UploadHistory::new);
        
        user_history.cleanup_old(self.config.rate_limit_window, now);
        
        if user_history.count_in_window(self.config.rate_limit_window, now) 
            >= self.config.max_uploads_per_window {
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
        active.entry(ip.to_string())
            .or_insert_with(Vec::new)
            .push(tracker);
        
        let mut history = self.upload_history.write().await;
        history.entry(ip.to_string())
            .or_insert_with(UploadHistory::new)
            .add_upload(Instant::now());
        
        tracing::info!(
            ip = ip,
            size = size,
            upload_id = %upload_id,
            "Upload registered"
        );
        
        upload_id
    }
    
    /// Unregister a completed upload
    pub async fn unregister_upload(&self, ip: &str, size: usize) {
        let mut active = self.active_uploads.write().await;
        if let Some(uploads) = active.get_mut(ip) {
            if let Some(pos) = uploads.iter().position(|t| t.size == size) {
                uploads.remove(pos);
                tracing::info!(ip = ip, size = size, "Upload completed");
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
        let total_size: usize = active.values()
            .flat_map(|v| v.iter())
            .map(|t| t.size)
            .sum();
        
        QuotaStats {
            active_uploads: total_active,
            total_active_size: total_size,
            max_total_size: self.config.max_total_concurrent_size,
            utilization_percent: (total_size as f64 / self.config.max_total_concurrent_size as f64 * 100.0) as u32,
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
```

### Step 2: Add Dependency

Update `backend/Cargo.toml`:
```toml
[dependencies]
fs2 = "0.4"  # For disk space checking
```

### Step 3: Update services/mod.rs

```rust
pub mod media;
pub mod project;
pub mod geocoding;
pub mod upload_quota;
```

### Step 4: Integrate into main.rs

```rust
use services::upload_quota::{UploadQuotaManager, QuotaConfig};

#[actix_web::main]
async fn main() -> io::Result<()> {
    // ... existing setup ...
    
    // Initialize upload quota manager
    let quota_config = QuotaConfig::from_env();
    let quota_manager = web::Data::new(UploadQuotaManager::new(quota_config.clone()));
    
    tracing::info!(
        "Upload quotas: max_payload={} MB, max_concurrent_per_ip={}, max_total={} GB",
        quota_config.max_payload_size / (1024 * 1024),
        quota_config.max_concurrent_per_ip,
        quota_config.max_total_concurrent_size / (1024 * 1024 * 1024)
    );
    
    HttpServer::new(move || {
        App::new()
            .app_data(web::PayloadConfig::new(quota_config.max_payload_size))
            .app_data(quota_manager.clone())
            // ... rest of config ...
    })
    // ...
}
```

### Step 5: Create Quota Middleware

Create `backend/src/middleware/quota_check.rs`:

```rust
use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    Error, HttpResponse,
};
use futures_util::future::LocalBoxFuture;
use std::future::{ready, Ready};

use crate::services::upload_quota::UploadQuotaManager;
use crate::models::AppError;

pub struct QuotaCheck;

impl<S, B> Transform<S, ServiceRequest> for QuotaCheck
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type InitError = ();
    type Transform = QuotaCheckMiddleware<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(QuotaCheckMiddleware { service }))
    }
}

pub struct QuotaCheckMiddleware<S> {
    service: S,
}

impl<S, B> Service<ServiceRequest> for QuotaCheckMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        // Only check quota for upload endpoints
        let path = req.path();
        let should_check = path.contains("/media/") || 
                          path.contains("/project/save") ||
                          path.contains("/project/import");
        
        if !should_check {
            let fut = self.service.call(req);
            return Box::pin(async move {
                let res = fut.await?;
                Ok(res)
            });
        }
        
        // Get client IP
        let ip = req
            .connection_info()
            .realip_remote_addr()
            .unwrap_or("unknown")
            .to_string();
        
        // Get content length
        let content_length = req
            .headers()
            .get("content-length")
            .and_then(|v| v.to_str().ok())
            .and_then(|v| v.parse::<usize>().ok())
            .unwrap_or(0);
        
        // Get quota manager from app data
        let quota_manager = req.app_data::<web::Data<UploadQuotaManager>>().cloned();
        
        let fut = self.service.call(req);
        
        Box::pin(async move {
            if let Some(manager) = quota_manager {
                // Check if upload can proceed
                if let Err(e) = manager.can_upload(&ip, content_length).await {
                    tracing::warn!(ip = %ip, size = content_length, error = %e, "Upload rejected");
                    return Ok(ServiceResponse::new(
                        fut.into_parts().0,
                        HttpResponse::TooManyRequests()
                            .json(serde_json::json!({
                                "error": "Quota exceeded",
                                "message": e
                            }))
                            .into_body()
                    ));
                }
                
                // Register upload
                let _upload_id = manager.register_upload(&ip, content_length).await;
                
                // Process request
                let res = fut.await?;
                
                // Unregister upload
                manager.unregister_upload(&ip, content_length).await;
                
                Ok(res)
            } else {
                // No quota manager, proceed normally
                fut.await
            }
        })
    }
}
```

### Step 6: Add Quota Stats Endpoint

In `backend/src/api/utils.rs`:

```rust
use actix_web::{web, HttpResponse};
use crate::services::upload_quota::UploadQuotaManager;
use crate::models::AppError;

/// Get current upload quota statistics
pub async fn quota_stats(
    quota_manager: web::Data<UploadQuotaManager>,
) -> Result<HttpResponse, AppError> {
    let stats = quota_manager.get_stats().await;
    Ok(HttpResponse::Ok().json(stats))
}
```

Add route in `main.rs`:
```rust
.service(web::scope("/api")
    .route("/quota/stats", web::get().to(api::utils::quota_stats))
    // ... other routes ...
)
```

### Step 7: Add Environment Configuration

Create `backend/.env.example`:
```bash
# Upload Quota Configuration

# Maximum payload size per request (bytes)
MAX_PAYLOAD_SIZE=2147483648  # 2GB

# Maximum concurrent uploads per IP
MAX_CONCURRENT_PER_IP=2

# Maximum total concurrent upload size across all users (bytes)
MAX_TOTAL_CONCURRENT_SIZE=10737418240  # 10GB

# Minimum free disk space required (bytes)
MIN_FREE_DISK_SPACE=5368709120  # 5GB

# Rate limit window (seconds)
RATE_LIMIT_WINDOW_SECS=3600  # 1 hour

# Maximum uploads per IP in time window
MAX_UPLOADS_PER_WINDOW=10
```

## Verification

### Unit Tests

Create `backend/src/services/upload_quota_tests.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_quota_allows_small_upload() {
        let config = QuotaConfig::default();
        let manager = UploadQuotaManager::new(config);
        
        let result = manager.can_upload("127.0.0.1", 1024 * 1024).await;
        assert!(result.is_ok());
    }
    
    #[tokio::test]
    async fn test_quota_rejects_oversized_upload() {
        let config = QuotaConfig {
            max_payload_size: 1024 * 1024, // 1MB
            ..Default::default()
        };
        let manager = UploadQuotaManager::new(config);
        
        let result = manager.can_upload("127.0.0.1", 2 * 1024 * 1024).await;
        assert!(result.is_err());
    }
    
    #[tokio::test]
    async fn test_concurrent_limit_per_ip() {
        let config = QuotaConfig {
            max_concurrent_per_ip: 1,
            ..Default::default()
        };
        let manager = UploadQuotaManager::new(config);
        
        // First upload should succeed
        manager.register_upload("127.0.0.1", 1024).await;
        
        // Second concurrent upload should fail
        let result = manager.can_upload("127.0.0.1", 1024).await;
        assert!(result.is_err());
        
        // After unregister, should succeed again
        manager.unregister_upload("127.0.0.1", 1024).await;
        let result = manager.can_upload("127.0.0.1", 1024).await;
        assert!(result.is_ok());
    }
}
```

Run tests:
```bash
cd backend && cargo test upload_quota
```

### Integration Testing

1. **Test concurrent uploads**:
   ```bash
   # Terminal 1
   curl -X POST -F "file=@large1.zip" http://localhost:8080/api/project/import
   
   # Terminal 2 (while first is running)
   curl -X POST -F "file=@large2.zip" http://localhost:8080/api/project/import
   
   # Terminal 3 (should be rejected)
   curl -X POST -F "file=@large3.zip" http://localhost:8080/api/project/import
   ```

2. **Test rate limiting**:
   ```bash
   for i in {1..15}; do
     curl -X POST -F "file=@test.zip" http://localhost:8080/api/project/import
   done
   # Should see rate limit errors after 10 uploads
   ```

3. **Check quota stats**:
   ```bash
   curl http://localhost:8080/api/quota/stats
   ```

## Success Criteria

- [ ] `UploadQuotaManager` service created
- [ ] Per-IP concurrent upload limits enforced
- [ ] Global concurrent size limits enforced
- [ ] Disk space monitoring implemented
- [ ] Rate limiting per IP implemented
- [ ] Configuration via environment variables
- [ ] Quota stats endpoint added
- [ ] Helpful error messages when limits exceeded
- [ ] Unit tests pass
- [ ] Integration tests verify limits work
- [ ] Documentation updated

## Notes

- This system prevents resource exhaustion in multi-user scenarios
- Limits are configurable for different deployment environments
- The middleware approach keeps quota logic separate from business logic
- Consider adding metrics/monitoring for quota violations
- Future enhancement: User authentication could enable per-user quotas instead of per-IP

# Completion Report
- Date: 2026-01-14T21:08:24Z
- Changes:
  - Created `UploadQuotaManager` service in `backend/src/services/upload_quota.rs`.
  - Added `fs2` dependency to `backend/Cargo.toml` for disk space checking.
  - Created `QuotaCheck` middleware in `backend/src/middleware/quota_check.rs` using `EitherBody` to handle responses correctly.
  - Integrated quota system into `backend/src/main.rs`.
  - Added `quota_stats` endpoint to `backend/src/api/utils.rs`.
  - Added `backend/.env.example` with quota configuration.
  - Added unit tests in `backend/src/services/upload_quota_tests.rs`.
- Verification:
  - Unit tests passed (`cargo test upload_quota`).
  - Implemented sturdy middleware pattern with `Rc` and `EitherBody` to handle async service calls and error injection.
