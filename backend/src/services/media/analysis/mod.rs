use bytes::Bytes;
use img_parts::riff::RiffContent;
use img_parts::webp::WebP;
use sha2::{Digest, Sha256};
use std::time::Instant;

use super::naming::get_suggested_name;
use crate::models::*;

pub mod exif;
pub mod quality;

use self::exif::extract_exif;
use self::quality::analyze_quality;

pub fn perform_metadata_extraction_rgba(
    src_rgba: &[u8],
    src_w: u32,
    src_h: u32,
    input_data: &[u8],
    original_filename: Option<&str>,
) -> Result<MetadataResponse, String> {
    let checkpoint = Instant::now();
    let mut hasher = Sha256::new();
    hasher.update(input_data);
    let hash_result = hasher.finalize();
    let checksum = format!("{:x}_{}", hash_result, input_data.len());

    tracing::debug!(module = "MediaAnalysis", duration_ms = checkpoint.elapsed().as_millis(), checksum = %checksum, "CHECKSUM_CALCULATED");

    // 0. Check for existing "reMX" specific metadata
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
            full_meta.checksum = checksum.clone();
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
    let exif = extract_exif(input_data, src_w, src_h);

    // 2. Quality Analysis
    let quality = analyze_quality(src_rgba, src_w, src_h)?;

    Ok(MetadataResponse {
        exif,
        quality,
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
