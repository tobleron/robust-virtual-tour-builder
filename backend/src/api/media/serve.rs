use actix_web::{HttpRequest, HttpResponse, web, HttpMessage};

use crate::api::utils::sanitize_filename;
use crate::models::{AppError, user::User};
use crate::services::media::StorageManager;

// Handler for serving project files
pub async fn serve_project_file(
    req: HttpRequest,
    path: web::Path<(String, String)>,
) -> Result<HttpResponse, AppError> {
    let (project_id, filename) = path.into_inner();
    let user = req.extensions().get::<User>().cloned().ok_or(AppError::Unauthorized("Authentication required".into()))?;

    tracing::info!(user_id = %user.id, project_id = %project_id, filename = %filename, "SERVE_PROJECT_FILE_START");

    // Security Check: Sanitize
    let safe_filename = match sanitize_filename(&filename) {
        Ok(f) => f,
        Err(e) => {
            tracing::error!(filename = %filename, error = %e, "FILENAME_SANITIZATION_FAILED");
            return Err(AppError::InternalError("Invalid filename".into()));
        }
    };

    let project_path = StorageManager::get_user_project_path(&user.id, &project_id);
    let file_path = project_path.join("images").join(&safe_filename);

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
    let root_path = project_path.join(&safe_filename);
    tracing::debug!(path = ?root_path, "Checking project root");
    if root_path.exists() && root_path.is_file() {
        tracing::info!(path = ?root_path, "Serving from project root");
        match actix_files::NamedFile::open(&root_path) {
            Ok(named_file) => return Ok(named_file.into_response(&req)),
            Err(e) => {
                tracing::error!(path = ?root_path, error = %e, "FAILED_TO_OPEN_ROOT_FILE");
                return Err(AppError::IoError(e));
            }
        }
    }

    tracing::warn!(
        project_id = %project_id,
        filename = %filename,
        "File not found in images/ or root"
    );
    Ok(HttpResponse::NotFound().body(format!("File not found: {}", safe_filename)))
}

#[cfg(test)]
mod tests {
    #[test]
    fn placeholder() {}
}
