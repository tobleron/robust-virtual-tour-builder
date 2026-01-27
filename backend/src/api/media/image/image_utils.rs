/* backend/src/api/media/image_utils.rs */

use crate::api::utils::MAX_UPLOAD_SIZE;
use crate::models::{AppError, ExifMetadata};
use actix_multipart::Multipart;
use futures_util::TryStreamExt as _;

pub struct MultipartImageData {
    pub data: Vec<u8>,
    pub filename: Option<String>,
    pub is_optimized: bool,
    pub metadata: Option<ExifMetadata>,
}

pub async fn read_multipart_image(mut payload: Multipart) -> Result<MultipartImageData, AppError> {
    let mut data = Vec::with_capacity(32 * 1024 * 1024);
    let mut total_size = 0;
    let mut original_filename: Option<String> = None;
    let mut is_optimized_frontend = false;
    let mut frontend_metadata: Option<ExifMetadata> = None;

    while let Some(mut field) = payload.try_next().await? {
        let name = field.name().unwrap_or("").to_string();

        if name == "file" {
            if original_filename.is_none()
                && let Some(content_disposition) = field.content_disposition()
                && let Some(filename) = content_disposition.get_filename()
            {
                original_filename = Some(filename.to_string());
            }

            while let Some(chunk) = field.try_next().await? {
                total_size += chunk.len();
                if total_size > MAX_UPLOAD_SIZE {
                    return Err(AppError::ImageError(format!(
                        "Upload exceeds maximum size of {}MB",
                        MAX_UPLOAD_SIZE / (1024 * 1024)
                    )));
                }
                data.extend_from_slice(&chunk);
            }
        } else if name == "is_optimized" {
            let mut value = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                value.extend_from_slice(&chunk);
            }
            if let Ok(s) = String::from_utf8(value) {
                is_optimized_frontend = s.to_lowercase() == "true";
            }
        } else if name == "metadata" {
            let mut value = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                value.extend_from_slice(&chunk);
            }
            if let Ok(s) = String::from_utf8(value) {
                frontend_metadata = serde_json::from_str(&s).ok();
            }
        }
    }

    Ok(MultipartImageData {
        data,
        filename: original_filename,
        is_optimized: is_optimized_frontend,
        metadata: frontend_metadata,
    })
}
