/* backend/src/api/project.rs - Consolidated Project API */

use actix_multipart::Multipart;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use serde::{Deserialize, Serialize};
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

    struct TempImagesCleanupGuard {
        paths: Vec<std::path::PathBuf>,
    }
    impl Drop for TempImagesCleanupGuard {
        fn drop(&mut self) {
            for path in &self.paths {
                let _ = std::fs::remove_file(path);
            }
        }
    }

    struct ZipCleanupGuard {
        path: std::path::PathBuf,
        keep: bool,
    }
    impl ZipCleanupGuard {
        fn new(path: std::path::PathBuf) -> Self {
            Self { path, keep: false }
        }

        fn keep(&mut self) {
            self.keep = true;
        }
    }
    impl Drop for ZipCleanupGuard {
        fn drop(&mut self) {
            if !self.keep {
                let _ = std::fs::remove_file(&self.path);
            }
        }
    }

    let _temp_images_guard = TempImagesCleanupGuard {
        paths: temp_images.iter().map(|(_, path)| path.clone()).collect(),
    };
    let mut zip_cleanup_guard = ZipCleanupGuard::new(zip_path.clone());

    let json_content = project_json.ok_or_else(|| {
        AppError::MultipartError(actix_multipart::MultipartError::Incomplete.to_string())
    })?;
    let project_path = match &session_id {
        Some(pid) => {
            Some(StorageManager::get_user_project_path(&user.id, pid).map_err(AppError::IoError)?)
        }
        None => None,
    };

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
            let file_bytes = tokio::fs::read(&zip_path)
                .await
                .map_err(AppError::IoError)?;
            zip_cleanup_guard.keep();
            let _ = std::fs::remove_file(&zip_path);
            tracing::info!(
                module = "ProjectManager",
                duration_ms = duration,
                "SAVE_PROJECT_COMPLETE"
            );
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(file_bytes))
        }
        Err(e) => Err(e.into()),
    }
}

