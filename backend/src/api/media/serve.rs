use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use std::io::{Read, Seek, SeekFrom};
use std::path::Path;

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

    let project_path = StorageManager::get_user_project_path(&user.id, &project_id);
    let images_path = project_path.join("images").join(&safe_filename);
    let root_path = project_path.join(&safe_filename);

    tracing::debug!(path = ?images_path, "Checking images/ subdir");

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
                return Ok(HttpResponse::NotFound().body(format!("File not found: {}", safe_filename)));
            }
        }
    };

    match actix_files::NamedFile::open(&file_path) {
        Ok(mut named_file) => {
            // Fix for "Black Image" issue:
            // Browsers block rendering of images with "application/octet-stream" content-type
            // when "X-Content-Type-Options: nosniff" is set (which we do for security).
            // Files saved without extensions (legacy projects) default to octet-stream.
            // We attempt to detect the MIME type or fallback to image/webp.

            let content_type = named_file.content_type().to_string();

            if content_type == "application/octet-stream" {
                tracing::warn!(filename = %safe_filename, "Detected octet-stream, attempting MIME sniffing");

                // Attempt to sniff header
                let mut buffer = [0u8; 12];
                // NamedFile::file() returns &File. &File implements Read and Seek.
                // We need 'mut' because Read takes &mut self (where self is &File).
                let mut file = named_file.file();

                // Save current position (should be 0, but good practice)
                let start_pos = file.stream_position().unwrap_or(0);

                if let Ok(_) = file.read_exact(&mut buffer) {
                    // Reset position
                    let _ = file.seek(SeekFrom::Start(start_pos));

                    if buffer.starts_with(b"RIFF") && &buffer[8..12] == b"WEBP" {
                        if let Ok(mime) = "image/webp".parse() {
                            named_file = named_file.set_content_type(mime);
                        }
                    } else if buffer.starts_with(&[0xFF, 0xD8, 0xFF]) {
                        if let Ok(mime) = "image/jpeg".parse() {
                            named_file = named_file.set_content_type(mime);
                        }
                    } else if buffer.starts_with(&[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
                        if let Ok(mime) = "image/png".parse() {
                            named_file = named_file.set_content_type(mime);
                        }
                    } else {
                        // Fallback default for this application
                        tracing::warn!("Sniffing failed, defaulting to image/webp");
                        if let Ok(mime) = "image/webp".parse() {
                            named_file = named_file.set_content_type(mime);
                        }
                    }
                } else {
                     // Read failed, just fallback
                     let _ = file.seek(SeekFrom::Start(start_pos));
                     if let Ok(mime) = "image/webp".parse() {
                         named_file = named_file.set_content_type(mime);
                     }
                }
            }

            return Ok(named_file.into_response(&req));
        },
        Err(e) => {
            tracing::error!(path = ?file_path, error = %e, "FAILED_TO_OPEN_FILE");
            return Err(AppError::IoError(e));
        }
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn placeholder() {}
}
