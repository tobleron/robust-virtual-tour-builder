use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
#[allow(unused_imports)]
use uuid::Uuid;

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize, Clone, sqlx::FromRow)]
#[serde(rename_all = "camelCase")]
pub struct User {
    pub id: String, // SQLite uses TEXT for UUIDs
    pub email: String,
    pub google_id: String,
    pub name: String,
    pub avatar_url: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthResponse {
    pub token: String,
    pub user: User,
}
