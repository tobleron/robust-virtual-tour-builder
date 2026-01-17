use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};
use futures_util::TryStreamExt as _;
use rayon::prelude::*;
use std::io::{Cursor, Write};
use std::time::Instant;
use zip::write::FileOptions;

use crate::models::{AppError, MetadataResponse};
use crate::services::media;
// Use crate::api::utils or super::super::utils
use crate::api::utils::{MAX_UPLOAD_SIZE, PROCESSED_IMAGE_WIDTH, WEBP_QUALITY};
use crate::metrics::{IMAGE_PROCESSING_DURATION, IMAGE_PROCESSING_TOTAL, UPLOAD_BYTES_TOTAL};

/// Processes an uploaded panorama image through the full optimization pipeline.
///
/// The pipeline performs the following steps:
/// 1. Decode the source image (JPEG, PNG, WebP, HEIC)
/// 2. Extract EXIF metadata (camera info, GPS, timestamp)
/// 3. Analyze image quality (luminance, sharpness, clipping)
/// 4. Generate multi-resolution outputs:
///    - `preview.webp` (2048px width, quality 80)
///    - `tiny.webp` (512px width, quality 60)
/// 5. Compute SHA-256 checksum for duplicate detection
///
/// # Arguments
/// * `payload` - Multipart form data containing a single image file.
///
/// # Returns
/// A ZIP file containing:
/// - `preview.webp`: Optimized preview image.
/// - `tiny.webp`: Thumbnail for sidebar.
/// - `metadata.json`: EXIF data, quality analysis, and checksum.
///
/// # Errors
/// * `ImageError` if no file provided or file exceeds `MAX_UPLOAD_SIZE`.
/// * `InternalError` if image decoding or processing fails.
#[tracing::instrument(skip(payload), name = "process_image_full")]
pub async fn process_image_full(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    // PERFORMANCE: Pre-allocate buffer for typical 30MB panoramic images
    let mut data = Vec::with_capacity(32 * 1024 * 1024);
    let mut total_size = 0;
    let mut original_filename: Option<String> = None;

    while let Some(mut field) = payload.try_next().await? {
        // Capture filename if available
        if original_filename.is_none() {
            if let Some(content_disposition) = field.content_disposition() {
                if let Some(filename) = content_disposition.get_filename() {
                    original_filename = Some(filename.to_string());
                }
            }
        }

        while let Some(chunk) = field.try_next().await? {
            total_size += chunk.len();
            if total_size > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError(format!(
                    "Upload exceeds maximum size of {}MB",
                    MAX_UPLOAD_SIZE / (1024 * 1024)
                )));
            }
            data.extend_from_slice(&chunk);
        }
    }

    // Metrics: Record upload size
    UPLOAD_BYTES_TOTAL.inc_by(total_size as f64);

    let total_start = Instant::now();
    let result_zip = web::block(move || -> Result<Vec<u8>, String> {
        let decode_start = Instant::now();
        let data_size = data.len();
        let img = image::ImageReader::new(Cursor::new(&data))
            .with_guessed_format()
            .map_err(|e| format!("Failed to guess image format (size: {} bytes): {}", data_size, e))?
            .decode()
            .map_err(|e| format!("Failed to decode image (size: {} bytes): {}", data_size, e))?;
        let decode_time = decode_start.elapsed().as_millis();
        tracing::info!(module = "Processor", duration_ms = decode_time, "IMAGE_DECODE_COMPLETE");

        // 0. Initial RGBA conversion
        let rgba_start = Instant::now();
        let (src_w, src_h) = (img.width(), img.height());
        let src_rgba = img.to_rgba8();
        let rgba_time = rgba_start.elapsed();

        // 1. Metadata Extraction
        let meta_start = Instant::now();
        let metadata = media::perform_metadata_extraction_rgba(&src_rgba, src_w, src_h, &data, original_filename.as_deref())?;
        let meta_time = meta_start.elapsed();

        // 2. Image Optimization (4K WebP)
        let opt_start = Instant::now();
        let webp_buffer_vec = if metadata.is_optimized && src_w == PROCESSED_IMAGE_WIDTH {
             tracing::info!(module = "Processor", "IMAGE_ALREADY_OPTIMIZED");
             data.clone()
        } else {
            let resized_rgba = media::resize_fast_rgba(&src_rgba, src_w, src_h, PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH)
                .map_err(|e| format!("Resize failed: {}", e))?;

            let img = image::RgbaImage::from_raw(PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH, resized_rgba)
                .ok_or_else(|| "Failed to create image buffer".to_string())
                .map_err(|e| format!("{}", e))?;

            let buf = media::encode_webp(&image::DynamicImage::ImageRgba8(img), WEBP_QUALITY)?;

            media::inject_remx_chunk(buf, &metadata)?
        };
        let opt_time = opt_start.elapsed();

        let webp_buffer = Cursor::new(webp_buffer_vec);

        // 3. Tiny Preview
        let tiny_start = Instant::now();
        let tiny_rgba = media::resize_fast_rgba(&src_rgba, src_w, src_h, 512, 512)
            .map_err(|e| format!("Tiny resize failed: {}", e))?;
        let tiny_img = image::RgbaImage::from_raw(512, 512, tiny_rgba)
            .ok_or_else(|| "Failed to create tiny image buffer".to_string())
            .map_err(|e| format!("{}", e))?;
        let tiny_bytes = media::encode_webp(&image::DynamicImage::ImageRgba8(tiny_img), 60.0)?;
        let tiny_buffer = Cursor::new(tiny_bytes);
        let tiny_time = tiny_start.elapsed();

        // 3. Package as ZIP
        let zip_start = Instant::now();
        let mut zip_buffer = Cursor::new(Vec::new());
        {
            let mut zip = zip::ZipWriter::new(&mut zip_buffer);
            let options = FileOptions::default()
                .compression_method(zip::CompressionMethod::Stored)
                .unix_permissions(0o755);

            zip.start_file("preview.webp", options).map_err(|e| e.to_string())?;
            zip.write_all(webp_buffer.get_ref()).map_err(|e| e.to_string())?;

            zip.start_file("tiny.webp", options).map_err(|e| e.to_string())?;
            zip.write_all(tiny_buffer.get_ref()).map_err(|e| e.to_string())?;

            zip.start_file("metadata.json", options).map_err(|e| e.to_string())?;
            let meta_json = serde_json::to_string(&metadata).map_err(|e| e.to_string())?;
            zip.write_all(meta_json.as_bytes()).map_err(|e| e.to_string())?;

            zip.finish().map_err(|e| e.to_string())?;
        }
        let zip_time = zip_start.elapsed();

        tracing::info!(
            "Backend Processing Timings: Decode: {:?}, RGBA: {:?}, Meta: {:?}, 4K: {:?}, Tiny: {:?}, Zip: {:?}",
            decode_time, rgba_time, meta_time, opt_time, tiny_time, zip_time
        );

        Ok(zip_buffer.into_inner())
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    tracing::info!(
        module = "Processor",
        duration_ms = total_start.elapsed().as_millis(),
        "PROCESS_IMAGE_FULL_TIMING"
    );

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
///
/// This is a lighter alternative to `process_image_full` used for quick previews
/// where full quality analysis is not required.
///
/// # Arguments
/// * `payload` - Multipart form data containing an image file.
///
/// # Returns
/// A single WebP image file as binary data.
///
/// # Errors
/// * `ImageError` if the image size exceeds limits or decoding fails.
#[tracing::instrument(skip(payload), name = "optimize_image")]
pub async fn optimize_image(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    let start = Instant::now();
    // PERFORMANCE: Pre-allocate buffer for typical 30MB panoramic images
    let mut data = Vec::with_capacity(32 * 1024 * 1024);
    let mut total_size = 0;

    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
            total_size += chunk.len();
            if total_size > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError(format!(
                    "Upload exceeds maximum size of {}MB",
                    MAX_UPLOAD_SIZE / (1024 * 1024)
                )));
            }
            data.extend_from_slice(&chunk);
        }
    }

    // Metrics
    UPLOAD_BYTES_TOTAL.inc_by(total_size as f64);

    let result_bytes = web::block(move || -> Result<Vec<u8>, String> {
        let start = Instant::now();
        let img = image::ImageReader::new(Cursor::new(data))
            .with_guessed_format()
            .map_err(|e| format!("Failed to guess format: {}", e))?
            .decode()
            .map_err(|e| format!("Failed to decode image: {}", e))?;
        let duration = start.elapsed().as_millis();
        tracing::info!(
            module = "Optimizer",
            duration_ms = duration,
            "IMAGE_DECODE_COMPLETE"
        );

        // Use Lanczos3 for absolute sharpness in editor previews (via fast_image_resize)
        let resized = media::resize_fast(&img, PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH)
            .map_err(|e| format!("Resize failed: {}", e))?;

        let webp_bytes = media::encode_webp(&resized, WEBP_QUALITY)?;

        Ok(webp_bytes)
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
///
/// Produces a ZIP containing 4K, 2K, and HD versions of the uploaded image
/// to support responsive viewing across different device types.
///
/// # Arguments
/// * `payload` - Multipart form data containing an image file.
///
/// # Returns
/// A ZIP file containing `4k.webp`, `2k.webp`, and `hd.webp`.
///
/// # Errors
/// * `ImageError` if the image cannot be processed.
/// * `InternalError` if parallel execution fails.
#[tracing::instrument(skip(payload), name = "resize_image_batch")]
pub async fn resize_image_batch(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "Resizer", "RESIZE_BATCH_START");
    let start = Instant::now();
    let mut data = Vec::with_capacity(32 * 1024 * 1024);
    let mut total_size = 0;

    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
            total_size += chunk.len();
            if total_size > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError(format!(
                    "Upload exceeds maximum size of {}MB",
                    MAX_UPLOAD_SIZE / (1024 * 1024)
                )));
            }
            data.extend_from_slice(&chunk);
        }
    }

    // Metrics
    UPLOAD_BYTES_TOTAL.inc_by(total_size as f64);

    let result_zip = web::block(move || -> Result<Vec<u8>, String> {
        // 2. Decode Image
        let img = image::ImageReader::new(Cursor::new(data))
            .with_guessed_format()
            .map_err(|e| format!("Failed to guess format: {}", e))?
            .decode()
            .map_err(|e| format!("Failed to decode image: {}", e))?;

        // 3. Prepare ZIP writer in memory
        let mut zip_buffer = Cursor::new(Vec::new());
        {
            let mut zip = zip::ZipWriter::new(&mut zip_buffer);
            let options = FileOptions::default()
                .compression_method(zip::CompressionMethod::Stored) // WebP is already compressed
                .unix_permissions(0o755);

            // 4. Resize and Write in parallel using Rayon
            // Targets: 4K (4096), 2K (2048), HD (1280)
            let targets = [("4k.webp", 4096), ("2k.webp", 2048), ("hd.webp", 1280)];

            let results: Vec<Result<(String, Vec<u8>), String>> = targets
                .par_iter()
                .map(|(filename, width)| {
                    let resized = media::resize_fast(&img, *width, *width)
                        .map_err(|e| format!("Resize failed: {}", e))?;

                    let webp_bytes = media::encode_webp(&resized, WEBP_QUALITY)?;

                    Ok((filename.to_string(), webp_bytes))
                })
                .collect();

            for result in results {
                let (filename, data) = result?;
                zip.start_file(filename, options)
                    .map_err(|e| e.to_string())?;
                zip.write_all(&data).map_err(|e| e.to_string())?;
            }

            zip.finish().map_err(|e| e.to_string())?;
        }

        Ok(zip_buffer.into_inner())
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
///
/// This handler does not save or optimize the image; it only returns the
/// technical details and quality metrics.
///
/// # Arguments
/// * `payload` - Multipart form data containing an image file.
///
/// # Returns
/// A `MetadataResponse` JSON object.
///
/// # Errors
/// * `ImageError` if the metadata cannot be parsed.
#[tracing::instrument(skip(payload), name = "extract_metadata")]
pub async fn extract_metadata(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    let mut data = Vec::with_capacity(32 * 1024 * 1024);
    let mut total_size = 0;
    let mut original_filename: Option<String> = None;

    while let Some(mut field) = payload.try_next().await? {
        if original_filename.is_none() {
            if let Some(content_disposition) = field.content_disposition() {
                if let Some(filename) = content_disposition.get_filename() {
                    original_filename = Some(filename.to_string());
                }
            }
        }

        while let Some(chunk) = field.try_next().await? {
            total_size += chunk.len();
            if total_size > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError(format!(
                    "Upload exceeds maximum size of {}MB",
                    MAX_UPLOAD_SIZE / (1024 * 1024)
                )));
            }
            data.extend_from_slice(&chunk);
        }
    }

    // Metrics
    UPLOAD_BYTES_TOTAL.inc_by(total_size as f64);

    let start = Instant::now();
    let result = web::block(move || -> Result<MetadataResponse, String> {
        let img = image::ImageReader::new(Cursor::new(&data))
            .with_guessed_format()
            .map_err(|e| format!("Failed to guess format: {}", e))?
            .decode()
            .map_err(|e| format!("Failed to decode: {}", e))?;

        media::perform_metadata_extraction(&img, &data, original_filename.as_deref())
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
    use crate::models::{ColorHist, QualityAnalysis, QualityStats};

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

        let json = serde_json::to_string(&qa).unwrap();
        assert!(json.contains("score"));
        assert!(json.contains("stats"));
    }
}
