use actix_multipart::Multipart;
use actix_web::{web, HttpResponse};
use futures_util::TryStreamExt as _;
use std::fs;
use std::io::{Write, Cursor};
use std::process::Command;
use std::path::PathBuf;
use uuid::Uuid;
use serde::Serialize;

use zip::write::FileOptions;
use std::collections::{HashMap, HashSet};
use rayon::prelude::*;
use headless_chrome::{Browser, LaunchOptions};
use std::time::{Duration, Instant};
use crate::services::media;
use crate::services::project;
use crate::models::*;
// flate2 and SystemTime removed as compression is not yet implemented


// Configs
const PROCESSED_IMAGE_WIDTH: u32 = 4096;
const WEBP_QUALITY: f32 = 92.0;
const TEMP_DIR: &str = "/tmp/remax_backend";
const SESSIONS_DIR: &str = "/tmp/remax_sessions";
const MAX_UPLOAD_SIZE: usize = 2048 * 1024 * 1024; // 2GB limit (increased for full projects)

// Log Rotation Configs
const MAX_LOG_SIZE: u64 = 10 * 1024 * 1024; // 10 MB
const MAX_LOG_FILES: usize = 5;
const LOG_RETENTION_DAYS: u64 = 7;

// --- Error Handling ---



// --- Helpers ---

fn get_temp_path(extension: &str) -> PathBuf {
    let mut path = PathBuf::from(TEMP_DIR);
    if !path.exists() {
        fs::create_dir_all(&path).unwrap_or_default();
    }
    path.push(format!("{}.{}", Uuid::new_v4(), extension));
    path
}

fn get_session_path(session_id: &str) -> PathBuf {
    let mut path = PathBuf::from(SESSIONS_DIR);
    path.push(session_id);
    path
}

/// Sanitize filename to prevent path traversal attacks
/// Returns only the filename component, rejecting any directory traversal attempts
fn sanitize_filename(fname: &str) -> Result<String, String> {
    use std::path::{Path, Component};
    
    // Reject empty filenames
    if fname.is_empty() {
        return Err("Empty filename not allowed".to_string());
    }
    
    let path = Path::new(fname);
    
    // Reject absolute paths
    if path.is_absolute() {
        return Err("Absolute paths not allowed".to_string());
    }
    
    // Check for parent directory components (..)
    for component in path.components() {
        match component {
            Component::ParentDir => {
                return Err("Parent directory traversal not allowed".to_string());
            }
            Component::RootDir => {
                return Err("Root directory access not allowed".to_string());
            }
            _ => {}
        }
    }
    
    // Extract only the filename (no directory structure)
    path.file_name()
        .and_then(|s| s.to_str())
        .map(|s| {
            // Additional sanitization: remove any remaining dangerous characters
            s.replace(['/', '\\', '\0'], "_")
        })
        .ok_or_else(|| "Invalid filename".to_string())
}

// --- Metadata Structs ---



// --- GEOCODING SYSTEM ---



lazy_static::lazy_static! {
    static ref GEOCODE_CACHE: std::sync::Arc<tokio::sync::RwLock<HashMap<GeocodeKey, CachedGeocode>>> = 
        std::sync::Arc::new(tokio::sync::RwLock::new(HashMap::new()));
    
    static ref CACHE_STATS: std::sync::Arc<tokio::sync::RwLock<CacheStats>> = 
        std::sync::Arc::new(tokio::sync::RwLock::new(CacheStats::default()));
}



const CACHE_FILE_PATH: &str = "../logs/geocode_cache.json";
const MAX_CACHE_SIZE: usize = 5000;
const CACHE_SAVE_INTERVAL_MS: u64 = 5000; // 5 seconds

fn round_coords(lat: f64, lon: f64) -> GeocodeKey {
    // Round to 4 decimal places (~11 meter precision)
    let lat_rounded = (lat * 10000.0).round() as i32;
    let lon_rounded = (lon * 10000.0).round() as i32;
    (lat_rounded, lon_rounded)
}

