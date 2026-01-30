use actix_multipart::Multipart;
use futures_util::TryStreamExt as _;
use std::collections::HashMap;
use std::fs;
use std::io::Write;
use std::path::PathBuf;
use uuid::Uuid;

use crate::api::utils::{MAX_UPLOAD_SIZE, get_temp_path, sanitize_filename};
use crate::models::AppError;

/// Reads a string field from multipart.
pub async fn read_string_field(field: &mut actix_multipart::Field) -> Result<String, AppError> {
    let mut bytes = Vec::new();
    while let Some(chunk) = field.try_next().await? {
        bytes.extend_from_slice(&chunk);
    }
    Ok(String::from_utf8_lossy(&bytes).to_string())
}

/// Saves a file field to a temporary file.
pub async fn save_temp_file_field(
    field: &mut actix_multipart::Field,
) -> Result<(String, PathBuf), AppError> {
    let filename = field
        .content_disposition()
        .and_then(|cd| cd.get_filename())
        .map(|f| f.to_string())
        .unwrap_or_else(|| format!("img_{}.webp", Uuid::new_v4()));
    let sanitized_name =
        sanitize_filename(&filename).unwrap_or_else(|_| format!("img_{}.webp", Uuid::new_v4()));
    let temp_img_path = get_temp_path("tmp");
    let mut f = fs::File::create(&temp_img_path).map_err(AppError::IoError)?;
    while let Some(chunk) = field.try_next().await? {
        f.write_all(&chunk).map_err(AppError::IoError)?;
    }
    Ok((sanitized_name, temp_img_path))
}

/// Parses the multipart payload for saving a project.
pub async fn parse_save_project_multipart(
    mut payload: Multipart,
) -> Result<(Option<String>, Option<String>, Vec<(String, PathBuf)>), AppError> {
    let mut project_json: Option<String> = None;
    let mut session_id: Option<String> = None;
    let mut temp_images: Vec<(String, PathBuf)> = Vec::new();

    while let Some(mut field) = payload.try_next().await? {
        match field.name().unwrap_or("") {
            "project_data" => project_json = Some(read_string_field(&mut field).await?),
            "files" => temp_images.push(save_temp_file_field(&mut field).await?),
            "session_id" => session_id = Some(read_string_field(&mut field).await?),
            _ => {
                let _ = read_string_field(&mut field).await?;
            }
        }
    }
    Ok((project_json, session_id, temp_images))
}

/// Extracts a single file from multipart payload based on extension logic (creates temp path).
pub async fn extract_file_from_multipart(
    mut payload: Multipart,
    ext: &str,
) -> Result<PathBuf, AppError> {
    while let Ok(Some(mut field)) = payload.try_next().await {
        if field.name() == Some("file") {
            let tmp_path = get_temp_path(ext);
            let mut f = fs::File::create(&tmp_path).map_err(AppError::IoError)?;
            while let Ok(Some(chunk)) = field.try_next().await {
                f.write_all(&chunk).map_err(AppError::IoError)?;
            }
            return Ok(tmp_path);
        }
    }
    Err(AppError::MultipartError(
        actix_multipart::MultipartError::Incomplete.to_string(),
    ))
}

/// Parses the multipart payload for creating a tour package.
pub async fn parse_tour_package_multipart(
    mut payload: Multipart,
) -> Result<(Vec<(String, Vec<u8>)>, HashMap<String, String>), AppError> {
    let mut image_files = Vec::new();
    let mut fields = HashMap::new();

    while let Some(mut field) = payload.try_next().await? {
        let name = field.name().unwrap_or("unknown").to_string();

        if ["html_4k", "html_2k", "html_hd", "html_index", "embed_codes"].contains(&name.as_str()) {
            fields.insert(name, read_string_field(&mut field).await?);
        } else {
            // It's a file
            let filename = field
                .content_disposition()
                .and_then(|cd| cd.get_filename())
                .map(|f| f.to_string())
                .unwrap_or_else(|| name.clone());

            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            image_files.push((filename, bytes));
        }
    }
    Ok((image_files, fields))
}

/// Saves the entire multipart payload to a temporary file (used for loading project zip).
pub async fn save_multipart_to_tempfile(
    mut payload: Multipart,
) -> Result<fs::File, AppError> {
    let mut temp_upload = tempfile::tempfile().map_err(AppError::IoError)?;
    let mut uploaded_size = 0;
    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
            uploaded_size += chunk.len();
            if uploaded_size > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError("Project too large".into()));
            }
            temp_upload.write_all(&chunk).map_err(AppError::IoError)?;
        }
    }
    Ok(temp_upload)
}
