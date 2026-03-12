use actix_web::{HttpMessage, HttpRequest, HttpResponse};
use serde::Serialize;
use serde_json::Value;
use std::path::PathBuf;
use uuid::Uuid;

use crate::models::{AppError, User};
use crate::services::media::StorageManager;

use super::{SNAPSHOT_FILENAME, project_assets, project_snapshot};

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

fn duplicate_tour_name(tour_name: &str) -> String {
    let trimmed = tour_name.trim();
    if trimmed.is_empty() {
        "Untitled Tour (Copy)".to_string()
    } else {
        format!("{} (Copy)", trimmed)
    }
}

fn build_duplicate_project_data(project_data: &Value, session_id: &str) -> Result<Value, AppError> {
    let mut object = project_data.as_object().cloned().ok_or_else(|| {
        AppError::ValidationError("Dashboard project snapshot must be a JSON object".into())
    })?;
    object.insert("sessionId".into(), Value::String(session_id.to_string()));
    object.insert(
        "tourName".into(),
        Value::String(duplicate_tour_name(&project_snapshot::project_tour_name(project_data))),
    );
    Ok(Value::Object(object))
}

fn copy_referenced_assets(
    source_project_dir: &std::path::Path,
    duplicate_project_dir: &std::path::Path,
    project_data: &Value,
) -> Result<(), AppError> {
    let referenced_files =
        crate::api::project_logic::reference::collect_referenced_project_files(project_data);

    for filename in referenced_files {
        if let Some(source_path) =
            project_assets::find_existing_project_asset(source_project_dir, &filename)
        {
            project_assets::persist_project_asset(duplicate_project_dir, &filename, &source_path)?;
        }
    }

    Ok(())
}

pub(super) async fn duplicate_dashboard_project(
    req: HttpRequest,
    path: actix_web::web::Path<String>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let source_session_id = path.into_inner();
    let user_root = StorageManager::get_user_path(&user.id).map_err(AppError::IoError)?;
    let source_project_dir = StorageManager::get_user_project_path(&user.id, &source_session_id)
        .map_err(AppError::IoError)?;
    let source_project_data =
        project_snapshot::validate_snapshot_project(&project_snapshot::read_snapshot(
            &source_project_dir,
        )?)?;

    project_assets::repair_missing_project_assets(
        &user_root,
        &source_project_dir,
        &source_project_data,
    )?;

    let duplicate_session_id = Uuid::new_v4().to_string();
    let duplicate_project_dir =
        StorageManager::ensure_project_dir(&user.id, &duplicate_session_id).map_err(AppError::IoError)?;
    let duplicate_project_data =
        build_duplicate_project_data(&source_project_data, &duplicate_session_id)?;

    copy_referenced_assets(
        &source_project_dir,
        &duplicate_project_dir,
        &duplicate_project_data,
    )?;
    project_snapshot::write_current_snapshot(&duplicate_project_dir, &duplicate_project_data)?;
    let history_entry = project_snapshot::persist_snapshot_history(
        &duplicate_project_dir,
        &duplicate_project_data,
        "duplicate",
    )?;

    Ok(HttpResponse::Ok().json(DashboardProjectSummary {
        session_id: duplicate_session_id,
        tour_name: project_snapshot::project_tour_name(&duplicate_project_data),
        updated_at: history_entry.created_at,
        scene_count: project_snapshot::scene_count(&duplicate_project_data),
        hotspot_count: project_snapshot::count_hotspots(&duplicate_project_data),
    }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn build_duplicate_project_data_assigns_new_session_and_copy_name() -> Result<(), AppError> {
        let project_data = serde_json::json!({
            "tourName": "Sample Tour",
            "sessionId": "old-session",
            "inventory": [],
            "sceneOrder": [],
            "scenes": [],
        });

        let duplicate = build_duplicate_project_data(&project_data, "new-session")?;

        assert_eq!(
            duplicate.get("sessionId").and_then(Value::as_str),
            Some("new-session")
        );
        assert_eq!(
            duplicate.get("tourName").and_then(Value::as_str),
            Some("Sample Tour (Copy)")
        );

        Ok(())
    }
}
