use bytes::Bytes;
use exif;
use fast_image_resize::{
    FilterType, PixelType, ResizeAlg, ResizeOptions, Resizer, images::Image as FrImage,
};
use image::DynamicImage;
use img_parts::riff::{RiffChunk, RiffContent};
use img_parts::webp::WebP;
use once_cell::sync::Lazy;
use regex::Regex;
use sha2::{Digest, Sha256};
use std::io::Cursor;
use std::time::Instant;

use crate::models::*;
use rayon::prelude::*;

// Compile regex once at startup using lazy static
static FILENAME_REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"_(\d{6})_\d{2}_(\d{3})").expect("Invalid regex pattern in source code")
});

/// Extracts a suggested human-readable name from a camera-generated filename.
///
/// Handles naming conventions like `_YYMMDD_XX_NNN` and converts them to
/// `YYMMDD_NNN` for better UX in the editor.
///
/// # Arguments
/// * `original` - The original filename string.
///
/// # Returns
/// A simplified filename string.
pub fn get_suggested_name(original: &str) -> String {
    // Remove extension
    let base_name = std::path::Path::new(original)
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or(original);

    // Try to match the pattern _(\d{6})_\d{2}_(\d{3})
    if let Some(caps) = FILENAME_REGEX.captures(base_name)
        && caps.len() >= 3
    {
        return format!("{}_{}", &caps[1], &caps[2]);
    }

    base_name.to_string()
}

/// Encodes a dynamic image to WebP format.
///
/// # Arguments
/// * `img` - The source image to encode.
/// * `quality` - The WebP quality setting (0.0 to 100.0).
///
/// # Returns
/// A vector of bytes representing the encoded WebP image.
pub fn encode_webp(img: &DynamicImage, quality: f32) -> Result<Vec<u8>, String> {
    let (w, h) = (img.width(), img.height());
    let rgba = img.to_rgba8();
    let encoder = webp::Encoder::from_rgba(&rgba, w, h);
    let webp = encoder.encode(quality);
    Ok(webp.to_vec())
}

/// Fast-resizes an RGBA buffer using Lanczos3 convolution.
///
/// This provides a significantly faster alternative to the standard `image`
/// crate's resize function for large panoramic images.
///
/// # Arguments
/// * `src_rgba` - The source pixel data.
/// * `src_w`/`src_h` - Source dimensions.
/// * `target_width`/`target_height` - Destination dimensions.
///
/// # Returns
/// A vector of bytes containing the resized RGBA data.
pub fn resize_fast_rgba(
    src_rgba: &[u8],
    src_w: u32,
    src_h: u32,
    target_width: u32,
    target_height: u32,
) -> Result<Vec<u8>, String> {
    if target_width == 0 || target_height == 0 {
        return Err("Invalid dimensions".to_string());
    }

    let src_image = FrImage::from_vec_u8(src_w, src_h, src_rgba.to_vec(), PixelType::U8x4)
        .map_err(|e| format!("FastResize Init Error: {:?}", e))?;

    let mut dst_image = FrImage::new(target_width, target_height, PixelType::U8x4);
    let mut resizer = Resizer::new();

    let options = ResizeOptions {
        algorithm: ResizeAlg::Convolution(FilterType::Lanczos3),
        ..Default::default()
    };

    resizer
        .resize(&src_image, &mut dst_image, &options)
        .map_err(|e| format!("FastResize Error: {:?}", e))?;

    Ok(dst_image.into_vec())
}

pub fn resize_fast(
    img: &image::DynamicImage,
    target_width: u32,
    target_height: u32,
) -> Result<image::DynamicImage, String> {
    let rgba = img.to_rgba8();
    let data = resize_fast_rgba(
        &rgba,
        img.width(),
        img.height(),
        target_width,
        target_height,
    )?;

    image::RgbaImage::from_raw(target_width, target_height, data)
        .map(image::DynamicImage::ImageRgba8)
        .ok_or_else(|| "Failed to create RgbaImage from resized data".to_string())
}

