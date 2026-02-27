// @efficiency: infra-adapter
use crate::models::AppError;
use crate::metrics::{DB_POOL_ACTIVE, DB_POOL_IDLE, DB_POOL_SIZE};
use sqlx::sqlite::{SqliteConnectOptions, SqlitePool, SqlitePoolOptions};
use std::env;
use std::str::FromStr;
use std::time::Duration;

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

        let pool = SqlitePoolOptions::new()
            .min_connections(2)
            .max_connections(10)
            .idle_timeout(Some(Duration::from_secs(300)))
            .max_lifetime(Some(Duration::from_secs(1800)))
            .connect_with(options)
            .await
            .map_err(|e| AppError::InternalError(format!("Failed to connect to SQLite: {}", e)))?;

        Self::apply_pragmas(&pool).await?;

        // Automatically run migrations on startup
        sqlx::migrate!("./migrations")
            .run(&pool)
            .await
            .map_err(|e| AppError::InternalError(format!("Database migration failed: {}", e)))?;

        Self::update_pool_metrics(&pool);

        tracing::info!(
            "SQLite initialized with WAL mode and pool tuning: min=2 max=10 idle_timeout=300s max_lifetime=1800s busy_timeout=5000ms synchronous=NORMAL cache_size=-64000 mmap_size=268435456"
        );

        Ok(pool)
    }

    async fn apply_pragmas(pool: &SqlitePool) -> Result<(), AppError> {
        let pragmas = [
            "PRAGMA journal_mode=WAL;",
            "PRAGMA busy_timeout=5000;",
            "PRAGMA synchronous=NORMAL;",
            "PRAGMA cache_size=-64000;",
            "PRAGMA mmap_size=268435456;",
        ];

        for pragma in pragmas {
            sqlx::query(pragma).execute(pool).await.map_err(|e| {
                AppError::InternalError(format!("Failed to apply SQLite pragma '{}': {}", pragma, e))
            })?;
        }

        Ok(())
    }

    fn update_pool_metrics(pool: &SqlitePool) {
        let size_u32 = pool.size();
        let idle_u32 = (pool.num_idle() as u32).min(size_u32);
        let size = size_u32 as f64;
        let idle = idle_u32 as f64;
        let active = size_u32.saturating_sub(idle_u32) as f64;

        if let Some(metric) = &*DB_POOL_SIZE {
            metric.set(size);
        }
        if let Some(metric) = &*DB_POOL_IDLE {
            metric.set(idle);
        }
        if let Some(metric) = &*DB_POOL_ACTIVE {
            metric.set(active);
        }
    }
}
