use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};
use futures_util::TryStreamExt as _;
use std::collections::HashMap;

use crate::api::utils::{MAX_UPLOAD_SIZE, sanitize_filename};
use crate::models::AppError;
use crate::services::project;

/// Creates a final tour package ZIP containing the tour application and all assets.
///
/// This function collects images and field data from a multipart request and packages
/// them into a downloadable ZIP file that can be hosted on any static web server.
///
/// # Arguments
/// * `payload` - Multipart form data containing "project_data" (JSON) and asset files.
///
/// # Returns
/// A response containing the ZIP file as binary data.
///
/// # Errors
/// * `ImageError` if the total upload size exceeds `MAX_UPLOAD_SIZE`.
/// * `InternalError` for path sanitization or processing failures.
#[tracing::instrument(skip(payload), name = "create_tour_package")]
pub async fn create_tour_package(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "Exporter", "EXPORT_START");
    let start = std::time::Instant::now();
    let mut fields: HashMap<String, String> = HashMap::new();
    let mut image_files: Vec<(String, Vec<u8>)> = Vec::new();

    let mut current_total_size = 0;

    // 1. Parse Multipart into Memory
    while let Some(mut field) = payload.try_next().await? {
        let content_disposition =
            field
                .content_disposition()
                .cloned()
                .ok_or(AppError::InternalError(
                    "Missing content disposition".into(),
                ))?;
        let name = content_disposition
            .get_name()
            .unwrap_or("unknown")
            .to_string();
        let filename = content_disposition.get_filename().map(|f| f.to_string());

        let mut data = Vec::new();
        while let Some(chunk) = field.try_next().await? {
            current_total_size += chunk.len();
            if current_total_size > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError(format!(
                    "Total upload size exceeds maximum of {}MB",
                    MAX_UPLOAD_SIZE / (1024 * 1024)
                )));
            }
            data.extend_from_slice(&chunk);
        }

        if let Some(fname) = filename {
            // Use secure sanitization to prevent path traversal
            let sanitized_name = sanitize_filename(&fname).map_err(|e| {
                AppError::InternalError(format!("Invalid filename '{}': {}", fname, e))
            })?;
            image_files.push((sanitized_name, data));
        } else {
            let value_str = String::from_utf8_lossy(&data).to_string();
            fields.insert(name, value_str);
        }
    }

    let result_zip = web::block(move || project::create_tour_package(image_files, fields))
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))?;

    let duration = start.elapsed().as_millis();
    match result_zip {
        Ok(zip_bytes) => {
            tracing::info!(
                module = "Exporter",
                duration_ms = duration,
                size = zip_bytes.len(),
                "EXPORT_COMPLETE"
            );
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        }
        Err(e) => {
            tracing::error!(module = "Exporter", duration_ms = duration, error = %e, "EXPORT_FAILED");
            Err(AppError::ZipError(e))
        }
    }
}
