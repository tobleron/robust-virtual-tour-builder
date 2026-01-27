/* backend/src/api/media/image.rs - Facade for Image API */

use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};
use std::time::Instant;

use crate::models::{AppError, MetadataResponse};
use crate::metrics::{IMAGE_PROCESSING_DURATION, IMAGE_PROCESSING_TOTAL, UPLOAD_BYTES_TOTAL};

mod image_logic;
mod image_utils;

use image_logic::*;
use image_utils::*;

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

/// Optimizes a single image for preview without full metadata extraction.
#[tracing::instrument(skip(payload), name = "optimize_image")]
pub async fn optimize_image(payload: Multipart) -> Result<HttpResponse, AppError> {
    let start = Instant::now();
    let multipart_data = read_multipart_image(payload).await?;
    let total_size = multipart_data.data.len();

    // Metrics
    UPLOAD_BYTES_TOTAL.inc_by(total_size as f64);

    let result_bytes = web::block(move || -> Result<Vec<u8>, String> {
        optimize_image_sync(multipart_data.data)
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{ColorHist, QualityAnalysis, QualityStats};
    use actix_web::{App, http::StatusCode};
    use image::{ImageFormat, RgbaImage};
    use std::io::Cursor;

    #[test]
    fn test_quality_analysis_serialization() {
        let stats = QualityStats {
            avg_luminance: 128,
            black_clipping: 0.01,
            white_clipping: 0.01,
            sharpness_variance: 500,
        };

        let qa = QualityAnalysis {
            score: 0.85,
            histogram: vec![0; 256],
            color_hist: ColorHist {
                r: vec![],
                g: vec![],
                b: vec![],
            },
            stats,
            is_blurry: false,
            is_soft: false,
            is_severely_dark: false,
            is_severely_bright: false,
            is_dim: false,
            has_black_clipping: false,
            has_white_clipping: false,
            issues: 0,
            warnings: 0,
            analysis: Some("Good".to_string()),
        };

        let json = serde_json::to_string(&qa).expect("Serialization failed");
        assert!(json.contains("score"));
        assert!(json.contains("stats"));
    }

    fn create_test_image() -> Vec<u8> {
        let img = RgbaImage::new(100, 100);
        let mut bytes: Vec<u8> = Vec::new();
        img.write_to(&mut Cursor::new(&mut bytes), ImageFormat::Png)
            .unwrap();
        bytes
    }

    fn create_multipart_body(
        boundary: &str,
        name: &str,
        filename: &str,
        content: &[u8],
    ) -> Vec<u8> {
        let mut body = Vec::new();
        body.extend_from_slice(format!("--{}\r\n", boundary).as_bytes());
        body.extend_from_slice(
            format!(
                "Content-Disposition: form-data; name=\"{}\"; filename=\"{}\"\r\n",
                name, filename
            )
            .as_bytes(),
        );
        body.extend_from_slice(b"Content-Type: image/png\r\n\r\n");
        body.extend_from_slice(content);
        body.extend_from_slice(format!("\r\n--{}--\r\n", boundary).as_bytes());
        body
    }

    #[actix_web::test]
    async fn test_extract_metadata_endpoint() {
        let app = actix_web::test::init_service(
            App::new().route("/metadata", web::post().to(extract_metadata)),
        )
        .await;

        let boundary = "test_boundary";
        let image_data = create_test_image();
        let body = create_multipart_body(boundary, "file", "test.png", &image_data);

        let req = actix_web::test::TestRequest::post()
            .uri("/metadata")
            .insert_header((
                "content-type",
                format!("multipart/form-data; boundary={}", boundary),
            ))
            .set_payload(body)
            .to_request();

        let resp = actix_web::test::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::OK);

        let result: MetadataResponse = actix_web::test::read_body_json(resp).await;
        assert_eq!(result.exif.width, 100);
        assert_eq!(result.exif.height, 100);
    }

    #[actix_web::test]
    async fn test_optimize_image_endpoint() {
        let app = actix_web::test::init_service(
            App::new().route("/optimize", web::post().to(optimize_image)),
        )
        .await;

        let boundary = "test_boundary";
        let image_data = create_test_image();
        let body = create_multipart_body(boundary, "file", "test.png", &image_data);

        let req = actix_web::test::TestRequest::post()
            .uri("/optimize")
            .insert_header((
                "content-type",
                format!("multipart/form-data; boundary={}", boundary),
            ))
            .set_payload(body)
            .to_request();

        let resp = actix_web::test::call_service(&app, req).await;
        assert_eq!(resp.status(), StatusCode::OK);
        assert_eq!(resp.headers().get("content-type").unwrap(), "image/webp");
    }
}
