/* backend/src/api/media/image_logic.rs */

use rayon::prelude::*;
use std::io::{Cursor, Write};
use std::time::Instant;
use zip::write::FileOptions;

use crate::api::utils::{PROCESSED_IMAGE_WIDTH, WEBP_QUALITY};
use crate::models::MetadataResponse;
use crate::services::media;

pub fn process_image_full_sync(
    data: Vec<u8>,
    original_filename: Option<String>,
    is_optimized_frontend: bool,
    frontend_metadata: Option<crate::models::ExifMetadata>,
) -> Result<Vec<u8>, String> {
    let decode_start = Instant::now();
    let data_size = data.len();

    // 1. Guess format and validate
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

    tracing::info!(
        module = "Processor",
        format = ?format,
        size = data_size,
        "IMAGE_FORMAT_IDENTIFIED"
    );

    // 2. Decode Image
    let img = reader
        .decode()
        .map_err(|e| format!("Failed to decode image (size: {} bytes): {}", data_size, e))?;

    let decode_time = decode_start.elapsed().as_millis();
    tracing::info!(
        module = "Processor",
        duration_ms = decode_time,
        "IMAGE_DECODE_COMPLETE"
    );

    // 0. Initial RGBA conversion
    let rgba_start = Instant::now();
    let (src_w, src_h) = (img.width(), img.height());
    let src_rgba = img.to_rgba8();
    let rgba_time = rgba_start.elapsed();

    // PARALLEL EXECUTION: Metadata, large resize, and tiny resize
    let parallel_start = Instant::now();
    let ((metadata_res, tiny_res), large_res) = rayon::join(
        || {
            rayon::join(
                // 1. Metadata Extraction
                || -> Result<crate::models::MetadataResponse, String> {
                    let mut meta = media::perform_metadata_extraction_rgba(
                        &src_rgba,
                        src_w,
                        src_h,
                        &data,
                        original_filename.as_deref(),
                    )?;

                    // IF frontend provided EXIF, we override it (because Canvas stripped it)
                    if let Some(front_exif) = frontend_metadata {
                        meta.exif = front_exif;
                        // Suggested name might be better with correct EXIF
                        meta.suggested_name =
                            original_filename.as_deref().map(media::get_suggested_name);
                    }

                    if is_optimized_frontend {
                        meta.is_optimized = true;
                    }

                    Ok(meta)
                },
                // 3. Tiny Preview
                || -> Result<Vec<u8>, String> {
                    let tiny_rgba = media::resize_fast_rgba(&src_rgba, src_w, src_h, 512, 512)
                        .map_err(|e| format!("Tiny resize failed: {}", e))?;
                    let tiny_img = image::RgbaImage::from_raw(512, 512, tiny_rgba)
                        .ok_or_else(|| "Failed to create tiny image buffer".to_string())
                        .map_err(|e| e.to_string())?;
                    media::encode_webp(&image::DynamicImage::ImageRgba8(tiny_img), 60.0)
                },
            )
        },
        // 2. Image Optimization (4K WebP) - Bypass if already optimized
        || -> Result<Vec<u8>, String> {
            if is_optimized_frontend && src_w == PROCESSED_IMAGE_WIDTH {
                tracing::info!(
                    module = "Processor",
                    "BYPASSING_4K_RESIZE_FRONTEND_OPTIMIZED"
                );
                Ok(data.clone()) // Bypass redundant re-encoding
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
                .ok_or_else(|| "Failed to create image buffer".to_string())
                .map_err(|e| e.to_string())?;

                media::encode_webp(&image::DynamicImage::ImageRgba8(img), WEBP_QUALITY)
            }
        },
    );
    let parallel_time = parallel_start.elapsed();

    let metadata = metadata_res?;
    let tiny_bytes = tiny_res?;
    let large_bytes = large_res?;

    let webp_buffer_vec = if is_optimized_frontend && src_w == PROCESSED_IMAGE_WIDTH {
        tracing::info!(module = "Processor", "IMAGE_ALREADY_OPTIMIZED_BY_FRONTEND");
        media::inject_remx_chunk(large_bytes, &metadata)?
    } else if metadata.is_optimized && src_w == PROCESSED_IMAGE_WIDTH {
        tracing::info!(module = "Processor", "IMAGE_ALREADY_OPTIMIZED_BY_REMX");
        data.clone()
    } else {
        media::inject_remx_chunk(large_bytes, &metadata)?
    };

    let webp_buffer = Cursor::new(webp_buffer_vec);
    let tiny_buffer = Cursor::new(tiny_bytes);

    // 3. Package as ZIP
    let zip_start = Instant::now();
    let mut zip_buffer = Cursor::new(Vec::new());
    {
        let mut zip = zip::ZipWriter::new(&mut zip_buffer);
        let options = FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored)
            .unix_permissions(0o755);

        zip.start_file("preview.webp", options)
            .map_err(|e| e.to_string())?;
        zip.write_all(webp_buffer.get_ref())
            .map_err(|e| e.to_string())?;

        zip.start_file("tiny.webp", options)
            .map_err(|e| e.to_string())?;
        zip.write_all(tiny_buffer.get_ref())
            .map_err(|e| e.to_string())?;

        zip.start_file("metadata.json", options)
            .map_err(|e| e.to_string())?;
        let meta_json = serde_json::to_string(&metadata).map_err(|e| e.to_string())?;
        zip.write_all(meta_json.as_bytes())
            .map_err(|e| e.to_string())?;

        zip.finish().map_err(|e| e.to_string())?;
    }
    let zip_time = zip_start.elapsed();

    tracing::info!(
        "Backend Processing Timings: Decode: {:?}, RGBA: {:?}, Parallel: {:?}, Zip: {:?}",
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

    let duration = start.elapsed().as_millis();
    tracing::info!(
        module = "Optimizer",
        format = ?format,
        duration_ms = duration,
        "IMAGE_DECODE_COMPLETE"
    );

    let resized = media::resize_fast(&img, PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH)
        .map_err(|e| format!("Resize failed: {}", e))?;

    let webp_bytes = media::encode_webp(&resized, WEBP_QUALITY)?;

    Ok(webp_bytes)
}

pub fn resize_image_batch_sync(data: Vec<u8>) -> Result<Vec<u8>, String> {
    let reader = image::ImageReader::new(Cursor::new(data))
        .with_guessed_format()
        .map_err(|e| format!("Failed to guess format: {}", e))?;

    let _format = reader
        .format()
        .ok_or_else(|| "Unsupported or invalid image format.".to_string())?;

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

    let _format = reader
        .format()
        .ok_or_else(|| "Unsupported or invalid image format.".to_string())?;

    let img = reader
        .decode()
        .map_err(|e| format!("Failed to decode: {}", e))?;

    media::perform_metadata_extraction(&img, &data, original_filename.as_deref())
}
