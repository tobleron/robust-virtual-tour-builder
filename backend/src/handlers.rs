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

// Configs
const PROCESSED_IMAGE_WIDTH: u32 = 4096;
const TEMP_DIR: &str = "/tmp/remax_backend";

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

// --- Helpers ---

fn get_temp_path(extension: &str) -> PathBuf {
    let mut path = PathBuf::from(TEMP_DIR);
    if !path.exists() {
        fs::create_dir_all(&path).unwrap_or_default();
    }
    path.push(format!("{}.{}", Uuid::new_v4(), extension));
    path
}

// --- Metadata Structs ---

#[derive(Debug, Serialize, Deserialize)]
pub struct GpsData {
    pub lat: f64,
    pub lon: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ExifMetadata {
    pub make: Option<String>,
    pub model: Option<String>,
    pub date_time: Option<String>,
    pub gps: Option<GpsData>,
    pub width: u32,
    pub height: u32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct QualityStats {
    pub avg_luminance: u32,
    pub black_clipping: f32,
    pub white_clipping: f32,
    pub sharpness_variance: u32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ColorHist {
    pub r: Vec<u32>,
    pub g: Vec<u32>,
    pub b: Vec<u32>,
}

#[derive(Debug, Serialize, Deserialize)]
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

#[derive(Debug, Serialize, Deserialize)]
pub struct MetadataResponse {
    pub exif: ExifMetadata,
    pub quality: QualityAnalysis,
}

// --- Internal Processing Logic (Extracted for reuse) ---

fn perform_metadata_extraction(img: &image::DynamicImage, input_data: &[u8]) -> Result<MetadataResponse, String> {
    // 1. Parse EXIF
    let mut reader = Cursor::new(input_data);
    let exif_reader = exif::Reader::new();
    let exif_data = exif_reader.read_from_container(&mut reader).ok();

    let mut make = None;
    let mut model = None;
    let mut date_time = None;
    let mut gps = None;

    if let Some(exif) = exif_data {
        make = exif.get_field(exif::Tag::Make, exif::In::PRIMARY).map(|f| f.display_value().to_string().replace("\"", ""));
        model = exif.get_field(exif::Tag::Model, exif::In::PRIMARY).map(|f| f.display_value().to_string().replace("\"", ""));
        date_time = exif.get_field(exif::Tag::DateTimeOriginal, exif::In::PRIMARY).map(|f| f.display_value().to_string());

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
    
    // OPTIMIZATION: Use thumbnail() - it's faster than resize() for large downscales
    let analyzed_img = img.thumbnail(400, 400);
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
        let lum = ((pixel[0] as u32 * 54 + pixel[1] as u32 * 183 + pixel[2] as u32 * 19) >> 8) as u8;
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
        }
    })
}

// --- Handlers ---

#[tracing::instrument(skip(payload), name = "process_image_full")]
pub async fn process_image_full(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    // PERFORMANCE: Pre-allocate buffer for typical 30MB panoramic images
    let mut data = Vec::with_capacity(32 * 1024 * 1024);
    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
            data.extend_from_slice(&chunk);
        }
    }

    let result_zip = web::block(move || -> Result<Vec<u8>, String> {
        let img = image::ImageReader::new(Cursor::new(&data))
            .with_guessed_format()
            .map_err(|e| format!("Failed to guess format: {}", e))?
            .decode()
            .map_err(|e| format!("Failed to decode image: {}", e))?;

        // 1. Metadata Extraction
        let metadata = perform_metadata_extraction(&img, &data)?;
        
        // 2. Image Optimization (4K WebP + Tiny 512px Progressive Preview)
        let resized = img.resize(PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH, image::imageops::FilterType::Lanczos3);
        let mut webp_buffer = Cursor::new(Vec::new());
        resized.write_to(&mut webp_buffer, image::ImageFormat::WebP)
            .map_err(|e| format!("Failed to encode WebP: {}", e))?;

        let tiny = img.thumbnail(512, 512);
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
    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
            data.extend_from_slice(&chunk);
        }
    }

    let result_bytes = web::block(move || -> Result<Vec<u8>, String> {
        let img = image::ImageReader::new(Cursor::new(data))
            .with_guessed_format()
            .map_err(|e| format!("Failed to guess format: {}", e))?
            .decode()
            .map_err(|e| format!("Failed to decode image: {}", e))?;
        
        // Use Lanczos3 for absolute sharpness in editor previews
        let resized = img.resize(PROCESSED_IMAGE_WIDTH, PROCESSED_IMAGE_WIDTH, image::imageops::FilterType::Lanczos3);
        
        let mut webp_buffer = Cursor::new(Vec::new());
        resized.write_to(&mut webp_buffer, image::ImageFormat::WebP)
            .map_err(|e| format!("Failed to encode WebP: {}", e))?;
        
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
    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
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
                    let resized = img.resize(*width, *width, image::imageops::FilterType::Lanczos3);
                    
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

    // 1. Parse Multipart into Memory
    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field.content_disposition().unwrap().clone();
        let name = content_disposition.get_name().unwrap_or("unknown").to_string();
        let filename = content_disposition.get_filename().map(|f| f.to_string());

        let mut data = Vec::new();
        while let Some(chunk) = field.try_next().await? {
            data.extend_from_slice(&chunk);
        }

        if let Some(fname) = filename {
            let sanitized_name: String = fname.replace("..", "").replace("/", "_");
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
                        let resized = img.resize(width, width, image::imageops::FilterType::Lanczos3);
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

#[tracing::instrument(skip(payload), name = "log_telemetry")]
pub async fn log_telemetry(payload: web::Json<TelemetryPayload>) -> Result<HttpResponse, AppError> {
    let log_dir = std::path::Path::new("../logs");
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
    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
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
    
    // Save upload to disk
    while let Some(mut field) = payload.try_next().await? {
        let mut f = fs::File::create(&input_path)?;
        while let Some(chunk) = field.try_next().await? {
            f.write_all(&chunk)?;
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