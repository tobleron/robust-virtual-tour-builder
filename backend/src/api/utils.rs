use std::path::{Path, PathBuf};
use uuid::Uuid;
use std::fs;
use actix_web::{web, HttpResponse};
use crate::services::shutdown::ShutdownManager;

// Configs
pub const PROCESSED_IMAGE_WIDTH: u32 = 4096;
pub const WEBP_QUALITY: f32 = 92.0;
pub const TEMP_DIR: &str = "/tmp/remax_backend";
pub const SESSIONS_DIR: &str = "/tmp/remax_sessions";
pub const MAX_UPLOAD_SIZE: usize = 2048 * 1024 * 1024; // 2GB limit
pub const MAX_LOG_SIZE: u64 = 10 * 1024 * 1024; // 10 MB
pub const MAX_LOG_FILES: usize = 5;
pub const LOG_RETENTION_DAYS: u64 = 7;

pub fn get_temp_path(extension: &str) -> PathBuf {
    let mut path = PathBuf::from(TEMP_DIR);
    if !path.exists() {
        fs::create_dir_all(&path).unwrap_or_default();
    }
    path.push(format!("{}.{}", Uuid::new_v4(), extension));
    path
}

pub fn get_session_path(session_id: &str) -> PathBuf {
    let mut path = PathBuf::from(SESSIONS_DIR);
    path.push(session_id);
    path
}

/// Sanitize filename to prevent path traversal attacks
/// Returns only the filename component, rejecting any directory traversal attempts
pub fn sanitize_filename(fname: &str) -> Result<String, String> {
    use std::path::{Component};
    
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

/// Trigger graceful shutdown (admin only in production)
pub async fn trigger_shutdown(
    shutdown_manager: web::Data<ShutdownManager>,
) -> HttpResponse {
    tracing::warn!("Shutdown triggered via API");
    
    let active = shutdown_manager.active_count().await;
    
    HttpResponse::Ok().json(serde_json::json!({
        "message": "Shutdown initiated",
        "active_requests": active
    }))
}