/// Performs complete technical analysis and metadata extraction on an image.
///
/// This is the core service function for image processing. It:
/// 1. Computes a SHA-256 checksum for deduplication.
/// 2. Extracts EXIF data (GPS, camera make/model, etc.).
/// 3. Analyzes image quality (blur, exposure, shadows).
/// 4. Checks for existing reMX metadata to avoid re-processing.
///
/// # Arguments
/// * `src_rgba` - Raw RGBA pixels for analysis.
/// * `src_w`/`src_h` - Dimensions.
/// * `input_data` - The original encoded image data (for EXIF and checksum).
/// * `original_filename` - Optional filename for name suggestion.
///
/// # Returns
/// A `MetadataResponse` containing all extracted information and analysis results.
pub fn perform_metadata_extraction_rgba(
    src_rgba: &[u8],
    src_w: u32,
    src_h: u32,
    input_data: &[u8],
    original_filename: Option<&str>,
) -> Result<MetadataResponse, String> {
    // Calculate SHA-256 checksum first (fast in Rust, ~10x faster than JS)
    let checksum_start = Instant::now();
    let mut hasher = Sha256::new();
    hasher.update(input_data);
    let hash_result = hasher.finalize();
    let checksum = format!("{:x}_{}", hash_result, input_data.len());
    let checksum_time = checksum_start.elapsed();
    tracing::debug!(
        "Checksum calculated in {:?}: {}...",
        checksum_time,
        &checksum[..16.min(checksum.len())]
    );

    // 0. Check for existing "reMX" specific metadata (PREVENTION of Re-optimization)
    if let Ok(webp) = WebP::from_bytes(Bytes::copy_from_slice(input_data))
        && let Some(chunk) = webp.chunk_by_id(*b"reMX")
    {
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
                    make: None,
                    model: None,
                    date_time: None,
                    gps: None,
                    width: src_w,
                    height: src_h,
                    focal_length: None,
                    aperture: None,
                    iso: None,
                },
                quality: prev_analysis,
                is_optimized: true,
                checksum: checksum.clone(),
                suggested_name: original_filename.map(get_suggested_name),
            });
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
        make = exif
            .get_field(exif::Tag::Make, exif::In::PRIMARY)
            .map(|f| f.display_value().to_string().replace("\"", ""));
        model = exif
            .get_field(exif::Tag::Model, exif::In::PRIMARY)
            .map(|f| f.display_value().to_string().replace("\"", ""));
        date_time = exif
            .get_field(exif::Tag::DateTimeOriginal, exif::In::PRIMARY)
            .map(|f| f.display_value().to_string());

        focal_length = exif
            .get_field(exif::Tag::FocalLength, exif::In::PRIMARY)
            .and_then(|f| {
                if let exif::Value::Rational(ref v) = f.value {
                    v.first().map(|r| r.to_f64() as f32)
                } else {
                    None
                }
            });
        aperture = exif
            .get_field(exif::Tag::FNumber, exif::In::PRIMARY)
            .and_then(|f| {
                if let exif::Value::Rational(ref v) = f.value {
                    v.first().map(|r| r.to_f64() as f32)
                } else {
                    None
                }
            });
        iso = exif
            .get_field(exif::Tag::PhotographicSensitivity, exif::In::PRIMARY)
            .and_then(|f| f.value.get_uint(0));

        let lat_field = exif.get_field(exif::Tag::GPSLatitude, exif::In::PRIMARY);
        let lat_ref_field = exif.get_field(exif::Tag::GPSLatitudeRef, exif::In::PRIMARY);
        let lon_field = exif.get_field(exif::Tag::GPSLongitude, exif::In::PRIMARY);
        let lon_ref_field = exif.get_field(exif::Tag::GPSLongitudeRef, exif::In::PRIMARY);

        if let (Some(lat), Some(lat_ref), Some(lon), Some(lon_ref)) =
            (lat_field, lat_ref_field, lon_field, lon_ref_field)
        {
            let parse_gps = |f: &exif::Field| -> Option<f64> {
                if let exif::Value::Rational(ref dms) = f.value
                    && dms.len() >= 3
                {
                    let d = dms[0].to_f64();
                    let m = dms[1].to_f64();
                    let s = dms[2].to_f64();
                    return Some(d + m / 60.0 + s / 3600.0);
                }
                None
            };

            if let (Some(mut lat_val), Some(mut lon_val)) = (parse_gps(lat), parse_gps(lon)) {
                if lat_ref.display_value().to_string().contains('S') {
                    lat_val = -lat_val;
                }
                if lon_ref.display_value().to_string().contains('W') {
                    lon_val = -lon_val;
                }
                gps = Some(GpsData {
                    lat: lat_val,
                    lon: lon_val,
                });
            }
        }
    }

    // 2. Quality Analysis
    // OPTIMIZATION: Use fast resize for analysis thumbnail
    let thumb_rgba = resize_fast_rgba(src_rgba, src_w, src_h, 400, 400)
        .map_err(|e| format!("Analysis resize failed: {}", e))?;

    let w = 400u32;
    let h = 400u32;
    let pixel_count = (w * h) as f32;

    // PARALLEL: Generate Gray Pixels Matrix (Preserves Order)
    let gray_pixels: Vec<u8> = thumb_rgba
        .par_chunks(4)
        .map(|chunk| {
            if chunk.len() >= 3 {
                ((chunk[0] as u32 * 54)
                    .saturating_add(chunk[1] as u32 * 183)
                    .saturating_add(chunk[2] as u32 * 19)
                    >> 8) as u8
            } else {
                0
            }
        })
        .collect();

    // PARALLEL: Calculate Histograms
    let (hist_r, hist_g, hist_b, hist_gray, total_lum) = thumb_rgba
        .par_chunks(4)
        .fold(
            || {
                (
                    vec![0u32; 256],
                    vec![0u32; 256],
                    vec![0u32; 256],
                    vec![0u32; 256],
                    0u64,
                )
            },
            |(mut hr, mut hg, mut hb, mut hgray, mut tlum), chunk| {
                if chunk.len() >= 3 {
                    let r = chunk[0] as usize;
                    let g = chunk[1] as usize;
                    let b = chunk[2] as usize;
                    hr[r] += 1;
                    hg[g] += 1;
                    hb[b] += 1;

                    let lum = ((chunk[0] as u32 * 54)
                        .saturating_add(chunk[1] as u32 * 183)
                        .saturating_add(chunk[2] as u32 * 19)
                        >> 8) as u8;
                    hgray[lum as usize] += 1;
                    tlum += lum as u64;
                }
                (hr, hg, hb, hgray, tlum)
            },
        )
        .reduce(
            || {
                (
                    vec![0u32; 256],
                    vec![0u32; 256],
                    vec![0u32; 256],
                    vec![0u32; 256],
                    0u64,
                )
            },
            |mut a, b| {
                for i in 0..256 {
                    a.0[i] += b.0[i];
                    a.1[i] += b.1[i];
                    a.2[i] += b.2[i];
                    a.3[i] += b.3[i];
                }
                a.4 += b.4;
                a
            },
        );

    let avg_lum = (total_lum as f32 / pixel_count) as u32;
    let black_clipping = (hist_gray[0] as f32 / pixel_count) * 100.0;
    let white_clipping = (hist_gray[255] as f32 / pixel_count) * 100.0;

    let y_start = (h as f32 * 0.2) as u32;
    let y_end = (h as f32 * 0.8) as u32;

    // PARALLEL: Laplace Variance Calculation
    let (laplace_sum, laplace_sq_sum, sampled_count) = ((y_start + 1)..(y_end - 1))
        .into_par_iter()
        .map(|y| {
            let mut l_sum = 0.0;
            let mut l_sq_sum = 0.0;
            let mut count = 0;

            for x in 1..(w - 1) {
                let idx = (y * w + x) as usize;
                if idx >= gray_pixels.len() {
                    continue;
                }
                let center = gray_pixels[idx] as i32;
                let lap = gray_pixels[idx - w as usize] as i32
                    + gray_pixels[idx - 1] as i32
                    + gray_pixels[idx + 1] as i32
                    + gray_pixels[idx + w as usize] as i32
                    - 4 * center;

                let lap_val = lap as f64;
                l_sum += lap_val;
                l_sq_sum += lap_val * lap_val;
                count += 1;
            }
            (l_sum, l_sq_sum, count)
        })
        .reduce(
            || (0.0, 0.0, 0u64),
            |a, b| (a.0 + b.0, a.1 + b.1, a.2 + b.2),
        );

    let laplace_var = if sampled_count > 0 {
        let mean = laplace_sum / sampled_count as f64;
        (laplace_sq_sum / sampled_count as f64) - (mean * mean)
    } else {
        0.0
    };

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

    if has_black_clipping {
        score -= 2.0;
        issues += 1;
    }
    if has_white_clipping {
        score -= 2.0;
        issues += 1;
    }
    if is_severely_dark {
        score -= 2.5;
        issues += 1;
    }
    if is_severely_bright {
        score -= 1.5;
        issues += 1;
    }
    if is_blurry {
        score -= 2.0;
        issues += 1;
    }
    if is_dim {
        score -= 1.0;
        warnings += 1;
    }
    if is_soft {
        score -= 1.0;
        warnings += 1;
    }
    if issues == 0 && warnings == 0 {
        score += 1.5;
    }
    score = score.clamp(1.0, 10.0);

    let mut analysis = Vec::new();
    if is_severely_dark {
        analysis.push("Very dark image.");
    }
    if is_severely_bright {
        analysis.push("Very bright image.");
    }
    if has_black_clipping {
        analysis.push("Lost shadow detail.");
    }
    if has_white_clipping {
        analysis.push("Lost highlight detail.");
    }
    if is_blurry {
        analysis.push("Possible blur detected.");
    }
    if is_dim {
        analysis.push("Image appears dim; brighter exposure recommended.");
    }
    if is_soft {
        analysis.push("Slight softness detected; check focus.");
    }

    Ok(MetadataResponse {
        exif: ExifMetadata {
            make,
            model,
            date_time,
            gps,
            width: src_w,
            height: src_h,
            focal_length,
            aperture,
            iso,
        },
        quality: QualityAnalysis {
            score,
            histogram: hist_gray,
            color_hist: ColorHist {
                r: hist_r,
                g: hist_g,
                b: hist_b,
            },
            stats: QualityStats {
                avg_luminance: avg_lum,
                black_clipping,
                white_clipping,
                sharpness_variance: laplace_var as u32,
            },
            is_blurry,
            is_soft,
            is_severely_dark,
            is_severely_bright,
            is_dim,
            has_black_clipping,
            has_white_clipping,
            issues,
            warnings,
            analysis: if analysis.is_empty() {
                None
            } else {
                Some(analysis.join(" "))
            },
        },
        is_optimized: false,
        checksum,
        suggested_name: original_filename.map(get_suggested_name),
    })
}

