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
use std::collections::{HashMap, HashSet};
use rayon::prelude::*;
use img_parts::webp::WebP;
use headless_chrome::{Browser, LaunchOptions};
use std::time::{Duration, Instant};
use img_parts::riff::{RiffContent, RiffChunk};
use bytes::Bytes;
use image::DynamicImage;
use fast_image_resize::{Resizer, ResizeOptions, FilterType, ResizeAlg, PixelType, images::Image as FrImage};
use sha2::{Sha256, Digest};
use once_cell::sync::Lazy;
use regex::Regex;
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

        // Structured error logging
        tracing::error!(
            module = "ErrorHandler",
            error_type = msg,
            details = %self,
            status_code = status.as_u16(),
            "REQUEST_FAILED"
        );

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
#[serde(rename_all = "camelCase")]
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
#[serde(rename_all = "camelCase")]
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
#[serde(rename_all = "camelCase")]
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
#[serde(rename_all = "camelCase")]
pub struct MetadataResponse {
    pub exif: ExifMetadata,
    pub quality: QualityAnalysis,
    pub is_optimized: bool,
    pub checksum: String, // SHA-256 hash in format: {hex}_{filesize}
    pub suggested_name: Option<String>, // Logic moved from frontend
}

// --- Internal Processing Logic (Extracted for reuse) ---

// Compile regex once at startup using lazy static
static FILENAME_REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"_(\d{6})_\d{2}_(\d{3})").expect("Invalid regex pattern in source code")
});

/// Extract a smart filename from the original filename
/// Logic: _YYMMDD_XX_NNN -> YYMMDD_NNN
fn get_suggested_name(original: &str) -> String {
    // Remove extension
    let base_name = std::path::Path::new(original)
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or(original);

    // Try to match the pattern _(\d{6})_\d{2}_(\d{3})
    if let Some(caps) = FILENAME_REGEX.captures(base_name) {
        if caps.len() >= 3 {
            return format!("{}_{}", &caps[1], &caps[2]);
        }
    }

    base_name.to_string()
}

// --- VALIDATION SYSTEM ---

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ValidationReport {
    pub broken_links_removed: u32,
    pub orphaned_scenes: Vec<String>, // Scenes with no incoming links
    pub unused_files: Vec<String>,    // Files in ZIP not used by project
    pub warnings: Vec<String>,
    pub errors: Vec<String>,
}

impl ValidationReport {
    fn new() -> Self {
        ValidationReport {
            broken_links_removed: 0,
            orphaned_scenes: Vec::new(),
            unused_files: Vec::new(),
            warnings: Vec::new(),
            errors: Vec::new(),
        }
    }
    
    fn has_issues(&self) -> bool {
        self.broken_links_removed > 0 
            || !self.orphaned_scenes.is_empty() 
            || !self.unused_files.is_empty()
            || !self.errors.is_empty()
    }
}

