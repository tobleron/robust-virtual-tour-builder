use actix_multipart::Multipart;
use actix_web::{web, HttpResponse};
use futures_util::TryStreamExt as _;
use std::fs;
use std::io::{Write, Cursor};
use std::process::Command;
use std::path::PathBuf;
use uuid::Uuid;
use rayon::prelude::*;
use headless_chrome::{Browser, LaunchOptions};
use std::time::{Duration, Instant};
use zip::write::FileOptions;

use crate::services::media;
use crate::models::{AppError, HistogramData, SimilarityRequest, SimilarityResponse, SimilarityResult, MetadataResponse};
use super::utils::{get_temp_path, get_session_path, sanitize_filename, PROCESSED_IMAGE_WIDTH, WEBP_QUALITY, MAX_UPLOAD_SIZE};

// --- SIMILARITY HELPERS ---

/// Bin a 256-element histogram into fewer bins for faster comparison
fn bin_histogram(hist: &[f32], num_bins: usize) -> Vec<f32> {
    let bin_size = 256.0 / num_bins as f32;
    let mut binned = vec![0.0; num_bins];
    
    for (i, &value) in hist.iter().enumerate().take(256) {
        let bin_idx = ((i as f32) / bin_size) as usize;
        if bin_idx < num_bins {
            binned[bin_idx] += value;
        }
    }
    
    binned
}

/// Calculate histogram intersection (similarity metric)
/// Returns value between 0.0 (no overlap) and 1.0 (identical)
fn histogram_intersection(hist_a: &[f32], hist_b: &[f32]) -> f32 {
    let num_bins = hist_a.len().min(hist_b.len());
    
    let mut intersection = 0.0;
    let mut sum_a = 0.0;
    
    for i in 0..num_bins {
        let val_a = hist_a.get(i).copied().unwrap_or(0.0);
        let val_b = hist_b.get(i).copied().unwrap_or(0.0);
        
        intersection += val_a.min(val_b);
        sum_a += val_a;
    }
    
    if sum_a > 0.0 {
        intersection / sum_a
    } else {
        0.0
    }
}

/// Calculate similarity between two images based on histograms
/// Prefers color histograms if available, falls back to luminance
fn calculate_similarity(
    hist_a: &HistogramData,
    hist_b: &HistogramData,
) -> f32 {
    // Try color histograms first (RGB channels)
    if let (Some(color_a), Some(color_b)) = (&hist_a.color_hist, &hist_b.color_hist) {
        // Bin to 8 bins for faster comparison
        let r_a = bin_histogram(&color_a.r, 8);
        let r_b = bin_histogram(&color_b.r, 8);
        let g_a = bin_histogram(&color_a.g, 8);
        let g_b = bin_histogram(&color_b.g, 8);
        let b_a = bin_histogram(&color_a.b, 8);
        let b_b = bin_histogram(&color_b.b, 8);
        
        let r_sim = histogram_intersection(&r_a, &r_b);
        let g_sim = histogram_intersection(&g_a, &g_b);
        let b_sim = histogram_intersection(&b_a, &b_b);
        
        // Average across channels
        return (r_sim + g_sim + b_sim) / 3.0;
    }
    
    // Fallback to luminance histogram
    if let (Some(luma_a), Some(luma_b)) = (&hist_a.histogram, &hist_b.histogram) {
        let binned_a = bin_histogram(luma_a, 8);
        let binned_b = bin_histogram(luma_b, 8);
        return histogram_intersection(&binned_a, &binned_b);
    }
    
    // No histogram data available
    0.0
}

