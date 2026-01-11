use actix_multipart::Multipart;
use actix_web::{web, HttpResponse, ResponseError};
use futures_util::TryStreamExt as _;
use std::fs;
use std::io::{Write, Cursor};
use std::process::Command;
use std::path::PathBuf;
use uuid::Uuid;
use serde::{Serialize, Deserialize};
use std::fmt;
use zip::write::FileOptions;
use std::collections::HashMap;
use rayon::prelude::*;
use img_parts::webp::WebP;
use headless_chrome::{Browser, LaunchOptions};
use std::time::Duration;

use img_parts::riff::{RiffContent, RiffChunk};
use bytes::Bytes;
use fast_image_resize::{Resizer, ResizeOptions, FilterType, ResizeAlg, PixelType, images::Image as FrImage};
// Configs
const PROCESSED_IMAGE_WIDTH: u32 = 4096;
const TEMP_DIR: &str = "/tmp/remax_backend";
const SESSIONS_DIR: &str = "/tmp/remax_sessions";
const MAX_UPLOAD_SIZE: usize = 2048 * 1024 * 1024; // 2GB limit (increased for full projects)

// --- Error Handling ---

#[derive(Debug, Serialize, Deserialize)]
pub struct ErrorResponse {
    pub error: String,
    pub details: Option<String>,
}

#[derive(Debug)]
pub enum AppError {
    IoError(std::io::Error),
    MultipartError(actix_multipart::MultipartError),
    ImageError(String),
    FFmpegError(String),
    ZipError(String),
    InternalError(String),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AppError::IoError(e) => write!(f, "IO Error: {}", e),
            AppError::MultipartError(e) => write!(f, "Multipart Error: {}", e),
            AppError::ImageError(e) => write!(f, "Image Processing Error: {}", e),
            AppError::FFmpegError(e) => write!(f, "FFmpeg Error: {}", e),
            AppError::ZipError(e) => write!(f, "Zip Error: {}", e),
            AppError::InternalError(e) => write!(f, "Internal Error: {}", e),
        }
    }
}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        let (status, msg, details) = match self {
            AppError::IoError(e) => (actix_web::http::StatusCode::INTERNAL_SERVER_ERROR, "File System Error", Some(e.to_string())),
            AppError::MultipartError(e) => (actix_web::http::StatusCode::BAD_REQUEST, "Upload Error", Some(e.to_string())),
            AppError::ImageError(e) => (actix_web::http::StatusCode::BAD_REQUEST, "Image Processing Failed", Some(e.clone())),
            AppError::FFmpegError(e) => (actix_web::http::StatusCode::INTERNAL_SERVER_ERROR, "Video Encoding Failed", Some(e.clone())),
            AppError::ZipError(e) => (actix_web::http::StatusCode::INTERNAL_SERVER_ERROR, "Zip Compression Failed", Some(e.clone())),
            AppError::InternalError(e) => (actix_web::http::StatusCode::INTERNAL_SERVER_ERROR, "Internal Server Error", Some(e.clone())),
        };

        // Log the error on the backend
        tracing::error!(error = ?self, "Request failed");

        HttpResponse::build(status).json(ErrorResponse {
            error: msg.to_string(),
            details,
        })
    }
}