/// Validate and clean project data
/// Returns a tuple of (cleaned_project, validation_report)
/// This function takes ownership of the project and returns a new cleaned version
fn validate_and_clean_project(
    project: serde_json::Value,
    available_files: &HashSet<String>
) -> Result<(serde_json::Value, ValidationReport), String> {
    let mut project = project; // Take ownership, now we can mutate locally
    let mut report = ValidationReport::new();
    
    // Extract scenes array
    let scenes = project["scenes"].as_array_mut()
        .ok_or("Invalid project structure: missing 'scenes' array")?;
    
    if scenes.is_empty() {
        report.errors.push("Project has no scenes".to_string());
        return Ok((project, report));
    }
    
    // Build scene name set for validation
    let scene_names: HashSet<String> = scenes.iter()
        .filter_map(|s| s["name"].as_str())
        .map(|s| s.to_string())
        .collect();
    
    tracing::info!(module = "Validator", scene_count = scene_names.len(), "VALIDATION_START");

    let mut incoming_links = HashSet::new();
    // The first scene is the entry point
    if let Some(first_scene_name) = scenes.first().and_then(|s| s["name"].as_str()) {
        incoming_links.insert(first_scene_name.to_string());
    }
    
    // Validate and clean each scene
    for scene in scenes.iter_mut() {
        let scene_name = scene["name"].as_str().unwrap_or("unknown").to_string();
        let mut seen_link_ids = HashSet::new();

        // 1. Check if image file exists in ZIP (check root and images/ folder)
        let mut image_found = false;
        if available_files.contains(&scene_name) || available_files.contains(&format!("images/{}", scene_name)) {
            image_found = true;
        }
        
        if !image_found {
            report.warnings.push(format!("Scene '{}': Image file not found in ZIP", scene_name));
        }

        // 2. Validate hotspots
        if let Some(hotspots) = scene["hotspots"].as_array_mut() {
            let original_count = hotspots.len();
            
            // Remove broken links
            hotspots.retain(|h| {
                if let Some(target) = h["target"].as_str() {
                    let is_valid = scene_names.contains(target);
                    if !is_valid {
                        tracing::warn!("Scene '{}': Removing broken link to '{}'", scene_name, target);
                    } else {
                        incoming_links.insert(target.to_string());
                    }
                    is_valid
                } else {
                    // Hotspot missing target field
                    tracing::warn!("Scene '{}': Removing hotspot with missing target", scene_name);
                    false
                }
            });
            
            let removed = original_count - hotspots.len();
            if removed > 0 {
                report.broken_links_removed += removed as u32;
                report.warnings.push(format!(
                    "Scene '{}': Removed {} broken link(s)",
                    scene_name, removed
                ));
            }

            // Check for duplicate link IDs
            for hotspot in hotspots.iter() {
                if let Some(link_id) = hotspot["linkId"].as_str() {
                    if !seen_link_ids.insert(link_id.to_string()) {
                        report.warnings.push(format!("Scene '{}': Duplicate linkId detected: '{}'", scene_name, link_id));
                    }
                }
            }
        }
        
        // 3. Validate required fields and set defaults
        if scene["id"].is_null() {
            report.warnings.push(format!(
                "Scene '{}': Missing ID, will be auto-generated",
                scene_name
            ));
        }
        
        if scene["category"].is_null() {
            report.warnings.push(format!("Scene '{}': Missing category metadata", scene_name));
            scene["category"] = serde_json::json!("indoor");
        }
        
        if scene["floor"].is_null() {
            report.warnings.push(format!("Scene '{}': Missing floor metadata", scene_name));
            scene["floor"] = serde_json::json!("ground");
        }
    }

    // 4. Check for orphaned scenes (scenes with no incoming links)
    for scene_name in &scene_names {
        if !incoming_links.contains(scene_name) {
             report.orphaned_scenes.push(scene_name.clone());
             report.warnings.push(format!("Orphaned scene detected (no incoming links): '{}'", scene_name));
        }
    }

    // 5. Check for orphaned image files in the ZIP (files not used in project)
    for file in available_files {
        if (file.ends_with(".webp") || file.ends_with(".jpg") || file.ends_with(".jpeg") || file.ends_with(".png")) 
           && !file.starts_with("project.json") {
            
            let base_name = if file.starts_with("images/") {
                file.strip_prefix("images/").unwrap_or(file)
            } else {
                file
            };
            
            if !scene_names.contains(base_name) {
                report.unused_files.push(file.clone());
            }
        }
    }
    
    // Summary logging
    if report.has_issues() {
        tracing::info!(
            "Validation complete: {} broken links removed, {} warnings, {} errors, {} orphaned scenes, {} unused files",
            report.broken_links_removed,
            report.warnings.len(),
            report.errors.len(),
            report.orphaned_scenes.len(),
            report.unused_files.len()
        );
    } else {
        tracing::info!("Validation complete: No issues found");
    }
    
    Ok((project, report))
}

// --- OPTIMIZED HELPERS ---

fn encode_webp(img: &DynamicImage, quality: f32) -> Result<Vec<u8>, String> {
    let (w, h) = (img.width(), img.height());
    let rgba = img.to_rgba8();
    let encoder = webp::Encoder::from_rgba(&rgba, w, h);
    let webp = encoder.encode(quality);
    Ok(webp.to_vec())
}

fn resize_fast_rgba(src_rgba: &[u8], src_w: u32, src_h: u32, target_width: u32, target_height: u32) -> Result<Vec<u8>, String> {
    if target_width == 0 || target_height == 0 {
        return Err("Invalid dimensions".to_string());
    }

    let src_image = FrImage::from_vec_u8(
        src_w,
        src_h,
        src_rgba.to_vec(),
        PixelType::U8x4,
    ).map_err(|e| format!("FastResize Init Error: {:?}", e))?;

    let mut dst_image = FrImage::new(target_width, target_height, PixelType::U8x4);
    let mut resizer = Resizer::new();
    
    let mut options = ResizeOptions::default();
    options.algorithm = ResizeAlg::Convolution(FilterType::Lanczos3);
    
    resizer.resize(&src_image, &mut dst_image, &options)
        .map_err(|e| format!("FastResize Error: {:?}", e))?;
    
    Ok(dst_image.into_vec())
}

