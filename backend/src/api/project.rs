/* backend/src/api/project.rs - Consolidated Project API */

use actix_multipart::Multipart;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use serde::Deserialize;
use serde::Serialize;
use serde_json::json;
use std::io::{Seek, SeekFrom};
use std::path::{Path, PathBuf};

use crate::api::utils::get_temp_path;
use crate::api::{project_logic, project_multipart};
use crate::models::{AppError, User};
use crate::pathfinder::PathRequest;
use crate::services::media::StorageManager;
use crate::services::project::{self};

const SNAPSHOT_FILENAME: &str = "project_snapshot.json";

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SnapshotSyncPayload {
    pub session_id: Option<String>,
    pub project_data: serde_json::Value,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SnapshotSyncResponse {
    pub session_id: String,
    pub updated_at: String,
    pub scene_count: usize,
    pub hotspot_count: usize,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DashboardProjectSummary {
    pub session_id: String,
    pub tour_name: String,
    pub updated_at: String,
    pub scene_count: usize,
    pub hotspot_count: usize,
}

fn count_hotspots(project_data: &serde_json::Value) -> usize {
    project_data
        .get("scenes")
        .and_then(|v| v.as_array())
        .map(|scenes| {
            scenes
                .iter()
                .map(|scene| {
                    scene
                        .get("hotspots")
                        .and_then(|v| v.as_array())
                        .map(|hotspots| hotspots.len())
                        .unwrap_or(0)
                })
                .sum()
        })
        .unwrap_or(0)
}

fn scene_count(project_data: &serde_json::Value) -> usize {
    project_data
        .get("scenes")
        .and_then(|v| v.as_array())
        .map(|scenes| scenes.len())
        .unwrap_or(0)
}

fn read_snapshot(project_dir: &Path) -> Result<serde_json::Value, AppError> {
    let snapshot_path = project_dir.join(SNAPSHOT_FILENAME);
    let raw = std::fs::read_to_string(snapshot_path).map_err(AppError::IoError)?;
    serde_json::from_str::<serde_json::Value>(&raw)
        .map_err(|e| AppError::ValidationError(format!("Invalid snapshot JSON: {}", e)))
}

fn validate_snapshot_project(project_data: &serde_json::Value) -> Result<serde_json::Value, AppError> {
    let obj = project_data
        .as_object()
        .ok_or_else(|| AppError::ValidationError("Snapshot payload must be a JSON object".into()))?;
    if !obj.contains_key("inventory") {
        return Err(AppError::ValidationError(
            "Snapshot payload missing required key: inventory".into(),
        ));
    }
    if !obj.contains_key("sceneOrder") {
        return Err(AppError::ValidationError(
            "Snapshot payload missing required key: sceneOrder".into(),
        ));
    }
    Ok(project_data.clone())
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

// --- SNAPSHOT / DASHBOARD HANDLERS ---

/// Persist canonical project snapshot JSON in backend storage and return stable session id.
pub async fn sync_snapshot(
    req: HttpRequest,
    payload: web::Json<SnapshotSyncPayload>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;

    let payload = payload.into_inner();
    let validated_project = validate_snapshot_project(&payload.project_data)?;
    let session_id = payload
        .session_id
        .filter(|id| !id.trim().is_empty())
        .unwrap_or_else(|| uuid::Uuid::new_v4().to_string());

    let project_dir = StorageManager::ensure_project_dir(&user.id, &session_id).map_err(AppError::IoError)?;
    let snapshot_path = project_dir.join(SNAPSHOT_FILENAME);

    let serialized = serde_json::to_string_pretty(&validated_project)
        .map_err(|e| AppError::InternalError(format!("Serialize snapshot failed: {}", e)))?;
    std::fs::write(snapshot_path, serialized).map_err(AppError::IoError)?;

    let response = SnapshotSyncResponse {
        session_id,
        updated_at: chrono::Utc::now().to_rfc3339(),
        scene_count: scene_count(&validated_project),
        hotspot_count: count_hotspots(&validated_project),
    };

    Ok(HttpResponse::Ok().json(response))
}

/// List persisted projects for dashboard browsing.
pub async fn list_dashboard_projects(req: HttpRequest) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;

    let user_path = StorageManager::get_user_path(&user.id).map_err(AppError::IoError)?;
    if !user_path.exists() {
        return Ok(HttpResponse::Ok().json(Vec::<DashboardProjectSummary>::new()));
    }

    let mut projects: Vec<DashboardProjectSummary> = Vec::new();
    for entry in std::fs::read_dir(&user_path).map_err(AppError::IoError)? {
        let entry = entry.map_err(AppError::IoError)?;
        if !entry.file_type().map_err(AppError::IoError)?.is_dir() {
            continue;
        }

        let session_id = entry.file_name().to_string_lossy().to_string();
        let project_dir: PathBuf = entry.path();
        let snapshot_path = project_dir.join(SNAPSHOT_FILENAME);
        if !snapshot_path.exists() {
            continue;
        }

        let project_data = read_snapshot(&project_dir)?;
        let tour_name = project_data
            .get("tourName")
            .and_then(|v| v.as_str())
            .unwrap_or("Untitled Tour")
            .to_string();

        let updated_at = std::fs::metadata(&snapshot_path)
            .and_then(|m| m.modified())
            .ok()
            .map(|t| chrono::DateTime::<chrono::Utc>::from(t).to_rfc3339())
            .unwrap_or_else(|| chrono::Utc::now().to_rfc3339());

        projects.push(DashboardProjectSummary {
            session_id,
            tour_name,
            updated_at,
            scene_count: scene_count(&project_data),
            hotspot_count: count_hotspots(&project_data),
        });
    }

    projects.sort_by(|a, b| b.updated_at.cmp(&a.updated_at));
    Ok(HttpResponse::Ok().json(projects))
}

/// Load persisted snapshot for direct dashboard-to-builder open flow.
pub async fn load_dashboard_project(
    req: HttpRequest,
    path: web::Path<String>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let session_id = path.into_inner();
    let project_dir = StorageManager::get_user_project_path(&user.id, &session_id).map_err(AppError::IoError)?;
    let project_data = read_snapshot(&project_dir)?;
    Ok(HttpResponse::Ok().json(json!({
        "sessionId": session_id,
        "projectData": project_data
    })))
}

/// Cleanup temp/cache files that are safe to regenerate (backend/temp/* and chunk caches).
pub async fn cleanup_backend_cache(req: HttpRequest) -> Result<HttpResponse, AppError> {
    let _user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;

    let mut removed_files = 0usize;
    let mut removed_dirs = 0usize;
    let temp_dir = PathBuf::from("temp");
    if temp_dir.exists() {
        for entry in std::fs::read_dir(&temp_dir).map_err(AppError::IoError)? {
            let entry = entry.map_err(AppError::IoError)?;
            let path = entry.path();
            if path.is_file() {
                if std::fs::remove_file(&path).is_ok() {
                    removed_files += 1;
                }
            } else if path.is_dir() && std::fs::remove_dir_all(&path).is_ok() {
                removed_dirs += 1;
            }
        }
    }

    Ok(HttpResponse::Ok().json(json!({
        "status": "ok",
        "removedFiles": removed_files,
        "removedDirs": removed_dirs
    })))
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
