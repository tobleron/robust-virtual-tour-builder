use crate::models::AppError;
use sqlx::sqlite::{SqliteConnectOptions, SqlitePool};
use std::env;
use std::str::FromStr;

pub struct DatabaseManager;

impl DatabaseManager {
    pub async fn new() -> Result<SqlitePool, AppError> {
        let database_url =
            env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite://data/database.db".to_string());

        // Ensure the directory exists
        if database_url.starts_with("sqlite://") {
            let path_str = database_url.trim_start_matches("sqlite://");
            if let Some(parent) = std::path::Path::new(path_str).parent() {
                std::fs::create_dir_all(parent).ok();
            }
        }

        let options = SqliteConnectOptions::from_str(&database_url)
            .map_err(|e| AppError::InternalError(format!("Invalid database URL: {}", e)))?
            .create_if_missing(true);

        let pool = SqlitePool::connect_with(options)
            .await
            .map_err(|e| AppError::InternalError(format!("Failed to connect to SQLite: {}", e)))?;

        // Automatically run migrations on startup
        sqlx::migrate!("./migrations")
            .run(&pool)
            .await
            .map_err(|e| AppError::InternalError(format!("Database migration failed: {}", e)))?;

        Ok(pool)
    }
}
