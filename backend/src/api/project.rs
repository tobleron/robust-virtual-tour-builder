/* backend/src/api/project.rs - Consolidated Project API */

use actix_multipart::Multipart;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use serde::{Deserialize, Serialize};
use std::fs;
use std::io::{Seek, SeekFrom};

use crate::api::utils::get_temp_path;
use crate::api::{project_logic, project_multipart};
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

    let (project_json, session_id, temp_images) =
        project_multipart::parse_save_project_multipart(payload).await?;

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
pub async fn load_project(req: HttpRequest, payload: Multipart) -> Result<HttpResponse, AppError> {
    let _user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;

    let mut temp_upload = project_multipart::save_multipart_to_tempfile(payload).await?;

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
    let tmp_path = project_multipart::extract_file_from_multipart(payload, "zip").await?;

    // Extract metadata
    let (project_id, project_data) = project_logic::extract_project_metadata_from_zip(&tmp_path)?;

    let project_dir =
        StorageManager::ensure_project_dir(&user.id, &project_id).map_err(AppError::IoError)?;

    // Use shared logic for extraction
    project_logic::extract_zip_to_project_dir(&tmp_path, &project_dir)
        .map_err(AppError::InternalError)?;

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
        let available_files = project_logic::list_available_files(&project_path);
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

    let (image_files, fields) = project_multipart::parse_tour_package_multipart(payload).await?;

    let result = web::block(move || project::create_tour_package(image_files, fields))
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))??;

    Ok(HttpResponse::Ok()
        .content_type("application/zip")
        .body(result))
}
