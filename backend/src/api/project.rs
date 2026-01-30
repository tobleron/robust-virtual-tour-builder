/* backend/src/api/project.rs - Consolidated Project API */

use actix_multipart::Multipart;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use futures_util::TryStreamExt as _;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::io::{Read, Seek, SeekFrom, Write};
use std::path::PathBuf;
use uuid::Uuid;

use crate::api::project_logic;
use crate::api::utils::{MAX_UPLOAD_SIZE, get_temp_path, sanitize_filename};
use crate::models::{AppError, User};
use crate::pathfinder::PathRequest;
use crate::services::media::StorageManager;
use crate::services::project;

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportResponse {
    pub session_id: String,
    pub project_data: serde_json::Value,
}

// --- STORAGE HANDLERS ---

/// Saves the current project state into a ZIP file.
#[tracing::instrument(skip(payload, req), name = "save_project")]
pub async fn save_project(req: HttpRequest, payload: Multipart) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    tracing::info!(module = "ProjectManager", user_id = %user.id, "SAVE_PROJECT_START");
    let start = std::time::Instant::now();
    let zip_path = get_temp_path("zip");

    let (project_json, session_id, temp_images) = parse_save_project_multipart(payload).await?;

    let json_content = project_json.ok_or_else(|| {
        AppError::MultipartError(actix_multipart::MultipartError::Incomplete.to_string())
    })?;
    let project_path = session_id
        .as_ref()
        .map(|pid| StorageManager::get_user_project_path(&user.id, pid));

    let (validated_json, _report, summary_content) = web::block({
        let temp_images = temp_images.clone();
        let project_path = project_path.clone();
        move || project_logic::validate_project_full_sync(json_content, temp_images, project_path)
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))??;

    let final_zip_path = zip_path.clone();
    let zip_creation_result = web::block({
        let validated_json = validated_json.clone();
        let project_path = project_path.clone();
        move || {
            project_logic::create_project_zip_sync(
                final_zip_path,
                validated_json,
                summary_content,
                temp_images,
                project_path,
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
            Err(e.into())
        }
    }
}

/// Loads a project ZIP file into memory.
pub async fn load_project(
    req: HttpRequest,
    mut payload: Multipart,
) -> Result<HttpResponse, AppError> {
    let _user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
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
    temp_upload
        .seek(SeekFrom::Start(0))
        .map_err(AppError::IoError)?;
    let result_zip_file = web::block(move || project::process_uploaded_project_zip(temp_upload))
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))??;
    let file = result_zip_file.reopen().map_err(AppError::IoError)?;
    let named_file = actix_files::NamedFile::from_file(file, "project.zip")?;
    Ok(named_file.into_response(&req))
}

/// Imports a project ZIP and establishes a persistent project.
pub async fn import_project(
    req: HttpRequest,
    payload: Multipart,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;

    // Extract file from payload
    let tmp_path = extract_file_from_multipart(payload, "zip").await?;

    // Extract metadata
    let (project_id, project_data) = extract_project_metadata_from_zip(&tmp_path)?;

    let project_dir =
        StorageManager::ensure_project_dir(&user.id, &project_id).map_err(AppError::IoError)?;

    extract_zip_to_project_dir(&tmp_path, &project_dir)?;

    let _ = fs::remove_file(&tmp_path);
    return Ok(HttpResponse::Ok().json(ImportResponse {
        session_id: project_id,
        project_data,
    }));
}

// --- NAVIGATION HANDLERS ---

/// Calculates a traversal path based on the requested strategy.
#[tracing::instrument(skip(payload), name = "calculate_path")]
pub async fn calculate_path(payload: web::Json<PathRequest>) -> Result<HttpResponse, AppError> {
    let request = payload.into_inner();
    let result = web::block(move || crate::pathfinder::calculate_path(request))
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))?;
    match result {
        Ok(steps) => Ok(HttpResponse::Ok().json(steps)),
        Err(e) => Err(AppError::InternalError(e)),
    }
}

// --- VALIDATION HANDLERS ---

#[derive(Deserialize)]
pub struct ValidatePayload {
    #[serde(rename = "sessionId")]
    pub session_id: String,
    pub data: serde_json::Value,
}

/// Validates project data and available scenes.
pub async fn validate_project(
    req: HttpRequest,
    payload: web::Json<ValidatePayload>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let payload = payload.into_inner();
    let project_path = StorageManager::get_user_project_path(&user.id, &payload.session_id);

    let result = web::block(move || {
        let mut available_files = HashSet::new();
        if let Ok(entries) = fs::read_dir(project_path.join("images")) {
            for entry in entries.flatten() {
                if let Ok(name) = entry.file_name().into_string() {
                    available_files.insert(name);
                }
            }
        }
        project::validate_and_clean_project(payload.data, &available_files)
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))??;

    Ok(HttpResponse::Ok().json(result.1))
}

// --- EXPORT HANDLERS ---