async fn call_osm_nominatim(lat: f64, lon: f64) -> Result<String, String> {
    let url = format!(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat={}&lon={}&zoom=18&addressdetails=1",
        lat, lon
    );
    
    let client = reqwest::Client::builder()
        .user_agent("RobustVirtualTourBuilder/1.0")
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| format!("Failed to create HTTP client: {}", e))?;
    
    let response = client.get(&url)
        .send()
        .await
        .map_err(|e| format!("Geocoding request failed: {}", e))?;
    
    if !response.status().is_success() {
        return Err(format!("OSM API returned status: {}", response.status()));
    }
    
    let json: serde_json::Value = response.json()
        .await
        .map_err(|e| format!("Failed to parse OSM response: {}", e))?;
    
    // Check for error in response
    if let Some(error) = json.get("error") {
        return Err(format!("OSM API error: {}", error));
    }
    
    // Extract and format address
    if let Some(address_obj) = json.get("address") {
        let mut parts = Vec::new();
        
        // Extract address components
        if let Some(road) = address_obj.get("road").and_then(|v| v.as_str()) {
            if !road.is_empty() {
                parts.push(road.to_string());
            }
        }
        
        // Suburb/neighborhood
        let suburb = address_obj.get("suburb")
            .or_else(|| address_obj.get("neighbourhood"))
            .and_then(|v| v.as_str());
        if let Some(s) = suburb {
            if !s.is_empty() {
                parts.push(s.to_string());
            }
        }
        
        // City/town/village
        let city = address_obj.get("city")
            .or_else(|| address_obj.get("town"))
            .or_else(|| address_obj.get("village"))
            .and_then(|v| v.as_str());
        if let Some(c) = city {
            if !c.is_empty() {
                parts.push(c.to_string());
            }
        }
        
        // State/province
        let state = address_obj.get("state")
            .or_else(|| address_obj.get("province"))
            .and_then(|v| v.as_str());
        if let Some(s) = state {
            if !s.is_empty() {
                parts.push(s.to_string());
            }
        }
        
        // Country
        if let Some(country) = address_obj.get("country").and_then(|v| v.as_str()) {
            if !country.is_empty() {
                parts.push(country.to_string());
            }
        }
        
        if !parts.is_empty() {
            return Ok(parts.join(", "));
        }
    }
    
    // Fallback to display_name
    json.get("display_name")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .ok_or_else(|| "No address found in response".to_string())
}

async fn save_cache_to_disk() -> std::io::Result<()> {
    let cache = GEOCODE_CACHE.read().await;
    let mut stats = CACHE_STATS.write().await;
    
    let current_time = get_current_timestamp();
    
    let data = serde_json::json!({
        "cache": *cache,
        "stats": *stats,
        "saved_at": current_time
    });
    
    let json = serde_json::to_string_pretty(&data)?;
    tokio::fs::write(CACHE_FILE_PATH, json).await?;
    
    stats.last_save = Some(current_time);
    
    tracing::info!(
        module = "Geocoder",
        entries = cache.len(),
        "CACHE_SAVED_TO_DISK"
    );
    
    Ok(())
}

pub async fn load_cache_from_disk() -> std::io::Result<()> {
    match tokio::fs::read_to_string(CACHE_FILE_PATH).await {
        Ok(contents) => {
            let data: serde_json::Value = serde_json::from_str(&contents)?;
            
            if let Some(cache_obj) = data.get("cache") {
                let loaded_cache: HashMap<GeocodeKey, CachedGeocode> = 
                    serde_json::from_value(cache_obj.clone())?;
                
                let mut cache = GEOCODE_CACHE.write().await;
                *cache = loaded_cache;
                
                tracing::info!(
                    module = "Geocoder",
                    entries = cache.len(),
                    "CACHE_LOADED_FROM_DISK"
                );
            }
            
            if let Some(stats_obj) = data.get("stats") {
                let loaded_stats: CacheStats = 
                    serde_json::from_value(stats_obj.clone())?;
                
                let mut stats = CACHE_STATS.write().await;
                *stats = loaded_stats;
            }
            
            Ok(())
        },
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
            tracing::info!(module = "Geocoder", "No cache file found - starting fresh");
            Ok(())
        },
        Err(e) => {
            tracing::warn!(module = "Geocoder", error = %e, "Failed to load cache");
            Ok(()) // Non-fatal - start with empty cache
        }
    }
}

fn get_current_timestamp() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::SystemTime::UNIX_EPOCH)
        .unwrap()
        .as_secs()
}

