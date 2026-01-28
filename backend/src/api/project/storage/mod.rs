/* backend/src/api/project/storage/mod.rs - Facade for Project Storage API */

use actix_multipart::Multipart;
use actix_web::{HttpRequest, HttpResponse, web};
use futures_util::TryStreamExt as _;
use serde::Serialize;
use std::fs;
use std::io::{Seek, SeekFrom, Write};
use std::path::PathBuf;
use uuid::Uuid;

use crate::api::utils::{
    MAX_UPLOAD_SIZE, SESSIONS_DIR, TEMP_DIR, get_temp_path, sanitize_filename,
};
use crate::models::AppError;
use crate::services::project;

mod storage_logic;
use storage_logic::*;

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportResponse {
    pub session_id: String,
    pub project_data: serde_json::Value,
}

/// Saves the current project state into a ZIP file.
#[tracing::instrument(skip(payload), name = "save_project")]
pub async fn save_project(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "ProjectManager", "SAVE_PROJECT_START");
    let start = std::time::Instant::now();
    let zip_path = get_temp_path("zip");

    let mut project_json: Option<String> = None;
    let mut session_id: Option<String> = None;
    let mut temp_images: Vec<(String, PathBuf)> = Vec::new();

    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field
            .content_disposition()
            .ok_or_else(|| AppError::InternalError("Missing content disposition".into()))?;
        let name = content_disposition
            .get_name()
            .unwrap_or("unknown")
            .to_string();

        if name == "project_data" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            project_json = Some(String::from_utf8_lossy(&bytes).to_string());
        } else if name == "files" {
            let filename = content_disposition
                .get_filename()
                .map(|f| f.to_string())
                .unwrap_or_else(|| format!("img_{}.webp", Uuid::new_v4()));
            let sanitized_name = sanitize_filename(&filename)
                .unwrap_or_else(|_| format!("img_{}.webp", Uuid::new_v4()));

            let temp_img_path = get_temp_path("tmp");
            let mut f = fs::File::create(&temp_img_path).map_err(AppError::IoError)?;

            while let Some(chunk) = field.try_next().await? {
                f.write_all(&chunk).map_err(AppError::IoError)?;
            }
            temp_images.push((sanitized_name, temp_img_path));
        } else if name == "session_id" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            session_id = Some(String::from_utf8_lossy(&bytes).to_string());
        }
    }

    let json_content = project_json
        .ok_or_else(|| AppError::MultipartError(actix_multipart::MultipartError::Incomplete))?;

    let (validated_json, _report, summary_content) = web::block({
        let temp_images = temp_images.clone();
        let session_id = session_id.clone();
        move || validate_project_full_sync(json_content, temp_images, session_id)
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))??;

    let final_zip_path = zip_path.clone();
    let zip_creation_result = web::block({
        let validated_json = validated_json.clone();
        let session_id = session_id.clone();
        move || {
            create_project_zip_sync(
                final_zip_path,
                validated_json,
                summary_content,
                temp_images,
                session_id,
            )
        }
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))?;

    let duration = start.elapsed().as_millis();
    match zip_creation_result {
        Ok(_) => {
            let file_bytes = fs::read(&zip_path).map_err(AppError::IoError)?;
            let _ = fs::remove_file(&zip_path);

            tracing::info!(
                module = "ProjectManager",
                duration_ms = duration,
                "SAVE_PROJECT_COMPLETE"
            );

            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(file_bytes))
        }
        Err(e) => {
            let _ = fs::remove_file(&zip_path);
            tracing::error!(module = "ProjectManager", duration_ms = duration, error = %e, "SAVE_PROJECT_FAILED");
            Err(e.into())
        }
    }
}

