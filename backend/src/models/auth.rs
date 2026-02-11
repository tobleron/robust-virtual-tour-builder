use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

// --- SESSION MODELS ---

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Session {
    pub id: String,
    pub user_id: String,
    pub expires_at: DateTime<Utc>,
}

impl Session {
    #[allow(dead_code)]
    pub async fn create(
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
}

// --- USER MODELS ---

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct User {
    pub id: String,
    pub email: String,
    #[serde(skip)]
    #[allow(dead_code)]
    pub password_hash: String,
    pub name: String,
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

impl User {
    #[allow(dead_code)]
    pub async fn create(
        pool: &sqlx::SqlitePool,
        email: &str,
        password_hash: &str,
        name: &str,
    ) -> Result<User, sqlx::Error> {
        let id = uuid::Uuid::new_v4().to_string();
        let user = sqlx::query_as::<_, User>(
            r#"
            INSERT INTO users (id, email, password_hash, name)
            VALUES (?, ?, ?, ?)
            RETURNING id, email, password_hash, name, theme_preference, language_preference, created_at
            "#
        )
        .bind(&id)
        .bind(email)
        .bind(password_hash)
        .bind(name)
        .fetch_one(pool)
        .await?;

        Ok(user)
    }

    #[allow(dead_code)]
    pub async fn find_by_email(
        pool: &sqlx::SqlitePool,
        email: &str,
    ) -> Result<Option<User>, sqlx::Error> {
        sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = ?")
            .bind(email)
            .fetch_optional(pool)
            .await
    }
}
