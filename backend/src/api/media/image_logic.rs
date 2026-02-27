use rayon::prelude::*;
use std::io::{Cursor, Write};
use std::time::Instant;
use zip::write::FileOptions;

use crate::api::media::image_tasks;
use crate::api::utils::{PROCESSED_IMAGE_WIDTH, WEBP_QUALITY};
use crate::models::{ExifMetadata, MetadataResponse};
use crate::services::media;

// --- SYNC LOGIC ---

pub fn process_image_full_sync(
    data: Vec<u8>,
    original_filename: Option<String>,
    is_optimized_frontend: bool,
    frontend_metadata: Option<ExifMetadata>,
) -> Result<Vec<u8>, String> {
    let decode_start = Instant::now();
    let data_size = data.len();

    let (img, format) = image_tasks::decode_image(&data)?;

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
    let (metadata, tiny_bytes, large_bytes) = image_tasks::execute_parallel_image_processing(
        &src_rgba,
        src_w,
        src_h,
        &data,
        original_filename.as_deref(),
        frontend_metadata,
        is_optimized_frontend,
    )?;
    let parallel_time = parallel_start.elapsed();

    let webp_buffer_vec = image_tasks::finalize_webp_buffer(
        &data,
        large_bytes,
        &metadata,
        is_optimized_frontend,
        src_w,
    )?;

    let zip_start = Instant::now();
    let zip_bytes = image_tasks::create_zip_response(&webp_buffer_vec, &tiny_bytes, &metadata)?;
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
    let (img, _format) = image_tasks::decode_image(&data)?;

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
    let (img, _format) = image_tasks::decode_image(&data)?;

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
            zip.start_file(filename, options.clone())
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
    let (img, _format) = image_tasks::decode_image(&data)?;
    media::perform_metadata_extraction(&img, &data, original_filename.as_deref())
}
