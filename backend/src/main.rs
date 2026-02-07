use actix_files as fs;
use actix_session::{SessionMiddleware, storage::CookieSessionStore};
use actix_web::{App, HttpResponse, HttpServer, Responder, cookie::Key, web};
use actix_web_prom::PrometheusMetricsBuilder;
use std::io;
use std::time::Duration;
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

    // Ensure logs directory exists
    let log_dir = std::env::var("LOG_DIR").unwrap_or_else(|_| "../logs".to_string());
    std::fs::create_dir_all(log_dir).ok();

    // Load geocoding cache from disk
    if let Err(e) = services::geocoding::load_cache_from_disk().await {
        tracing::warn!("Failed to load geocoding cache: {}", e);
    }

    // Initialize shutdown manager
    let shutdown_timeout = Duration::from_secs(
        std::env::var("SHUTDOWN_TIMEOUT_SECS")
            .ok()
            .and_then(|s| s.parse().ok())
            .unwrap_or(30),
    );
    let shutdown_manager = web::Data::new(ShutdownManager::new(shutdown_timeout));

    tracing::info!(
        timeout_secs = shutdown_timeout.as_secs(),
        "Shutdown manager initialized"
    );

    // Initialize upload quota manager
    let quota_config = QuotaConfig::from_env();
    let quota_manager = web::Data::new(UploadQuotaManager::new(quota_config.clone()));

    tracing::info!(
        "Upload quotas: max_payload={} MB, max_concurrent_per_ip={}, max_total={} GB",
        quota_config.max_payload_size / (1024 * 1024),
        quota_config.max_concurrent_per_ip,
        quota_config.max_total_concurrent_size / (1024 * 1024 * 1024)
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

    // Rate limiting configuration: allow generous limits for dev/test environments
    // Production: 100 req/sec | Dev/Test: 10000 req/sec (unlimited for E2E testing)
    let is_production = std::env::var("NODE_ENV")
        .map(|v| v == "production")
        .unwrap_or(false);

    let (requests_per_sec, burst_size) = if is_production {
        (100, 200) // Strict production limits
    } else {
        (10000, 20000) // Very generous dev/test limits for concurrent E2E test startup
    };

    let governor_conf = actix_governor::GovernorConfigBuilder::default()
        .per_second(requests_per_sec)
        .burst_size(burst_size)
        .finish()
        .expect("Failed to initialize rate limiter configuration.");

    tracing::info!(
        requests_per_second = requests_per_sec,
        burst_size = burst_size,
        environment = if is_production {
            "production"
        } else {
            "development"
        },
        "Rate limiter configured"
    );

    let shutdown_manager_server = shutdown_manager.clone();
    let db_pool_server = db_pool.clone();

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
                Key::from(
                    std::env::var("SESSION_KEY")
                        .expect("SESSION_KEY must be set")
                        .as_bytes(),
                ),
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
    .bind(("0.0.0.0", 8080))?
    .run();

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

        // Stop accepting new connections
        server_handle.stop(true).await;

        // Perform cleanup
        perform_shutdown_cleanup(&shutdown_manager_clone).await;
    });

    // Wait for server to finish
    server_task
        .await
        .map_err(|e| io::Error::new(io::ErrorKind::Other, e))??;

    Ok(())
}
