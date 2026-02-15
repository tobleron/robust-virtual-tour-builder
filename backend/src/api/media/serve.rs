use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use std::path::Path;
use tokio::io::AsyncReadExt;

use crate::api::utils::sanitize_filename;
use crate::models::{AppError, User};
use crate::services::media::StorageManager;

// Handler for serving project files
pub async fn serve_project_file(
    req: HttpRequest,
    path: web::Path<(String, String)>,
) -> Result<HttpResponse, AppError> {
    let (project_id, filename) = path.into_inner();
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;

    tracing::info!(user_id = %user.id, project_id = %project_id, filename = %filename, "SERVE_PROJECT_FILE_START");

    // Security Check: Sanitize
    let safe_filename = match sanitize_filename(&filename) {
        Ok(f) => f,
        Err(e) => {
            tracing::error!(filename = %filename, error = %e, "FILENAME_SANITIZATION_FAILED");
            return Err(AppError::InternalError("Invalid filename".into()));
        }
    };

    let project_path = match StorageManager::get_user_project_path(&user.id, &project_id) {
        Ok(path) => path,
        Err(e) => {
            tracing::error!(project_id = %project_id, error = %e, "PROJECT_ID_VALIDATION_FAILED");
            return Err(AppError::ValidationError("Invalid project ID".into()));
        }
    };
    let images_path = project_path.join("images").join(&safe_filename);
    let root_path = project_path.join(&safe_filename);

    tracing::info!(path = ?images_path, "Checking images/ subdir for file request");

    // Logic:
    // 1. Check images/filename
    // 2. Check root/filename
    // 3. If filename has extension, check images/filename_without_extension (Legacy fallback)

    let file_path = if images_path.exists() && images_path.is_file() {
        tracing::info!(path = ?images_path, "Serving from images/ subdir");
        images_path
    } else if root_path.exists() && root_path.is_file() {
        tracing::info!(path = ?root_path, "Serving from project root");
        root_path
    } else {
        // Fallback: Check if file exists without extension
        let path_obj = Path::new(&safe_filename);
        let fallback_path = if let Some(stem) = path_obj.file_stem() {
            // Only try fallback if there was an extension to strip (stem != original)
            // or just check stem generally.
            if stem != path_obj.as_os_str() {
                let stem_str = stem.to_string_lossy();
                let no_ext = project_path.join("images").join(stem_str.as_ref());
                if no_ext.exists() && no_ext.is_file() {
                    tracing::warn!(path = ?no_ext, original = %safe_filename, "Serving extensionless fallback");
                    Some(no_ext)
                } else {
                    None
                }
            } else {
                None
            }
        } else {
            None
        };

        match fallback_path {
            Some(p) => p,
            None => {
                tracing::warn!(
                    project_id = %project_id,
                    filename = %filename,
                    "File not found in images/ or root"
                );
                return Ok(
                    HttpResponse::NotFound().body(format!("File not found: {}", safe_filename))
                );
            }
        }
    };
    let user_root = StorageManager::get_user_path(&user.id).map_err(AppError::IoError)?;
    crate::api::utils::validate_path_safe(&user_root, &file_path)?;

    match actix_files::NamedFile::open(&file_path) {
        Ok(mut named_file) => {
            // FORCE REFRESH: Disable caching headers to prevent 304 Not Modified
            // This ensures the browser always gets the corrected Content-Type header
            named_file = named_file.use_etag(false).use_last_modified(false);

            let initial_content_type = named_file.content_type().to_string();

            tracing::debug!(
                filename = %safe_filename,
                initial_content_type = %initial_content_type,
                "SERVING_FILE_DEBUG_CHECK"
            );

            // If it's octet-stream or text/plain (common for extensionless/unknown files), attempt sniffing
            if initial_content_type == "application/octet-stream"
                || initial_content_type == "text/plain"
            {
                tracing::debug!(
                    filename = %safe_filename,
                    content_type = %initial_content_type,
                    "Suspected missing content-type, attempting MIME sniffing"
                );

                let mut buffer = [0u8; 12];
                // Use a separate file handle to avoid messing with named_file's internal pointer
                if let Ok(mut f) = tokio::fs::File::open(&file_path).await {
                    if let Ok(_) = f.read_exact(&mut buffer).await {
                        let detected_mime = if buffer.starts_with(b"RIFF")
                            && &buffer[8..12] == b"WEBP"
                        {
                            Some("image/webp")
                        } else if buffer.starts_with(&[0xFF, 0xD8, 0xFF]) {
                            Some("image/jpeg")
                        } else if buffer
                            .starts_with(&[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
                        {
                            Some("image/png")
                        } else if buffer.starts_with(b"GIF87a") || buffer.starts_with(b"GIF89a") {
                            Some("image/gif")
                        } else if buffer.starts_with(b"BM") {
                            Some("image/bmp")
                        } else {
                            None
                        };

                        if let Some(m) = detected_mime {
                            if let Ok(mime) = m.parse() {
                                tracing::debug!(filename = %safe_filename, sniffed_mime = %m, "MIME sniffed successfully");
                                named_file = named_file.set_content_type(mime);
                            }
                        } else {
                            // Fallback to webp only if it was octet-stream
                            if initial_content_type == "application/octet-stream" {
                                tracing::warn!(filename = %safe_filename, "Sniffing failed, defaulting to image/webp");
                                if let Ok(mime) = "image/webp".parse() {
                                    named_file = named_file.set_content_type(mime);
                                }
                            }
                        }
                    } else {
                        tracing::warn!(filename = %safe_filename, "Failed to read file header for sniffing");
                    }
                } else {
                    tracing::warn!(filename = %safe_filename, "Failed to open file for sniffing");
                }
            }

            let final_content_type = named_file.content_type().to_string();
            tracing::debug!(
                filename = %safe_filename,
                final_content_type = %final_content_type,
                "SERVING_FILE_FINAL_RESPONSE"
            );

            let mut response = named_file.into_response(&req);

            // SECURITY/FIX: Force no-cache to prevent browsers from holding onto
            // the "application/octet-stream" version of these files.
            response.headers_mut().insert(
                actix_web::http::header::CACHE_CONTROL,
                actix_web::http::header::HeaderValue::from_static(
                    "no-store, no-cache, must-revalidate, proxy-revalidate",
                ),
            );
            response.headers_mut().insert(
                actix_web::http::header::PRAGMA,
                actix_web::http::header::HeaderValue::from_static("no-cache"),
            );
            response.headers_mut().insert(
                actix_web::http::header::EXPIRES,
                actix_web::http::header::HeaderValue::from_static("0"),
            );

            Ok(response)
        }
        Err(e) => {
            tracing::error!(path = ?file_path, error = %e, "FAILED_TO_OPEN_FILE");
            Err(AppError::IoError(e))
        }
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn placeholder() {}
}