async fn evict_lru_entry() {
    let mut cache = GEOCODE_CACHE.write().await;
    
    // Find oldest entry by last_accessed
    if let Some((&key, _)) = cache.iter()
        .min_by_key(|(_, v)| v.last_accessed) {
        
        cache.remove(&key);
        
        let mut stats = CACHE_STATS.write().await;
        stats.evictions += 1;
        
        tracing::debug!(module = "Geocoder", "LRU_EVICTION");
    }
}


// --- SIMILARITY SYSTEM ---



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


// --- Internal Processing Logic (Extracted for reuse) ---


// FILENAME_REGEX and get_suggested_name moved to services::media

// --- VALIDATION SYSTEM ---



// validate_and_clean_project moved to services::project

// Optimized helpers moved to services::media

// Metadata extraction moved to services::media

// --- Handlers ---

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
        
        // Optimize Image also needs to inject metadata maybe?
        // User said "prevent re-optimization".
        // But `optimize_image` in this handler seems to just resize.
        // It doesn't seem to get `QualityAnalysis` first unless we call extract.
        // But `process_image_full` calls both.
        // Let's assume `optimize_image` is strictly for the tool's internal use or similar.
        // However, if we want to be consistent, we should inject here too if we had the analysis.
        // But we don't calculate analysis in `optimize_image`.
        // So we leave it as is, or we verify if `optimize_image` should also gain analysis capabilities.
        // Given the prompt "when an image is uploaded ... processed by the tool", it likely refers to `process_image_full` which does the heavy lifting.
        
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

