use crate::metrics::ACTIVE_SESSIONS;
#[cfg(feature = "builder-runtime")]
use crate::services::geocoding;
use actix_web::{HttpResponse, Responder, web};
use serde::Serialize;
use sqlx::SqlitePool;
use std::path::{Path, PathBuf};

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct HealthComponent {
    status: String,
    message: Option<String>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct HealthDisk {
    status: String,
    cache_dir: String,
    database_dir: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct HealthCache {
    cache_size: usize,
    max_cache_size: usize,
    hits: u64,
    misses: u64,
    hit_rate: f64,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct HealthRuntime {
    active_sessions: u64,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct HealthResponse {
    status: String,
    timestamp: String,
    db: HealthComponent,
    disk: HealthDisk,
    cache: HealthCache,
    runtime: HealthRuntime,
}

fn sqlite_data_dir_from_url(database_url: &str) -> PathBuf {
    let trimmed = database_url.trim_start_matches("sqlite://");
    let db_path = Path::new(trimmed);
    db_path
        .parent()
        .map_or_else(|| PathBuf::from("data"), PathBuf::from)
}

fn cache_dir_from_env() -> PathBuf {
    let cache_file = std::env::var("GEOCODING_CACHE_FILE")
        .unwrap_or_else(|_| "../cache/geocoding.json".to_string());
    Path::new(&cache_file)
        .parent()
        .map_or_else(|| PathBuf::from("../cache"), PathBuf::from)
}

fn probe_dir_writable(path: &Path, probe_name: &str) -> Result<(), String> {
    std::fs::create_dir_all(path)
        .map_err(|e| format!("create_dir_all failed for '{}': {}", path.display(), e))?;

    let probe_file = path.join(format!(".health_probe_{}", probe_name));
    std::fs::write(&probe_file, b"ok")
        .map_err(|e| format!("write failed for '{}': {}", probe_file.display(), e))?;

    let _ = std::fs::remove_file(&probe_file);
    Ok(())
}

pub async fn health_check(db_pool: web::Data<SqlitePool>) -> impl Responder {
    let now = chrono::Utc::now().to_rfc3339();

    // DB health: lightweight probe query.
    let db_probe = sqlx::query_scalar::<_, i64>("SELECT 1")
        .fetch_one(db_pool.get_ref())
        .await;
    let (db_ok, db_message) = match db_probe {
        Ok(_) => (true, None),
        Err(e) => (false, Some(format!("database probe failed: {}", e))),
    };

    // Disk health: ensure cache/database directories are writable.
    let database_url =
        std::env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite://data/database.db".to_string());
    let database_dir = sqlite_data_dir_from_url(&database_url);
    let cache_dir = cache_dir_from_env();

    let cache_probe = probe_dir_writable(&cache_dir, "cache");
    let db_dir_probe = probe_dir_writable(&database_dir, "db");
    let disk_ok = cache_probe.is_ok() && db_dir_probe.is_ok();

    let disk_message = match (cache_probe, db_dir_probe) {
        (Ok(_), Ok(_)) => None,
        (Err(cache_err), Ok(_)) => Some(cache_err),
        (Ok(_), Err(db_err)) => Some(db_err),
        (Err(cache_err), Err(db_err)) => Some(format!("{} | {}", cache_err, db_err)),
    };

    // Geocoding cache observability.
    #[cfg(feature = "builder-runtime")]
    let geocode_info = geocoding::get_info().await;
    #[cfg(feature = "builder-runtime")]
    let total_requests = geocode_info.stats.hits + geocode_info.stats.misses;
    #[cfg(feature = "builder-runtime")]
    let hit_rate = if total_requests > 0 {
        (geocode_info.stats.hits as f64 / total_requests as f64) * 100.0
    } else {
        0.0
    };
    #[cfg(not(feature = "builder-runtime"))]
    let hit_rate = 0.0;

    let healthy = db_ok && disk_ok;
    let active_sessions = ACTIVE_SESSIONS
        .as_ref()
        .map(|g| g.get().max(0.0) as u64)
        .unwrap_or(0);
    let response = HealthResponse {
        status: if healthy { "ok" } else { "degraded" }.to_string(),
        timestamp: now,
        db: HealthComponent {
            status: if db_ok { "ok" } else { "error" }.to_string(),
            message: db_message.clone(),
        },
        disk: HealthDisk {
            status: if disk_ok { "ok" } else { "error" }.to_string(),
            cache_dir: cache_dir.display().to_string(),
            database_dir: database_dir.display().to_string(),
        },
        cache: HealthCache {
            #[cfg(feature = "builder-runtime")]
            cache_size: geocode_info.cache_size,
            #[cfg(not(feature = "builder-runtime"))]
            cache_size: 0,
            #[cfg(feature = "builder-runtime")]
            max_cache_size: geocoding::MAX_CACHE_SIZE,
            #[cfg(not(feature = "builder-runtime"))]
            max_cache_size: 0,
            #[cfg(feature = "builder-runtime")]
            hits: geocode_info.stats.hits,
            #[cfg(not(feature = "builder-runtime"))]
            hits: 0,
            #[cfg(feature = "builder-runtime")]
            misses: geocode_info.stats.misses,
            #[cfg(not(feature = "builder-runtime"))]
            misses: 0,
            hit_rate,
        },
        runtime: HealthRuntime { active_sessions },
    };

    if healthy {
        HttpResponse::Ok().json(response)
    } else {
        let details = match (db_message.clone(), disk_message) {
            (Some(db_err), Some(disk_err)) => format!("{} | {}", db_err, disk_err),
            (Some(db_err), None) => db_err,
            (None, Some(disk_err)) => disk_err,
            (None, None) => "one or more health probes failed".to_string(),
        };
        sentry::with_scope(
            |scope| {
                scope.set_tag("system-health", "critical");
                scope.set_extra("dbStatus", serde_json::json!(response.db.status));
                scope.set_extra("diskStatus", serde_json::json!(response.disk.status));
                scope.set_extra(
                    "activeSessions",
                    serde_json::json!(response.runtime.active_sessions),
                );
                scope.set_extra("details", serde_json::json!(details.clone()));
            },
            || {
                sentry::capture_message(
                    "Health endpoint reported degraded status",
                    sentry::Level::Error,
                )
            },
        );
        HttpResponse::ServiceUnavailable()
            .insert_header(("Retry-After", "5"))
            .json(serde_json::json!({
                "status": response.status,
                "timestamp": response.timestamp,
                "db": response.db,
                "disk": response.disk,
                "cache": response.cache,
                "runtime": response.runtime,
                "details": details
            }))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sqlite_dir_defaults_to_data_parent() {
        let dir = sqlite_data_dir_from_url("sqlite://data/database.db");
        assert_eq!(dir, PathBuf::from("data"));
    }

    #[test]
    fn sqlite_dir_handles_nested_path() {
        let dir = sqlite_data_dir_from_url("sqlite://foo/bar/baz.db");
        assert_eq!(dir, PathBuf::from("foo/bar"));
    }
}
