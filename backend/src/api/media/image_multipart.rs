use actix_multipart::Multipart;
use futures_util::TryStreamExt as _;

use crate::api::utils::MAX_UPLOAD_SIZE;
use crate::models::{AppError, ExifMetadata};

pub struct MultipartImageData {
    pub data: Vec<u8>,
    pub filename: Option<String>,
    pub is_optimized: bool,
    pub metadata: Option<ExifMetadata>,
}

async fn read_field_content(field: &mut actix_multipart::Field) -> Result<Vec<u8>, AppError> {
    let mut value = Vec::new();
    while let Some(chunk) = field.try_next().await? {
        value.extend_from_slice(&chunk);
    }
    Ok(value)
}

async fn read_file_field_content(
    field: &mut actix_multipart::Field,
    max_size: usize,
) -> Result<Vec<u8>, AppError> {
    let mut data = Vec::with_capacity(32 * 1024 * 1024);
    let mut total_size = 0;
    while let Some(chunk) = field.try_next().await? {
        total_size += chunk.len();
        if total_size > max_size {
            return Err(AppError::ImageError(format!(
                "Upload exceeds limit of {}MB",
                max_size / (1024 * 1024)
            )));
        }
        data.extend_from_slice(&chunk);
    }
    Ok(data)
}

async fn process_file_field(
    field: &mut actix_multipart::Field,
    original_filename: &mut Option<String>,
) -> Result<Vec<u8>, AppError> {
    if original_filename.is_none() {
        if let Some(cd) = field.content_disposition() {
            if let Some(fname) = cd.get_filename() {
                *original_filename = Some(fname.to_string());
            }
        }
    }
    read_file_field_content(field, MAX_UPLOAD_SIZE).await
}

async fn process_optimized_field(field: &mut actix_multipart::Field) -> Result<bool, AppError> {
    let value = read_field_content(field).await?;
    if let Ok(s) = String::from_utf8(value) {
        Ok(s.to_lowercase() == "true")
    } else {
        Ok(false)
    }
}

async fn process_metadata_field(
    field: &mut actix_multipart::Field,
) -> Result<Option<ExifMetadata>, AppError> {
    let value = read_field_content(field).await?;
    if let Ok(s) = String::from_utf8(value) {
        Ok(serde_json::from_str(&s).ok())
    } else {
        Ok(None)
    }
}

pub async fn read_multipart_image(mut payload: Multipart) -> Result<MultipartImageData, AppError> {
    let mut data = Vec::new();
    let mut filename: Option<String> = None;
    let mut is_optimized = false;
    let mut metadata: Option<ExifMetadata> = None;

    while let Some(mut field) = payload.try_next().await? {
        match field.name().unwrap_or("") {
            "file" => data = process_file_field(&mut field, &mut filename).await?,
            "is_optimized" => is_optimized = process_optimized_field(&mut field).await?,
            "metadata" => metadata = process_metadata_field(&mut field).await?,
            _ => {
                let _ = read_field_content(&mut field).await?;
            }
        }
    }

    Ok(MultipartImageData {
        data,
        filename,
        is_optimized,
        metadata,
    })
}