/// Loads a project ZIP file into memory.
pub async fn load_project(req: HttpRequest, payload: Multipart) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;

    tracing::info!(module = "ProjectManager", user_id = %user.id, "LOAD_PROJECT_START");

    let mut temp_upload = project_multipart::save_multipart_to_tempfile(payload).await?;

    temp_upload
        .seek(SeekFrom::Start(0))
        .map_err(AppError::IoError)?;
    let result_zip_file = web::block(move || project::process_uploaded_project_zip(temp_upload))
        .await
        .map_err(|e| AppError::InternalError(e.to_string()))??;
    let file = result_zip_file.reopen().map_err(AppError::IoError)?;
    let named_file = actix_files::NamedFile::from_file(file, "project.zip")?;

    tracing::info!(module = "ProjectManager", user_id = %user.id, "LOAD_PROJECT_COMPLETE");

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

    tracing::info!(module = "ProjectManager", user_id = %user.id, "IMPORT_PROJECT_START");

    // Extract file from payload
    let tmp_path = project_multipart::extract_file_from_multipart(payload, "zip").await?;
    struct TempUploadCleanupGuard {
        path: std::path::PathBuf,
    }
    impl Drop for TempUploadCleanupGuard {
        fn drop(&mut self) {
            let _ = std::fs::remove_file(&self.path);
        }
    }
    let _tmp_upload_cleanup = TempUploadCleanupGuard {
        path: tmp_path.clone(),
    };

    // Extract metadata
    let tmp_path_clone = tmp_path.clone();
    let (project_id, project_data) =
        web::block(move || project_logic::extract_project_metadata_from_zip(&tmp_path_clone))
            .await
            .map_err(|e| AppError::InternalError(e.to_string()))??;

    let project_dir =
        StorageManager::ensure_project_dir(&user.id, &project_id).map_err(AppError::IoError)?;

    // Use shared logic for extraction
    let tmp_path_clone = tmp_path.clone();
    let project_dir_clone = project_dir.clone();
    web::block(move || {
        project_logic::extract_zip_to_project_dir(&tmp_path_clone, &project_dir_clone)
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))?
    .map_err(AppError::InternalError)?;

    let validated_project = web::block({
        let project_dir = project_dir.clone();
        let project_data = project_data.clone();
        move || -> Result<serde_json::Value, AppError> {
            let available_files = project_logic::list_available_files(&project_dir);
            let (mut cleaned_project, report) =
                project::validate_and_clean_project(project_data, &available_files)
                    .map_err(AppError::InternalError)?;

            cleaned_project["validationReport"] = serde_json::to_value(&report)
                .map_err(|e| AppError::InternalError(e.to_string()))?;

            let persisted = serde_json::to_string_pretty(&cleaned_project)
                .map_err(|e| AppError::InternalError(e.to_string()))?;
            std::fs::write(project_dir.join("project.json"), persisted)
                .map_err(AppError::IoError)?;

            Ok(cleaned_project)
        }
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))??;

    tracing::info!(module = "ProjectManager", user_id = %user.id, session_id = %project_id, "IMPORT_PROJECT_COMPLETE");

    return Ok(HttpResponse::Ok().json(ImportResponse {
        session_id: project_id,
        project_data: validated_project,
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
    let project_path = StorageManager::get_user_project_path(&user.id, &payload.session_id)
        .map_err(AppError::IoError)?;

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
#[tracing::instrument(skip(payload, req), name = "create_tour_package")]
pub async fn create_tour_package(
    req: HttpRequest,
    payload: Multipart,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;

    tracing::info!(module = "Exporter", user_id = %user.id, "CREATE_PACKAGE_START");

    let zip_path = get_temp_path("zip");
    let zip_path_clone = zip_path.clone();

    // Set a 10-minute timeout for the entire operation
    let timeout_duration = std::time::Duration::from_secs(600);

    let result: Result<Result<(), AppError>, tokio::time::error::Elapsed> =
        tokio::time::timeout(timeout_duration, async {
            let (image_files, fields) =
                project_multipart::parse_tour_package_multipart(payload).await?;

            // Wrap image_files in a Guard for cleanup on early return/panic
            struct CleanupGuard(Option<Vec<(String, std::path::PathBuf)>>);
            impl Drop for CleanupGuard {
                fn drop(&mut self) {
                    if let Some(files) = &self.0 {
                        for (_, path) in files {
                            let _ = std::fs::remove_file(path);
                        }
                    }
                }
            }
            let mut guard = CleanupGuard(Some(image_files));

            web::block(move || {
                let files = guard.0.take().unwrap_or_default();
                project::create_tour_package(files, fields, zip_path_clone)
            })
            .await
            .map_err(|e| AppError::InternalError(e.to_string()))?
            .map_err(AppError::InternalError)
        })
        .await;

    match result {
        Ok(Ok(())) => {
            let file_bytes = tokio::fs::read(&zip_path)
                .await
                .map_err(AppError::IoError)?;
            let _ = tokio::fs::remove_file(&zip_path).await;
            tracing::info!(module = "Exporter", user_id = %user.id, "CREATE_PACKAGE_COMPLETE");
            Ok(HttpResponse::Ok()
                .content_type("application/zip")
                .body(file_bytes))
        }
        Ok(Err(e)) => {
            let _ = tokio::fs::remove_file(&zip_path).await;
            tracing::error!(module = "Exporter", user_id = %user.id, error = ?e, "CREATE_PACKAGE_FAILED");
            Err(e)
        }
        Err(_) => {
            let _ = tokio::fs::remove_file(&zip_path).await;
            tracing::error!(module = "Exporter", user_id = %user.id, "CREATE_PACKAGE_TIMEOUT");
            Err(AppError::InternalError(
                "Export timed out after 10 minutes".into(),
            ))
        }
    }
}
