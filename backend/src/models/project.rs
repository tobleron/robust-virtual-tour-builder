use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

// --- PROJECT MODELS ---

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize, Clone, sqlx::Type)]
#[serde(rename_all = "lowercase")]
pub enum ProjectStatus {
    Draft,
    Published,
    Archived,
}

impl From<String> for ProjectStatus {
    fn from(s: String) -> Self {
        match s.as_str() {
            "published" => ProjectStatus::Published,
            "archived" => ProjectStatus::Archived,
            _ => ProjectStatus::Draft,
        }
    }
}

impl ToString for ProjectStatus {
    fn to_string(&self) -> String {
        match self {
            ProjectStatus::Draft => "draft".to_string(),
            ProjectStatus::Published => "published".to_string(),
            ProjectStatus::Archived => "archived".to_string(),
        }
    }
}

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Project {
    pub id: String,
    pub user_id: String,
    pub name: String,
    pub data: String,
    pub status: String,
    pub scene_count: i64,
    pub hotspot_count: i64,
    pub updated_at: DateTime<Utc>,
}

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProjectSyncRequest {
    pub project_id: Option<String>,
    pub name: String,
    pub status: String,
    pub data: serde_json::Value,
    pub scene_count: Option<i64>,
    pub hotspot_count: Option<i64>,
}

impl Project {
    #[allow(dead_code)]
    pub async fn create(
        pool: &sqlx::SqlitePool,
        user_id: &str,
        name: &str,
        data: &str,
        status: &str,
        scene_count: i64,
        hotspot_count: i64,
    ) -> Result<Project, sqlx::Error> {
        let id = uuid::Uuid::new_v4().to_string();
        let project = sqlx::query_as::<_, Project>(
            r#"
            INSERT INTO projects (id, user_id, name, data, status, scene_count, hotspot_count)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            RETURNING id, user_id, name, data, status, scene_count, hotspot_count, updated_at
            "#,
        )
        .bind(&id)
        .bind(user_id)
        .bind(name)
        .bind(data)
        .bind(status)
        .bind(scene_count)
        .bind(hotspot_count)
        .fetch_one(pool)
        .await?;
        Ok(project)
    }
}

// --- VALIDATION MODELS ---

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ValidationReport {
    pub broken_links_removed: u32,
    pub orphaned_scenes: Vec<String>,
    pub unused_files: Vec<String>,
    pub warnings: Vec<String>,
    pub errors: Vec<String>,
}

impl Default for ValidationReport {
    fn default() -> Self {
        Self::new()
    }
}

impl ValidationReport {
    pub fn new() -> Self {
        ValidationReport {
            broken_links_removed: 0,
            orphaned_scenes: Vec::new(),
            unused_files: Vec::new(),
            warnings: Vec::new(),
            errors: Vec::new(),
        }
    }

    pub fn has_issues(&self) -> bool {
        self.broken_links_removed > 0
            || !self.orphaned_scenes.is_empty()
            || !self.unused_files.is_empty()
            || !self.errors.is_empty()
    }
}
