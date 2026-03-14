use actix_files as fs;
use actix_session::{SessionMiddleware, storage::CookieSessionStore};
use actix_web::dev::Service;
use actix_web::http::header::{CACHE_CONTROL, HeaderValue, VARY};
use actix_web::middleware::Compress;
use actix_web::{App, HttpResponse, HttpServer, Responder, web};
use actix_web_prom::PrometheusMetricsBuilder;
use std::io;
use std::path::PathBuf;
use tokio::signal;
use tracing_actix_web::TracingLogger;

// Modules
mod api;
mod auth;
mod metrics;
mod middleware;
mod models;
mod pathfinder;
mod services;
mod startup;

use middleware::QuotaCheck;
use middleware::RequestTracker;
use middleware::rate_limiter::RateLimiters;
use services::database::DatabaseManager;
use services::media::StorageManager;
use services::project::ChunkedProjectExportUploadManager;
use services::project::ChunkedProjectImportManager;
use services::shutdown::{ShutdownManager, perform_shutdown_cleanup};
use services::upload_quota::{QuotaConfig, UploadQuotaManager};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum AppSurface {
    Builder,
    Portal,
}

impl AppSurface {
    fn from_env() -> Self {
        match std::env::var("APP_SURFACE")
            .unwrap_or_default()
            .trim()
            .to_ascii_lowercase()
            .as_str()
        {
            "portal" => Self::Portal,
            "builder" => Self::Builder,
            _ => Self::Builder,
        }
    }

    fn builder_dist_root() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../dist")
    }

    fn portal_dist_root() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../dist-portal")
    }

    fn dist_root(self) -> PathBuf {
        match self {
            Self::Builder => Self::builder_dist_root(),
            Self::Portal => Self::portal_dist_root(),
        }
    }
}

#[cfg(unix)]
async fn wait_for_shutdown_signal() -> &'static str {
    let mut sigterm = match tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
    {
        Ok(stream) => stream,
        Err(err) => {
            tracing::error!(%err, "Failed to subscribe to SIGTERM; falling back to Ctrl+C only");
            let _ = signal::ctrl_c().await;
            return "CTRL_C_FALLBACK";
        }
    };

    tokio::select! {
        _ = signal::ctrl_c() => "CTRL_C",
        _ = sigterm.recv() => "SIGTERM",
    }
}

#[cfg(not(unix))]
async fn wait_for_shutdown_signal() -> &'static str {
    let _ = signal::ctrl_c().await;
    "CTRL_C"
}

fn is_hashed_static_asset(path: &str) -> bool {
    // Match patterns like /static/js/index-a1b2c3.js
    if !(path.starts_with("/static/") || path.starts_with("/assets/")) {
        return false;
    }
    let file = match path.rsplit('/').next() {
        Some(v) => v,
        None => return false,
    };
    let mut parts = file.splitn(2, '.');
    let stem = match parts.next() {
        Some(v) => v,
        None => return false,
    };
    let hash = match stem.rsplit('-').next() {
        Some(v) => v,
        None => return false,
    };
    hash.len() >= 6 && hash.chars().all(|c| c.is_ascii_hexdigit())
}

#[cfg(test)]
mod cache_header_tests {
    use super::is_hashed_static_asset;

    #[test]
    fn detects_hashed_static_and_assets_paths() {
        assert!(is_hashed_static_asset("/static/js/index-a1b2c3.js"));
        assert!(is_hashed_static_asset("/assets/index-abcdef12.css"));
        assert!(is_hashed_static_asset("/assets/chunk-123abc.mjs"));
    }

    #[test]
    fn ignores_non_hashed_or_non_static_paths() {
        assert!(!is_hashed_static_asset("/static/js/index.js"));
        assert!(!is_hashed_static_asset("/images/photo-a1b2c3.webp"));
        assert!(!is_hashed_static_asset("/api/project/load"));
    }
}

async fn health_check(shutdown_manager: web::Data<ShutdownManager>) -> impl Responder {
    if shutdown_manager.is_shutting_down() {
        let retry_after = shutdown_manager.estimated_retry_after_secs();
        return HttpResponse::ServiceUnavailable()
            .insert_header(("Retry-After", retry_after.to_string()))
            .json(serde_json::json!({
                "status": "draining",
                "draining": true,
                "retryAfterSec": retry_after,
                "timestamp": chrono::Utc::now().to_rfc3339(),
            }));
    }
    HttpResponse::Ok().json(serde_json::json!({
        "status": "ok",
        "draining": false,
        "timestamp": chrono::Utc::now().to_rfc3339(),
    }))
}

