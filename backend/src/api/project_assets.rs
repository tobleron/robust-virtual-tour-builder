use actix_multipart::Multipart;
use actix_web::{HttpMessage, HttpRequest, HttpResponse};
use serde::Serialize;
use serde_json::json;
use std::io::{Seek, SeekFrom};
use std::path::{Path, PathBuf};

use crate::api::project_multipart;
use crate::models::{AppError, User};
use crate::services::media::StorageManager;
use crate::services::project;

use super::{SNAPSHOT_FILENAME, project_snapshot};

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SnapshotAssetSyncResponse {
    pub session_id: String,
    pub stored_files: usize,
}

pub(super) fn persist_project_asset(
    project_dir: &Path,
    filename: &str,
    temp_path: &Path,
) -> Result<(), AppError> {
    let safe_filename =
        crate::api::utils::sanitize_filename(filename).map_err(AppError::ValidationError)?;
    let target_path = if safe_filename == "logo_upload" {
        project_dir.join("logo_upload")
    } else {
        let images_dir = project_dir.join("images");
        std::fs::create_dir_all(&images_dir).map_err(AppError::IoError)?;
        images_dir.join(safe_filename)
    };
    std::fs::copy(temp_path, target_path).map_err(AppError::IoError)?;
    Ok(())
}

pub(super) fn find_existing_project_asset(project_dir: &Path, filename: &str) -> Option<PathBuf> {
    let images_path = project_dir.join("images").join(filename);
    if images_path.exists() && images_path.is_file() {
        return Some(images_path);
    }

    let root_path = project_dir.join(filename);
    if root_path.exists() && root_path.is_file() {
        return Some(root_path);
    }

    None
}

pub(super) fn repair_missing_project_assets(
    user_root: &Path,
    project_dir: &Path,
    project_data: &serde_json::Value,
) -> Result<(), AppError> {
    let referenced_files =
        crate::api::project_logic::reference::collect_referenced_project_files(project_data);
    if referenced_files.is_empty() {
        return Ok(());
    }

    let mut missing_files: Vec<String> = referenced_files
        .into_iter()
        .filter(|filename| find_existing_project_asset(project_dir, filename).is_none())
        .collect();

    if missing_files.is_empty() {
        return Ok(());
    }

    let mut candidate_dirs: Vec<PathBuf> = std::fs::read_dir(user_root)
        .map_err(AppError::IoError)?
        .filter_map(|entry| entry.ok())
        .filter_map(|entry| {
            entry
                .file_type()
                .ok()
                .filter(|file_type| file_type.is_dir())
                .map(|_| entry.path())
        })
        .filter(|path| path != project_dir)
        .collect();

    candidate_dirs.sort_by(|a, b| {
        let a_time = std::fs::metadata(a.join(SNAPSHOT_FILENAME))
            .and_then(|metadata| metadata.modified())
            .ok();
        let b_time = std::fs::metadata(b.join(SNAPSHOT_FILENAME))
            .and_then(|metadata| metadata.modified())
            .ok();
        b_time.cmp(&a_time)
    });

    for candidate_dir in candidate_dirs {
        let remaining = missing_files.clone();
        for filename in remaining {
            if let Some(source) = find_existing_project_asset(&candidate_dir, &filename) {
                let target = if filename == "logo_upload" {
                    project_dir.join("logo_upload")
                } else {
                    let images_dir = project_dir.join("images");
                    std::fs::create_dir_all(&images_dir).map_err(AppError::IoError)?;
                    images_dir.join(&filename)
                };
                std::fs::copy(source, target).map_err(AppError::IoError)?;
                missing_files.retain(|item| item != &filename);
            }
        }
        if missing_files.is_empty() {
            break;
        }
    }

    Ok(())
}

pub(super) async fn load_project(
    req: HttpRequest,
    payload: Multipart,
) -> Result<HttpResponse, AppError> {
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
    let result_zip_file =
        actix_web::web::block(move || project::process_uploaded_project_zip(temp_upload))
            .await
            .map_err(|error| AppError::InternalError(error.to_string()))??;
    let file = result_zip_file.reopen().map_err(AppError::IoError)?;
    let named_file = actix_files::NamedFile::from_file(file, "project.zip")?;

    tracing::info!(module = "ProjectManager", user_id = %user.id, "LOAD_PROJECT_COMPLETE");

    Ok(named_file.into_response(&req))
}

pub(super) async fn sync_snapshot_assets(
    req: HttpRequest,
    payload: Multipart,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;

    let (_project_json, session_id_opt, temp_images) =
        project_multipart::parse_save_project_multipart(payload).await?;
    let session_id = session_id_opt
        .filter(|value| !value.trim().is_empty())
        .ok_or_else(|| AppError::ValidationError("Missing session_id for asset sync".into()))?;

    let project_dir =
        StorageManager::ensure_project_dir(&user.id, &session_id).map_err(AppError::IoError)?;

    let mut stored_files = 0usize;
    for (filename, temp_path) in &temp_images {
        persist_project_asset(&project_dir, filename, temp_path)?;
        stored_files += 1;
    }
    for (_, temp_path) in temp_images {
        let _ = std::fs::remove_file(temp_path);
    }

    Ok(HttpResponse::Ok().json(SnapshotAssetSyncResponse {
        session_id,
        stored_files,
    }))
}

pub(super) async fn delete_dashboard_project(
    req: HttpRequest,
    path: actix_web::web::Path<String>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let session_id = path.into_inner();
    let project_dir =
        StorageManager::get_user_project_path(&user.id, &session_id).map_err(AppError::IoError)?;

    if project_dir.exists() {
        std::fs::remove_dir_all(project_dir).map_err(AppError::IoError)?;
    }

    Ok(HttpResponse::Ok().json(json!({
        "ok": true,
        "sessionId": session_id
    })))
}

pub(super) async fn cleanup_backend_cache(req: HttpRequest) -> Result<HttpResponse, AppError> {
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

pub(super) async fn load_dashboard_project(
    req: HttpRequest,
    path: actix_web::web::Path<String>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let session_id = path.into_inner();
    let user_root = StorageManager::get_user_path(&user.id).map_err(AppError::IoError)?;
    let project_dir =
        StorageManager::get_user_project_path(&user.id, &session_id).map_err(AppError::IoError)?;
    let project_data = project_snapshot::read_snapshot(&project_dir)?;
    repair_missing_project_assets(&user_root, &project_dir, &project_data)?;
    Ok(HttpResponse::Ok().json(json!({
        "sessionId": session_id,
        "projectData": project_data
    })))
}