/// Packages the project into a deployment-ready static structure.
#[tracing::instrument(skip(payload), name = "create_tour_package")]
pub async fn create_tour_package(payload: Multipart) -> Result<HttpResponse, AppError> {
    tracing::info!(module = "Exporter", "CREATE_PACKAGE_START");

    let (image_files, fields) = parse_tour_package_multipart(payload).await?;

    let result = web::block(move || project::create_tour_package(image_files, fields))
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))??;

    Ok(HttpResponse::Ok()
        .content_type("application/zip")
        .body(result))
}

// --- PRIVATE HELPERS ---

fn extract_project_metadata_from_zip(path: &PathBuf) -> Result<(String, serde_json::Value), AppError> {
    let file = fs::File::open(path).map_err(AppError::IoError)?;
    let mut archive =
        zip::ZipArchive::new(file).map_err(|e| AppError::ZipError(e.to_string()))?;
    let mut json_file = archive
        .by_name("project.json")
        .map_err(|_| AppError::InternalError("project.json missing".into()))?;
    let mut json_str = String::new();
    json_file
        .read_to_string(&mut json_str)
        .map_err(AppError::IoError)?;
    let data: serde_json::Value =
        serde_json::from_str(&json_str).map_err(|e| AppError::InternalError(e.to_string()))?;
    let id = data
        .get("id")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| Uuid::new_v4().to_string());
    Ok((id, data))
}

async fn read_string_field(field: &mut actix_multipart::Field) -> Result<String, AppError> {
    let mut bytes = Vec::new();
    while let Some(chunk) = field.try_next().await? {
        bytes.extend_from_slice(&chunk);
    }
    Ok(String::from_utf8_lossy(&bytes).to_string())
}

async fn save_temp_file_field(field: &mut actix_multipart::Field) -> Result<(String, PathBuf), AppError> {
    let filename = field
        .content_disposition()
        .and_then(|cd| cd.get_filename())
        .map(|f| f.to_string())
        .unwrap_or_else(|| format!("img_{}.webp", Uuid::new_v4()));
    let sanitized_name = sanitize_filename(&filename)
        .unwrap_or_else(|_| format!("img_{}.webp", Uuid::new_v4()));
    let temp_img_path = get_temp_path("tmp");
    let mut f = fs::File::create(&temp_img_path).map_err(AppError::IoError)?;
    while let Some(chunk) = field.try_next().await? {
        f.write_all(&chunk).map_err(AppError::IoError)?;
    }
    Ok((sanitized_name, temp_img_path))
}

async fn parse_save_project_multipart(
    mut payload: Multipart,
) -> Result<(Option<String>, Option<String>, Vec<(String, PathBuf)>), AppError> {
    let mut project_json: Option<String> = None;
    let mut session_id: Option<String> = None;
    let mut temp_images: Vec<(String, PathBuf)> = Vec::new();

    while let Some(mut field) = payload.try_next().await? {
        let name = field.name().unwrap_or("unknown").to_string();
        match name.as_str() {
            "project_data" => {
                project_json = Some(read_string_field(&mut field).await?);
            },
            "files" => {
                temp_images.push(save_temp_file_field(&mut field).await?);
            },
            "session_id" => {
                session_id = Some(read_string_field(&mut field).await?);
            },
            _ => {
                // consume unknown field
                let _ = read_string_field(&mut field).await?;
            }
        }
    }
    Ok((project_json, session_id, temp_images))
}

async fn extract_file_from_multipart(
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

fn extract_zip_to_project_dir(zip_path: &PathBuf, project_dir: &PathBuf) -> Result<(), AppError> {
    let file = fs::File::open(zip_path).map_err(AppError::IoError)?;
    let mut archive = zip::ZipArchive::new(file).map_err(|e| AppError::ZipError(e.to_string()))?;
    for i in 0..archive.len() {
        let mut file = archive
            .by_index(i)
            .map_err(|e| AppError::ZipError(e.to_string()))?;
        let outpath = match file.enclosed_name() {
            Some(path) => project_dir.join(path),
            None => continue,
        };
        if file.name().ends_with('/') {
            fs::create_dir_all(&outpath).map_err(AppError::IoError)?;
        } else {
            if let Some(p) = outpath.parent() {
                if !p.exists() {
                    fs::create_dir_all(p).map_err(AppError::IoError)?;
                }
            }
            let mut outfile = fs::File::create(&outpath).map_err(AppError::IoError)?;
            std::io::copy(&mut file, &mut outfile).map_err(AppError::IoError)?;
        }
    }
    Ok(())
}

async fn parse_tour_package_multipart(
    mut payload: Multipart,
) -> Result<(Vec<(String, Vec<u8>)>, HashMap<String, String>), AppError> {
    let mut image_files = Vec::new();
    let mut fields = HashMap::new();

    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field
            .content_disposition()
            .ok_or_else(|| AppError::InternalError("Missing content disposition".into()))?;
        let name = content_disposition
            .get_name()
            .unwrap_or("unknown")
            .to_string();

        if ["html_4k", "html_2k", "html_hd", "html_index", "embed_codes"].contains(&name.as_str()) {
            fields.insert(name, read_string_field(&mut field).await?);
        } else {
            // Assume it's a file (library, logo, or scene)
            let filename = content_disposition
                .get_filename()
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
