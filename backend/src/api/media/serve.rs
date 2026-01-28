use actix_web::{HttpRequest, HttpResponse, web};
use std::fs;

use crate::api::utils::{get_session_path, sanitize_filename};
use crate::models::AppError;

// Handler for serving session files
pub async fn serve_session_file(
    req: HttpRequest,
    path: web::Path<(String, String)>,
) -> Result<HttpResponse, AppError> {
    let (session_id, filename) = path.into_inner();

    println!(
        ">>> SERVE_SESSION_FILE: sid={}, file={}",
        session_id, filename
    );
    tracing::info!(session_id = %session_id, filename = %filename, "SERVE_SESSION_FILE_START");

    // Security Check: Sanitize
    let safe_filename = match sanitize_filename(&filename) {
        Ok(f) => f,
        Err(e) => {
            tracing::error!(filename = %filename, error = %e, "FILENAME_SANITIZATION_FAILED");
            return Err(AppError::InternalError("Invalid filename".into()));
        }
    };

    let session_path = get_session_path(&session_id);
    let file_path = session_path.join("images").join(&safe_filename);

    tracing::debug!(path = ?file_path, "Checking images/ subdir");

    if file_path.exists() && file_path.is_file() {
        tracing::info!(path = ?file_path, "Serving from images/ subdir");
        match actix_files::NamedFile::open(&file_path) {
            Ok(named_file) => return Ok(named_file.into_response(&req)),
            Err(e) => {
                tracing::error!(path = ?file_path, error = %e, "FAILED_TO_OPEN_IMAGE_FILE");
                return Err(AppError::IoError(e));
            }
        }
    }

    // Try root
    let root_path = session_path.join(&safe_filename);
    tracing::debug!(path = ?root_path, "Checking session root");
    if root_path.exists() && root_path.is_file() {
        tracing::info!(path = ?root_path, "Serving from session root");
        match actix_files::NamedFile::open(&root_path) {
            Ok(named_file) => return Ok(named_file.into_response(&req)),
            Err(e) => {
                tracing::error!(path = ?root_path, error = %e, "FAILED_TO_OPEN_ROOT_FILE");
                return Err(AppError::IoError(e));
            }
        }
    }

    tracing::warn!(
        session_id = %session_id,
        filename = %filename,
        "File not found in images/ or root (searched images/ and root)"
    );
    Ok(HttpResponse::NotFound().body(format!("File not found: {}", safe_filename)))
}

#[cfg(test)]
mod tests {
    #[test]
    fn placeholder() {}
}
