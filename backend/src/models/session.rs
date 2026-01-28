use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Session {
    pub id: String,
    pub user_id: String,
    pub expires_at: DateTime<Utc>,
}

impl Session {
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
            "#
        )
        .bind(&id)
        .bind(user_id)
        .bind(expires_at)
        .fetch_one(pool)
        .await?;
        Ok(session)
    }
}
