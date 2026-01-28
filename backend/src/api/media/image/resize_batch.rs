// @efficiency: service-orchestrator
use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};
use std::time::Instant;

use super::image_logic::*;
use super::image_utils::*;
use crate::metrics::{IMAGE_PROCESSING_DURATION, IMAGE_PROCESSING_TOTAL, UPLOAD_BYTES_TOTAL};
use crate::models::AppError;

/// Generates a batch of images at different resolutions in parallel.
#[tracing::instrument(skip(payload), name = "resize_image_batch")]
pub async fn resize_image_batch(payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "Resizer", "RESIZE_BATCH_START");
    let start = Instant::now();
    let multipart_data = read_multipart_image(payload).await?;
    let total_size = multipart_data.data.len();

    // Metrics
    UPLOAD_BYTES_TOTAL.inc_by(total_size as f64);

    let result_zip = web::block(move || -> Result<Vec<u8>, String> {
        resize_image_batch_sync(multipart_data.data)
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))?;

    let duration = start.elapsed().as_millis();
    match result_zip {
        Ok(zip_bytes) => {
            tracing::info!(
                module = "Resizer",
                duration_ms = duration,
                "RESIZE_BATCH_COMPLETE"
            );

            // Metrics
            IMAGE_PROCESSING_TOTAL
                .with_label_values(&["resize_batch"])
                .inc();
            IMAGE_PROCESSING_DURATION.observe(start.elapsed().as_secs_f64());

            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        }
        Err(e) => {
            tracing::error!(module = "Resizer", duration_ms = duration, error = %e, "RESIZE_BATCH_FAILED");
            Err(AppError::ImageError(e))
        }
    }
}
