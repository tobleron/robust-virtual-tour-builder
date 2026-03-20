/* backend/src/api/project.rs - Consolidated Project API */
#![allow(dead_code)]

#[path = "project_assets.rs"]
mod project_assets;
#[path = "project_dashboard.rs"]
mod project_dashboard;
#[path = "project_package.rs"]
mod project_package;
#[path = "project_save.rs"]
mod project_save;
#[path = "project_snapshot.rs"]
mod project_snapshot;
#[path = "project_validation.rs"]
mod project_validation;

use actix_multipart::Multipart;
use actix_web::{HttpRequest, HttpResponse, web};
use std::path::{Path, PathBuf};

use crate::models::AppError;
use crate::pathfinder::PathRequest;

#[allow(unused_imports)]
pub use project_assets::{
    BulkDeleteDashboardProjectsFailure, BulkDeleteDashboardProjectsPayload,
    BulkDeleteDashboardProjectsResponse, SnapshotAssetSyncResponse,
};
#[allow(unused_imports)]
pub use project_dashboard::{DashboardProjectSummary, DashboardProjectsPage, DashboardProjectsQuery};
use project_snapshot::SnapshotHistoryEnvelope;
#[allow(unused_imports)]
pub use project_snapshot::{
    SnapshotHistoryItem, SnapshotRestoreResponse, SnapshotSyncPayload, SnapshotSyncResponse,
};
#[allow(unused_imports)]
pub use project_validation::ValidatePayload;

const SNAPSHOT_FILENAME: &str = "project_snapshot.json";
const SNAPSHOT_HISTORY_DIR: &str = "snapshots";
const MAX_PROJECT_SNAPSHOTS: usize = 9;

fn default_snapshot_origin() -> String {
    project_snapshot::default_snapshot_origin()
}

fn count_hotspots(project_data: &serde_json::Value) -> usize {
    project_snapshot::count_hotspots(project_data)
}

fn scene_count(project_data: &serde_json::Value) -> usize {
    project_snapshot::scene_count(project_data)
}

fn project_tour_name(project_data: &serde_json::Value) -> String {
    project_snapshot::project_tour_name(project_data)
}

fn snapshot_history_dir(project_dir: &Path) -> PathBuf {
    project_snapshot::snapshot_history_dir(project_dir)
}

fn snapshot_content_hash(project_data: &serde_json::Value) -> Result<String, AppError> {
    project_snapshot::snapshot_content_hash(project_data)
}

fn write_current_snapshot(
    project_dir: &Path,
    project_data: &serde_json::Value,
) -> Result<(), AppError> {
    project_snapshot::write_current_snapshot(project_dir, project_data)
}

fn load_snapshot_history(project_dir: &Path) -> Result<Vec<SnapshotHistoryEnvelope>, AppError> {
    project_snapshot::load_snapshot_history(project_dir)
}

fn prune_snapshot_history(project_dir: &Path) -> Result<(), AppError> {
    project_snapshot::prune_snapshot_history(project_dir)
}

fn persist_snapshot_history(
    project_dir: &Path,
    project_data: &serde_json::Value,
    origin: &str,
) -> Result<SnapshotHistoryEnvelope, AppError> {
    project_snapshot::persist_snapshot_history(project_dir, project_data, origin)
}

fn snapshot_item_from_envelope(envelope: &SnapshotHistoryEnvelope) -> SnapshotHistoryItem {
    project_snapshot::snapshot_item_from_envelope(envelope)
}

fn persist_project_asset(
    project_dir: &Path,
    filename: &str,
    temp_path: &Path,
) -> Result<(), AppError> {
    project_assets::persist_project_asset(project_dir, filename, temp_path)
}

fn find_existing_project_asset(project_dir: &Path, filename: &str) -> Option<PathBuf> {
    project_assets::find_existing_project_asset(project_dir, filename)
}

