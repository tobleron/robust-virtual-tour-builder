use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::path::PathBuf;
use uuid::Uuid;

use crate::models::{AppError, User};
use crate::services::media::StorageManager;

use super::{project_assets, project_snapshot};

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DashboardProjectSummary {
    pub session_id: String,
    pub tour_name: String,
    pub updated_at: String,
    pub scene_count: usize,
    pub hotspot_count: usize,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DashboardProjectsQuery {
    pub page: Option<usize>,
    pub page_size: Option<usize>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DashboardProjectsPage {
    pub items: Vec<DashboardProjectSummary>,
    pub page: usize,
    pub page_size: usize,
    pub total_items: usize,
    pub total_pages: usize,
}

const SUMMARY_FILENAME: &str = "summary.txt";
const DASHBOARD_PAGE_SIZE_DEFAULT: usize = 20;
const DASHBOARD_PAGE_SIZE_MAX: usize = 20;

fn parse_summary_count(line: &str, prefix: &str) -> Option<usize> {
    line.strip_prefix(prefix)
        .map(str::trim)
        .and_then(|value| value.split_whitespace().next())
        .and_then(|value| value.parse::<usize>().ok())
}

fn parse_project_summary_file(project_dir: &std::path::Path) -> Option<(String, usize, usize)> {
    let summary_path = project_dir.join(SUMMARY_FILENAME);
    let raw = std::fs::read_to_string(summary_path).ok()?;

    let mut tour_name: Option<String> = None;
    let mut scene_count: Option<usize> = None;
    let mut hotspot_count: Option<usize> = None;

    for line in raw.lines() {
        let trimmed = line.trim();
        if tour_name.is_none()
            && let Some(value) = trimmed.strip_prefix("Project Name:")
        {
            let parsed = value.trim();
            if !parsed.is_empty() {
                tour_name = Some(parsed.to_string());
            }
            continue;
        }

        if scene_count.is_none() {
            scene_count = parse_summary_count(trimmed, "Total Scenes:");
        }

        if hotspot_count.is_none() {
            hotspot_count = parse_summary_count(trimmed, "Total Hotspots:");
        }
    }

    Some((
        tour_name.unwrap_or_else(|| "Untitled Tour".to_string()),
        scene_count.unwrap_or(0),
        hotspot_count.unwrap_or(0),
    ))
}

fn normalize_dashboard_page(query: &DashboardProjectsQuery) -> (usize, usize) {
    let page = query.page.unwrap_or(1).max(1);
    let page_size = query
        .page_size
        .unwrap_or(DASHBOARD_PAGE_SIZE_DEFAULT)
        .clamp(1, DASHBOARD_PAGE_SIZE_MAX);
    (page, page_size)
}

pub(super) async fn list_dashboard_projects(
    req: HttpRequest,
    query: web::Query<DashboardProjectsQuery>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let (requested_page, page_size) = normalize_dashboard_page(&query);

    let user_path = StorageManager::get_user_path(&user.id).map_err(AppError::IoError)?;
    if !user_path.exists() {
        return Ok(HttpResponse::Ok().json(DashboardProjectsPage {
            items: Vec::new(),
            page: 1,
            page_size,
            total_items: 0,
            total_pages: 1,
        }));
    }

    let mut projects: Vec<DashboardProjectSummary> = Vec::new();
    for entry in std::fs::read_dir(&user_path).map_err(AppError::IoError)? {
        let entry = entry.map_err(AppError::IoError)?;
        if !entry.file_type().map_err(AppError::IoError)?.is_dir() {
            continue;
        }

        let session_id = entry.file_name().to_string_lossy().to_string();
        let project_dir: PathBuf = entry.path();
        let snapshot_path = match project_snapshot::resolve_snapshot_path(&project_dir) {
            Ok(path) => path,
            Err(_) => continue,
        };
        if !snapshot_path.exists() {
            continue;
        }

        let (tour_name, scene_count, hotspot_count) =
            if let Some(summary) = parse_project_summary_file(&project_dir) {
                summary
            } else {
                let project_data = project_snapshot::read_snapshot(&project_dir)?;
                (
                    project_data
                        .get("tourName")
                        .and_then(|value| value.as_str())
                        .unwrap_or("Untitled Tour")
                        .to_string(),
                    project_snapshot::scene_count(&project_data),
                    project_snapshot::count_hotspots(&project_data),
                )
            };

        let updated_at = std::fs::metadata(&snapshot_path)
            .and_then(|metadata| metadata.modified())
            .ok()
            .map(|time| chrono::DateTime::<chrono::Utc>::from(time).to_rfc3339())
            .unwrap_or_else(|| chrono::Utc::now().to_rfc3339());

        projects.push(DashboardProjectSummary {
            session_id,
            tour_name,
            updated_at,
            scene_count,
            hotspot_count,
        });
    }

    projects.sort_by(|a, b| b.updated_at.cmp(&a.updated_at));

    let total_items = projects.len();
    let total_pages = usize::max(1, total_items.div_ceil(page_size));
    let page = requested_page.min(total_pages);
    let start = (page - 1) * page_size;
    let end = usize::min(start + page_size, total_items);
    let items = if start < total_items {
        projects[start..end].to_vec()
    } else {
        Vec::new()
    };

    Ok(HttpResponse::Ok().json(DashboardProjectsPage {
        items,
        page,
        page_size,
        total_items,
        total_pages,
    }))
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
        Value::String(duplicate_tour_name(&project_snapshot::project_tour_name(
            project_data,
        ))),
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
    let source_project_data = project_snapshot::validate_snapshot_project(
        &project_snapshot::read_snapshot(&source_project_dir)?,
    )?;

    project_assets::repair_missing_project_assets(
        &user_root,
        &source_project_dir,
        &source_project_data,
    )?;

    let duplicate_session_id = Uuid::new_v4().to_string();
    let duplicate_project_dir = StorageManager::ensure_project_dir(&user.id, &duplicate_session_id)
        .map_err(AppError::IoError)?;
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
