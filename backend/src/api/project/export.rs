// @efficiency: infra-adapter
use super::export_utils::parse_export_multipart;
use crate::models::AppError;
use crate::services::project;
use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};

/// Creates a final tour package ZIP containing the tour application and all assets.
#[tracing::instrument(skip(payload), name = "create_tour_package")]
pub async fn create_tour_package(payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "Exporter", "EXPORT_START");
    let start = std::time::Instant::now();

    let (image_files, fields) = parse_export_multipart(payload).await?;

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