pub fn perform_metadata_extraction(
    img: &image::DynamicImage,
    input_data: &[u8],
    original_filename: Option<&str>,
) -> Result<MetadataResponse, String> {
    let rgba = img.to_rgba8();
    perform_metadata_extraction_rgba(
        &rgba,
        img.width(),
        img.height(),
        input_data,
        original_filename,
    )
}

/// Injects a custom `reMX` chunk into a WebP file containing metadata JSON.
///
/// This chunk is used to cache processing results directly within the image
/// file, which can be read back by `perform_metadata_extraction_rgba`
/// to prevent redundant computation.
///
/// # Arguments
/// * `webp_data` - The binary content of a WebP file.
/// * `metadata` - The metadata structure to inject.
///
/// # Returns
/// The modified WebP file as binary data.
pub fn inject_remx_chunk(
    webp_data: Vec<u8>,
    metadata: &MetadataResponse,
) -> Result<Vec<u8>, String> {
    let mut webp = WebP::from_bytes(Bytes::from(webp_data)).map_err(|e| e.to_string())?;
    let json = serde_json::to_string(metadata).map_err(|e| e.to_string())?;

    // Create custom chunk "reMX"
    let chunk = RiffChunk::new(*b"reMX", RiffContent::Data(Bytes::from(json)));
    webp.chunks_mut().push(chunk);

    // Encode back to bytes
    let mut writer = Cursor::new(Vec::new());
    webp.encoder()
        .write_to(&mut writer)
        .map_err(|e: std::io::Error| e.to_string())?;
    Ok(writer.into_inner())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_suggested_name_regex() {
        assert_eq!(get_suggested_name("_240114_00_001.jpg"), "240114_001");
        assert_eq!(get_suggested_name("random_file.png"), "random_file");
        // get_suggested_name takes the filename, not the path, but let's see how it handles it
        assert_eq!(
            get_suggested_name("images/_240114_00_001.jpg"),
            "240114_001"
        );
    }

    #[test]
    fn test_checksum_format() {
        let data = b"hello world";
        // We need a valid-ish RGBA buffer for the quality analysis part
        let rgba = vec![0u8; 400 * 400 * 4];
        let res = perform_metadata_extraction_rgba(&rgba, 400, 400, data, None)
            .expect("Metadata extraction failed");

        // sha256 of "hello world" is b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9
        assert!(res.checksum.starts_with("b94d27b9934d3e08"));
        assert!(res.checksum.ends_with("_11")); // "hello world" is 11 bytes
    }

    #[test]
    fn test_blur_detection() {
        // Create a solid gray image (zero variance)
        let w = 400;
        let h = 400;
        let rgba = vec![128u8; (w * h * 4) as usize];
        let data = vec![0u8; 100]; // Dummy input data

        let res = perform_metadata_extraction_rgba(&rgba, w, h, &data, None)
            .expect("Metadata extraction failed");
        assert!(res.quality.is_blurry);
        assert_eq!(res.quality.stats.sharpness_variance, 0);
    }

    #[test]
    fn test_brightness_detection() {
        let w = 400;
        let h = 400;

        // Very dark image
        let mut dark_rgba = vec![0u8; (w * h * 4) as usize];
        for i in 0..(w * h) {
            dark_rgba[(i * 4) as usize] = 10;
            dark_rgba[(i * 4 + 1) as usize] = 10;
            dark_rgba[(i * 4 + 2) as usize] = 10;
            dark_rgba[(i * 4 + 3) as usize] = 255;
        }
        let res_dark = perform_metadata_extraction_rgba(&dark_rgba, w, h, &vec![0], None)
            .expect("Metadata extraction failed");
        assert!(res_dark.quality.is_severely_dark);

        // Very bright image
        let mut bright_rgba = vec![0u8; (w * h * 4) as usize];
        for i in 0..(w * h) {
            bright_rgba[(i * 4) as usize] = 250;
            bright_rgba[(i * 4 + 1) as usize] = 250;
            bright_rgba[(i * 4 + 2) as usize] = 250;
            bright_rgba[(i * 4 + 3) as usize] = 255;
        }
        let res_bright = perform_metadata_extraction_rgba(&bright_rgba, w, h, &vec![0], None)
            .expect("Metadata extraction failed");
        assert!(
            res_bright
                .quality
                .analysis
                .expect("Analysis missing")
                .contains("Very bright")
        );
    }
    #[test]
    fn test_encode_webp_basic() {
        let img = DynamicImage::new_rgba8(100, 100);
        let result = encode_webp(&img, 80.0);
        assert!(result.is_ok());
        let bytes = result.expect("WebP encoding failed");
        assert!(bytes.len() > 0);
        assert_eq!(&bytes[0..4], b"RIFF");
    }
}
