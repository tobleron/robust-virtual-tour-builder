// @efficiency: service-orchestrator
use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};
use std::time::Instant;

use super::image_logic::*;
use super::image_utils::*;
use crate::metrics::{IMAGE_PROCESSING_DURATION, IMAGE_PROCESSING_TOTAL, UPLOAD_BYTES_TOTAL};
use crate::models::{AppError, MetadataResponse};

/// Extracts EXIF metadata and performs quality analysis on an image.
#[tracing::instrument(skip(payload), name = "extract_metadata")]
pub async fn extract_metadata(payload: Multipart) -> Result<HttpResponse, AppError> {
    let multipart_data = read_multipart_image(payload).await?;
    let total_size = multipart_data.data.len();

    // Metrics
    UPLOAD_BYTES_TOTAL.inc_by(total_size as f64);

    let start = Instant::now();
    let result = web::block(move || -> Result<MetadataResponse, String> {
        extract_metadata_sync(multipart_data.data, multipart_data.filename)
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))?;

    let duration = start.elapsed().as_millis();
    match result {
        Ok(data) => {
            tracing::info!(
                module = "Extractor",
                duration_ms = duration,
                "EXTRACT_METADATA_COMPLETE"
            );

            // Metrics
            IMAGE_PROCESSING_TOTAL
                .with_label_values(&["extract_metadata"])
                .inc();
            IMAGE_PROCESSING_DURATION.observe(start.elapsed().as_secs_f64());

            Ok(HttpResponse::Ok().json(data))
        }
        Err(e) => {
            tracing::error!(module = "Extractor", duration_ms = duration, error = %e, "EXTRACT_METADATA_FAILED");
            Err(AppError::ImageError(e))
        }
    }
}
