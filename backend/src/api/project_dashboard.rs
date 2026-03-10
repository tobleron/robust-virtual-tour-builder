use actix_web::{HttpMessage, HttpRequest, HttpResponse};
use serde::Serialize;
use std::path::PathBuf;

use crate::models::{AppError, User};
use crate::services::media::StorageManager;

use super::{project_assets, project_snapshot, SNAPSHOT_FILENAME};

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DashboardProjectSummary {
    pub session_id: String,
    pub tour_name: String,
    pub updated_at: String,
    pub scene_count: usize,
    pub hotspot_count: usize,
}

pub(super) async fn list_dashboard_projects(req: HttpRequest) -> Result<HttpResponse, AppError> {
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

        let project_data = project_snapshot::read_snapshot(&project_dir)?;
        let tour_name = project_data
            .get("tourName")
            .and_then(|value| value.as_str())
            .unwrap_or("Untitled Tour")
            .to_string();

        let updated_at = std::fs::metadata(&snapshot_path)
            .and_then(|metadata| metadata.modified())
            .ok()
            .map(|time| chrono::DateTime::<chrono::Utc>::from(time).to_rfc3339())
            .unwrap_or_else(|| chrono::Utc::now().to_rfc3339());

        projects.push(DashboardProjectSummary {
            session_id,
            tour_name,
            updated_at,
            scene_count: project_snapshot::scene_count(&project_data),
            hotspot_count: project_snapshot::count_hotspots(&project_data),
        });
    }

    projects.sort_by(|a, b| b.updated_at.cmp(&a.updated_at));
    Ok(HttpResponse::Ok().json(projects))
}

pub(super) async fn load_dashboard_project(
    req: HttpRequest,
    path: actix_web::web::Path<String>,
) -> Result<HttpResponse, AppError> {
    project_assets::load_dashboard_project(req, path).await
}
