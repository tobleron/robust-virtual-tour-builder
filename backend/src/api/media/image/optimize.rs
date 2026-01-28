// @efficiency: service-orchestrator
use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};
use std::time::Instant;

use super::image_logic::*;
use super::image_utils::*;
use crate::metrics::{IMAGE_PROCESSING_DURATION, IMAGE_PROCESSING_TOTAL, UPLOAD_BYTES_TOTAL};
use crate::models::AppError;

/// Optimizes a single image for preview without full metadata extraction.
#[tracing::instrument(skip(payload), name = "optimize_image")]
pub async fn optimize_image(payload: Multipart) -> Result<HttpResponse, AppError> {
    let start = Instant::now();
    let multipart_data = read_multipart_image(payload).await?;
    let total_size = multipart_data.data.len();

    // Metrics
    UPLOAD_BYTES_TOTAL.inc_by(total_size as f64);

    let result_bytes =
        web::block(move || -> Result<Vec<u8>, String> { optimize_image_sync(multipart_data.data) })
            .await
            .map_err(|e| AppError::InternalError(e.to_string()))?;

    let duration = start.elapsed().as_millis();
    match result_bytes {
        Ok(bytes) => {
            tracing::info!(
                module = "Optimizer",
                duration_ms = duration,
                "OPTIMIZE_IMAGE_COMPLETE"
            );

            // Metrics
            IMAGE_PROCESSING_TOTAL
                .with_label_values(&["optimize"])
                .inc();
            IMAGE_PROCESSING_DURATION.observe(start.elapsed().as_secs_f64());

            Ok(HttpResponse::Ok().content_type("image/webp").body(bytes))
        }
        Err(e) => {
            tracing::error!(module = "Optimizer", duration_ms = duration, error = %e, "OPTIMIZE_IMAGE_FAILED");
            Err(AppError::ImageError(e))
        }
    }
}