#[tracing::instrument(skip(req), name = "batch_calculate_similarity")]
pub async fn batch_calculate_similarity(
    req: web::Json<SimilarityRequest>,
) -> Result<HttpResponse, AppError> {
    let start = Instant::now();
    let pair_count = req.pairs.len();
    
    tracing::info!(
        module = "Similarity",
        pair_count = pair_count,
        "SIMILARITY_BATCH_START"
    );
    
    if pair_count == 0 {
        return Ok(HttpResponse::Ok().json(SimilarityResponse {
            results: vec![],
            duration_ms: 0,
        }));
    }
    
    if pair_count > 10000 {
        return Err(AppError::InternalError(
            "Too many pairs (max 10000)".to_string()
        ));
    }
    
    let pairs = req.into_inner().pairs;
    
    // Process in parallel using Rayon
    let results = web::block(move || -> Vec<SimilarityResult> {
        pairs.par_iter()
            .map(|pair| {
                let similarity = calculate_similarity(
                    &pair.histogram_a,
                    &pair.histogram_b,
                );
                
                SimilarityResult {
                    id_a: pair.id_a.clone(),
                    id_b: pair.id_b.clone(),
                    similarity,
                }
            })
            .collect()
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;
    
    let duration = start.elapsed().as_millis();
    
    tracing::info!(
        module = "Similarity",
        pair_count = pair_count,
        duration_ms = duration,
        avg_ms_per_pair = (duration as f64 / pair_count as f64),
        "SIMILARITY_BATCH_COMPLETE"
    );
    
    Ok(HttpResponse::Ok().json(SimilarityResponse {
        results,
        duration_ms: duration,
    }))
}

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
                return Err(AppError::ImageError(
                    format!("Upload exceeds maximum size of {}MB", MAX_UPLOAD_SIZE / (1024 * 1024))
                ));
            }
            data.extend_from_slice(&chunk);
        }
    }

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

    tracing::info!(module = "Processor", duration_ms = total_start.elapsed().as_millis(), "PROCESS_IMAGE_FULL_TIMING");

    match result_zip {
        Ok(zip_bytes) => {
            let duration = total_start.elapsed().as_millis();
            tracing::info!(module = "Processor", duration_ms = duration, "PROCESS_IMAGE_FULL_COMPLETE");
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        },
        Err(e) => Err(AppError::ImageError(e))
    }
}

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
                return Err(AppError::ImageError(
                    format!("Upload exceeds maximum size of {}MB", MAX_UPLOAD_SIZE / (1024 * 1024))
                ));
            }
            data.extend_from_slice(&chunk);
        }
    }

    let result_bytes = web::block(move || -> Result<Vec<u8>, String> {
        let start = Instant::now();
        let img = image::ImageReader::new(Cursor::new(data))
            .with_guessed_format()
            .map_err(|e| format!("Failed to guess format: {}", e))?
            .decode()
            .map_err(|e| format!("Failed to decode image: {}", e))?;
        let duration = start.elapsed().as_millis();
        tracing::info!(module = "Optimizer", duration_ms = duration, "IMAGE_DECODE_COMPLETE");
        
        // Use Lanczos3 for absolute sharpness in editor previews (via fast_image_resize)
        let resized = media::resize_fast(&img, PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH)
             .map_err(|e| format!("Resize failed: {}", e))?;
        
        let webp_bytes = media::encode_webp(&resized, WEBP_QUALITY)?;
        
        Ok(webp_bytes)
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    let duration = start.elapsed().as_millis();
    match result_bytes {
        Ok(bytes) => {
            tracing::info!(module = "Optimizer", duration_ms = duration, "OPTIMIZE_IMAGE_COMPLETE");
            Ok(HttpResponse::Ok()
                .content_type("image/webp")
                .body(bytes))
        },
        Err(e) => {
            tracing::error!(module = "Optimizer", duration_ms = duration, error = %e, "OPTIMIZE_IMAGE_FAILED");
            Err(AppError::ImageError(e))
        },
    }
}

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
                return Err(AppError::ImageError(
                    format!("Upload exceeds maximum size of {}MB", MAX_UPLOAD_SIZE / (1024 * 1024))
                ));
            }
            data.extend_from_slice(&chunk);
        }
    }

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

            let results: Vec<Result<(String, Vec<u8>), String>> = targets.par_iter()
                .map(|(filename, width)| {
                    let resized = media::resize_fast(&img, *width, *width)
                        .map_err(|e| format!("Resize failed: {}", e))?;
                    
                    let webp_bytes = media::encode_webp(&resized, WEBP_QUALITY)?;
                    
                    Ok((filename.to_string(), webp_bytes))
                })
                .collect();

            for result in results {
                let (filename, data) = result?;
                zip.start_file(filename, options).map_err(|e| e.to_string())?;
                zip.write_all(&data).map_err(|e| e.to_string())?;
            }

            zip.finish().map_err(|e| e.to_string())?;
        }
        
        Ok(zip_buffer.into_inner())
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    let duration = start.elapsed().as_millis();
    match result_zip {
        Ok(zip_bytes) => {
            tracing::info!(module = "Resizer", duration_ms = duration, "RESIZE_BATCH_COMPLETE");
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        },
        Err(e) => {
            tracing::error!(module = "Resizer", duration_ms = duration, error = %e, "RESIZE_BATCH_FAILED");
            Err(AppError::ImageError(e))
        }
    }
}

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
                return Err(AppError::ImageError(
                    format!("Upload exceeds maximum size of {}MB", MAX_UPLOAD_SIZE / (1024 * 1024))
                ));
            }
            data.extend_from_slice(&chunk);
        }
    }

    let start = Instant::now();
    let result = web::block(move || -> Result<MetadataResponse, String> {
        let img = image::ImageReader::new(Cursor::new(&data))
            .with_guessed_format()
            .map_err(|e| format!("Failed to guess format: {}", e))?
            .decode()
            .map_err(|e| format!("Failed to decode: {}", e))?;

        media::perform_metadata_extraction(&img, &data, original_filename.as_deref())
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    let duration = start.elapsed().as_millis();
    match result {
        Ok(data) => {
            tracing::info!(module = "Extractor", duration_ms = duration, "EXTRACT_METADATA_COMPLETE");
            Ok(HttpResponse::Ok().json(data))
        },
        Err(e) => {
            tracing::error!(module = "Extractor", duration_ms = duration, error = %e, "EXTRACT_METADATA_FAILED");
            Err(AppError::ImageError(e))
        },
    }
}

#[tracing::instrument(skip(payload), name = "transcode_video")]
pub async fn transcode_video(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    let input_path = get_temp_path("webm");
    
    let mut total_size = 0;

    // Save upload to disk
    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field.content_disposition().ok_or_else(|| AppError::InternalError("Missing content disposition".to_string()))?;
        
        // Only process the 'file' field as video
        if content_disposition.get_name() == Some("file") {
            let mut f = fs::File::create(&input_path)?;
            while let Some(chunk) = field.try_next().await? {
                total_size += chunk.len();
                if total_size > MAX_UPLOAD_SIZE {
                    let _ = fs::remove_file(&input_path);
                    return Err(AppError::ImageError(
                        format!("Video upload exceeds maximum size of {}MB", MAX_UPLOAD_SIZE / (1024 * 1024))
                    ));
                }
                f.write_all(&chunk)?;
            }
        }
    }

    let output_path = get_temp_path("mp4");
    let input_str = input_path.to_str()
        .ok_or(AppError::InternalError("Invalid input path encoding".into()))?
        .to_string();
    let output_str = output_path.to_str()
        .ok_or(AppError::InternalError("Invalid output path encoding".into()))?
        .to_string();

    tracing::info!(module = "VideoEncoder", input = %input_str, output = %output_str, "TRANSCODE_START");

    let result = web::block(move || -> Result<PathBuf, String> {
        let local_ffmpeg = PathBuf::from("./bin/ffmpeg");
        let ffmpeg_cmd = if local_ffmpeg.exists() {
            local_ffmpeg.to_str()
                .ok_or("Invalid ffmpeg path encoding".to_string())?
                .to_string()
            
        } else {
            "ffmpeg".to_string()
        };

        let output = Command::new(&ffmpeg_cmd)
            .args(&[
                "-y",
                "-i", &input_str,
                "-c:v", "libx264",
                "-preset", "medium",
                "-crf", "23",
                "-c:a", "aac",
                &output_str
            ])
            .output()
            .map_err(|e| format!("Failed to spawn ffmpeg (path: {}): {}", ffmpeg_cmd, e))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(format!("FFmpeg exited with code {}: {}", 
                output.status.code().unwrap_or(-1), 
                stderr
            ));
        }

        let _ = fs::remove_file(&input_str);
        Ok::<PathBuf, String>(PathBuf::from(output_str))
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    match result {
        Ok(path) => {
            tracing::info!(module = "VideoEncoder", "TRANSCODE_COMPLETE");
            let file_bytes = fs::read(&path)?;
            let _ = fs::remove_file(path);
            Ok(HttpResponse::Ok()
                .content_type("video/mp4")
                .body(file_bytes))
        },
        Err(e) => {
            let _ = fs::remove_file(&input_path);
            Err(AppError::FFmpegError(e))
        },
    }
}

#[tracing::instrument(skip(payload), name = "generate_teaser")]
pub async fn generate_teaser(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    // 1. Create a transient session ID for this generation request
    let session_id = Uuid::new_v4().to_string();
    let session_path = get_session_path(&session_id);
    fs::create_dir_all(&session_path).map_err(AppError::IoError)?;
    
    tracing::info!(module = "TeaserGenerator", session_id = %session_id, "TEASER_GENERATION_START");

    let mut project_data_value: Option<serde_json::Value> = None;
    let mut width = 1920;
    let mut height = 1080;
    let duration_limit = 120; // Default limit

    // 2. Parse Multipart
    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field.content_disposition()
            .cloned()
            .ok_or(AppError::InternalError("Missing content disposition".into()))?;
        let name = content_disposition.get_name().unwrap_or("").to_string();

        if name == "project_data" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? { bytes.extend_from_slice(&chunk); }
            project_data_value = serde_json::from_slice(&bytes).ok();
        } else if name == "width" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? { bytes.extend_from_slice(&chunk); }
            if let Ok(s) = String::from_utf8(bytes) {
                if let Ok(val) = s.parse::<u32>() { width = val; }
            }
        } else if name == "height" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? { bytes.extend_from_slice(&chunk); }
             if let Ok(s) = String::from_utf8(bytes) {
                if let Ok(val) = s.parse::<u32>() { height = val; }
            }
        } else if name == "files" {
            let filename = content_disposition.get_filename().map(|f| f.to_string()).unwrap_or_else(|| format!("img_{}.webp", Uuid::new_v4()));
            let sanitized = sanitize_filename(&filename).unwrap_or(filename);
            let file_path = session_path.join(&sanitized);
            let mut f = fs::File::create(file_path).map_err(AppError::IoError)?;
             while let Some(chunk) = field.try_next().await? { f.write_all(&chunk).map_err(AppError::IoError)?; }
        }
    }

    let project_data = project_data_value.ok_or_else(|| AppError::InternalError("Missing project_data JSON".into()))?;

    let output_path = get_temp_path("mp4");
    let output_str = output_path.to_str()
        .ok_or(AppError::InternalError("Invalid output path encoding".into()))?
        .to_string();
    
    // session_id must be moved into the closure
    let session_id_clone = session_id.clone();
    let _session_path_clone = session_path.clone();

    // Run blocking browser automation
    let result = web::block(move || -> Result<(), String> {
        // 1. Launch Browser
        let browser = Browser::new(LaunchOptions {
            headless: true,
            window_size: Some((width, height)),
            args: vec![
                std::ffi::OsStr::new("--force-device-scale-factor=1.0"), 
                std::ffi::OsStr::new("--enable-webgl"), 
                std::ffi::OsStr::new("--ignore-gpu-blacklist")
            ], 
            ..LaunchOptions::default()
        }).map_err(|e| format!("Failed to launch browser: {}", e))?;

        let tab = browser.new_tab().map_err(|e| format!("Failed to create tab: {}", e))?;

        // 2. Navigate to Frontend
        // Ensure this URL is reachable from the backend process
        // Note: Make sure the frontend is running!
        tab.navigate_to("http://localhost:8080").map_err(|e| format!("Nav failed: {}", e))?;
        tab.wait_until_navigated().map_err(|e| format!("Nav timeout: {}", e))?;

        // 3. Inject Project Data & Loader Script
        let json_str = serde_json::to_string(&project_data)
            .map_err(|e| format!("Failed to serialize project data: {}", e))?;
        // Script: Fetch images from session, create blobs, then load project
        let script = format!(r#"
            (async function() {{
                try {{
                    // Data from backend
                    const data = {};
                    const sessionId = "{}";
                    
                    console.log("Headless: Starting resource hydration for session " + sessionId);

                    if (!window.store) {{
                        console.error("Store not found!");
                        window.HEADLESS_ERROR = "Store not found";
                        return;
                    }}

                    // Hydrate scenes with Blobs
                    // We need to mutate the scene objects in 'data.scenes' to add 'file' property (Blob)
                    // But JSON parsing makes them plain objects.
                    // We must fetch blobs.
                    
                    if (data.scenes && Array::isArray(data.scenes)) {{
                        await Promise.all(data.scenes.map(async (scene) => {{
                            try {{
                                // Filename in project match filename stored
                                const url = `/api/session/${{sessionId}}/${{encodeURIComponent(scene.name)}}`;
                                const resp = await fetch(url);
                                if (!resp.ok) throw new Error("Fetch failed: " + resp.status);
                                const blob = await resp.blob();
                                // Create File object
                                // Note: Pannellum needs .file property on scene object if it uses it.
                                // Or store.loadProject handles it? store.loadProject DOES NOT handle fetching.
                                // So we attach it here.
                                scene.file = new File([blob], scene.name, {{ type: 'image/webp' }});
                                scene.originalFile = scene.file;
                                scene.tinyFile = scene.file; 
                            }} catch (e) {{
                                console.error("Failed to hydrate scene: " + scene.name, e);
                            }}
                        }}));
                    }}

                    // Load Project
                    await Promise.resolve(window.store.loadProject(data)); // This sets store.state.scenes = data.scenes (with blobs!)
                    
                    console.log("Project loaded in headless mode");
                    
                    // Allow UI to settle (Pannellum init)
                    setTimeout(() => {{ window.HEADLESS_READY = true; }}, 2000);

                }} catch (e) {{
                    console.error("Headless initialization failed:", e);
                    window.HEADLESS_ERROR = e.toString();
                }}
            }})();
        "#, json_str, session_id_clone);
        
        tab.evaluate(&script, false).map_err(|e| format!("Injection failed: {}", e))?;

        // Wait for ready
        let start_wait = std::time::Instant::now();
        loop {
            if std::time::Instant::now() - start_wait > Duration::from_secs(60) { // Increased timeout for fetch
                return Err("Timeout waiting for project load".to_string());
            }
            
            // Check success
            let val = tab.evaluate("window.HEADLESS_READY", false);
            if let Ok(v) = val {
                if v.value.and_then(|x| x.as_bool()).unwrap_or(false) {
                    break;
                }
            }
            
            // Check error
            let err_val = tab.evaluate("window.HEADLESS_ERROR", false);
             if let Ok(v) = err_val {
                if let Some(msg) = v.value.and_then(|x| x.as_str().map(|s| s.to_string())) {
                     return Err(format!("Headless Client Error: {}", msg));
                }
            }
            
            std::thread::sleep(Duration::from_millis(500));
        }

        // 4. Start FFmpeg Process
        let local_ffmpeg = PathBuf::from("./bin/ffmpeg");
        let ffmpeg_cmd = if local_ffmpeg.exists() {
            local_ffmpeg.to_str()
                .ok_or("Invalid ffmpeg path encoding".to_string())?
                .to_string()
        } else {
            "ffmpeg".to_string()
        };

        let mut child = Command::new(&ffmpeg_cmd)
            .args(&[
                "-y",
                "-f", "image2pipe",
                "-vcodec", "png",
                "-r", "30",
                "-i", "-",
                "-c:v", "libx264",
                "-preset", "ultrafast",
                "-pix_fmt", "yuv420p",
                "-movflags", "+faststart",
                &output_str
            ])
            .stdin(std::process::Stdio::piped())
            .stderr(std::process::Stdio::inherit()) // Log ffmpeg error to stderr
            .spawn()
            .map_err(|e| format!("Failed to spawn ffmpeg: {}", e))?;

        let mut stdin = child.stdin.take().ok_or("Failed to open ffmpeg stdin")?;

        // 5. Trigger Cinematic Teaser via Frontend (MP4 mode, autoPilot)
        tab.evaluate("window.startCinematicTeaser(true, 'mp4', true)", false)
            .map_err(|e| format!("Failed to start teaser: {}", e))?;

        // 6. Capture Loop
        let start_sim = std::time::Instant::now();
        let max_dur = Duration::from_secs(duration_limit);
        
        loop {
            if std::time::Instant::now() - start_sim > max_dur {
                break;
            }

            // Check if simulation finished
            let active = tab.evaluate("window.isAutoPilotActive()", false);
            if let Ok(v) = active {
                if !v.value.and_then(|x| x.as_bool()).unwrap_or(true) {
                    break;
                }
            }

            // Capture Screenshot
            let png_data = tab.capture_screenshot(headless_chrome::protocol::cdp::Page::CaptureScreenshotFormatOption::Png, None, None, true)
                .map_err(|e| format!("Screenshot failed: {}", e))?;

            if let Err(_e) = stdin.write_all(&png_data) {
                // EPIPE means ffmpeg closed (maybe finished or errored)
                break; 
            }
            
            std::thread::sleep(Duration::from_millis(10));
        }

        drop(stdin); // Close stdin to signal EOF
        child.wait().map_err(|e| format!("FFmpeg failed: {}", e))?;

        Ok(())
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    // Clean up session files
    let _ = fs::remove_dir_all(&session_path);

    match result {
        Ok(_) => {
            tracing::info!(module = "TeaserGenerator", "TEASER_GENERATION_COMPLETE");
            let file_bytes = fs::read(&output_path).map_err(AppError::IoError)?;
            let _ = fs::remove_file(output_path); // Cleanup result file
            Ok(HttpResponse::Ok()
                .content_type("video/mp4")
                .body(file_bytes))
        },
        Err(e) => {
            let _ = fs::remove_file(&output_path); // Cleanup on error
            Err(AppError::InternalError(e))
        },
    }
}

// Handler for serving session files
pub async fn serve_session_file(path: web::Path<(String, String)>) -> Result<HttpResponse, AppError> {
    let (session_id, filename) = path.into_inner();
    
    // Security Check: Sanitize
    let safe_filename = sanitize_filename(&filename).map_err(|_| AppError::InternalError("Invalid filename".into()))?;
    
    let session_path = get_session_path(&session_id);
    // Images are inside "images" subdir based on our save structure?
    // Wait, import_project puts them directly in session dir?
    // In import_project: `outpath` is session_dir.join(path).
    // In generate_teaser: `file_path = session_path.join(&sanitized)`.
    // So for import/teaser hydration, files are at root of session_path.
    // The previous code in handlers.rs had logic:
    // `let file_path = session_path.join("images").join(&safe_filename);`
    // `if !file_path.exists() { let root_path = session_path.join(&safe_filename); ... }`
    // So it checks images/ then root.
    
    let file_path = session_path.join("images").join(&safe_filename);

    if !file_path.exists() {
        // Try root
        let root_path = session_path.join(&safe_filename);
        if root_path.exists() {
             let data = fs::read(root_path).map_err(AppError::IoError)?;
             let mime = mime_guess::from_path(&safe_filename).first_or_octet_stream();
             return Ok(HttpResponse::Ok().content_type(mime.as_ref()).body(data));
        }
        return Ok(HttpResponse::NotFound().body("File not found"));
    }
    
    let data = fs::read(file_path).map_err(AppError::IoError)?;
    let mime = mime_guess::from_path(&safe_filename).first_or_octet_stream();
    
    Ok(HttpResponse::Ok()
        .content_type(mime.as_ref())
        .body(data))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{QualityAnalysis, ColorHist, QualityStats};

    #[test]
    fn test_histogram_binning() {
        let hist = vec![1.0; 256];
        let binned = bin_histogram(&hist, 8);
        assert_eq!(binned.len(), 8);
        assert_eq!(binned[0], 32.0); // 256/8 = 32 bins collapsed
    }
    
    #[test]
    fn test_histogram_intersection_identical() {
        let hist_a = vec![1.0, 2.0, 3.0];
        let hist_b = vec![1.0, 2.0, 3.0];
        let result = histogram_intersection(&hist_a, &hist_b);
        assert!((result - 1.0).abs() < 0.001); // Should be 1.0
    }
    
    #[test]
    fn test_histogram_intersection_different() {
        let hist_a = vec![1.0, 0.0, 0.0];
        let hist_b = vec![0.0, 1.0, 0.0];
        let result = histogram_intersection(&hist_a, &hist_b);
        assert_eq!(result, 0.0); // No overlap
    }
    
    #[test]
    fn test_quality_analysis_serialization() {
       let analysis = QualityAnalysis {
            score: 9.0,
            histogram: vec![0; 256],
            color_hist: ColorHist { r: vec![], g: vec![], b: vec![] },
            stats: QualityStats { avg_luminance: 100, black_clipping: 0.0, white_clipping: 0.0, sharpness_variance: 50 },
            is_blurry: false, is_soft: false, is_severely_dark: false, is_dim: false,
            has_black_clipping: false, has_white_clipping: false,
            issues: 0, warnings: 0, analysis: None
        };
        // Just checking it compiles
    }
}
