// @efficiency: util-pure
use crate::api::utils::{MAX_UPLOAD_SIZE, sanitize_filename};
use crate::models::AppError;
use actix_multipart::Multipart;
use futures_util::TryStreamExt as _;
use std::collections::HashMap;

pub async fn parse_export_multipart(
    mut payload: Multipart,
) -> Result<(Vec<(String, Vec<u8>)>, HashMap<String, String>), AppError> {
    let mut fields: HashMap<String, String> = HashMap::new();
    let mut image_files: Vec<(String, Vec<u8>)> = Vec::new();
    let mut current_total_size = 0;

    while let Some(mut field) = payload.try_next().await? {
        let content_disposition =
            field
                .content_disposition()
                .cloned()
                .ok_or(AppError::InternalError(
                    "Missing content disposition".into(),
                ))?;
        let name = content_disposition
            .get_name()
            .unwrap_or("unknown")
            .to_string();
        let filename = content_disposition.get_filename().map(|f| f.to_string());

        let mut data = Vec::new();
        while let Some(chunk) = field.try_next().await? {
            current_total_size += chunk.len();
            if current_total_size > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError(format!(
                    "Total upload size exceeds maximum of {}MB",
                    MAX_UPLOAD_SIZE / (1024 * 1024)
                )));
            }
            data.extend_from_slice(&chunk);
        }

        if let Some(fname) = filename {
            let sanitized_name = sanitize_filename(&fname).map_err(|e| {
                AppError::InternalError(format!("Invalid filename '{}': {}", fname, e))
            })?;
            image_files.push((sanitized_name, data));
        } else {
            let value_str = String::from_utf8_lossy(&data).to_string();
            fields.insert(name, value_str);
        }
    }
    Ok((image_files, fields))
}
