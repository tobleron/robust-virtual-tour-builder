use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize, Clone, sqlx::Type)]
#[serde(rename_all = "lowercase")]
pub enum ProjectStatus {
    Draft,
    Published,
    Archived,
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

pub async fn create_project(
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

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Session {
    pub id: String,
    pub user_id: String,
    pub expires_at: DateTime<Utc>,
}

pub async fn create_session(
    pool: &sqlx::SqlitePool,
    user_id: &str,
    expires_at: DateTime<Utc>,
) -> Result<Session, sqlx::Error> {
    let id = uuid::Uuid::new_v4().to_string();
    let session = sqlx::query_as::<_, Session>(
        r#"
        INSERT INTO sessions (id, user_id, expires_at)
        VALUES (?, ?, ?)
        RETURNING id, user_id, expires_at
        "#,
    )
    .bind(&id)
    .bind(user_id)
    .bind(expires_at)
    .fetch_one(pool)
    .await?;
    Ok(session)
}
