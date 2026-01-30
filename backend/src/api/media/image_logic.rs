use actix_multipart::Multipart;
use futures_util::TryStreamExt as _;
use rayon::prelude::*;
use std::io::{Cursor, Write};
use std::time::Instant;
use zip::write::FileOptions;

use crate::api::utils::{MAX_UPLOAD_SIZE, PROCESSED_IMAGE_WIDTH, WEBP_QUALITY};
use crate::models::{AppError, ExifMetadata, MetadataResponse};
use crate::services::media;

// --- TYPES ---

pub struct MultipartImageData {
    pub data: Vec<u8>,
    pub filename: Option<String>,
    pub is_optimized: bool,
    pub metadata: Option<ExifMetadata>,
}

// --- HELPER FUNCTIONS ---

fn decode_image(data: &[u8]) -> Result<(image::DynamicImage, image::ImageFormat), String> {
    let data_size = data.len();
    let reader = image::ImageReader::new(Cursor::new(data))
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

    let img = reader
        .decode()
        .map_err(|e| format!("Failed to decode image (size: {} bytes): {}", data_size, e))?;

    Ok((img, format))
}

fn process_metadata_task(
    src_rgba: &image::RgbaImage,
    src_w: u32,
    src_h: u32,
    data: &[u8],
    original_filename: Option<&str>,
    frontend_metadata: Option<ExifMetadata>,
    is_optimized_frontend: bool,
) -> Result<MetadataResponse, String> {
    let mut meta =
        media::perform_metadata_extraction_rgba(src_rgba, src_w, src_h, data, original_filename)?;
    if let Some(front_exif) = frontend_metadata {
        meta.exif = front_exif;
        meta.suggested_name = original_filename.map(media::get_suggested_name);
    }
    if is_optimized_frontend {
        meta.is_optimized = true;
    }
    Ok(meta)
}

fn process_tiny_image_task(
    src_rgba: &image::RgbaImage,
    src_w: u32,
    src_h: u32,
) -> Result<Vec<u8>, String> {
    let tiny_rgba = media::resize_fast_rgba(src_rgba, src_w, src_h, 512, 512)
        .map_err(|e| format!("Tiny resize failed: {}", e))?;
    let tiny_img = image::RgbaImage::from_raw(512, 512, tiny_rgba)
        .ok_or_else(|| "Failed to create tiny image buffer".to_string())?;
    media::encode_webp(&image::DynamicImage::ImageRgba8(tiny_img), 60.0)
}

fn process_large_image_task(
    src_rgba: &image::RgbaImage,
    src_w: u32,
    src_h: u32,
    data: &[u8],
    is_optimized_frontend: bool,
) -> Result<Vec<u8>, String> {
    if is_optimized_frontend && src_w == PROCESSED_IMAGE_WIDTH {
        tracing::info!(
            module = "Processor",
            "BYPASSING_4K_RESIZE_FRONTEND_OPTIMIZED"
        );
        Ok(data.to_vec())
    } else {
        let resized_rgba = media::resize_fast_rgba(
            src_rgba,
            src_w,
            src_h,
            PROCESSED_IMAGE_WIDTH,
            PROCESSED_IMAGE_WIDTH,
        )
        .map_err(|e| format!("Resize failed: {}", e))?;
        let img =
            image::RgbaImage::from_raw(PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH, resized_rgba)
                .ok_or_else(|| "Failed to create image buffer".to_string())?;
        media::encode_webp(&image::DynamicImage::ImageRgba8(img), WEBP_QUALITY)
    }
}

fn execute_parallel_image_processing(
    src_rgba: &image::RgbaImage,
    src_w: u32,
    src_h: u32,
    data: &[u8],
    original_filename: Option<&str>,
    frontend_metadata: Option<ExifMetadata>,
    is_optimized_frontend: bool,
) -> Result<(MetadataResponse, Vec<u8>, Vec<u8>), String> {
    let ((metadata_res, tiny_res), large_res) = rayon::join(
        || {
            rayon::join(
                || {
                    process_metadata_task(
                        src_rgba,
                        src_w,
                        src_h,
                        data,
                        original_filename,
                        frontend_metadata.clone(),
                        is_optimized_frontend,
                    )
                },
                || process_tiny_image_task(src_rgba, src_w, src_h),
            )
        },
        || process_large_image_task(src_rgba, src_w, src_h, data, is_optimized_frontend),
    );

    let metadata = metadata_res?;
    let tiny_bytes = tiny_res?;
    let large_bytes = large_res?;

    Ok((metadata, tiny_bytes, large_bytes))
}

fn create_zip_response(
    webp_buffer_vec: &[u8],
    tiny_bytes: &[u8],
    metadata: &MetadataResponse,
) -> Result<Vec<u8>, String> {
    let mut zip_buffer = Cursor::new(Vec::new());
    {
        let mut zip = zip::ZipWriter::new(&mut zip_buffer);
        let options = FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored)
            .unix_permissions(0o755);

        zip.start_file("preview.webp", options)
            .map_err(|e| e.to_string())?;
        zip.write_all(webp_buffer_vec).map_err(|e| e.to_string())?;

        zip.start_file("tiny.webp", options)
            .map_err(|e| e.to_string())?;
        zip.write_all(tiny_bytes).map_err(|e| e.to_string())?;

        zip.start_file("metadata.json", options)
            .map_err(|e| e.to_string())?;
        let meta_json = serde_json::to_string(metadata).map_err(|e| e.to_string())?;
        zip.write_all(meta_json.as_bytes())
            .map_err(|e| e.to_string())?;

        zip.finish().map_err(|e| e.to_string())?;
    }
    Ok(zip_buffer.into_inner())
}

