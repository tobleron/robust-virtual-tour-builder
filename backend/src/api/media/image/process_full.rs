// @efficiency: service-orchestrator
use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};
use std::time::Instant;

use super::image_logic::*;
use super::image_utils::*;
use crate::metrics::{IMAGE_PROCESSING_DURATION, IMAGE_PROCESSING_TOTAL, UPLOAD_BYTES_TOTAL};
use crate::models::AppError;

/// Processes an uploaded panorama image through the full optimization pipeline.
#[tracing::instrument(skip(payload), name = "process_image_full")]
pub async fn process_image_full(payload: Multipart) -> Result<HttpResponse, AppError> {
    let multipart_data = read_multipart_image(payload).await?;
    let total_size = multipart_data.data.len();

    // Metrics: Record upload size
    UPLOAD_BYTES_TOTAL.inc_by(total_size as f64);

    let total_start = Instant::now();
    let result_zip = web::block(move || -> Result<Vec<u8>, String> {
        process_image_full_sync(
            multipart_data.data,
            multipart_data.filename,
            multipart_data.is_optimized,
            multipart_data.metadata,
        )
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))?;

    match result_zip {
        Ok(zip_bytes) => {
            let duration = total_start.elapsed().as_millis();
            tracing::info!(
                module = "Processor",
                duration_ms = duration,
                "PROCESS_IMAGE_FULL_COMPLETE"
            );

            // Metrics: Record success
            IMAGE_PROCESSING_TOTAL
                .with_label_values(&["process_full"])
                .inc();
            IMAGE_PROCESSING_DURATION.observe(total_start.elapsed().as_secs_f64());

            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        }
        Err(e) => Err(AppError::ImageError(e)),
    }
}
