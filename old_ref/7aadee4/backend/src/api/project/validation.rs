use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};
use futures_util::TryStreamExt as _;

use crate::api::utils::MAX_UPLOAD_SIZE;
use crate::models::AppError;
use crate::services::project;

/// Validates a project ZIP file without fully loading its images.
///
/// This handler inspects the `project.json` within the ZIP and cross-references
/// it with the files present in the archive to find broken links or orphaned scenes.
///
/// # Arguments
/// * `payload` - Multipart form data containing the project ZIP "file".
///
/// # Returns
/// A `ValidationReport` containing errors and warnings.
///
/// # Errors
/// * `ImageError` if the project size exceeds limits.
/// * `InternalError` if validation fails.
#[tracing::instrument(skip(payload), name = "validate_project")]
pub async fn validate_project(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "Validator", "VALIDATE_PROJECT_START");
    let start = std::time::Instant::now();
    let mut zip_data = Vec::new();

    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
            zip_data.extend_from_slice(&chunk);
            if zip_data.len() > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError("Project too large".into()));
            }
        }
    }

    let report = web::block(move || project::validate_project_zip(zip_data))
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))?;

    let duration = start.elapsed().as_millis();
    match report {
        Ok(validation_report) => {
            tracing::info!(
                module = "Validator",
                duration_ms = duration,
                "VALIDATE_PROJECT_COMPLETE"
            );
            Ok(HttpResponse::Ok().json(validation_report))
        }
        Err(e) => {
            tracing::error!(module = "Validator", duration_ms = duration, error = %e, "VALIDATE_PROJECT_FAILED");
            Err(AppError::InternalError(e))
        }
    }
}