#[tracing::instrument(skip(payload), name = "create_tour_package")]
pub async fn create_tour_package(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "Exporter", "EXPORT_START");
    let start = Instant::now();
    let mut fields: HashMap<String, String> = HashMap::new();
    let mut image_files: Vec<(String, Vec<u8>)> = Vec::new();

    let mut current_total_size = 0;

    // 1. Parse Multipart into Memory
    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field.content_disposition()
            .cloned()
            .ok_or(AppError::InternalError("Missing content disposition".into()))?;
        let name = content_disposition.get_name().unwrap_or("unknown").to_string();
        let filename = content_disposition.get_filename().map(|f| f.to_string());

        let mut data = Vec::new();
        while let Some(chunk) = field.try_next().await? {
            current_total_size += chunk.len();
            if current_total_size > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError(
                    format!("Total upload size exceeds maximum of {}MB", MAX_UPLOAD_SIZE / (1024 * 1024))
                ));
            }
            data.extend_from_slice(&chunk);
        }

        if let Some(fname) = filename {
            // Use secure sanitization to prevent path traversal
            let sanitized_name = sanitize_filename(&fname)
                .map_err(|e| AppError::InternalError(format!("Invalid filename '{}': {}", fname, e)))?;
            image_files.push((sanitized_name, data));
        } else {
            let value_str = String::from_utf8_lossy(&data).to_string();
            fields.insert(name, value_str);
        }
    }

    let result_zip = web::block(move || {
        project::create_tour_package(image_files, fields)
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    let duration = start.elapsed().as_millis();
    match result_zip {
        Ok(zip_bytes) => {
            tracing::info!(module = "Exporter", duration_ms = duration, size = zip_bytes.len(), "EXPORT_COMPLETE");
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        },
        Err(e) => {
            tracing::error!(module = "Exporter", duration_ms = duration, error = %e, "EXPORT_FAILED");
            Err(AppError::ZipError(e))
        },
    }
}




#[tracing::instrument(skip(payload), name = "save_project")]
pub async fn save_project(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "ProjectManager", "SAVE_PROJECT_START");
    let start = Instant::now();
    // 1. Prepare Zip Writer
    // We stream directly to a file in TEMP_DIR to avoid memory issues with huge projects
    // let zip_filename = format!("save_{}.zip", Uuid::new_v4()); // Unused
    let zip_path = get_temp_path("zip"); // returns full path with .zip extension
    
    // Create file (This was redundant and causing unused variable warning)
    // let file = fs::File::create(&zip_path).map_err(AppError::IoError)?; 
    
    // We use a block to scope the ZipWriter
    let mut project_json: Option<String> = None;
    let mut temp_images: Vec<(String, PathBuf)> = Vec::new(); // (filename, temp_path)
    
    // 2. Iterate Multipart Stream
    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field.content_disposition()
            .cloned()
            .ok_or(AppError::InternalError("Missing content disposition".into()))?;
        let name = content_disposition.get_name().unwrap_or("unknown").to_string();
        
        if name == "project_data" {
            // Read JSON into memory (it's small)
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            project_json = Some(String::from_utf8_lossy(&bytes).to_string());
        } else if name == "files" {
            // This is an image file. Stream it to a temp file first to keep RAM low.
            let filename = content_disposition.get_filename().map(|f| f.to_string()).unwrap_or_else(|| format!("img_{}.webp", Uuid::new_v4()));
            let sanitized_name = sanitize_filename(&filename).unwrap_or_else(|_| format!("img_{}.webp", Uuid::new_v4()));
            
            let temp_img_path = get_temp_path("tmp");
            let mut f = fs::File::create(&temp_img_path).map_err(AppError::IoError)?;
            
            while let Some(chunk) = field.try_next().await? {
                f.write_all(&chunk).map_err(AppError::IoError)?;
            }
            temp_images.push((sanitized_name, temp_img_path));
        }
    }
    
    // 3. Create ZIP
    // We do this in a blocking thread to avoid blocking async runtime
    let final_zip_path = zip_path.clone();
    let json_content = project_json.ok_or_else(|| AppError::MultipartError(actix_multipart::MultipartError::Incomplete))?;
    
    // Run validation before saving
    let temp_images_for_validation = temp_images.clone();
    let (validated_json, _report) = web::block(move || -> Result<(String, ValidationReport), String> {
        let project_data: serde_json::Value = serde_json::from_str(&json_content)
            .map_err(|e| format!("Invalid project JSON: {}", e))?;
        
        // For save-project, available files are the ones being uploaded
        let mut available_files = HashSet::new();
        for (name, _) in &temp_images_for_validation {
            available_files.insert(name.clone());
        }
        
        let (mut validated_project, report) = project::validate_and_clean_project(project_data, &available_files)?;
        
        // Embed report
        validated_project["validationReport"] = serde_json::to_value(&report)
            .map_err(|e| format!("Failed to serialize report: {}", e))?;
            
        let updated_json = serde_json::to_string_pretty(&validated_project)
            .map_err(|e| e.to_string())?;
            
        Ok((updated_json, report))
    }).await.map_err(|e| AppError::InternalError(e.to_string()))??;

    let zip_creation_result = web::block(move || -> Result<(), std::io::Error> {
        let file = fs::File::create(&final_zip_path)?;
        let mut zip = zip::ZipWriter::new(file);
        let options = FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored) // Already compressed WebPs
            .unix_permissions(0o755);
            
        // Write JSON
        zip.start_file("project.json", options)?;
        zip.write_all(validated_json.as_bytes())?;
        
        // Write Images
        for (filename, path) in temp_images {
            zip.start_file(format!("images/{}", filename), options)?;
            let mut f = fs::File::open(&path)?;
            std::io::copy(&mut f, &mut zip)?;
            
            // Allow OS to clean up temp file (best effort)
            let _ = fs::remove_file(path);
        }
        
        zip.finish()?;
        Ok(())
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;
    
    // 4. Stream Back the ZIP
    let duration = start.elapsed().as_millis();
    match zip_creation_result {
        Ok(_) => {
            let zip_file = fs::File::open(&zip_path).map_err(AppError::IoError)?;
            let metadata = zip_file.metadata().map_err(AppError::IoError)?;
            
            let mut buffer = Vec::with_capacity(metadata.len() as usize);
            let mut reader = std::io::BufReader::new(zip_file);
            std::io::copy(&mut reader, &mut buffer).map_err(AppError::IoError)?;
            
            // Clean up
            let _ = fs::remove_file(&zip_path);

            tracing::info!(module = "ProjectManager", duration_ms = duration, "SAVE_PROJECT_COMPLETE");

            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(buffer))
        },
        Err(e) => {
            let _ = fs::remove_file(&zip_path); // Clean up on error too
            tracing::error!(module = "ProjectManager", duration_ms = duration, error = %e, "SAVE_PROJECT_FAILED");
            Err(e.into())
        }
    }
}

