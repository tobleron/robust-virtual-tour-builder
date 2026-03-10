use actix_web::{web, HttpMessage, HttpRequest, HttpResponse};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::path::{Path, PathBuf};
use uuid::Uuid;

use crate::models::{AppError, User};
use crate::services::media::StorageManager;

use super::{project_assets, MAX_PROJECT_SNAPSHOTS, SNAPSHOT_FILENAME, SNAPSHOT_HISTORY_DIR};

pub(super) fn default_snapshot_origin() -> String {
    "auto".to_string()
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SnapshotSyncPayload {
    pub session_id: Option<String>,
    pub project_data: serde_json::Value,
    pub save_origin: Option<String>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SnapshotSyncResponse {
    pub session_id: String,
    pub updated_at: String,
    pub scene_count: usize,
    pub hotspot_count: usize,
}

#[derive(Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub(super) struct SnapshotHistoryEnvelope {
    pub(super) snapshot_id: String,
    pub(super) created_at: String,
    pub(super) tour_name: String,
    pub(super) scene_count: usize,
    pub(super) hotspot_count: usize,
    pub(super) content_hash: String,
    #[serde(default = "default_snapshot_origin")]
    pub(super) origin: String,
    pub(super) project_data: serde_json::Value,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SnapshotHistoryItem {
    pub snapshot_id: String,
    pub created_at: String,
    pub tour_name: String,
    pub scene_count: usize,
    pub hotspot_count: usize,
    pub content_hash: String,
    pub origin: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SnapshotRestoreResponse {
    pub session_id: String,
    pub snapshot_id: String,
    pub project_data: serde_json::Value,
}

pub(super) fn count_hotspots(project_data: &serde_json::Value) -> usize {
    project_data
        .get("scenes")
        .and_then(|value| value.as_array())
        .map(|scenes| {
            scenes
                .iter()
                .map(|scene| {
                    scene
                        .get("hotspots")
                        .and_then(|value| value.as_array())
                        .map(|hotspots| hotspots.len())
                        .unwrap_or(0)
                })
                .sum()
        })
        .unwrap_or(0)
}

pub(super) fn scene_count(project_data: &serde_json::Value) -> usize {
    project_data
        .get("scenes")
        .and_then(|value| value.as_array())
        .map(|scenes| scenes.len())
        .unwrap_or(0)
}

pub(super) fn project_tour_name(project_data: &serde_json::Value) -> String {
    project_data
        .get("tourName")
        .and_then(|value| value.as_str())
        .unwrap_or("Untitled Tour")
        .to_string()
}

pub(super) fn snapshot_history_dir(project_dir: &Path) -> PathBuf {
    project_dir.join(SNAPSHOT_HISTORY_DIR)
}

pub(super) fn snapshot_content_hash(project_data: &serde_json::Value) -> Result<String, AppError> {
    let serialized = serde_json::to_vec(project_data)
        .map_err(|error| AppError::InternalError(format!("Serialize snapshot hash failed: {}", error)))?;
    let mut hasher = Sha256::new();
    hasher.update(serialized);
    Ok(format!("{:x}", hasher.finalize()))
}

pub(super) fn write_current_snapshot(
    project_dir: &Path,
    project_data: &serde_json::Value,
) -> Result<(), AppError> {
    let snapshot_path = project_dir.join(SNAPSHOT_FILENAME);
    let serialized = serde_json::to_string_pretty(project_data)
        .map_err(|error| AppError::InternalError(format!("Serialize snapshot failed: {}", error)))?;
    std::fs::write(snapshot_path, serialized).map_err(AppError::IoError)
}

pub(super) fn load_snapshot_history(
    project_dir: &Path,
) -> Result<Vec<SnapshotHistoryEnvelope>, AppError> {
    let entries = load_snapshot_history_files(project_dir)?
        .into_iter()
        .map(|(_, envelope)| envelope)
        .collect();
    Ok(entries)
}

fn load_snapshot_history_files(
    project_dir: &Path,
) -> Result<Vec<(PathBuf, SnapshotHistoryEnvelope)>, AppError> {
    let history_dir = snapshot_history_dir(project_dir);
    if !history_dir.exists() {
        return Ok(Vec::new());
    }

    let mut entries: Vec<(PathBuf, SnapshotHistoryEnvelope)> = Vec::new();
    for entry in std::fs::read_dir(&history_dir).map_err(AppError::IoError)? {
        let entry = entry.map_err(AppError::IoError)?;
        if !entry.file_type().map_err(AppError::IoError)?.is_file() {
            continue;
        }
        let path = entry.path();
        let raw = std::fs::read_to_string(&path).map_err(AppError::IoError)?;
        let envelope = serde_json::from_str::<SnapshotHistoryEnvelope>(&raw).map_err(|error| {
            AppError::ValidationError(format!("Invalid snapshot history JSON: {}", error))
        })?;
        entries.push((path, envelope));
    }

    entries.sort_by(|a, b| b.1.created_at.cmp(&a.1.created_at));
    Ok(entries)
}

pub(super) fn prune_snapshot_history(project_dir: &Path) -> Result<(), AppError> {
    let file_entries = load_snapshot_history_files(project_dir)?;
    for (path, _) in file_entries.into_iter().skip(MAX_PROJECT_SNAPSHOTS) {
        std::fs::remove_file(path).map_err(AppError::IoError)?;
    }

    Ok(())
}

pub(super) fn persist_snapshot_history(
    project_dir: &Path,
    project_data: &serde_json::Value,
    origin: &str,
) -> Result<SnapshotHistoryEnvelope, AppError> {
    let history_dir = snapshot_history_dir(project_dir);
    std::fs::create_dir_all(&history_dir).map_err(AppError::IoError)?;

    let content_hash = snapshot_content_hash(project_data)?;
    let existing_history = load_snapshot_history_files(project_dir)?;
    if let Some((latest_path, existing_latest)) = existing_history.first()
        && existing_latest.content_hash == content_hash
    {
        if existing_latest.origin == "auto" && origin == "manual" {
            let mut upgraded = existing_latest.clone();
            upgraded.origin = "manual".to_string();
            let serialized = serde_json::to_string_pretty(&upgraded).map_err(|error| {
                AppError::InternalError(format!("Serialize snapshot history failed: {}", error))
            })?;
            std::fs::write(latest_path, serialized).map_err(AppError::IoError)?;
            return Ok(upgraded);
        }
        return Ok(existing_latest.clone());
    }

    let created_at = chrono::Utc::now().to_rfc3339();
    let snapshot_id = Uuid::new_v4().to_string();
    let envelope = SnapshotHistoryEnvelope {
        snapshot_id: snapshot_id.clone(),
        created_at: created_at.clone(),
        tour_name: project_tour_name(project_data),
        scene_count: scene_count(project_data),
        hotspot_count: count_hotspots(project_data),
        content_hash,
        origin: origin.to_string(),
        project_data: project_data.clone(),
    };

    let filename = format!(
        "snapshot_{}_{}.json",
        chrono::Utc::now().format("%Y%m%dT%H%M%S%.3fZ"),
        snapshot_id
    );
    let serialized = serde_json::to_string_pretty(&envelope).map_err(|error| {
        AppError::InternalError(format!("Serialize snapshot history failed: {}", error))
    })?;
    std::fs::write(history_dir.join(filename), serialized).map_err(AppError::IoError)?;
    prune_snapshot_history(project_dir)?;
    Ok(envelope)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn persist_snapshot_history_upgrades_auto_origin_for_identical_manual_save(
    ) -> Result<(), Box<dyn std::error::Error>> {
        let temp = tempfile::tempdir()?;
        let project_dir = temp.path();
        let project_data = serde_json::json!({
            "tourName": "Origin Test",
            "inventory": {},
            "sceneOrder": [],
            "scenes": [],
        });

        let initial = persist_snapshot_history(project_dir, &project_data, "auto")?;
        let upgraded = persist_snapshot_history(project_dir, &project_data, "manual")?;

        assert_eq!(initial.snapshot_id, upgraded.snapshot_id);
        assert_eq!(upgraded.origin, "manual");

        let history = load_snapshot_history(project_dir)?;
        assert_eq!(history.len(), 1);
        assert_eq!(history[0].origin, "manual");

        Ok(())
    }
}

pub(super) fn snapshot_item_from_envelope(
    envelope: &SnapshotHistoryEnvelope,
) -> SnapshotHistoryItem {
    SnapshotHistoryItem {
        snapshot_id: envelope.snapshot_id.clone(),
        created_at: envelope.created_at.clone(),
        tour_name: envelope.tour_name.clone(),
        scene_count: envelope.scene_count,
        hotspot_count: envelope.hotspot_count,
        content_hash: envelope.content_hash.clone(),
        origin: envelope.origin.clone(),
    }
}

pub(super) fn read_snapshot(project_dir: &Path) -> Result<serde_json::Value, AppError> {
    let snapshot_path = project_dir.join(SNAPSHOT_FILENAME);
    let raw = std::fs::read_to_string(snapshot_path).map_err(AppError::IoError)?;
    serde_json::from_str::<serde_json::Value>(&raw)
        .map_err(|error| AppError::ValidationError(format!("Invalid snapshot JSON: {}", error)))
}

pub(super) fn validate_snapshot_project(
    project_data: &serde_json::Value,
) -> Result<serde_json::Value, AppError> {
    let obj = project_data.as_object().ok_or_else(|| {
        AppError::ValidationError("Snapshot payload must be a JSON object".into())
    })?;
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

pub(super) async fn sync_snapshot(
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

    let project_dir =
        StorageManager::ensure_project_dir(&user.id, &session_id).map_err(AppError::IoError)?;
    write_current_snapshot(&project_dir, &validated_project)?;
    let history_entry = persist_snapshot_history(
        &project_dir,
        &validated_project,
        payload.save_origin.as_deref().unwrap_or("auto"),
    )?;

    let response = SnapshotSyncResponse {
        session_id,
        updated_at: history_entry.created_at,
        scene_count: scene_count(&validated_project),
        hotspot_count: count_hotspots(&validated_project),
    };

    Ok(HttpResponse::Ok().json(response))
}

pub(super) async fn list_project_snapshots(
    req: HttpRequest,
    path: web::Path<String>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let session_id = path.into_inner();
    let project_dir =
        StorageManager::get_user_project_path(&user.id, &session_id).map_err(AppError::IoError)?;

    let history = load_snapshot_history(&project_dir)?
        .into_iter()
        .map(|entry| snapshot_item_from_envelope(&entry))
        .collect::<Vec<_>>();

    Ok(HttpResponse::Ok().json(history))
}

pub(super) async fn load_project_snapshot(
    req: HttpRequest,
    path: web::Path<(String, String)>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let (session_id, snapshot_id) = path.into_inner();
    let user_root = StorageManager::get_user_path(&user.id).map_err(AppError::IoError)?;
    let project_dir =
        StorageManager::get_user_project_path(&user.id, &session_id).map_err(AppError::IoError)?;

    let history = load_snapshot_history(&project_dir)?;
    let snapshot = history
        .into_iter()
        .find(|entry| entry.snapshot_id == snapshot_id)
        .ok_or_else(|| AppError::ValidationError("Snapshot not found".into()))?;

    project_assets::repair_missing_project_assets(&user_root, &project_dir, &snapshot.project_data)?;

    Ok(HttpResponse::Ok().json(SnapshotRestoreResponse {
        session_id,
        snapshot_id,
        project_data: snapshot.project_data,
    }))
}

pub(super) async fn restore_project_snapshot(
    req: HttpRequest,
    path: web::Path<(String, String)>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or(AppError::Unauthorized("Authentication required".into()))?;
    let (session_id, snapshot_id) = path.into_inner();
    let project_dir =
        StorageManager::get_user_project_path(&user.id, &session_id).map_err(AppError::IoError)?;

    let history = load_snapshot_history(&project_dir)?;
    let restored = history
        .into_iter()
        .find(|entry| entry.snapshot_id == snapshot_id)
        .ok_or_else(|| AppError::ValidationError("Snapshot not found".into()))?;

    write_current_snapshot(&project_dir, &restored.project_data)?;
    let latest_entry = persist_snapshot_history(&project_dir, &restored.project_data, "manual")?;

    Ok(HttpResponse::Ok().json(SnapshotRestoreResponse {
        session_id,
        snapshot_id: latest_entry.snapshot_id,
        project_data: restored.project_data,
    }))
}
