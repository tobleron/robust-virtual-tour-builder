use std::io::Cursor;
use std::time::Instant;
use regex::Regex;
use image::DynamicImage;
use img_parts::webp::WebP;
use img_parts::riff::{RiffContent, RiffChunk};
use bytes::Bytes;
use fast_image_resize::{Resizer, ResizeOptions, FilterType, ResizeAlg, PixelType, images::Image as FrImage};
use sha2::{Sha256, Digest};
use once_cell::sync::Lazy;
use exif;

use crate::models::*;

// Compile regex once at startup using lazy static
static FILENAME_REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"_(\d{6})_\d{2}_(\d{3})").expect("Invalid regex pattern in source code")
});

/// Extract a smart filename from the original filename
/// Logic: _YYMMDD_XX_NNN -> YYMMDD_NNN
pub fn get_suggested_name(original: &str) -> String {
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

pub fn encode_webp(img: &DynamicImage, quality: f32) -> Result<Vec<u8>, String> {
    let (w, h) = (img.width(), img.height());
    let rgba = img.to_rgba8();
    let encoder = webp::Encoder::from_rgba(&rgba, w, h);
    let webp = encoder.encode(quality);
    Ok(webp.to_vec())
}

pub fn resize_fast_rgba(src_rgba: &[u8], src_w: u32, src_h: u32, target_width: u32, target_height: u32) -> Result<Vec<u8>, String> {
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

pub fn resize_fast(img: &image::DynamicImage, target_width: u32, target_height: u32) -> Result<image::DynamicImage, String> {
    let rgba = img.to_rgba8();
    let data = resize_fast_rgba(&rgba, img.width(), img.height(), target_width, target_height)?;
    
    image::RgbaImage::from_raw(target_width, target_height, data)
        .map(image::DynamicImage::ImageRgba8)
        .ok_or_else(|| "Failed to create RgbaImage from resized data".to_string())
}

pub fn perform_metadata_extraction_rgba(src_rgba: &[u8], src_w: u32, src_h: u32, input_data: &[u8], original_filename: Option<&str>) -> Result<MetadataResponse, String> {
    // Calculate SHA-256 checksum first (fast in Rust, ~10x faster than JS)
    let checksum_start = Instant::now();
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

pub fn perform_metadata_extraction(img: &image::DynamicImage, input_data: &[u8], original_filename: Option<&str>) -> Result<MetadataResponse, String> {
    let rgba = img.to_rgba8();
    perform_metadata_extraction_rgba(&rgba, img.width(), img.height(), input_data, original_filename)
}

// INJECTION HELPER
pub fn inject_remx_chunk(webp_data: Vec<u8>, metadata: &MetadataResponse) -> Result<Vec<u8>, String> {
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
