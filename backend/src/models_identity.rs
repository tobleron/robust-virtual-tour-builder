use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct User {
    pub id: String,
    pub email: String,
    pub username: Option<String>,
    #[serde(skip)]
    #[allow(dead_code)]
    pub password_hash: String,
    pub name: String,
    pub role: String,
    pub status: Option<String>,
    pub email_verified_at: Option<DateTime<Utc>>,
    pub force_step_up_reason: Option<String>,
    pub force_step_up_until: Option<DateTime<Utc>>,
    pub theme_preference: Option<String>,
    pub language_preference: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthResponse {
    pub token: String,
    pub user: User,
}

pub async fn create_user(
    pool: &sqlx::SqlitePool,
    email: &str,
    username: &str,
    password_hash: &str,
    name: &str,
    role: &str,
) -> Result<User, sqlx::Error> {
    let id = uuid::Uuid::new_v4().to_string();
    let user = sqlx::query_as::<_, User>(
        r#"
        INSERT INTO users (id, email, username, password_hash, name, role, status)
        VALUES (?, ?, ?, ?, ?, ?, 'pending_verification')
        RETURNING id, email, username, password_hash, name, role, status, email_verified_at, force_step_up_reason, force_step_up_until, theme_preference, language_preference, created_at
        "#,
    )
    .bind(&id)
    .bind(email)
    .bind(username)
    .bind(password_hash)
    .bind(name)
    .bind(role)
    .fetch_one(pool)
    .await?;

    Ok(user)
}

pub async fn find_user_by_email(
    pool: &sqlx::SqlitePool,
    email: &str,
) -> Result<Option<User>, sqlx::Error> {
    sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = ?")
        .bind(email)
        .fetch_optional(pool)
        .await
}
