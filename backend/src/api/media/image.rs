/* backend/src/api/media/image.rs - Consolidated Image API */

use actix_multipart::Multipart;
use actix_web::{HttpResponse, web};
use futures_util::TryStreamExt as _;
use rayon::prelude::*;
use std::io::{Cursor, Write};
use std::time::Instant;
use zip::write::FileOptions;

use crate::api::utils::{MAX_UPLOAD_SIZE, PROCESSED_IMAGE_WIDTH, WEBP_QUALITY};
use crate::metrics::{IMAGE_PROCESSING_DURATION, IMAGE_PROCESSING_TOTAL, UPLOAD_BYTES_TOTAL};
use crate::models::{AppError, ExifMetadata, MetadataResponse};
use crate::services::media;

// --- TYPES ---

pub struct MultipartImageData {
    pub data: Vec<u8>,
    pub filename: Option<String>,
    pub is_optimized: bool,
    pub metadata: Option<ExifMetadata>,
}

// --- HANDLERS ---

/// Extracts EXIF metadata and performs quality analysis on an image.
#[tracing::instrument(skip(payload), name = "extract_metadata")]
pub async fn extract_metadata(payload: Multipart) -> Result<HttpResponse, AppError> {
    let multipart_data = read_multipart_image(payload).await?;
    let total_size = multipart_data.data.len();

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

/// Optimizes a single image for preview without full metadata extraction.
#[tracing::instrument(skip(payload), name = "optimize_image")]
pub async fn optimize_image(payload: Multipart) -> Result<HttpResponse, AppError> {
    let start = Instant::now();
    let multipart_data = read_multipart_image(payload).await?;
    let total_size = multipart_data.data.len();

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

/// Processes an uploaded panorama image through the full optimization pipeline.
#[tracing::instrument(skip(payload), name = "process_image_full")]
pub async fn process_image_full(payload: Multipart) -> Result<HttpResponse, AppError> {
    let multipart_data = read_multipart_image(payload).await?;
    let total_size = multipart_data.data.len();

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

/// Generates a batch of images at different resolutions in parallel.
#[tracing::instrument(skip(payload), name = "resize_image_batch")]
pub async fn resize_image_batch(payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "Resizer", "RESIZE_BATCH_START");
    let start = Instant::now();
    let multipart_data = read_multipart_image(payload).await?;
    let total_size = multipart_data.data.len();

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

// --- INTERNAL SYNC LOGIC ---

pub fn process_image_full_sync(
    data: Vec<u8>,
    original_filename: Option<String>,
    is_optimized_frontend: bool,
    frontend_metadata: Option<ExifMetadata>,
) -> Result<Vec<u8>, String> {
    let decode_start = Instant::now();
    let data_size = data.len();

    let reader = image::ImageReader::new(Cursor::new(&data))
        .with_guessed_format()
        .map_err(|e| {
            format!(
                "Failed to guess image format (size: {} bytes): {}",
                data_size, e
            )
        })?;

    let format = reader.format().ok_or_else(|| {
        "Unsupported or invalid image format. Please upload JPEG, PNG, WebP, or HEIC.".to_string()
    })?;

    tracing::info!(module = "Processor", format = ?format, size = data_size, "IMAGE_FORMAT_IDENTIFIED");

    let img = reader
        .decode()
        .map_err(|e| format!("Failed to decode image (size: {} bytes): {}", data_size, e))?;

    let decode_time = decode_start.elapsed().as_millis();
    tracing::info!(
        module = "Processor",
        duration_ms = decode_time,
        "IMAGE_DECODE_COMPLETE"
    );

    let rgba_start = Instant::now();
    let (src_w, src_h) = (img.width(), img.height());
    let src_rgba = img.to_rgba8();
    let rgba_time = rgba_start.elapsed();

    let parallel_start = Instant::now();
    let ((metadata_res, tiny_res), large_res) = rayon::join(
        || {
            rayon::join(
                || -> Result<MetadataResponse, String> {
                    let mut meta = media::perform_metadata_extraction_rgba(
                        &src_rgba,
                        src_w,
                        src_h,
                        &data,
                        original_filename.as_deref(),
                    )?;
                    if let Some(front_exif) = frontend_metadata {
                        meta.exif = front_exif;
                        meta.suggested_name =
                            original_filename.as_deref().map(media::get_suggested_name);
                    }
                    if is_optimized_frontend {
                        meta.is_optimized = true;
                    }
                    Ok(meta)
                },
                || -> Result<Vec<u8>, String> {
                    let tiny_rgba = media::resize_fast_rgba(&src_rgba, src_w, src_h, 512, 512)
                        .map_err(|e| format!("Tiny resize failed: {}", e))?;
                    let tiny_img = image::RgbaImage::from_raw(512, 512, tiny_rgba)
                        .ok_or_else(|| "Failed to create tiny image buffer".to_string())?;
                    media::encode_webp(&image::DynamicImage::ImageRgba8(tiny_img), 60.0)
                },
            )
        },
        || -> Result<Vec<u8>, String> {
            if is_optimized_frontend && src_w == PROCESSED_IMAGE_WIDTH {
                tracing::info!(
                    module = "Processor",
                    "BYPASSING_4K_RESIZE_FRONTEND_OPTIMIZED"
                );
                Ok(data.clone())
            } else {
                let resized_rgba = media::resize_fast_rgba(
                    &src_rgba,
                    src_w,
                    src_h,
                    PROCESSED_IMAGE_WIDTH,
                    PROCESSED_IMAGE_WIDTH,
                )
                .map_err(|e| format!("Resize failed: {}", e))?;
                let img = image::RgbaImage::from_raw(
                    PROCESSED_IMAGE_WIDTH,
                    PROCESSED_IMAGE_WIDTH,
                    resized_rgba,
                )
                .ok_or_else(|| "Failed to create image buffer".to_string())?;
                media::encode_webp(&image::DynamicImage::ImageRgba8(img), WEBP_QUALITY)
            }
        },
    );
    let parallel_time = parallel_start.elapsed();

    let metadata = metadata_res?;
    let tiny_bytes = tiny_res?;
    let large_bytes = large_res?;

    let webp_buffer_vec = if is_optimized_frontend && src_w == PROCESSED_IMAGE_WIDTH {
        media::inject_remx_chunk(large_bytes, &metadata)?
    } else if metadata.is_optimized && src_w == PROCESSED_IMAGE_WIDTH {
        data.clone()
    } else {
        media::inject_remx_chunk(large_bytes, &metadata)?
    };

    let mut zip_buffer = Cursor::new(Vec::new());
    {
        let mut zip = zip::ZipWriter::new(&mut zip_buffer);
        let options = FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored)
            .unix_permissions(0o755);

        zip.start_file("preview.webp", options)
            .map_err(|e| e.to_string())?;
        zip.write_all(&webp_buffer_vec).map_err(|e| e.to_string())?;

        zip.start_file("tiny.webp", options)
            .map_err(|e| e.to_string())?;
        zip.write_all(&tiny_bytes).map_err(|e| e.to_string())?;

        zip.start_file("metadata.json", options)
            .map_err(|e| e.to_string())?;
        let meta_json = serde_json::to_string(&metadata).map_err(|e| e.to_string())?;
        zip.write_all(meta_json.as_bytes())
            .map_err(|e| e.to_string())?;

        zip.finish().map_err(|e| e.to_string())?;
    }
    let zip_time = Instant::now().elapsed(); // Approximate

    tracing::info!(
        "Backend Timings: Decode: {}ms, RGBA: {:?}, Parallel: {:?}, Zip: {:?}",
        decode_time,
        rgba_time,
        parallel_time,
        zip_time
    );
    Ok(zip_buffer.into_inner())
}

pub fn optimize_image_sync(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let start = Instant::now();
    let reader = image::ImageReader::new(Cursor::new(data))
        .with_guessed_format()
        .map_err(|e| format!("Failed to guess format: {}", e))?;
    let format = reader
        .format()
        .ok_or_else(|| "Unsupported or invalid image format.".to_string())?;
    let img = reader
        .decode()
        .map_err(|e| format!("Failed to decode image: {}", e))?;

    tracing::info!(module = "Optimizer", format = ?format, duration_ms = start.elapsed().as_millis(), "IMAGE_DECODE_COMPLETE");

    let resized = media::resize_fast(&img, PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH)
        .map_err(|e| format!("Resize failed: {}", e))?;
    media::encode_webp(&resized, WEBP_QUALITY)
}

pub fn resize_image_batch_sync(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let reader = image::ImageReader::new(Cursor::new(data))
        .with_guessed_format()
        .map_err(|e| format!("Failed to guess format: {}", e))?;
    let img = reader
        .decode()
        .map_err(|e| format!("Failed to decode image: {}", e))?;

    let mut zip_buffer = Cursor::new(Vec::new());
    {
        let mut zip = zip::ZipWriter::new(&mut zip_buffer);
        let options = FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored)
            .unix_permissions(0o755);
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
}

pub fn extract_metadata_sync(
    data: Vec<u8>,
    original_filename: Option<String>,
) -> Result<MetadataResponse, String> {
    let reader = image::ImageReader::new(Cursor::new(&data))
        .with_guessed_format()
        .map_err(|e| format!("Failed to guess format: {}", e))?;
    let img = reader
        .decode()
        .map_err(|e| format!("Failed to decode: {}", e))?;
    media::perform_metadata_extraction(&img, &data, original_filename.as_deref())
}

// --- UTILS ---

pub async fn read_multipart_image(mut payload: Multipart) -> Result<MultipartImageData, AppError> {
    let mut data = Vec::with_capacity(32 * 1024 * 1024);
    let mut total_size = 0;
    let mut original_filename: Option<String> = None;
    let mut is_optimized_frontend = false;
    let mut frontend_metadata: Option<ExifMetadata> = None;

    while let Some(mut field) = payload.try_next().await? {
        let name = field.name().unwrap_or("").to_string();
        if name == "file" {
            if original_filename.is_none()
                && let Some(cd) = field.content_disposition()
                && let Some(fname) = cd.get_filename()
            {
                original_filename = Some(fname.to_string());
            }
            while let Some(chunk) = field.try_next().await? {
                total_size += chunk.len();
                if total_size > MAX_UPLOAD_SIZE {
                    return Err(AppError::ImageError(format!(
                        "Upload exceeds limit of {}MB",
                        MAX_UPLOAD_SIZE / (1024 * 1024)
                    )));
                }
                data.extend_from_slice(&chunk);
            }
        } else if name == "is_optimized" {
            let mut value = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                value.extend_from_slice(&chunk);
            }
            if let Ok(s) = String::from_utf8(value) {
                is_optimized_frontend = s.to_lowercase() == "true";
            }
        } else if name == "metadata" {
            let mut value = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                value.extend_from_slice(&chunk);
            }
            if let Ok(s) = String::from_utf8(value) {
                frontend_metadata = serde_json::from_str(&s).ok();
            }
        }
    }
    Ok(MultipartImageData {
        data,
        filename: original_filename,
        is_optimized: is_optimized_frontend,
        metadata: frontend_metadata,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

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
        let serialized = serde_json::to_string(&quality).unwrap();
        assert!(serialized.contains("\"score\":0.82"));
    }
}