fn repair_missing_project_assets(
    user_root: &Path,
    project_dir: &Path,
    project_data: &serde_json::Value,
) -> Result<(), AppError> {
    project_assets::repair_missing_project_assets(user_root, project_dir, project_data)
}

fn read_snapshot(project_dir: &Path) -> Result<serde_json::Value, AppError> {
    project_snapshot::read_snapshot(project_dir)
}

fn validate_snapshot_project(
    project_data: &serde_json::Value,
) -> Result<serde_json::Value, AppError> {
    project_snapshot::validate_snapshot_project(project_data)
}

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

pub async fn save_project(req: HttpRequest, payload: Multipart) -> Result<HttpResponse, AppError> {
    project_save::save_project(req, payload).await
}

pub async fn load_project(req: HttpRequest, payload: Multipart) -> Result<HttpResponse, AppError> {
    project_assets::load_project(req, payload).await
}

pub async fn sync_snapshot(
    req: HttpRequest,
    payload: web::Json<SnapshotSyncPayload>,
) -> Result<HttpResponse, AppError> {
    project_snapshot::sync_snapshot(req, payload).await
}

pub async fn list_dashboard_projects(
    req: HttpRequest,
    query: web::Query<DashboardProjectsQuery>,
) -> Result<HttpResponse, AppError> {
    project_dashboard::list_dashboard_projects(req, query).await
}

pub async fn load_dashboard_project(
    req: HttpRequest,
    path: web::Path<String>,
) -> Result<HttpResponse, AppError> {
    project_dashboard::load_dashboard_project(req, path).await
}

pub async fn duplicate_dashboard_project(
    req: HttpRequest,
    path: web::Path<String>,
) -> Result<HttpResponse, AppError> {
    project_dashboard::duplicate_dashboard_project(req, path).await
}

pub async fn list_project_snapshots(
    req: HttpRequest,
    path: web::Path<String>,
) -> Result<HttpResponse, AppError> {
    project_snapshot::list_project_snapshots(req, path).await
}

pub async fn load_project_snapshot(
    req: HttpRequest,
    path: web::Path<(String, String)>,
) -> Result<HttpResponse, AppError> {
    project_snapshot::load_project_snapshot(req, path).await
}

pub async fn restore_project_snapshot(
    req: HttpRequest,
    path: web::Path<(String, String)>,
) -> Result<HttpResponse, AppError> {
    project_snapshot::restore_project_snapshot(req, path).await
}

pub async fn sync_snapshot_assets(
    req: HttpRequest,
    payload: Multipart,
) -> Result<HttpResponse, AppError> {
    project_assets::sync_snapshot_assets(req, payload).await
}

pub async fn delete_dashboard_project(
    req: HttpRequest,
    path: web::Path<String>,
) -> Result<HttpResponse, AppError> {
    project_assets::delete_dashboard_project(req, path).await
}

pub async fn bulk_delete_dashboard_projects(
    req: HttpRequest,
    payload: web::Json<BulkDeleteDashboardProjectsPayload>,
) -> Result<HttpResponse, AppError> {
    project_assets::bulk_delete_dashboard_projects(req, payload).await
}

pub async fn cleanup_backend_cache(req: HttpRequest) -> Result<HttpResponse, AppError> {
    project_assets::cleanup_backend_cache(req).await
}

#[tracing::instrument(skip(payload), name = "calculate_path")]
pub async fn calculate_path(payload: web::Json<PathRequest>) -> Result<HttpResponse, AppError> {
    project_validation::calculate_path(payload).await
}

pub async fn validate_project(
    req: HttpRequest,
    payload: web::Json<ValidatePayload>,
) -> Result<HttpResponse, AppError> {
    project_validation::validate_project(req, payload).await
}

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

pub async fn create_tour_package(
    req: HttpRequest,
    payload: Multipart,
) -> Result<HttpResponse, AppError> {
    project_package::create_tour_package(req, payload).await
}