#[actix_web::main]
async fn main() -> io::Result<()> {
    // Load environment variables from .env file
    let _ = dotenvy::dotenv();

    let app_surface = AppSurface::from_env();

    // Initialize Logging
    let _guards = startup::init_logging();

    // Validate Auth Config
    startup::validate_auth_config()?;

    // Initialize Database
    let pool = DatabaseManager::new().await.map_err(|e| {
        io::Error::new(
            io::ErrorKind::Other,
            format!("Failed to init database: {}", e),
        )
    })?;
    let db_pool = web::Data::new(pool);

    // Initialize Storage
    StorageManager::init().map_err(|e| {
        io::Error::new(
            io::ErrorKind::Other,
            format!("Failed to init storage: {}", e),
        )
    })?;
    services::portal::init_storage().map_err(|e| {
        io::Error::new(
            io::ErrorKind::Other,
            format!("Failed to init portal storage: {}", e),
        )
    })?;

    // Ensure logs directory exists - handled in init_logging

    // Load geocoding cache from disk
    if let Err(e) = services::geocoding::load_cache_from_disk().await {
        tracing::warn!("Failed to load geocoding cache: {}", e);
    }

    // Initialize shutdown manager
    let shutdown_timeout = startup::shutdown_timeout();
    let shutdown_manager = web::Data::new(ShutdownManager::new(shutdown_timeout));

    tracing::info!(
        timeout_secs = shutdown_timeout.as_secs(),
        "Shutdown manager initialized"
    );

    // Initialize upload quota manager
    let quota_config = QuotaConfig::from_env();
    let quota_manager = web::Data::new(UploadQuotaManager::new(quota_config.clone()));
    let project_import_uploads =
        web::Data::new(ChunkedProjectImportManager::new().map_err(|e| {
            io::Error::other(format!(
                "Failed to initialize chunked import upload manager: {}",
                e
            ))
        })?);
    let project_export_uploads =
        web::Data::new(ChunkedProjectExportUploadManager::new().map_err(|e| {
            io::Error::other(format!(
                "Failed to initialize chunked export upload manager: {}",
                e
            ))
        })?);
    if let Err(e) = project_import_uploads.load_sessions_manifest().await {
        tracing::warn!(error = %e, "Failed to restore chunked import session manifest");
    }
    if let Err(e) = project_export_uploads.load_sessions_manifest().await {
        tracing::warn!(error = %e, "Failed to restore chunked export session manifest");
    }

    let disk_bypass = std::env::var("ALLOW_DISK_CHECK_BYPASS").unwrap_or_default();

    tracing::info!(
        "Upload quotas: max_payload={} MB, max_concurrent_per_ip={}, max_total={} GB, disk_bypass={}",
        quota_config.max_payload_size / (1024 * 1024),
        quota_config.max_concurrent_per_ip,
        quota_config.max_total_concurrent_size / (1024 * 1024 * 1024),
        disk_bypass
    );

    let prometheus = PrometheusMetricsBuilder::new("vtb_api")
        .endpoint("/metrics")
        .registry(prometheus::default_registry().clone())
        .build()
        .map_err(|e| {
            io::Error::new(
                io::ErrorKind::Other,
                format!("Failed to init prometheus: {}", e),
            )
        })?;

    // Initialize Rate Limiters
    let rate_limiters = web::Data::new(RateLimiters::new());

    tracing::info!(
        environment = if startup::is_production() {
            "production"
        } else {
            "development"
        },
        app_surface = ?app_surface,
        "Rate limiters configured"
    );

    let session_key = startup::session_key()?;
    let shutdown_manager_server = shutdown_manager.clone();
    let db_pool_server = db_pool.clone();
    let project_import_uploads_for_app = project_import_uploads.clone();
    let project_export_uploads_for_app = project_export_uploads.clone();
    let worker_count = startup::server_worker_count();
    let dist_root = app_surface.dist_root();

    let server = HttpServer::new(move || {
        let app_surface = app_surface;
        let dist_root = dist_root.clone();
        App::new()
            .app_data(web::PayloadConfig::new(quota_config.max_payload_size))
            .app_data(quota_manager.clone())
            .app_data(project_import_uploads_for_app.clone())
            .app_data(project_export_uploads_for_app.clone())
            .app_data(shutdown_manager_server.clone())
            .app_data(db_pool_server.clone())
            .wrap(QuotaCheck)
            .wrap(RequestTracker)
            .wrap(Compress::default())
            .wrap_fn(|req, srv| {
                let path = req.path().to_owned();
                let fut = srv.call(req);
                async move {
                    let mut res = fut.await?;
                    res.headers_mut()
                        .insert(VARY, HeaderValue::from_static("Accept-Encoding"));
                    if is_hashed_static_asset(&path) {
                        res.headers_mut().insert(
                            CACHE_CONTROL,
                            HeaderValue::from_static("public, max-age=31536000, immutable"),
                        );
                    }
                    Ok(res)
                }
            })
            .wrap(TracingLogger::default())
            .wrap(startup::security_headers())
            .wrap(SessionMiddleware::new(
                CookieSessionStore::default(),
                session_key.clone(),
            ))
            .wrap(startup::cors())
            .wrap(prometheus.clone())
            .route(
                "/health",
                web::get()
                    .to(health_check)
                    .wrap(middleware::rate_limiter::RateLimitResponseTransformer::new(
                        "health",
                    ))
                    .wrap(actix_governor::Governor::new(&rate_limiters.health)),
            )
            .configure(|cfg| match app_surface {
                AppSurface::Builder => api::config(cfg, &rate_limiters),
                AppSurface::Portal => api::config_portal(cfg, &rate_limiters),
            })
            .configure({
                let static_root = dist_root.clone();
                move |cfg: &mut web::ServiceConfig| {
                    let static_dir = static_root.join("static");
                    let image_dir = static_root.join("images");
                    if static_dir.is_dir() {
                        cfg.service(fs::Files::new("/static", static_dir));
                    }
                    if image_dir.is_dir() {
                        cfg.service(fs::Files::new("/images", image_dir));
                    }
                }
            })
            .configure(move |cfg: &mut web::ServiceConfig| match app_surface {
                AppSurface::Builder => {
                    cfg.service(fs::Files::new("/sounds", "../public/sounds"));
                    cfg.service(fs::Files::new("/libs", "../public/libs"));
                    cfg.route(
                        "/service-worker.js",
                        web::get()
                            .to(|| async { fs::NamedFile::open("../dist/service-worker.js") }),
                    );
                }
                AppSurface::Portal => {}
            })
            .route(
                "/manifest.json",
                web::get().to({
                    let dist_root = dist_root.clone();
                    move || {
                        let path = dist_root.join("manifest.json");
                        async move { fs::NamedFile::open(path) }
                    }
                }),
            )
            .route(
                "/asset-manifest.json",
                web::get().to({
                    let dist_root = dist_root.clone();
                    move || {
                        let path = dist_root.join("asset-manifest.json");
                        async move { fs::NamedFile::open(path) }
                    }
                }),
            )
            .route(
                "/",
                web::get().to({
                    let dist_root = dist_root.clone();
                    move || {
                        let path = dist_root.join("index.html");
                        async move { fs::NamedFile::open(path) }
                    }
                }),
            )
            .default_service(web::get().to({
                let dist_root = dist_root.clone();
                move || {
                    let path = dist_root.join("index.html");
                    async move { fs::NamedFile::open(path) }
                }
            }))
    })
    .workers(worker_count)
    .shutdown_timeout(shutdown_timeout.as_secs() as u64);

    tracing::info!(
        worker_count,
        "Configured backend HTTP worker count before binding"
    );

    let server = server.bind(("0.0.0.0", 8080)).map_err(|err| {
        tracing::error!(%err, "Failed to bind backend HTTP server to 0.0.0.0:8080");
        err
    })?;

    tracing::info!("Backend HTTP server bound to 0.0.0.0:8080");

    let server = server.run();

    // Get server handle for graceful shutdown
    let server_handle = server.handle();

    // Spawn server
    let server_task = tokio::spawn(server);

    // Wait for shutdown signal
    let shutdown_manager_clone = shutdown_manager.clone();
    let project_import_uploads_for_shutdown = project_import_uploads.clone();
    let project_export_uploads_for_shutdown = project_export_uploads.clone();
    tokio::spawn(async move {
        let signal_name = wait_for_shutdown_signal().await;
        tracing::info!(signal = signal_name, "Received shutdown signal");

        shutdown_manager_clone.begin_shutdown();

        // Stop accepting new connections
        server_handle.stop(true).await;

        // Perform cleanup
        perform_shutdown_cleanup(
            &shutdown_manager_clone,
            &project_import_uploads_for_shutdown,
            &project_export_uploads_for_shutdown,
        )
        .await;
    });

    // Wait for server to finish
    match server_task.await {
        Ok(Ok(())) => {
            tracing::info!("Backend HTTP server exited normally");
        }
        Ok(Err(server_err)) => {
            tracing::error!(error = ?server_err, "Backend HTTP server terminated with an error");
            return Err(io::Error::new(
                io::ErrorKind::Other,
                format!("Backend HTTP server failed: {}", server_err),
            ));
        }
        Err(join_err) => {
            tracing::error!(error = ?join_err, "Backend HTTP server task panicked");
            return Err(io::Error::new(io::ErrorKind::Other, join_err));
        }
    }

    Ok(())
}