fn finalize_webp_buffer(
    data: &[u8],
    large_bytes: Vec<u8>,
    metadata: &MetadataResponse,
    is_optimized_frontend: bool,
    src_w: u32,
) -> Result<Vec<u8>, String> {
    if is_optimized_frontend && src_w == PROCESSED_IMAGE_WIDTH {
        media::inject_remx_chunk(large_bytes, metadata)
    } else if metadata.is_optimized && src_w == PROCESSED_IMAGE_WIDTH {
        Ok(data.to_vec())
    } else {
        media::inject_remx_chunk(large_bytes, metadata)
    }
}

// --- SYNC LOGIC ---

pub fn process_image_full_sync(
    data: Vec<u8>,
    original_filename: Option<String>,
    is_optimized_frontend: bool,
    frontend_metadata: Option<ExifMetadata>,
) -> Result<Vec<u8>, String> {
    let decode_start = Instant::now();
    let data_size = data.len();

    let (img, format) = decode_image(&data)?;

    tracing::info!(module = "Processor", format = ?format, size = data_size, "IMAGE_FORMAT_IDENTIFIED");

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
    let (metadata, tiny_bytes, large_bytes) = execute_parallel_image_processing(
        &src_rgba,
        src_w,
        src_h,
        &data,
        original_filename.as_deref(),
        frontend_metadata,
        is_optimized_frontend,
    )?;
    let parallel_time = parallel_start.elapsed();

    let webp_buffer_vec =
        finalize_webp_buffer(&data, large_bytes, &metadata, is_optimized_frontend, src_w)?;

    let zip_start = Instant::now();
    let zip_bytes = create_zip_response(&webp_buffer_vec, &tiny_bytes, &metadata)?;
    let zip_time = zip_start.elapsed();

    tracing::info!(
        "Backend Timings: Decode: {}ms, RGBA: {:?}, Parallel: {:?}, Zip: {:?}",
        decode_time,
        rgba_time,
        parallel_time,
        zip_time
    );
    Ok(zip_bytes)
}

pub fn optimize_image_sync(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let start = Instant::now();
    let reader = image::ImageReader::new(Cursor::new(data))
        .with_guessed_format()
        .map_err(|e| format!("Failed to guess format: {}", e))?;
    reader
        .format()
        .ok_or_else(|| "Unsupported or invalid image format.".to_string())?;
    let img = reader
        .decode()
        .map_err(|e| format!("Failed to decode image: {}", e))?;

    tracing::info!(
        module = "Optimizer",
        duration_ms = start.elapsed().as_millis(),
        "IMAGE_DECODE_COMPLETE"
    );

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

async fn read_field_content(field: &mut actix_multipart::Field) -> Result<Vec<u8>, AppError> {
    let mut value = Vec::new();
    while let Some(chunk) = field.try_next().await? {
        value.extend_from_slice(&chunk);
    }
    Ok(value)
}

async fn read_file_field_content(
    field: &mut actix_multipart::Field,
    max_size: usize,
) -> Result<Vec<u8>, AppError> {
    let mut data = Vec::with_capacity(32 * 1024 * 1024);
    let mut total_size = 0;
    while let Some(chunk) = field.try_next().await? {
        total_size += chunk.len();
        if total_size > max_size {
            return Err(AppError::ImageError(format!(
                "Upload exceeds limit of {}MB",
                max_size / (1024 * 1024)
            )));
        }
        data.extend_from_slice(&chunk);
    }
    Ok(data)
}

async fn process_file_field(
    field: &mut actix_multipart::Field,
    original_filename: &mut Option<String>,
) -> Result<Vec<u8>, AppError> {
    if original_filename.is_none() {
        if let Some(cd) = field.content_disposition() {
            if let Some(fname) = cd.get_filename() {
                *original_filename = Some(fname.to_string());
            }
        }
    }
    read_file_field_content(field, MAX_UPLOAD_SIZE).await
}

async fn process_optimized_field(field: &mut actix_multipart::Field) -> Result<bool, AppError> {
    let value = read_field_content(field).await?;
    if let Ok(s) = String::from_utf8(value) {
        Ok(s.to_lowercase() == "true")
    } else {
        Ok(false)
    }
}

async fn process_metadata_field(
    field: &mut actix_multipart::Field,
) -> Result<Option<ExifMetadata>, AppError> {
    let value = read_field_content(field).await?;
    if let Ok(s) = String::from_utf8(value) {
        Ok(serde_json::from_str(&s).ok())
    } else {
        Ok(None)
    }
}

pub async fn read_multipart_image(mut payload: Multipart) -> Result<MultipartImageData, AppError> {
    let mut data = Vec::new();
    let mut filename: Option<String> = None;
    let mut is_optimized = false;
    let mut metadata: Option<ExifMetadata> = None;

    while let Some(mut field) = payload.try_next().await? {
        match field.name().unwrap_or("") {
            "file" => data = process_file_field(&mut field, &mut filename).await?,
            "is_optimized" => is_optimized = process_optimized_field(&mut field).await?,
            "metadata" => metadata = process_metadata_field(&mut field).await?,
            _ => {
                let _ = read_field_content(&mut field).await?;
            }
        }
    }

    Ok(MultipartImageData {
        data,
        filename,
        is_optimized,
        metadata,
    })
}
