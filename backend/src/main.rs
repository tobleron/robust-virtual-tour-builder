use actix_files as fs;
use actix_session::{SessionMiddleware, storage::CookieSessionStore};
use actix_web::{App, HttpResponse, HttpServer, Responder, web};
use actix_web_prom::PrometheusMetricsBuilder;
use std::io;
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
use services::database::DatabaseManager;
use services::media::StorageManager;
use services::shutdown::{ShutdownManager, perform_shutdown_cleanup};
use services::upload_quota::{QuotaConfig, UploadQuotaManager};

async fn health_check() -> impl Responder {
    HttpResponse::Ok().body("Tour Builder API is running!")
}

#[actix_web::main]
async fn main() -> io::Result<()> {
    // Load environment variables from .env file
    let _ = dotenvy::dotenv();

    // Initialize Logging
    let _guards = startup::init_logging();

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

    let (requests_per_sec, burst_size) = startup::rate_limit_settings();

    let governor_conf = actix_governor::GovernorConfigBuilder::default()
        .per_second(requests_per_sec)
        .burst_size(burst_size)
        .finish()
        .ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::Other,
                "Failed to initialize rate limiter configuration.",
            )
        })?;

    tracing::info!(
        requests_per_second = requests_per_sec,
        burst_size = burst_size,
        environment = if startup::is_production() {
            "production"
        } else {
            "development"
        },
        "Rate limiter configured"
    );

    let session_key = startup::session_key()?;
    let shutdown_manager_server = shutdown_manager.clone();
    let db_pool_server = db_pool.clone();
    let worker_count = startup::server_worker_count();

    let server = HttpServer::new(move || {
        App::new()
            .app_data(web::PayloadConfig::new(quota_config.max_payload_size))
            .app_data(quota_manager.clone())
            .app_data(shutdown_manager_server.clone())
            .app_data(db_pool_server.clone())
            .wrap(QuotaCheck)
            .wrap(RequestTracker)
            .wrap(TracingLogger::default())
            .wrap(startup::security_headers())
            .wrap(actix_governor::Governor::new(&governor_conf))
            .wrap(SessionMiddleware::new(
                CookieSessionStore::default(),
                session_key.clone(),
            ))
            .wrap(startup::cors())
            .wrap(prometheus.clone())
            .route("/health", web::get().to(health_check))
            .configure(api::config)
            // --- STATIC FILES (Serve Production Build from dist/) ---
            .configure(|cfg: &mut web::ServiceConfig| {
                if std::path::Path::new("../dist/static").is_dir() {
                    cfg.service(fs::Files::new("/static", "../dist/static"));
                }
                if std::path::Path::new("../dist/images").is_dir() {
                    cfg.service(fs::Files::new("/images", "../dist/images"));
                }
            })
            .service(fs::Files::new("/sounds", "../public/sounds"))
            .service(fs::Files::new("/libs", "../public/libs"))
            .route(
                "/service-worker.js",
                web::get().to(|| async { fs::NamedFile::open("../dist/service-worker.js") }),
            )
            .route(
                "/manifest.json",
                web::get().to(|| async { fs::NamedFile::open("../dist/manifest.json") }),
            )
            .route(
                "/asset-manifest.json",
                web::get().to(|| async { fs::NamedFile::open("../dist/asset-manifest.json") }),
            )
            .route(
                "/",
                web::get().to(|| async { fs::NamedFile::open("../dist/index.html") }),
            )
            .default_service(web::get().to(|| async { fs::NamedFile::open("../dist/index.html") }))
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
    tokio::spawn(async move {
        match signal::ctrl_c().await {
            Ok(()) => {
                tracing::info!("Received Ctrl+C signal");
            }
            Err(err) => {
                tracing::error!("Failed to listen for Ctrl+C: {}", err);
            }
        }

        shutdown_manager_clone.begin_shutdown();

        // Stop accepting new connections
        server_handle.stop(true).await;

        // Perform cleanup
        perform_shutdown_cleanup(&shutdown_manager_clone).await;
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