fn resize_fast(img: &image::DynamicImage, target_width: u32, target_height: u32) -> Result<image::DynamicImage, String> {
    let rgba = img.to_rgba8();
    let data = resize_fast_rgba(&rgba, img.width(), img.height(), target_width, target_height)?;
    
    image::RgbaImage::from_raw(target_width, target_height, data)
        .map(image::DynamicImage::ImageRgba8)
        .ok_or_else(|| "Failed to create RgbaImage from resized data".to_string())
}

// --- Internal Processing Logic (Extracted for reuse) ---
fn perform_metadata_extraction_rgba(src_rgba: &[u8], src_w: u32, src_h: u32, input_data: &[u8], original_filename: Option<&str>) -> Result<MetadataResponse, String> {
    // Calculate SHA-256 checksum first (fast in Rust, ~10x faster than JS)
    let checksum_start = std::time::Instant::now();
    let mut hasher = Sha256::new();
    hasher.update(input_data);
    let hash_result = hasher.finalize();
    let checksum = format!("{:x}_{}", hash_result, input_data.len());
    let checksum_time = checksum_start.elapsed();
    tracing::debug!("Checksum calculated in {:?}: {}...", checksum_time, &checksum[..16.min(checksum.len())]);

    // 0. Check for existing "reMX" specific metadata (PREVENTION of Re-optimization)
    if let Ok(webp) = WebP::from_bytes(Bytes::copy_from_slice(input_data)) {
        if let Some(chunk) = webp.chunk_by_id(*b"reMX") {
            let data_ref = chunk.content();
            let slice = match data_ref {
                RiffContent::Data(data) => data.as_ref(),
                _ => &[] as &[u8],
            };
            
            if let Ok(mut full_meta) = serde_json::from_slice::<MetadataResponse>(slice) {
                full_meta.is_optimized = true;
                full_meta.checksum = checksum.clone(); // Update with fresh checksum
                full_meta.suggested_name = original_filename.map(get_suggested_name);
                return Ok(full_meta);
            }

            if let Ok(prev_analysis) = serde_json::from_slice::<QualityAnalysis>(slice) {
                  return Ok(MetadataResponse {
                      exif: ExifMetadata {
                        make: None, model: None, date_time: None, gps: None,
                        width: src_w, height: src_h,
                        focal_length: None, aperture: None, iso: None,
                      }, 
                      quality: prev_analysis,
                      is_optimized: true,
                      checksum: checksum.clone(),
                      suggested_name: original_filename.map(get_suggested_name),
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
    // OPTIMIZATION: Use fast resize for analysis thumbnail
    let thumb_rgba = resize_fast_rgba(src_rgba, src_w, src_h, 400, 400).map_err(|e| format!("Analysis resize failed: {}", e))?;
    
    let w = 400u32;
    let h = 400u32;
    let pixel_count = (w * h) as f32;

    let mut hist_r = vec![0u32; 256];
    let mut hist_g = vec![0u32; 256];
    let mut hist_b = vec![0u32; 256];
    let mut hist_gray = vec![0u32; 256];
    let mut total_lum = 0u64;
    let mut gray_pixels = Vec::with_capacity((w * h) as usize);

    for chunk in thumb_rgba.chunks(4) {
        if chunk.len() < 3 { continue; }
        let r = chunk[0] as usize;
        let g = chunk[1] as usize;
        let b = chunk[2] as usize;
        hist_r[r] += 1;
        hist_g[g] += 1;
        hist_b[b] += 1;

        let lum = ((chunk[0] as u32 * 54).saturating_add(chunk[1] as u32 * 183).saturating_add(chunk[2] as u32 * 19) >> 8) as u8;
        hist_gray[lum as usize] += 1;
        total_lum += lum as u64;
        gray_pixels.push(lum);
    }

    let avg_lum = (total_lum as f32 / pixel_count) as u32;
    let black_clipping = (hist_gray[0] as f32 / pixel_count) * 100.0;
    let white_clipping = (hist_gray[255] as f32 / pixel_count) * 100.0;

    let y_start = (h as f32 * 0.2) as u32;
    let y_end = (h as f32 * 0.8) as u32;
    let (laplace_sum, laplace_sq_sum, sampled_count) = ((y_start + 1)..(y_end - 1))
        .flat_map(|y| (1..(w - 1)).map(move |x| (y, x)))
        .filter_map(|(y, x)| {
            let idx = (y * w + x) as usize;
            if idx >= gray_pixels.len() { return None; }
            
            let center = gray_pixels[idx] as i32;
            let lap = gray_pixels[idx - w as usize] as i32 +
                      gray_pixels[idx - 1] as i32 +
                      gray_pixels[idx + 1] as i32 +
                      gray_pixels[idx + w as usize] as i32 - 4 * center;
            
            Some(lap as f64)
        })
        .fold((0.0f64, 0.0f64, 0u64), |(sum, sq_sum, count), lap| {
            (sum + lap, sq_sum + lap * lap, count + 1)
        });

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
            width: src_w, height: src_h,
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
        is_optimized: false,
        checksum,
        suggested_name: original_filename.map(get_suggested_name),
    })
}

fn perform_metadata_extraction(img: &image::DynamicImage, input_data: &[u8], original_filename: Option<&str>) -> Result<MetadataResponse, String> {
    let rgba = img.to_rgba8();
    perform_metadata_extraction_rgba(&rgba, img.width(), img.height(), input_data, original_filename)
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
        let metadata = perform_metadata_extraction_rgba(&src_rgba, src_w, src_h, &data, original_filename.as_deref())?;
        let meta_time = meta_start.elapsed();
        
        // 2. Image Optimization (4K WebP)
        let opt_start = Instant::now();
        let webp_buffer_vec = if metadata.is_optimized && src_w == PROCESSED_IMAGE_WIDTH {
             tracing::info!(module = "Processor", "IMAGE_ALREADY_OPTIMIZED");
             data.clone()
        } else {
            let resized_rgba = resize_fast_rgba(&src_rgba, src_w, src_h, PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH)
                .map_err(|e| format!("Resize failed: {}", e))?;
            
            let encoder = webp::Encoder::from_rgba(&resized_rgba, PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH);
            let webp = encoder.encode(WEBP_QUALITY);
            let buf = webp.to_vec();
            
            inject_remx_chunk(buf, &metadata)?
        };
        let opt_time = opt_start.elapsed();

        let webp_buffer = Cursor::new(webp_buffer_vec);

        // 3. Tiny Preview
        let tiny_start = Instant::now();
        let tiny_rgba = resize_fast_rgba(&src_rgba, src_w, src_h, 512, 512)
            .map_err(|e| format!("Tiny resize failed: {}", e))?;
        let tiny_encoder = webp::Encoder::from_rgba(&tiny_rgba, 512, 512);
        let tiny_bytes = tiny_encoder.encode(60.0).to_vec();
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
        let resized = resize_fast(&img, PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH)
             .map_err(|e| format!("Resize failed: {}", e))?;
        
        let webp_bytes = encode_webp(&resized, WEBP_QUALITY)?;
        
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
                    let resized = resize_fast(&img, *width, *width)
                        .map_err(|e| format!("Resize failed: {}", e))?;
                    
                    let webp_bytes = encode_webp(&resized, WEBP_QUALITY)?;
                    
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
                        
                        let webp_bytes = encode_webp(&resized, WEBP_QUALITY)?;
                        
                        artifacts.push((zip_path, webp_bytes));
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

#[derive(Debug, Serialize, Deserialize)]
pub struct TelemetryEntry {
    pub level: String,
    pub module: String,
    pub message: String,
    pub data: Option<serde_json::Value>,
    pub timestamp: String,
}

// NOTE: LoadProjectResponse is no longer used - we now return ZIP directly
// Keeping for reference during transition period
// #[derive(Serialize)]
// #[serde(rename_all = "camelCase")]
// pub struct LoadProjectResponse {
//     pub session_id: String,
//     pub project_data: serde_json::Value,
// }

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
        
        let (mut validated_project, report) = validate_and_clean_project(project_data, &available_files)?;
        
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
    
    let report = web::block(move || -> Result<ValidationReport, String> {
        use std::io::Read;
        
        let cursor = Cursor::new(&zip_data);
        let mut archive = zip::ZipArchive::new(cursor)
            .map_err(|e| format!("Failed to read ZIP: {}", e))?;
        
        // Collect list of files in ZIP for validation
        let mut available_files = HashSet::new();
        for i in 0..archive.len() {
            if let Ok(file) = archive.by_index(i) {
                available_files.insert(file.name().to_string());
            }
        }

        let mut project_file = archive.by_name("project.json")
            .map_err(|e| format!("Missing project.json: {}", e))?;
        let mut project_json = String::new();
        project_file.read_to_string(&mut project_json)
            .map_err(|e| format!("Failed to read project.json: {}", e))?;
        drop(project_file);
        
        let project_data: serde_json::Value = serde_json::from_str(&project_json)
            .map_err(|e| format!("Invalid project.json: {}", e))?;
        
        let (_validated_project, report) = validate_and_clean_project(project_data, &available_files)?;
        Ok(report)
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
    let result_zip = web::block(move || -> Result<Vec<u8>, String> {
        use std::io::Read;
        
        // Open uploaded ZIP archive
        let cursor = Cursor::new(&zip_data);
        let mut archive = zip::ZipArchive::new(cursor)
            .map_err(|e| format!("Failed to read ZIP: {}", e))?;
        
        // 1. Collect list of files in ZIP for validation
        let mut available_files = HashSet::new();
        for i in 0..archive.len() {
            if let Ok(file) = archive.by_index(i) {
                available_files.insert(file.name().to_string());
            }
        }
        
        // 2. Extract project.json
        let mut project_file = archive.by_name("project.json")
            .map_err(|e| format!("Missing project.json: {}", e))?;
        let mut project_json = String::new();
        project_file.read_to_string(&mut project_json)
            .map_err(|e| format!("Failed to read project.json: {}", e))?;
        drop(project_file);
        
        let project_data: serde_json::Value = serde_json::from_str(&project_json)
            .map_err(|e| format!("Invalid project.json: {}", e))?;
        
        // 3. Validate and clean project
        let (mut validated_project, validation_report) = validate_and_clean_project(project_data, &available_files)?;
        
        // Log validation results
        if validation_report.has_issues() {
            tracing::warn!("Project validation found issues: {} broken links removed", 
                validation_report.broken_links_removed);
        }
        
        // Add validation report to project data
        validated_project["validationReport"] = serde_json::to_value(&validation_report)
            .map_err(|e| format!("Failed to serialize validation report: {}", e))?;
        
        // 4. Create response ZIP containing validated project.json + all images normalized in images/
        let mut response_zip_buffer = Cursor::new(Vec::new());
        {
            let mut zip_writer = zip::ZipWriter::new(&mut response_zip_buffer);
            let options = FileOptions::default()
                .compression_method(zip::CompressionMethod::Stored)
                .unix_permissions(0o755);
            
            // Add validated project.json
            zip_writer.start_file("project.json", options)
                .map_err(|e| e.to_string())?;
            let updated_json = serde_json::to_string_pretty(&validated_project)
                .map_err(|e| e.to_string())?;
            zip_writer.write_all(updated_json.as_bytes())
                .map_err(|e| e.to_string())?;
            
            // Copy all image files, normalizing to images/ folder
            for i in 0..archive.len() {
                let mut file = archive.by_index(i)
                    .map_err(|e| format!("Failed to read file {}: {}", i, e))?;
                
                let filename = file.name().to_string();
                
                // Skip project.json
                if filename == "project.json" {
                    continue;
                }
                
                // Include files in images/ directory or root-level image files
                if filename.starts_with("images/") || 
                   filename.ends_with(".webp") || 
                   filename.ends_with(".jpg") || 
                   filename.ends_with(".jpeg") || 
                   filename.ends_with(".png") {
                    
                    let mut zip_path = filename.clone();
                    // Normalize images into images/ folder if not already there
                    if (filename.ends_with(".webp") || filename.ends_with(".jpg") || filename.ends_with(".jpeg") || filename.ends_with(".png")) 
                       && !filename.starts_with("images/") {
                        zip_path = format!("images/{}", filename);
                    }
                    
                    zip_writer.start_file(&zip_path, options)
                        .map_err(|e| e.to_string())?;
                    
                    let mut buffer = Vec::new();
                    file.read_to_end(&mut buffer)
                        .map_err(|e| e.to_string())?;
                    
                    zip_writer.write_all(&buffer)
                        .map_err(|e| e.to_string())?;
                }
            }
            
            zip_writer.finish()
                .map_err(|e| e.to_string())?;
        }
        
        Ok(response_zip_buffer.into_inner())
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

        perform_metadata_extraction(&img, &data, original_filename.as_deref())
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
        assert_eq!(get_suggested_name("_260113_01_005.jpg"), "260113_005");
        assert_eq!(get_suggested_name("DSC_001.JPG"), "DSC_001");
        assert_eq!(get_suggested_name("plain_file"), "plain_file");
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
}
#[derive(Serialize)]
pub struct ImportResponse {
    pub sessionId: String,
    pub projectData: serde_json::Value,
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
                 sessionId: session_id,
                 projectData: project_data
             }));
        }
    }
    
    Err(AppError::MultipartError(actix_multipart::MultipartError::Incomplete)) // Using existing error variant if applicable or just Incomplete
}