/// Validate a project ZIP without loading it
/// Returns a ValidationReport JSON with warnings and errors
#[tracing::instrument(skip(payload), name = "validate_project")]
pub async fn validate_project(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "Validator", "VALIDATE_PROJECT_START");
    let start = Instant::now();
    let mut zip_data = Vec::new();
    
    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
            zip_data.extend_from_slice(&chunk);
            if zip_data.len() > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError("Project too large".into()));
            }
        }
    }
    
    let report = web::block(move || {
        project::validate_project_zip(zip_data)
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;
    
    let duration = start.elapsed().as_millis();
    match report {
        Ok(validation_report) => {
            tracing::info!(module = "Validator", duration_ms = duration, "VALIDATE_PROJECT_COMPLETE");
            Ok(HttpResponse::Ok().json(validation_report))
        },
        Err(e) => {
            tracing::error!(module = "Validator", duration_ms = duration, error = %e, "VALIDATE_PROJECT_FAILED");
            Err(AppError::InternalError(e))
        },
    }
}

#[tracing::instrument(skip(payload), name = "load_project")]
pub async fn load_project(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "ProjectManager", "LOAD_PROJECT_START");
    let start = Instant::now();
    let mut zip_data = Vec::new();
    
    // 1. Read ZIP Upload into memory
    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
            zip_data.extend_from_slice(&chunk);
            if zip_data.len() > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError("Project too large".into()));
            }
        }
    }

    tracing::info!(module = "ProjectManager", size_bytes = zip_data.len(), "PROJECT_ZIP_RECEIVED");
    
    // 2. Process in blocking thread - create response ZIP with project.json + all images
    let result_zip = web::block(move || {
        project::process_uploaded_project_zip(zip_data)
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;
    
    let duration = start.elapsed().as_millis();
    match result_zip {
        Ok(zip_bytes) => {
            tracing::info!(module = "ProjectManager", duration_ms = duration, "LOAD_PROJECT_COMPLETE");
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        },
        Err(e) => {
            tracing::error!(module = "ProjectManager", duration_ms = duration, error = %e, "LOAD_PROJECT_FAILED");
            Err(e.into())
        },
    }
}

// Handler for serving session files
pub async fn serve_session_file(path: web::Path<(String, String)>) -> Result<HttpResponse, AppError> {
    let (session_id, filename) = path.into_inner();
    
    // Security Check: Sanitize
    let safe_filename = sanitize_filename(&filename).map_err(|_| AppError::InternalError("Invalid filename".into()))?;
    
    let session_path = get_session_path(&session_id);
    // Images are inside "images" subdir based on our save structure
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

async fn rotate_log_file(path: &std::path::Path) -> std::io::Result<()> {
    let stem = path.file_stem()
        .and_then(|s| s.to_str())
        .ok_or_else(|| std::io::Error::new(std::io::ErrorKind::InvalidInput, "Invalid log file stem"))?;
    let ext = path.extension()
        .and_then(|e| e.to_str())
        .unwrap_or("log");
    let dir = path.parent()
        .ok_or_else(|| std::io::Error::new(std::io::ErrorKind::InvalidInput, "Log file has no parent directory"))?;
    
    // Shift existing rotated files
    for i in (1..MAX_LOG_FILES).rev() {
        let old = dir.join(format!("{}.{}.{}", stem, i, ext));
        let new = dir.join(format!("{}.{}.{}", stem, i + 1, ext));
        if let Ok(exists) = tokio::fs::try_exists(&old).await {
            if exists {
                tokio::fs::rename(&old, &new).await?;
            }
        }
    }
    
    // Rotate current file to .1
    let rotated = dir.join(format!("{}.1.{}", stem, ext));
    tokio::fs::rename(path, &rotated).await?;
    
    // Delete oldest if over limit
    let oldest = dir.join(format!("{}.{}.{}", stem, MAX_LOG_FILES, ext));
    if let Ok(exists) = tokio::fs::try_exists(&oldest).await {
        if exists {
            tokio::fs::remove_file(oldest).await?;
        }
    }
    
    Ok(())
}

#[allow(dead_code)] // Helper for rotation
async fn append_to_log(path: &str, content: &str) -> std::io::Result<()> {
    use tokio::fs::OpenOptions;
    use tokio::io::AsyncWriteExt;
    
    // Support configurable log directory via environment variable
    let log_dir_str = std::env::var("LOG_DIR").unwrap_or_else(|_| "../logs".to_string());
    let log_file_path = std::path::Path::new(&log_dir_str).join(path);

    // Check if rotation is needed
    if let Ok(metadata) = tokio::fs::metadata(&log_file_path).await {
        if metadata.len() > MAX_LOG_SIZE {
             if let Err(e) = rotate_log_file(&log_file_path).await {
                 tracing::error!("Failed to rotate log file: {}", e);
             }
        }
    }

    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_file_path)
        .await?;
    
    file.write_all(content.as_bytes()).await?;
    file.flush().await?;
    
    Ok(())
}

#[tracing::instrument(name = "cleanup_logs")]
pub async fn cleanup_logs() -> impl actix_web::Responder {
    let log_dir_str = std::env::var("LOG_DIR").unwrap_or_else(|_| "../logs".to_string());
    
    // Use spawn_blocking for fs traversal as it's sync
    let result = web::block(move || -> std::io::Result<i32> {
        let logs_dir = std::path::Path::new(&log_dir_str);
        if !logs_dir.exists() {
             return Ok(0);
        }
        
        let mut count = 0;
        if let Ok(entries) = fs::read_dir(logs_dir) {
            for entry in entries {
                 if let Ok(entry) = entry {
                     if let Ok(metadata) = entry.metadata() {
                         if let Ok(modified) = metadata.modified() {
                             if let Ok(age) = modified.elapsed() {
                                 if age > Duration::from_secs(LOG_RETENTION_DAYS * 24 * 60 * 60) {
                                      fs::remove_file(entry.path()).ok();
                                      count += 1;
                                 }
                             }
                         }
                     }
                 }
            }
        }
        Ok(count)
    }).await;

    match result {
         Ok(Ok(count)) => HttpResponse::Ok().json(serde_json::json!({ "deleted": count })),
         _ => HttpResponse::InternalServerError().finish()
    }
}

#[tracing::instrument(skip(entry), name = "log_telemetry")]
pub async fn log_telemetry(entry: web::Json<TelemetryEntry>) -> Result<HttpResponse, AppError> {
    // Append to telemetry.log as JSON line
    let line = serde_json::to_string(&entry.into_inner()).unwrap_or_default() + "\n";
    
    if let Err(e) = append_to_log("telemetry.log", &line).await {
        tracing::error!("Failed to write telemetry: {}", e);
    }
    
    Ok(HttpResponse::Ok().finish())
}

#[tracing::instrument(skip(entry), name = "log_error")]
pub async fn log_error(entry: web::Json<TelemetryEntry>) -> Result<HttpResponse, AppError> {
    let entry_inner = entry.into_inner();
    
    // Append to error.log as plaintext
    let line = format!("[{}] [{}] {} - {:?}\n", 
        entry_inner.timestamp, entry_inner.module, entry_inner.message, entry_inner.data);
    
    if let Err(e) = append_to_log("error.log", &line).await {
        tracing::error!("Failed to write error log: {}", e);
    }
    
    // Also append to telemetry for completeness
    let json_line = serde_json::to_string(&entry_inner).unwrap_or_default() + "\n";
    let _ = append_to_log("telemetry.log", &json_line).await;
    
    Ok(HttpResponse::Ok().finish())
}

#[tracing::instrument(skip(req), name = "reverse_geocode")]
pub async fn reverse_geocode(req: web::Json<GeocodeRequest>) -> Result<HttpResponse, AppError> {
    let lat = req.lat;
    let lon = req.lon;
    let cache_key = round_coords(lat, lon);
    let current_time = get_current_timestamp();
    
    tracing::info!(
        module = "Geocoder", 
        lat = lat, 
        lon = lon, 
        "REVERSE_GEOCODE_START"
    );
    
    // Check cache first
    {
        let mut cache = GEOCODE_CACHE.write().await;
        if let Some(entry) = cache.get_mut(&cache_key) {
            // Update access time and count
            entry.last_accessed = current_time;
            entry.access_count += 1;
            
            let mut stats = CACHE_STATS.write().await;
            stats.hits += 1;
            
            tracing::info!(
                module = "Geocoder",
                access_count = entry.access_count,
                "CACHE_HIT"
            );
            
            return Ok(HttpResponse::Ok().json(GeocodeResponse {
                address: entry.address.clone(),
            }));
        }
    }
    
    // Cache miss
    {
        let mut stats = CACHE_STATS.write().await;
        stats.misses += 1;
    }
    
    tracing::debug!(module = "Geocoder", "CACHE_MISS - calling OSM API");
    
    // Call OSM API
    match call_osm_nominatim(lat, lon).await {
        Ok(address) => {
            // Store in cache with timestamp
            {
                let mut cache = GEOCODE_CACHE.write().await;
                
                // Evict if at capacity
                if cache.len() >= MAX_CACHE_SIZE {
                    drop(cache); // Release lock before evicting
                    evict_lru_entry().await;
                    cache = GEOCODE_CACHE.write().await; // Re-acquire
                }
                
                cache.insert(cache_key, CachedGeocode {
                    address: address.clone(),
                    last_accessed: current_time,
                    access_count: 1,
                });
            }
            
            // Trigger async save (debounced)
            tokio::spawn(async move {
                tokio::time::sleep(tokio::time::Duration::from_millis(CACHE_SAVE_INTERVAL_MS)).await;
                let _ = save_cache_to_disk().await;
            });
            
            tracing::info!(module = "Geocoder", "REVERSE_GEOCODE_COMPLETE");
            Ok(HttpResponse::Ok().json(GeocodeResponse { address }))
        },
        Err(e) => {
            tracing::error!(module = "Geocoder", error = %e, "REVERSE_GEOCODE_FAILED");
            // Return a graceful fallback message
            Ok(HttpResponse::Ok().json(GeocodeResponse {
                address: format!("[Geocoding unavailable: {}]", e),
            }))
        }
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct GeocodeStatsResponse {
    cache_size: usize,
    max_cache_size: usize,
    hit_rate: f64,
    total_requests: u64,
    hits: u64,
    misses: u64,
    evictions: u64,
    last_save: Option<String>,
}

#[tracing::instrument(name = "geocode_stats")]
pub async fn geocode_stats() -> impl actix_web::Responder {
    let cache = GEOCODE_CACHE.read().await;
    let stats = CACHE_STATS.read().await;
    
    let total_requests = stats.hits + stats.misses;
    let hit_rate = if total_requests > 0 {
        (stats.hits as f64 / total_requests as f64) * 100.0
    } else {
        0.0
    };
    
    let last_save_time = stats.last_save.map(|ts| {
        chrono::DateTime::<chrono::Utc>::from_timestamp(ts as i64, 0)
            .map(|dt| dt.to_rfc3339())
            .unwrap_or_else(|| "Unknown".to_string())
    });
    
    HttpResponse::Ok().json(GeocodeStatsResponse {
        cache_size: cache.len(),
        max_cache_size: MAX_CACHE_SIZE,
        hit_rate,
        total_requests,
        hits: stats.hits,
        misses: stats.misses,
        evictions: stats.evictions,
        last_save: last_save_time,
    })
}

#[tracing::instrument(name = "clear_geocode_cache")]
pub async fn clear_geocode_cache() -> impl actix_web::Responder {
    {
        let mut cache = GEOCODE_CACHE.write().await;
        let size = cache.len();
        cache.clear();
        
        tracing::info!(
            module = "Geocoder",
            entries_cleared = size,
            "CACHE_CLEARED"
        );
    }
    
    // Reset stats
    {
        let mut stats = CACHE_STATS.write().await;
        *stats = CacheStats::default();
    }
    
    // Save empty cache
    let _ = save_cache_to_disk().await;
    
    HttpResponse::Ok().json(serde_json::json!({
        "success": true,
        "message": "Cache cleared"
    }))
}


#[tracing::instrument(skip(payload), name = "extract_metadata")]
pub async fn extract_metadata(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    // PERFORMANCE: Pre-allocate buffer for typical 30MB panoramic images
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
                    
                    if (data.scenes && Array.isArray(data.scenes)) {{
                        await Promise.all(data.scenes.map(async (scene) => {{
                            try {{
                                // Filename in project match filename stored
                                const url = `/session/${{sessionId}}/${{encodeURIComponent(scene.name)}}`;
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

#[cfg(test)]
mod tests {
    use super::*;
    use img_parts::riff::RiffContent;

        // Probe removed
    
    #[test]
    fn test_suggested_name() {
        assert_eq!(media::get_suggested_name("_260113_01_005.jpg"), "260113_005");
        assert_eq!(media::get_suggested_name("DSC_001.JPG"), "DSC_001");
        assert_eq!(media::get_suggested_name("plain_file"), "plain_file");
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
        let json = serde_json::to_string(&analysis)
            .expect("Test serialization should not fail");
        assert!(json.contains("\"score\":9.0"));
    }

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
}
#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportResponse {
    pub session_id: String,
    pub project_data: serde_json::Value,
}

pub async fn import_project(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    // 1. Generate Session ID
    let session_id = Uuid::new_v4().to_string();
    let session_dir = PathBuf::from(format!("{}/{}", SESSIONS_DIR, session_id));
    fs::create_dir_all(&session_dir).map_err(AppError::IoError)?;
    
    tracing::info!(module = "ProjectManager", session_id = %session_id, "IMPORT_PROJECT_START");

    while let Ok(Some(mut field)) = payload.try_next().await {
        
        let name = field.content_disposition().and_then(|cd| cd.get_name()).unwrap_or("unknown");

        if name == "file" {
            let tmp_path = format!("{}/{}_upload.zip", TEMP_DIR, session_id);
             fs::create_dir_all(TEMP_DIR).map_err(AppError::IoError)?; // Ensure temp dir exists
             
             let mut f = fs::File::create(&tmp_path).map_err(AppError::IoError)?;
             while let Ok(Some(chunk)) = field.try_next().await {
                 f.write_all(&chunk).map_err(AppError::IoError)?;
             }
             
             // Unzip
             let file = fs::File::open(&tmp_path).map_err(AppError::IoError)?;
             let mut archive = zip::ZipArchive::new(file).map_err(|e| AppError::ZipError(e.to_string()))?;
             
             for i in 0..archive.len() {
                 let mut file = archive.by_index(i).map_err(|e| AppError::ZipError(e.to_string()))?;
                 let outpath = match file.enclosed_name() {
                    Some(path) => session_dir.join(path),
                    None => continue,
                 };
                 
                 if file.name().ends_with('/') {
                    fs::create_dir_all(&outpath).map_err(AppError::IoError)?;
                 } else {
                    if let Some(p) = outpath.parent() {
                        if !p.exists() {
                            fs::create_dir_all(&p).map_err(AppError::IoError)?;
                        }
                    }
                    let mut outfile = fs::File::create(&outpath).map_err(AppError::IoError)?;
                    std::io::copy(&mut file, &mut outfile).map_err(AppError::IoError)?;
                 }
             }

             // Clean temp zip
             let _ = fs::remove_file(&tmp_path);
             
             // Read project.json
             let project_json_path = session_dir.join("project.json");
             if !project_json_path.exists() {
                  return Err(AppError::InternalError("project.json not found in archive".into()));
             }
             
             let json_str = fs::read_to_string(project_json_path).map_err(AppError::IoError)?;
             let project_data: serde_json::Value = serde_json::from_str(&json_str).map_err(|e| AppError::InternalError(e.to_string()))?;
             
             tracing::info!(module = "ProjectManager", session_id = %session_id, "IMPORT_PROJECT_SUCCESS");

             return Ok(HttpResponse::Ok().json(ImportResponse {
                 session_id: session_id,
                 project_data: project_data
             }));
        }
    }
    
    Err(AppError::MultipartError(actix_multipart::MultipartError::Incomplete)) // Using existing error variant if applicable or just Incomplete
}

pub async fn calculate_path(
    req: web::Json<crate::pathfinder::PathRequest>,
) -> Result<HttpResponse, AppError> {
    let result = match req.into_inner() {
        crate::pathfinder::PathRequest::Walk { scenes, skip_auto_forward } => {
            crate::pathfinder::calculate_walk_path(scenes, skip_auto_forward)
        }
        crate::pathfinder::PathRequest::Timeline { scenes, timeline, skip_auto_forward } => {
            crate::pathfinder::calculate_timeline_path(scenes, timeline, skip_auto_forward)
        }
    };
    Ok(HttpResponse::Ok().json(result))
}
