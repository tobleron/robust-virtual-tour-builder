use actix_web::http::header::{
    CACHE_CONTROL, ETAG, HeaderValue, IF_NONE_MATCH, PRAGMA, VARY,
};
use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use std::path::Path;
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::io::AsyncReadExt;

use crate::api::utils::sanitize_filename;
use crate::models::{AppError, User};
use crate::services::media::StorageManager;

fn build_weak_etag(file_len: u64, modified: Option<SystemTime>) -> String {
    let modified_nanos = modified
        .and_then(|ts| ts.duration_since(UNIX_EPOCH).ok())
        .map(|dur| dur.as_nanos())
        .unwrap_or(0);
    format!("W/\"{}-{}\"", file_len, modified_nanos)
}

fn matches_if_none_match(if_none_match: &str, etag: &str) -> bool {
    if if_none_match.trim() == "*" {
        return true;
    }
    if_none_match
        .split(',')
        .map(str::trim)
        .any(|candidate| candidate == etag)
}

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
    let thumbnails_path = project_path.join("thumbnails").join(&safe_filename);
    let root_path = project_path.join(&safe_filename);

    tracing::info!(
        path = ?images_path,
        thumbnails_path = ?thumbnails_path,
        "Checking images/ and thumbnails/ subdirs for file request"
    );

    // Logic:
    // 1. Check images/filename
    // 2. Check thumbnails/filename
    // 3. Check root/filename
    // 4. If filename has extension, check images/filename_without_extension (Legacy fallback)

    let file_path = if images_path.exists() && images_path.is_file() {
        tracing::info!(path = ?images_path, "Serving from images/ subdir");
        images_path
    } else if thumbnails_path.exists() && thumbnails_path.is_file() {
        tracing::info!(path = ?thumbnails_path, "Serving from thumbnails/ subdir");
        thumbnails_path
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
                let image_no_ext = project_path.join("images").join(stem_str.as_ref());
                if image_no_ext.exists() && image_no_ext.is_file() {
                    tracing::warn!(
                        path = ?image_no_ext,
                        original = %safe_filename,
                        "Serving extensionless fallback from images/"
                    );
                    Some(image_no_ext)
                } else {
                    let thumbnail_no_ext = project_path.join("thumbnails").join(stem_str.as_ref());
                    if thumbnail_no_ext.exists() && thumbnail_no_ext.is_file() {
                        tracing::warn!(
                            path = ?thumbnail_no_ext,
                            original = %safe_filename,
                            "Serving extensionless fallback from thumbnails/"
                        );
                        Some(thumbnail_no_ext)
                    } else {
                        None
                    }
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
                    "File not found in images/, thumbnails/, or root"
                );
                return Ok(
                    HttpResponse::NotFound().body(format!("File not found: {}", safe_filename))
                );
            }
        }
    };
    let user_root = StorageManager::get_user_path(&user.id).map_err(AppError::IoError)?;
    crate::api::utils::validate_path_safe(&user_root, &file_path)?;

    let metadata = tokio::fs::metadata(&file_path)
        .await
        .map_err(AppError::IoError)?;
    let etag = build_weak_etag(metadata.len(), metadata.modified().ok());

    if let Some(if_none_match) = req.headers().get(IF_NONE_MATCH) {
        if let Ok(if_none_match_val) = if_none_match.to_str() {
            if matches_if_none_match(if_none_match_val, &etag) {
                return Ok(HttpResponse::NotModified()
                    .insert_header((ETAG, etag.clone()))
                    .insert_header((CACHE_CONTROL, "public, max-age=3600"))
                    .insert_header((VARY, "Accept-Encoding"))
                    .finish());
            }
        }
    }

    match actix_files::NamedFile::open(&file_path) {
        Ok(mut named_file) => {
            named_file = named_file.use_etag(true).use_last_modified(true);

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

            if let Ok(header) = HeaderValue::from_str(&etag) {
                response.headers_mut().insert(ETAG, header);
            }
            response.headers_mut().insert(
                CACHE_CONTROL,
                HeaderValue::from_static("public, max-age=3600"),
            );
            response.headers_mut().insert(
                VARY,
                HeaderValue::from_static("Accept-Encoding"),
            );
            response
                .headers_mut()
                .insert(PRAGMA, HeaderValue::from_static("public"));

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
    use super::{build_weak_etag, matches_if_none_match};
    use std::time::{Duration, UNIX_EPOCH};

    #[test]
    fn etag_builder_is_stable() {
        let etag = build_weak_etag(42, Some(UNIX_EPOCH + Duration::from_secs(5)));
        assert_eq!(etag, "W/\"42-5000000000\"");
    }

    #[test]
    fn if_none_match_supports_multi_value() {
        let etag = "W/\"42-5000000000\"";
        assert!(matches_if_none_match("abc, W/\"42-5000000000\"", etag));
        assert!(!matches_if_none_match("abc, def", etag));
    }
}
