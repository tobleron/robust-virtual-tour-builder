/* backend/src/api/media/image.rs - Consolidated Image API */

use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};
use std::time::Instant;

use crate::api::media::{image_logic, image_multipart};
use crate::metrics::{IMAGE_PROCESSING_DURATION, IMAGE_PROCESSING_TOTAL, UPLOAD_BYTES_TOTAL};
use crate::models::{AppError, MetadataResponse};

// --- HANDLERS ---

/// Extracts EXIF metadata and performs quality analysis on an image.
#[tracing::instrument(skip(payload), name = "extract_metadata")]
pub async fn extract_metadata(payload: Multipart) -> Result<HttpResponse, AppError> {
    let multipart_data = image_multipart::read_multipart_image(payload).await?;
    let total_size = multipart_data.data.len();

    if let Some(m) = &*UPLOAD_BYTES_TOTAL {
        m.inc_by(total_size as f64);
    }

    let start = Instant::now();
    let result = web::block(move || -> Result<MetadataResponse, String> {
        image_logic::extract_metadata_sync(multipart_data.data, multipart_data.filename)
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
            if let Some(m) = &*IMAGE_PROCESSING_TOTAL {
                m.with_label_values(&["extract_metadata"]).inc();
            }
            if let Some(m) = &*IMAGE_PROCESSING_DURATION {
                m.observe(start.elapsed().as_secs_f64());
            }
            Ok(HttpResponse::Ok().json(data))
        }
        Err(e) => {
            tracing::error!(module = "Extractor", duration_ms = duration, error = %e, "EXTRACT_METADATA_FAILED");
            Err(AppError::ImageError(e))
        }
    }
}

/// Optimizes a single image for preview without full metadata extraction.
#[tracing::instrument(skip(payload), name = "optimize_image")]
pub async fn optimize_image(payload: Multipart) -> Result<HttpResponse, AppError> {
    let start = Instant::now();
    let multipart_data = image_multipart::read_multipart_image(payload).await?;
    let total_size = multipart_data.data.len();

    if let Some(m) = &*UPLOAD_BYTES_TOTAL {
        m.inc_by(total_size as f64);
    }

    let result_bytes = web::block(move || -> Result<Vec<u8>, String> {
        image_logic::optimize_image_sync(multipart_data.data)
    })
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
            if let Some(m) = &*IMAGE_PROCESSING_TOTAL {
                m.with_label_values(&["optimize"]).inc();
            }
            if let Some(m) = &*IMAGE_PROCESSING_DURATION {
                m.observe(start.elapsed().as_secs_f64());
            }
            Ok(HttpResponse::Ok().content_type("image/webp").body(bytes))
        }
        Err(e) => {
            tracing::error!(module = "Optimizer", duration_ms = duration, error = %e, "OPTIMIZE_IMAGE_FAILED");
            Err(AppError::ImageError(e))
        }
    }
}

/// Processes an uploaded panorama image through the full optimization pipeline.
#[tracing::instrument(skip(payload), name = "process_image_full")]
pub async fn process_image_full(payload: Multipart) -> Result<HttpResponse, AppError> {
    let multipart_data = image_multipart::read_multipart_image(payload).await?;
    let total_size = multipart_data.data.len();

    if let Some(m) = &*UPLOAD_BYTES_TOTAL {
        m.inc_by(total_size as f64);
    }

    let total_start = Instant::now();
    let result_zip = web::block(move || -> Result<Vec<u8>, String> {
        image_logic::process_image_full_sync(
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
            if let Some(m) = &*IMAGE_PROCESSING_TOTAL {
                m.with_label_values(&["process_full"]).inc();
            }
            if let Some(m) = &*IMAGE_PROCESSING_DURATION {
                m.observe(total_start.elapsed().as_secs_f64());
            }
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        }
        Err(e) => Err(AppError::ImageError(e)),
    }
}

/// Generates a batch of images at different resolutions in parallel.
#[tracing::instrument(skip(payload), name = "resize_image_batch")]
pub async fn resize_image_batch(payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "Resizer", "RESIZE_BATCH_START");
    let start = Instant::now();
    let multipart_data = image_multipart::read_multipart_image(payload).await?;
    let total_size = multipart_data.data.len();

    if let Some(m) = &*UPLOAD_BYTES_TOTAL {
        m.inc_by(total_size as f64);
    }

    let result_zip = web::block(move || -> Result<Vec<u8>, String> {
        image_logic::resize_image_batch_sync(multipart_data.data)
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
            if let Some(m) = &*IMAGE_PROCESSING_TOTAL {
                m.with_label_values(&["resize_batch"]).inc();
            }
            if let Some(m) = &*IMAGE_PROCESSING_DURATION {
                m.observe(start.elapsed().as_secs_f64());
            }
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

#[cfg(test)]
mod tests {

    #[test]
    fn test_quality_analysis_serialization() {
        let quality = crate::models::QualityAnalysis {
            score: 0.82,
            histogram: vec![0; 256],
            color_hist: crate::models::ColorHist {
                r: vec![0; 256],
                g: vec![0; 256],
                b: vec![0; 256],
            },
            stats: crate::models::QualityStats {
                avg_luminance: 120,
                black_clipping: 0.0,
                white_clipping: 0.0,
                sharpness_variance: 1000,
            },
            is_blurry: false,
            is_soft: false,
            is_severely_dark: false,
            is_severely_bright: false,
            is_dim: false,
            has_black_clipping: false,
            has_white_clipping: false,
            issues: 0,
            warnings: 0,
            analysis: None,
        };
        let serialized = serde_json::to_string(&quality).expect("Serialization failed");
        assert!(serialized.contains("\"score\":0.82"));
    }
}
