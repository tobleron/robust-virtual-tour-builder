use crate::models::AppError;
use crate::services::shutdown::ShutdownManager;
use crate::services::upload_quota::UploadQuotaManager;
use actix_web::{HttpResponse, http::StatusCode, web};
use std::fs;
use std::path::{Path, PathBuf};
use uuid::Uuid;

// Configs
pub const PROCESSED_IMAGE_WIDTH: u32 = 4096;
pub const WEBP_QUALITY: f32 = 85.0;
pub const TEMP_DIR: &str = "/tmp/vt_backend";
pub const MAX_UPLOAD_SIZE: usize = 60 * 1024 * 1024; // 60MB limit
pub const MAX_LOG_SIZE: u64 = 10 * 1024 * 1024; // 10 MB
pub const MAX_LOG_FILES: usize = 5;
pub const LOG_RETENTION_DAYS: u64 = 7;

fn temp_root() -> PathBuf {
    std::env::var("TEMP_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from(TEMP_DIR))
}

fn safe_extension(extension: &str) -> &str {
    if extension
        .chars()
        .all(|c| c.is_ascii_alphanumeric() || c == '_')
    {
        extension
    } else {
        "tmp"
    }
}

pub fn get_temp_path(extension: &str) -> PathBuf {
    let mut path = temp_root();
    if !path.exists()
        && let Err(e) = fs::create_dir_all(&path)
    {
        tracing::error!("Failed to create temp directory {:?}: {}", path, e);
    }
    path.push(format!("{}.{}", Uuid::new_v4(), safe_extension(extension)));
    path
}

pub async fn get_temp_path_async(extension: &str) -> PathBuf {
    let mut path = temp_root();
    if let Err(e) = tokio::fs::create_dir_all(&path).await {
        tracing::error!("Failed to create temp directory {:?}: {}", path, e);
    }
    path.push(format!("{}.{}", Uuid::new_v4(), safe_extension(extension)));
    path
}

/// Sanitize ID (project_id, session_id) to prevent potential injections or path traversal
pub fn sanitize_id(id: &str) -> Result<String, String> {
    if id.is_empty() {
        return Err("ID cannot be empty".to_string());
    }

    // Strictly allow only alphanumeric, hyphen, and underscore
    if !id
        .chars()
        .all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_')
    {
        return Err("ID contains invalid characters".to_string());
    }

    // Limit length to prevent extreme paths
    if id.len() > 64 {
        return Err("ID too long".to_string());
    }

    Ok(id.to_string())
}

/// Validates that a resolved path is strictly within a base directory
pub fn validate_path_safe(base: &Path, resolved: &Path) -> Result<(), AppError> {
    let canonical_base = base
        .canonicalize()
        .map_err(|_| AppError::InternalError("Failed to canonicalize base path".into()))?;
    let canonical_resolved = resolved
        .canonicalize()
        .map_err(|_| AppError::InternalError("Failed to canonicalize resolved path".into()))?;

    if !canonical_resolved.starts_with(&canonical_base) {
        tracing::error!(
            "Path escape detected: {:?} is not within {:?}",
            canonical_resolved,
            canonical_base
        );
        return Err(AppError::ValidationError(
            "Security violation: Path escape detected".into(),
        ));
    }
    Ok(())
}

/// Sanitize filename to prevent path traversal attacks
/// Returns only the filename component, rejecting any directory traversal attempts
pub fn sanitize_filename(fname: &str) -> Result<String, String> {
    use std::path::Component;

    // Reject empty filenames
    if fname.is_empty() {
        return Err("Empty filename not allowed".to_string());
    }

    let path = Path::new(fname);

    // Reject absolute paths
    if path.is_absolute() {
        return Err("Absolute paths not allowed".to_string());
    }

    // Check for parent directory components (..)
    for component in path.components() {
        match component {
            Component::ParentDir => {
                return Err("Parent directory traversal not allowed".to_string());
            }
            Component::RootDir => {
                return Err("Root directory access not allowed".to_string());
            }
            _ => {}
        }
    }

    // Extract only the filename (no directory structure)
    path.file_name()
        .and_then(|s| s.to_str())
        .map(|s| {
            // Additional sanitization: remove any remaining dangerous characters
            s.replace(['/', '\\', '\0'], "_")
        })
        .ok_or_else(|| "Invalid filename".to_string())
}

/// Trigger graceful shutdown (admin only)
pub async fn trigger_shutdown(
    req: actix_web::HttpRequest,
    shutdown_manager: web::Data<ShutdownManager>,
) -> Result<HttpResponse, AppError> {
    use crate::models::User;
    use actix_web::HttpMessage;

    let user = req.extensions().get::<User>().cloned().ok_or_else(|| {
        AppError::Unauthorized("Authentication required for this operation".into())
    })?;

    if user.role != "admin" {
        tracing::error!(
            target: "audit",
            user_id = %user.id,
            user_email = %user.email,
            "🛑 UNAUTHORIZED SHUTDOWN ATTEMPT rejected"
        );
        return Err(AppError::Unauthorized("Admin role required".into()));
    }

    tracing::warn!(
        target: "audit",
        user_id = %user.id,
        user_email = %user.email,
        "⚠️ SERVER SHUTDOWN INITIATED via API"
    );

    shutdown_manager.begin_shutdown();

    let active = shutdown_manager.active_count().await;

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "message": "Shutdown initiated",
        "active_requests": active,
        "operator": user.email
    })))
}

pub fn json_error_response(
    status: StatusCode,
    error: &str,
    message: &str,
    request_id: Option<&str>,
) -> HttpResponse {
    HttpResponse::build(status).json(serde_json::json!({
        "error": error,
        "message": message,
        "requestId": request_id.unwrap_or("unknown"),
    }))
}

/// Get current upload quota statistics
pub async fn quota_stats(
    quota_manager: web::Data<UploadQuotaManager>,
) -> Result<HttpResponse, AppError> {
    let stats = quota_manager.get_stats().await;
    Ok(HttpResponse::Ok().json(stats))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sanitize_id() {
        assert_eq!(
            sanitize_id("valid-id_123").expect("valid id should not fail"),
            "valid-id_123"
        );
        assert!(sanitize_id("path/traversal").is_err());
        assert!(sanitize_id("../hidden").is_err());
        assert!(sanitize_id("").is_err());
        assert!(sanitize_id("with spaces").is_err());
        assert!(sanitize_id("special!@#").is_err());
        assert!(sanitize_id(&"a".repeat(65)).is_err());
        assert!(sanitize_id(&"a".repeat(64)).is_ok());
    }

    #[test]
    fn test_validate_path_safe() {
        let temp = tempfile::tempdir().expect("failed to create temp directory");
        let base = temp.path().to_path_buf();
        let safe_child = base.join("safe.txt");
        fs::write(&safe_child, "data").expect("failed to write test file");

        assert!(validate_path_safe(&base, &safe_child).is_ok());

        // Note: canonicalize() requires file exists for some OS,
        // and ALWAYS requires the file exists for the full path to be canonicalized reliably in this context.
    }
}
