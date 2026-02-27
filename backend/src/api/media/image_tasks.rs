use std::io::{Cursor, Write};
use zip::write::FileOptions;

use crate::api::utils::{PROCESSED_IMAGE_WIDTH, TINY_WEBP_QUALITY, WEBP_QUALITY};
use crate::models::{ExifMetadata, MetadataResponse};
use crate::services::media;

pub const DEFAULT_MAX_DECODE_DIMENSION: u32 = 16_384;
pub const DEFAULT_MAX_DECODE_ALLOC_BYTES: u64 = 1_073_741_824; // 1 GiB

fn max_decode_dimension() -> u32 {
    std::env::var("IMAGE_MAX_DECODE_DIMENSION")
        .ok()
        .and_then(|v| v.parse::<u32>().ok())
        .filter(|v| *v >= 1_024)
        .unwrap_or(DEFAULT_MAX_DECODE_DIMENSION)
}

fn max_decode_alloc_bytes() -> u64 {
    std::env::var("IMAGE_MAX_DECODE_ALLOC_BYTES")
        .ok()
        .and_then(|v| v.parse::<u64>().ok())
        .filter(|v| *v >= 128 * 1024 * 1024)
        .unwrap_or(DEFAULT_MAX_DECODE_ALLOC_BYTES)
}

fn decode_guardrail(width: u32, height: u32) -> Result<(), String> {
    let max_dim = max_decode_dimension();
    if width > max_dim || height > max_dim {
        return Err(format!(
            "Image dimensions too large: {}x{} exceeds {}x{}",
            width, height, max_dim, max_dim
        ));
    }
    Ok(())
}

pub fn decode_image(data: &[u8]) -> Result<(image::DynamicImage, image::ImageFormat), String> {
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

    decode_guardrail(img.width(), img.height())?;
    let estimated_rgba_bytes = img.width() as u64 * img.height() as u64 * 4;
    let alloc_budget = max_decode_alloc_bytes();
    if estimated_rgba_bytes > alloc_budget {
        return Err(format!(
            "Image exceeds decode allocation budget: estimated {} bytes > limit {} bytes",
            estimated_rgba_bytes, alloc_budget
        ));
    }

    Ok((img, format))
}

pub fn process_metadata_task(
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

pub fn process_tiny_image_task(
    src_rgba: &image::RgbaImage,
    src_w: u32,
    src_h: u32,
) -> Result<Vec<u8>, String> {
    let tiny_rgba = media::resize_fast_rgba_progressive(src_rgba, src_w, src_h, 512, 512)
        .map_err(|e| format!("Tiny resize failed: {}", e))?;
    let tiny_img = image::RgbaImage::from_raw(512, 512, tiny_rgba)
        .ok_or_else(|| "Failed to create tiny image buffer".to_string())?;
    media::encode_webp(
        &image::DynamicImage::ImageRgba8(tiny_img),
        TINY_WEBP_QUALITY,
    )
}

pub fn process_large_image_task(
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
        let resized_rgba = media::resize_fast_rgba_progressive(
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

pub fn execute_parallel_image_processing(
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

pub fn create_zip_response(
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

pub fn finalize_webp_buffer(
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