// Implement From traits for easy conversion
impl From<std::io::Error> for AppError {
    fn from(err: std::io::Error) -> Self { AppError::IoError(err) }
}
impl From<actix_multipart::MultipartError> for AppError {
    fn from(err: actix_multipart::MultipartError) -> Self { AppError::MultipartError(err) }
}
impl From<zip::result::ZipError> for AppError {
    fn from(err: zip::result::ZipError) -> Self { AppError::ZipError(err.to_string()) }
}
impl From<String> for AppError {
    fn from(err: String) -> Self { AppError::InternalError(err) }
}

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

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GpsData {
    pub lat: f64,
    pub lon: f64,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ExifMetadata {
    pub make: Option<String>,
    pub model: Option<String>,
    pub date_time: Option<String>,
    pub gps: Option<GpsData>,
    pub width: u32,
    pub height: u32,
    pub focal_length: Option<f32>,
    pub aperture: Option<f32>,
    pub iso: Option<u32>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct QualityStats {
    pub avg_luminance: u32,
    pub black_clipping: f32,
    pub white_clipping: f32,
    pub sharpness_variance: u32,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ColorHist {
    pub r: Vec<u32>,
    pub g: Vec<u32>,
    pub b: Vec<u32>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct QualityAnalysis {
    pub score: f32,
    pub histogram: Vec<u32>,
    pub color_hist: ColorHist,
    pub stats: QualityStats,
    pub is_blurry: bool,
    pub is_soft: bool,
    pub is_severely_dark: bool,
    pub is_dim: bool,
    pub has_black_clipping: bool,
    pub has_white_clipping: bool,
    pub issues: u32,
    pub warnings: u32,
    pub analysis: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MetadataResponse {
    pub exif: ExifMetadata,
    pub quality: QualityAnalysis,
    pub is_optimized: bool,
}

// --- Internal Processing Logic (Extracted for reuse) ---

// --- OPTIMIZED HELPER ---
fn resize_fast(img: &image::DynamicImage, target_width: u32, target_height: u32) -> Result<image::DynamicImage, String> {
    if target_width == 0 || target_height == 0 {
        return Err("Invalid dimensions: width and height must be greater than 0".to_string());
    }

    // Convert to RGBA8 for consistent processing (fast_image_resize works best with known pixel types)
    let rgba_img = img.to_rgba8();
    
    let src_image = FrImage::from_vec_u8(
        img.width(),
        img.height(),
        rgba_img.into_raw(),
        PixelType::U8x4,
    ).map_err(|e| format!("FastResize Init Error: {:?}", e))?;

    let mut dst_image = FrImage::new(
        target_width,
        target_height,
        src_image.pixel_type(),
    );

    let mut resizer = Resizer::new();
    let options = ResizeOptions::new().resize_alg(ResizeAlg::Convolution(FilterType::Lanczos3));
    
    resizer.resize(&src_image, &mut dst_image, &options)
        .map_err(|e| format!("FastResize Error: {:?}", e))?;

    let data = dst_image.into_vec();
    
    image::RgbaImage::from_raw(target_width, target_height, data)
        .map(image::DynamicImage::ImageRgba8)
        .ok_or_else(|| "Failed to reconstruct image from buffer".to_string())
}

// --- Internal Processing Logic (Extracted for reuse) ---
fn perform_metadata_extraction(img: &image::DynamicImage, input_data: &[u8]) -> Result<MetadataResponse, String> {
    // 0. Check for existing "reMX" specific metadata (PREVENTION of Re-optimization)
    // We parse the input bytes as WebP to see if our custom chunk exists.
    if let Ok(webp) = WebP::from_bytes(Bytes::copy_from_slice(input_data)) {
        if let Some(chunk) = webp.chunk_by_id(*b"reMX") {
            let data_ref = chunk.content();
            let slice = match data_ref {
                RiffContent::Data(data) => data.as_ref(),
                _ => &[] as &[u8],
            };
            
            // Try to deserialize as full MetadataResponse first (new format)
            if let Ok(mut full_meta) = serde_json::from_slice::<MetadataResponse>(slice) {
                full_meta.is_optimized = true;
                return Ok(full_meta);
            }

            // Fallback for older "QualityAnalysis" only chunks
            if let Ok(prev_analysis) = serde_json::from_slice::<QualityAnalysis>(slice) {
                 let (w, h) = (img.width(), img.height());
                 return Ok(MetadataResponse {
                     exif: ExifMetadata {
                        make: None, model: None, date_time: None, gps: None,
                        width: w, height: h,
                        focal_length: None, aperture: None, iso: None,
                     }, 
                     quality: prev_analysis,
                     is_optimized: true
                 });
            }
        }
    }

    // 1. Parse EXIF
    let mut reader = Cursor::new(input_data);
    let exif_reader = exif::Reader::new();
    let exif_data = exif_reader.read_from_container(&mut reader).ok();

    let mut make = None;
    let mut model = None;
    let mut date_time = None;
    let mut gps = None;
    let mut focal_length = None;
    let mut aperture = None;
    let mut iso = None;

    if let Some(exif) = exif_data {
        make = exif.get_field(exif::Tag::Make, exif::In::PRIMARY).map(|f| f.display_value().to_string().replace("\"", ""));
        model = exif.get_field(exif::Tag::Model, exif::In::PRIMARY).map(|f| f.display_value().to_string().replace("\"", ""));
        date_time = exif.get_field(exif::Tag::DateTimeOriginal, exif::In::PRIMARY).map(|f| f.display_value().to_string());

        focal_length = exif.get_field(exif::Tag::FocalLength, exif::In::PRIMARY).and_then(|f| {
            if let exif::Value::Rational(ref v) = f.value {
                v.get(0).map(|r| r.to_f64() as f32)
            } else { None }
        });
        aperture = exif.get_field(exif::Tag::FNumber, exif::In::PRIMARY).and_then(|f| {
            if let exif::Value::Rational(ref v) = f.value {
                v.get(0).map(|r| r.to_f64() as f32)
            } else { None }
        });
        iso = exif.get_field(exif::Tag::PhotographicSensitivity, exif::In::PRIMARY).and_then(|f| {
            f.value.get_uint(0)
        });

        let lat_field = exif.get_field(exif::Tag::GPSLatitude, exif::In::PRIMARY);
        let lat_ref_field = exif.get_field(exif::Tag::GPSLatitudeRef, exif::In::PRIMARY);
        let lon_field = exif.get_field(exif::Tag::GPSLongitude, exif::In::PRIMARY);
        let lon_ref_field = exif.get_field(exif::Tag::GPSLongitudeRef, exif::In::PRIMARY);

        if let (Some(lat), Some(lat_ref), Some(lon), Some(lon_ref)) = (lat_field, lat_ref_field, lon_field, lon_ref_field) {
            let parse_gps = |f: &exif::Field| -> Option<f64> {
                if let exif::Value::Rational(ref dms) = f.value {
                    if dms.len() >= 3 {
                        let d = dms[0].to_f64();
                        let m = dms[1].to_f64();
                        let s = dms[2].to_f64();
                        return Some(d + m / 60.0 + s / 3600.0);
                    }
                }
                None
            };

            if let (Some(mut lat_val), Some(mut lon_val)) = (parse_gps(lat), parse_gps(lon)) {
                if lat_ref.display_value().to_string().contains('S') { lat_val = -lat_val; }
                if lon_ref.display_value().to_string().contains('W') { lon_val = -lon_val; }
                gps = Some(GpsData { lat: lat_val, lon: lon_val });
            }
        }
    }

    // 2. Quality Analysis
    let (orig_w, orig_h) = (img.width(), img.height());
    
    
    // OPTIMIZATION: Use fast resize for analysis thumbnail
    let analyzed_img = resize_fast(img, 400, 400).unwrap_or_else(|_| img.thumbnail(400, 400));
    let rgb = analyzed_img.into_rgb8(); // consumes analyzed_img, avoids a copy
    let (w, h) = rgb.dimensions();
    let pixel_count = (w * h) as f32;

    let mut hist_r = vec![0u32; 256];
    let mut hist_g = vec![0u32; 256];
    let mut hist_b = vec![0u32; 256];
    let mut hist_gray = vec![0u32; 256];
    let mut total_lum = 0u64;
    let mut gray_pixels = Vec::with_capacity((w * h) as usize);

    for pixel in rgb.pixels() {
        let r = pixel[0] as usize;
        let g = pixel[1] as usize;
        let b = pixel[2] as usize;
        hist_r[r] += 1;
        hist_g[g] += 1;
        hist_b[b] += 1;

        // OPTIMIZATION: Use fixed-point integer math for luminance (faster than float)
        // (R*54 + G*183 + B*19) >> 8
        // Use saturating arithmetic to prevent overflow (defensive programming)
        let lum = ((pixel[0] as u32 * 54)
            .saturating_add(pixel[1] as u32 * 183)
            .saturating_add(pixel[2] as u32 * 19) >> 8) as u8;
        hist_gray[lum as usize] += 1;
        total_lum += lum as u64;
        gray_pixels.push(lum);
    }

    let avg_lum = (total_lum as f32 / pixel_count) as u32;
    let black_clipping = (hist_gray[0] as f32 / pixel_count) * 100.0;
    let white_clipping = (hist_gray[255] as f32 / pixel_count) * 100.0;

    let y_start = (h as f32 * 0.2) as u32;
    let y_end = (h as f32 * 0.8) as u32;
    let mut laplace_sum = 0.0f64;
    let mut laplace_sq_sum = 0.0f64;
    let mut sampled_count = 0u64;

    for y in (y_start + 1)..(y_end - 1) {
        for x in 1..(w - 1) {
            let idx = (y * w + x) as usize;
            let center = gray_pixels[idx] as i32;
            let lap = gray_pixels[idx - w as usize] as i32 +
                      gray_pixels[idx - 1] as i32 +
                      gray_pixels[idx + 1] as i32 +
                      gray_pixels[idx + w as usize] as i32 - 4 * center;
            
            let lap_f = lap as f64;
            laplace_sum += lap_f;
            laplace_sq_sum += lap_f * lap_f;
            sampled_count += 1;
        }
    }

    let laplace_var = if sampled_count > 0 {
        let mean = laplace_sum / sampled_count as f64;
        (laplace_sq_sum / sampled_count as f64) - (mean * mean)
    } else { 0.0 };

    let is_blurry = laplace_var < 100.0;
    let is_soft = !is_blurry && laplace_var < 120.0;
    let is_severely_dark = avg_lum < 50;
    let is_severely_bright = avg_lum > 200;
    let is_dim = !is_severely_dark && avg_lum < 60;
    let has_black_clipping = black_clipping > 15.0;
    let has_white_clipping = white_clipping > 15.0;

    let mut score = 7.5f32;
    let mut issues = 0u32;
    let mut warnings = 0u32;

    if has_black_clipping { score -= 2.0; issues += 1; }
    if has_white_clipping { score -= 2.0; issues += 1; }
    if is_severely_dark { score -= 2.5; issues += 1; }
    if is_severely_bright { score -= 1.5; issues += 1; }
    if is_blurry { score -= 2.0; issues += 1; }
    if is_dim { score -= 1.0; warnings += 1; }
    if is_soft { score -= 1.0; warnings += 1; }
    if issues == 0 && warnings == 0 { score += 1.5; }
    score = score.clamp(1.0, 10.0);

    let mut analysis = Vec::new();
    if is_severely_dark { analysis.push("Very dark image."); }
    if is_severely_bright { analysis.push("Very bright image."); }
    if has_black_clipping { analysis.push("Lost shadow detail."); }
    if has_white_clipping { analysis.push("Lost highlight detail."); }
    if is_blurry { analysis.push("Possible blur detected."); }
    if is_dim { analysis.push("Image appears dim; brighter exposure recommended."); }
    if is_soft { analysis.push("Slight softness detected; check focus."); }

    Ok(MetadataResponse {
        exif: ExifMetadata {
            make, model, date_time, gps,
            width: orig_w, height: orig_h,
            focal_length, aperture, iso,
        },
        quality: QualityAnalysis {
            score,
            histogram: hist_gray,
            color_hist: ColorHist { r: hist_r, g: hist_g, b: hist_b },
            stats: QualityStats {
                avg_luminance: avg_lum,
                black_clipping,
                white_clipping,
                sharpness_variance: laplace_var as u32,
            },
            is_blurry, is_soft, is_severely_dark, is_dim,
            has_black_clipping, has_white_clipping,
            issues, warnings,
            analysis: if analysis.is_empty() { None } else { Some(analysis.join(" ")) },
        },
        is_optimized: false
    })
}

// INJECTION HELPER
fn inject_remx_chunk(webp_data: Vec<u8>, metadata: &MetadataResponse) -> Result<Vec<u8>, String> {
    let mut webp = WebP::from_bytes(Bytes::from(webp_data)).map_err(|e| e.to_string())?;
    let json = serde_json::to_string(metadata).map_err(|e| e.to_string())?;
    
    // Create custom chunk "reMX"
    let chunk = RiffChunk::new(*b"reMX", RiffContent::Data(Bytes::from(json)));
    webp.chunks_mut().push(chunk);
    
    // Encode back to bytes
    let mut writer = Cursor::new(Vec::new());
    webp.encoder().write_to(&mut writer).map_err(|e: std::io::Error| e.to_string())?;
    Ok(writer.into_inner())
}

// --- Handlers ---

#[tracing::instrument(skip(payload), name = "process_image_full")]
pub async fn process_image_full(mut payload: Multipart) -> Result<HttpResponse, AppError> {
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
        let data_size = data.len();
        let img = image::ImageReader::new(Cursor::new(&data))
            .with_guessed_format()
            .map_err(|e| format!("Failed to guess image format (size: {} bytes): {}", data_size, e))?
            .decode()
            .map_err(|e| format!("Failed to decode image (size: {} bytes): {}", data_size, e))?;

        // 1. Metadata Extraction
        let metadata = perform_metadata_extraction(&img, &data)?;
        
        // 2. Image Optimization (4K WebP + Tiny 512px Progressive Preview)
        
        let webp_buffer_vec = if metadata.is_optimized && img.width() == PROCESSED_IMAGE_WIDTH {
             // Skip Re-optimization!
             tracing::info!("Image already optimized. Skipping resize and encode.");
             // If input was WebP (which it likely is if is_optimized is true), use it.
             // data is the raw input bytes.
             data.clone()
        } else {
            // OPTIMIZATION: Use fast_image_resize
            let resized = resize_fast(&img, PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH)
                .map_err(|e| format!("Resize failed: {}", e))?;
            
            let mut buf = Cursor::new(Vec::new());
            resized.write_to(&mut buf, image::ImageFormat::WebP)
                .map_err(|e| format!("Failed to encode WebP: {}", e))?;
            
            // INJECT METADATA
            inject_remx_chunk(buf.into_inner(), &metadata)?
        };

        let webp_buffer = Cursor::new(webp_buffer_vec);

        // OPTIMIZATION: Parallelize Tiny generation? (Left sequential for now but using fast resize)
        let tiny = resize_fast(&img, 512, 512).unwrap_or_else(|_| img.thumbnail(512, 512));
        let mut tiny_buffer = Cursor::new(Vec::new());
        tiny.write_to(&mut tiny_buffer, image::ImageFormat::WebP)
            .map_err(|e| format!("Failed to encode Tiny WebP: {}", e))?;

        // 3. Package as ZIP
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
        
        Ok(zip_buffer.into_inner())
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    match result_zip {
        Ok(zip_bytes) => {
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        },
        Err(e) => Err(AppError::ImageError(e))
    }
}

#[tracing::instrument(skip(payload), name = "optimize_image")]
pub async fn optimize_image(mut payload: Multipart) -> Result<HttpResponse, AppError> {
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
        let img = image::ImageReader::new(Cursor::new(data))
            .with_guessed_format()
            .map_err(|e| format!("Failed to guess format: {}", e))?
            .decode()
            .map_err(|e| format!("Failed to decode image: {}", e))?;
        
        // Use Lanczos3 for absolute sharpness in editor previews (via fast_image_resize)
        let resized = resize_fast(&img, PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH)
             .map_err(|e| format!("Resize failed: {}", e))?;
        
        let mut webp_buffer = Cursor::new(Vec::new());
        resized.write_to(&mut webp_buffer, image::ImageFormat::WebP)
            .map_err(|e| format!("Failed to encode WebP: {}", e))?;
        
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
        
        Ok(webp_buffer.into_inner())
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    match result_bytes {
        Ok(bytes) => {
            Ok(HttpResponse::Ok()
                .content_type("image/webp")
                .body(bytes))
        },
        Err(e) => Err(AppError::ImageError(e)),
    }
}

#[tracing::instrument(skip(payload), name = "resize_image_batch")]
pub async fn resize_image_batch(mut payload: Multipart) -> Result<HttpResponse, AppError> {
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
                    let resized = resize_fast(&img, *width, *width)
                        .map_err(|e| format!("Resize failed: {}", e))?;
                    
                    let mut webp_buffer = Cursor::new(Vec::new());
                    resized.write_to(&mut webp_buffer, image::ImageFormat::WebP)
                        .map_err(|e| format!("Failed to encode WebP {}: {}", filename, e))?;
                    
                    Ok((filename.to_string(), webp_buffer.into_inner()))
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

    match result_zip {
        Ok(zip_bytes) => {
            tracing::info!("Batch resize successful, returning {} bytes", zip_bytes.len());
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        },
        Err(e) => Err(AppError::ImageError(e))
    }
}

#[tracing::instrument(skip(payload), name = "create_tour_package")]
pub async fn create_tour_package(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    let mut fields: HashMap<String, String> = HashMap::new();
    let mut image_files: Vec<(String, Vec<u8>)> = Vec::new();

    let mut current_total_size = 0;

    // 1. Parse Multipart into Memory
    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field.content_disposition().unwrap().clone();
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

    let result_zip = web::block(move || -> Result<Vec<u8>, String> {
        let mut zip_buffer = Cursor::new(Vec::new());
        {
            let mut zip = zip::ZipWriter::new(&mut zip_buffer);
            let options = FileOptions::default()
                .compression_method(zip::CompressionMethod::Stored)
                .unix_permissions(0o755);

            // 2. Add Static Assets (Logo)
            if let Some((_, logo_bytes)) = image_files.iter().find(|(name, _)| name == "logo.png") {
                 for folder in &["tour_4k", "tour_2k", "tour_hd"] {
                     zip.start_file(format!("{}/assets/logo.png", folder), options).map_err(|e| e.to_string())?;
                     zip.write_all(logo_bytes).map_err(|e| e.to_string())?;
                 }
            }

            // 3. Add Libraries
            let lib_files = ["pannellum.js", "pannellum.css"];
            for lib in lib_files {
                if let Some((_, lib_bytes)) = image_files.iter().find(|(name, _)| name == lib) {
                    for folder in &["tour_4k", "tour_2k", "tour_hd"] {
                        zip.start_file(format!("{}/libs/{}", folder, lib), options).map_err(|e| e.to_string())?;
                        zip.write_all(lib_bytes).map_err(|e| e.to_string())?;
                    }
                }
            }

            // 4. Add HTML Templates
            if let Some(html) = fields.get("html_4k") {
                zip.start_file("tour_4k/index.html", options).map_err(|e| e.to_string())?;
                zip.write_all(html.as_bytes()).map_err(|e| e.to_string())?;
            }
            if let Some(html) = fields.get("html_2k") {
                zip.start_file("tour_2k/index.html", options).map_err(|e| e.to_string())?;
                zip.write_all(html.as_bytes()).map_err(|e| e.to_string())?;
            }
            if let Some(html) = fields.get("html_hd") {
                zip.start_file("tour_hd/index.html", options).map_err(|e| e.to_string())?;
                zip.write_all(html.as_bytes()).map_err(|e| e.to_string())?;
            }
            if let Some(html) = fields.get("html_index") {
                zip.start_file("index.html", options).map_err(|e| e.to_string())?;
                zip.write_all(html.as_bytes()).map_err(|e| e.to_string())?;
            }
            if let Some(embed) = fields.get("embed_codes") {
                zip.start_file("embed_codes.txt", options).map_err(|e| e.to_string())?;
                zip.write_all(embed.as_bytes()).map_err(|e| e.to_string())?;
            }

            // 5. Process Scenes (Resize)
            let scene_files: Vec<_> = image_files.iter()
                .filter(|(name, _)| !name.starts_with("logo") && !name.starts_with("pannellum"))
                .collect();

            let processed_results: Vec<Result<Vec<(String, Vec<u8>)>, String>> = scene_files.par_iter()
                .map(|(name, data)| -> Result<Vec<(String, Vec<u8>)>, String> {
                    let img = image::ImageReader::new(Cursor::new(data))
                        .with_guessed_format()
                        .map_err(|e| format!("Failed to guess format for {}: {}", name, e))?
                        .decode()
                        .map_err(|e| format!("Failed to decode {}: {}", name, e))?;

                    let targets = [
                        ("tour_4k", 4096),
                        ("tour_2k", 2048),
                        ("tour_hd", 1280),
                    ];

                    let mut artifacts = Vec::new();
                    for (folder, width) in targets {
                        let resized = resize_fast(&img, width, width)
                            .map_err(|e| format!("Resize failed: {}", e))?;
                        let webp_name = std::path::Path::new(name).with_extension("webp");
                        let fname = webp_name.file_name().ok_or("Invalid filename")?.to_str().ok_or("Invalid filename")?;
                        let zip_path = format!("{}/assets/images/{}", folder, fname);
                        
                        let mut webp_buffer = Cursor::new(Vec::new());
                        resized.write_to(&mut webp_buffer, image::ImageFormat::WebP)
                            .map_err(|e| format!("Failed to encode WebP for {}: {}", name, e))?;
                        
                        artifacts.push((zip_path, webp_buffer.into_inner()));
                    }
                    Ok(artifacts)
                })
                .collect();

            for result in processed_results {
                let artifacts = result?;
                for (zip_path, data) in artifacts {
                    zip.start_file(zip_path, options).map_err(|e| e.to_string())?;
                    zip.write_all(&data).map_err(|e| e.to_string())?;
                }
            }

            zip.finish().map_err(|e| e.to_string())?;
        }
        
        Ok(zip_buffer.into_inner())
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    match result_zip {
        Ok(zip_bytes) => {
            tracing::info!("Tour package created successfully, size: {} bytes", zip_bytes.len());
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(zip_bytes))
        },
        Err(e) => Err(AppError::ZipError(e)),
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TelemetryPayload {
    pub level: String,
    pub module: String,
    pub message: String,
    pub data: Option<serde_json::Value>,
    pub timestamp: String,
}

#[derive(Serialize)]
pub struct LoadProjectResponse {
    pub session_id: String,
    pub project_data: serde_json::Value,
}

#[tracing::instrument(skip(payload), name = "save_project")]
pub async fn save_project(mut payload: Multipart) -> Result<HttpResponse, AppError> {
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
        let content_disposition = field.content_disposition().unwrap().clone();
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
    
    let _ = web::block(move || -> Result<(), std::io::Error> {
        let file = fs::File::create(&final_zip_path)?;
        let mut zip = zip::ZipWriter::new(file);
        let options = FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored) // Already compressed WebPs
            .unix_permissions(0o755);
            
        // Write JSON
        zip.start_file("project.json", options)?;
        zip.write_all(json_content.as_bytes())?;
        
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
    }).await.map_err(|e| AppError::InternalError(e.to_string()))??;
    
    // 4. Stream Back the ZIP
    let zip_file = fs::File::open(&zip_path).map_err(AppError::IoError)?;
    let metadata = zip_file.metadata().map_err(AppError::IoError)?;
    
    let mut buffer = Vec::with_capacity(metadata.len() as usize);
    let mut reader = std::io::BufReader::new(zip_file);
    std::io::copy(&mut reader, &mut buffer).map_err(AppError::IoError)?;
    
    // Clean up
    let _ = fs::remove_file(zip_path);

    Ok(HttpResponse::Ok()
        .content_type("application/zip")
        .body(buffer))
}

#[tracing::instrument(skip(payload), name = "load_project")]
pub async fn load_project(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    let mut zip_data = Vec::new();
    
    // 1. Read ZIP Upload (Stream to memory if fits, else file? Let's buffer in memory for load)
    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
            zip_data.extend_from_slice(&chunk);
             if zip_data.len() > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError("Project too large".into()));
            }
        }
    }
    
    let session_id = Uuid::new_v4().to_string();
    let session_path = get_session_path(&session_id);
    
    // 2. Unzip and Process
    let project_data = web::block(move || -> Result<serde_json::Value, String> {
        // Create Session Dir
        fs::create_dir_all(&session_path).map_err(|e| e.to_string())?;
        
        let reader = Cursor::new(zip_data);
        let mut zip = zip::ZipArchive::new(reader).map_err(|e| e.to_string())?;
        
        // Extract Everything
        zip.extract(&session_path).map_err(|e| e.to_string())?;
        
        // Read project.json
        let json_path = session_path.join("project.json");
        let json_str = fs::read_to_string(json_path).map_err(|e| e.to_string())?;
        let json: serde_json::Value = serde_json::from_str(&json_str).map_err(|e| e.to_string())?;
        
        Ok(json)
    }).await.map_err(|e| AppError::InternalError(e.to_string()))??;
    
    Ok(HttpResponse::Ok().json(LoadProjectResponse {
        session_id,
        project_data
    }))
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

#[tracing::instrument(skip(payload), name = "log_telemetry")]
pub async fn log_telemetry(payload: web::Json<TelemetryPayload>) -> Result<HttpResponse, AppError> {
    // Support configurable log directory via environment variable
    let log_dir_str = std::env::var("LOG_DIR").unwrap_or_else(|_| "../logs".to_string());
    let log_dir = std::path::Path::new(&log_dir_str);
    
    if !log_dir.exists() {
        fs::create_dir_all(log_dir).ok();
    }

    let log_file_path = log_dir.join("telemetry.log");
    let mut file = fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_file_path)?;

    let log_entry = format!(
        "[{}] [{}] [{}] {} - {:?}\n",
        payload.timestamp,
        payload.level.to_uppercase(),
        payload.module,
        payload.message,
        payload.data
    );

    file.write_all(log_entry.as_bytes())?;
    
    Ok(HttpResponse::Ok().finish())
}

#[tracing::instrument(skip(payload), name = "extract_metadata")]
pub async fn extract_metadata(mut payload: Multipart) -> Result<HttpResponse, AppError> {
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

    let result = web::block(move || -> Result<MetadataResponse, String> {
        let img = image::ImageReader::new(Cursor::new(&data))
            .with_guessed_format()
            .map_err(|e| format!("Failed to guess format: {}", e))?
            .decode()
            .map_err(|e| format!("Failed to decode: {}", e))?;

        perform_metadata_extraction(&img, &data)
    }).await.map_err(|e| AppError::InternalError(e.to_string()))?;

    match result {
        Ok(data) => Ok(HttpResponse::Ok().json(data)),
        Err(e) => Err(AppError::ImageError(e)),
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
    let input_str = input_path.to_str().unwrap().to_string();
    let output_str = output_path.to_str().unwrap().to_string();

    tracing::info!(input = %input_str, output = %output_str, "Starting FFmpeg transcoding");

    let result = web::block(move || {
        let local_ffmpeg = PathBuf::from("./bin/ffmpeg");
        let ffmpeg_cmd = if local_ffmpeg.exists() {
            local_ffmpeg.to_str().unwrap().to_string()
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
            tracing::info!("Transcoding successful");
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
    
    tracing::info!("Starting teaser generation session: {}", session_id);

    let mut project_data_value: Option<serde_json::Value> = None;
    let mut width = 1920;
    let mut height = 1080;
    let duration_limit = 120; // Default limit

    // 2. Parse Multipart
    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field.content_disposition().unwrap().clone();
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
    let output_str = output_path.to_str().unwrap().to_string();
    
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
        tab.navigate_to("http://localhost:5173").map_err(|e| format!("Nav failed: {}", e))?;
        tab.wait_until_navigated().map_err(|e| format!("Nav timeout: {}", e))?;

        // 3. Inject Project Data & Loader Script
        let json_str = serde_json::to_string(&project_data).unwrap();
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
            local_ffmpeg.to_str().unwrap().to_string()
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
            tracing::info!("Teaser generation successful");
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
        let json = serde_json::to_string(&analysis).unwrap();
        assert!(json.contains("\"score\":9.0"));
    }
}