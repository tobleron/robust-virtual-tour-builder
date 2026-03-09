// @efficiency-role: infra-adapter
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

pub(super) async fn read_string_field(
    field: &mut actix_multipart::Field,
) -> Result<String, AppError> {
    let mut bytes = Vec::new();
    while let Some(chunk) = field.try_next().await? {
        bytes.extend_from_slice(&chunk);
    }
    Ok(String::from_utf8_lossy(&bytes).to_string())
}

pub(super) async fn save_field_to_file(
    field: &mut actix_multipart::Field,
    path: &Path,
) -> Result<(), AppError> {
    let file = tokio::fs::File::create(path)
        .await
        .map_err(AppError::IoError)?;
    let mut writer = BufWriter::new(file);
    while let Some(chunk) = field.try_next().await? {
        writer.write_all(&chunk).await.map_err(AppError::IoError)?;
    }
    writer.flush().await.map_err(AppError::IoError)?;
    Ok(())
}

pub(super) async fn save_temp_file_field(
    field: &mut actix_multipart::Field,
) -> Result<(String, PathBuf), AppError> {
    let filename = field
        .content_disposition()
        .and_then(|content_disposition| content_disposition.get_filename())
        .map(|filename| filename.to_string())
        .unwrap_or_else(|| format!("img_{}.webp", Uuid::new_v4()));
    let sanitized_name =
        sanitize_filename(&filename).unwrap_or_else(|_| format!("img_{}.webp", Uuid::new_v4()));
    let temp_img_path = get_temp_path("tmp");

    super::save_field_to_file(field, &temp_img_path).await?;

    Ok((sanitized_name, temp_img_path))
}

pub(super) async fn parse_save_project_multipart(
    payload: &mut Multipart,
) -> Result<(Option<String>, Option<String>, Vec<(String, PathBuf)>), AppError> {
    let mut project_json: Option<String> = None;
    let mut session_id: Option<String> = None;
    let mut temp_images: Vec<(String, PathBuf)> = Vec::new();

    loop {
        let next_field = payload.try_next().await;
        let maybe_field = match next_field {
            Ok(next) => next,
            Err(error) => {
                cleanup_temp_images(&temp_images);
                return Err(error.into());
            }
        };

        let Some(mut field) = maybe_field else {
            break;
        };

        let parse_result: Result<(), AppError> = match field.name().unwrap_or("") {
            "project_data" => {
                project_json = Some(super::read_string_field(&mut field).await?);
                Ok(())
            }
            "files" => {
                temp_images.push(super::save_temp_file_field(&mut field).await?);
                Ok(())
            }
            "session_id" => {
                session_id = Some(super::read_string_field(&mut field).await?);
                Ok(())
            }
            _ => {
                let _ = super::read_string_field(&mut field).await?;
                Ok(())
            }
        };

        if let Err(error) = parse_result {
            cleanup_temp_images(&temp_images);
            return Err(error);
        }
    }

    Ok((project_json, session_id, temp_images))
}

pub(super) async fn extract_file_from_multipart(
    payload: &mut Multipart,
    ext: &str,
) -> Result<PathBuf, AppError> {
    while let Ok(Some(mut field)) = payload.try_next().await {
        if field.name() == Some("file") {
            let tmp_path = get_temp_path(ext);
            super::save_field_to_file(&mut field, &tmp_path).await?;
            return Ok(tmp_path);
        }
    }

    Err(AppError::MultipartError(
        actix_multipart::MultipartError::Incomplete.to_string(),
    ))
}

pub(super) async fn parse_tour_package_multipart(
    payload: &mut Multipart,
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
            "publish_profiles",
            "scene_policy",
        ]
        .contains(&name.as_str())
        {
            fields.insert(name, super::read_string_field(&mut field).await?);
        } else {
            image_files.push(super::save_temp_file_field(&mut field).await?);
        }
    }

    Ok((image_files, fields))
}

pub(super) async fn save_multipart_to_tempfile(
    payload: &mut Multipart,
) -> Result<fs::File, AppError> {
    let temp_upload = web::block(tempfile::tempfile)
        .await
        .map_err(|error| AppError::InternalError(error.to_string()))?
        .map_err(AppError::IoError)?;

    let async_file = tokio::fs::File::from_std(temp_upload);
    let mut uploaded_size = 0usize;
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

fn cleanup_temp_images(images: &[(String, PathBuf)]) {
    for (_, path) in images {
        let _ = fs::remove_file(path);
    }
}
