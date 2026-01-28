// @efficiency: infra-adapter
/* backend/src/services/media/webp.rs */

use crate::models::MetadataResponse;
use bytes::Bytes;
use image::DynamicImage;
use img_parts::riff::{RiffChunk, RiffContent};
use img_parts::webp::WebP;
use std::io::Cursor;

pub fn encode_webp(img: &DynamicImage, quality: f32) -> Result<Vec<u8>, String> {
    let (w, h) = (img.width(), img.height());
    let rgba = img.to_rgba8();
    let encoder = webp::Encoder::from_rgba(&rgba, w, h);
    let webp = encoder.encode(quality);
    Ok(webp.to_vec())
}

pub fn inject_remx_chunk(
    webp_data: Vec<u8>,
    metadata: &MetadataResponse,
) -> Result<Vec<u8>, String> {
    let mut webp = WebP::from_bytes(Bytes::from(webp_data)).map_err(|e| e.to_string())?;
    let json = serde_json::to_string(metadata).map_err(|e| e.to_string())?;

    let chunk = RiffChunk::new(*b"reMX", RiffContent::Data(Bytes::from(json)));
    webp.chunks_mut().push(chunk);

    let mut writer = Cursor::new(Vec::new());
    webp.encoder()
        .write_to(&mut writer)
        .map_err(|e: std::io::Error| e.to_string())?;
    Ok(writer.into_inner())
}
