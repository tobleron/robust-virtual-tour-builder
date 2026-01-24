use crate::models::AppError;
use sqlx::sqlite::SqlitePool;
use std::env;

pub struct DatabaseManager {
    #[allow(dead_code)]
    pub pool: SqlitePool,
}

#[allow(dead_code)]
impl DatabaseManager {
    pub async fn new() -> Result<Self, AppError> {
        let database_url =
            env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite://data/database.db".to_string());

        let pool = SqlitePool::connect(&database_url)
            .await
            .map_err(|e| AppError::InternalError(format!("Failed to connect to SQLite: {}", e)))?;

        // Automatically run migrations on startup
        sqlx::migrate!("./migrations")
            .run(&pool)
            .await
            .map_err(|e| AppError::InternalError(format!("Database migration failed: {}", e)))?;

        Ok(Self { pool })
    }
}