/// Loads a project ZIP file into memory and processes its content.
#[tracing::instrument(skip(payload, req), name = "load_project")]
pub async fn load_project(
    req: HttpRequest,
    mut payload: Multipart,
) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "ProjectManager", "LOAD_PROJECT_START");
    let start = std::time::Instant::now();

    // Use anonymous temp file for the upload to ensure cleanup on drop
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

    // Rewind for reading
    temp_upload
        .seek(SeekFrom::Start(0))
        .map_err(AppError::IoError)?;

    let result_zip_file = web::block(move || project::process_uploaded_project_zip(temp_upload))
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))??;

    let duration = start.elapsed().as_millis();
    tracing::info!(
        module = "ProjectManager",
        duration_ms = duration,
        "LOAD_PROJECT_COMPLETE"
    );

    // Reopen the file to stream it back (this creates a new independent handle).
    // Even if NamedTempFile drops and unlinks the file, the open handle remains valid on Unix.
    let file = result_zip_file.reopen().map_err(AppError::IoError)?;
    let named_file = actix_files::NamedFile::from_file(file, "project.zip")?;

    Ok(named_file.into_response(&req))
}

/// Imports a project ZIP and establishes a server-side session.
pub async fn import_project(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    let session_id = Uuid::new_v4().to_string();
    let session_dir = PathBuf::from(format!("{}/{}", SESSIONS_DIR, session_id));
    fs::create_dir_all(&session_dir).map_err(AppError::IoError)?;

    tracing::info!(module = "ProjectManager", session_id = %session_id, "IMPORT_PROJECT_START");

    while let Ok(Some(mut field)) = payload.try_next().await {
        let name = field
            .content_disposition()
            .and_then(|cd| cd.get_name())
            .unwrap_or("unknown");

        if name == "file" {
            let tmp_path = format!("{}/{}_upload.zip", TEMP_DIR, session_id);
            fs::create_dir_all(TEMP_DIR).map_err(AppError::IoError)?;

            let mut f = fs::File::create(&tmp_path).map_err(AppError::IoError)?;
            while let Ok(Some(chunk)) = field.try_next().await {
                f.write_all(&chunk).map_err(AppError::IoError)?;
            }

            // Unzip
            let file = fs::File::open(&tmp_path).map_err(AppError::IoError)?;
            let mut archive =
                zip::ZipArchive::new(file).map_err(|e| AppError::ZipError(e.to_string()))?;

            for i in 0..archive.len() {
                let mut file = archive
                    .by_index(i)
                    .map_err(|e| AppError::ZipError(e.to_string()))?;
                let outpath = match file.enclosed_name() {
                    Some(path) => {
                        // Strip 'images/' prefix if present to normalize structure
                        let mut components = path.components();
                        let first = components.next();
                        let final_path = if let Some(std::path::Component::Normal(c)) = first
                            && c == "images"
                        {
                            components.as_path()
                        } else {
                            path
                        };
                        session_dir.join(final_path)
                    }
                    None => continue,
                };

                if file.name().ends_with('/') {
                    fs::create_dir_all(&outpath).map_err(AppError::IoError)?;
                } else {
                    if let Some(p) = outpath.parent()
                        && !p.exists()
                    {
                        fs::create_dir_all(p).map_err(AppError::IoError)?;
                    }
                    let mut outfile = fs::File::create(&outpath).map_err(AppError::IoError)?;
                    std::io::copy(&mut file, &mut outfile).map_err(AppError::IoError)?;
                }
            }

            let _ = fs::remove_file(&tmp_path);

            let project_json_path = session_dir.join("project.json");
            if !project_json_path.exists() {
                return Err(AppError::InternalError(
                    "project.json not found in archive".into(),
                ));
            }

            let json_str = fs::read_to_string(project_json_path).map_err(AppError::IoError)?;
            let project_data: serde_json::Value = serde_json::from_str(&json_str)
                .map_err(|e| AppError::InternalError(e.to_string()))?;

            tracing::info!(module = "ProjectManager", session_id = %session_id, "IMPORT_PROJECT_SUCCESS");

            return Ok(HttpResponse::Ok().json(ImportResponse {
                session_id,
                project_data,
            }));
        }
    }

    Err(AppError::MultipartError(
        actix_multipart::MultipartError::Incomplete,
    ))
}
