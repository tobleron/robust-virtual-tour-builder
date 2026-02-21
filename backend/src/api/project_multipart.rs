use actix_multipart::Multipart;
use actix_web::web;
use futures_util::TryStreamExt as _;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use tokio::io::{AsyncWriteExt, BufWriter};
use uuid::Uuid;

use crate::api::utils::{MAX_UPLOAD_SIZE, get_temp_path, sanitize_filename};
use crate::models::AppError;
use crate::services::project::MAX_IMPORT_CHUNK_SIZE_BYTES;

/// Reads a string field from multipart.
pub async fn read_string_field(field: &mut actix_multipart::Field) -> Result<String, AppError> {
    let mut bytes = Vec::new();
    while let Some(chunk) = field.try_next().await? {
        bytes.extend_from_slice(&chunk);
    }
    Ok(String::from_utf8_lossy(&bytes).to_string())
}

/// Helper to save field content to a file asynchronously
async fn save_field_to_file(
    field: &mut actix_multipart::Field,
    path: &Path,
) -> Result<(), AppError> {
    let f = tokio::fs::File::create(path)
        .await
        .map_err(AppError::IoError)?;
    let mut writer = BufWriter::new(f);
    while let Some(chunk) = field.try_next().await? {
        writer.write_all(&chunk).await.map_err(AppError::IoError)?;
    }
    writer.flush().await.map_err(AppError::IoError)?;
    Ok(())
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

    save_field_to_file(field, &temp_img_path).await?;

    Ok((sanitized_name, temp_img_path))
}

/// Parsed multipart payload for a chunk upload request.
pub struct ImportChunkMultipartData {
    pub upload_id: String,
    pub chunk_index: usize,
    pub chunk_byte_length: Option<usize>,
    pub chunk_data: Vec<u8>,
}

/// Parses the multipart payload for saving a project.
pub async fn parse_save_project_multipart(
    mut payload: Multipart,
) -> Result<(Option<String>, Option<String>, Vec<(String, PathBuf)>), AppError> {
    let mut project_json: Option<String> = None;
    let mut session_id: Option<String> = None;
    let mut temp_images: Vec<(String, PathBuf)> = Vec::new();

    let cleanup_temp_images = |images: &Vec<(String, PathBuf)>| {
        for (_, path) in images {
            let _ = fs::remove_file(path);
        }
    };

    loop {
        let next_field = payload.try_next().await;
        let maybe_field = match next_field {
            Ok(next) => next,
            Err(e) => {
                cleanup_temp_images(&temp_images);
                return Err(e.into());
            }
        };

        let Some(mut field) = maybe_field else {
            break;
        };

        let parse_result: Result<(), AppError> = match field.name().unwrap_or("") {
            "project_data" => {
                project_json = Some(read_string_field(&mut field).await?);
                Ok(())
            }
            "files" => {
                temp_images.push(save_temp_file_field(&mut field).await?);
                Ok(())
            }
            "session_id" => {
                session_id = Some(read_string_field(&mut field).await?);
                Ok(())
            }
            _ => {
                let _ = read_string_field(&mut field).await?;
                Ok(())
            }
        };

        if let Err(e) = parse_result {
            cleanup_temp_images(&temp_images);
            return Err(e);
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
            save_field_to_file(&mut field, &tmp_path).await?;
            return Ok(tmp_path);
        }
    }
    Err(AppError::MultipartError(
        actix_multipart::MultipartError::Incomplete.to_string(),
    ))
}

/// Parses the multipart payload for project import chunk upload.
pub async fn parse_import_chunk_multipart(
    mut payload: Multipart,
) -> Result<ImportChunkMultipartData, AppError> {
    let mut upload_id: Option<String> = None;
    let mut chunk_index: Option<usize> = None;
    let mut chunk_byte_length: Option<usize> = None;
    let mut chunk_data: Option<Vec<u8>> = None;

    while let Some(mut field) = payload.try_next().await? {
        match field.name().unwrap_or("") {
            "uploadId" | "upload_id" => {
                upload_id = Some(read_string_field(&mut field).await?);
            }
            "chunkIndex" | "chunk_index" => {
                let raw = read_string_field(&mut field).await?;
                chunk_index = Some(raw.trim().parse::<usize>().map_err(|_| {
                    AppError::ValidationError("Invalid chunkIndex provided".to_string())
                })?);
            }
            "chunkByteLength" | "chunk_byte_length" => {
                let raw = read_string_field(&mut field).await?;
                chunk_byte_length = Some(raw.trim().parse::<usize>().map_err(|_| {
                    AppError::ValidationError("Invalid chunkByteLength provided".to_string())
                })?);
            }
            "chunk" | "file" => {
                let mut bytes = Vec::new();
                while let Some(chunk) = field.try_next().await? {
                    bytes.extend_from_slice(&chunk);
                    if bytes.len() > MAX_IMPORT_CHUNK_SIZE_BYTES {
                        return Err(AppError::ValidationError(format!(
                            "Chunk exceeds maximum size of {} bytes",
                            MAX_IMPORT_CHUNK_SIZE_BYTES
                        )));
                    }
                }
                chunk_data = Some(bytes);
            }
            _ => {
                let _ = read_string_field(&mut field).await?;
            }
        }
    }

    let upload_id = upload_id.ok_or_else(|| {
        AppError::MultipartError("Missing uploadId field in chunk payload".to_string())
    })?;
    let chunk_index = chunk_index.ok_or_else(|| {
        AppError::MultipartError("Missing chunkIndex field in chunk payload".to_string())
    })?;
    let chunk_data = chunk_data.ok_or_else(|| {
        AppError::MultipartError("Missing chunk data in chunk payload".to_string())
    })?;

    Ok(ImportChunkMultipartData {
        upload_id,
        chunk_index,
        chunk_byte_length,
        chunk_data,
    })
}

/// Parses the multipart payload for creating a tour package.
pub async fn parse_tour_package_multipart(
    mut payload: Multipart,
) -> Result<(Vec<(String, PathBuf)>, HashMap<String, String>), AppError> {
    let mut image_files = Vec::new();
    let mut fields = HashMap::new();

    while let Some(mut field) = payload.try_next().await? {
        let name = field.name().unwrap_or("unknown").to_string();

        if [
            "html_4k",
            "html_2k",
            "html_hd",
            "html_desktop_2k_blob",
            "html_index",
            "embed_codes",
            "project_data",
            "scene_policy",
        ]
        .contains(&name.as_str())
        {
            fields.insert(name, read_string_field(&mut field).await?);
        } else {
            // Use existing helper to stream to file
            image_files.push(save_temp_file_field(&mut field).await?);
        }
    }
    Ok((image_files, fields))
}

/// Saves the entire multipart payload to a temporary file (used for loading project zip).
pub async fn save_multipart_to_tempfile(mut payload: Multipart) -> Result<fs::File, AppError> {
    let temp_upload = web::block(|| tempfile::tempfile())
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))?
        .map_err(AppError::IoError)?;

    let async_file = tokio::fs::File::from_std(temp_upload);
    let mut uploaded_size = 0;
    let mut writer = BufWriter::new(async_file);

    while let Some(mut field) = payload.try_next().await? {
        while let Some(chunk) = field.try_next().await? {
            uploaded_size += chunk.len();
            if uploaded_size > MAX_UPLOAD_SIZE {
                return Err(AppError::ImageError("Project too large".into()));
            }
            writer.write_all(&chunk).await.map_err(AppError::IoError)?;
        }
    }
    writer.flush().await.map_err(AppError::IoError)?;
    Ok(writer.into_inner().into_std().await)
}
