use actix_cors::Cors;
use actix_files as fs;
use actix_governor::{Governor, GovernorConfigBuilder};
use actix_web::{App, HttpResponse, HttpServer, Responder, middleware::DefaultHeaders, web};
use actix_web_prom::PrometheusMetricsBuilder;
use std::io;
use std::time::Duration;
use tokio::signal;
use tracing_actix_web::TracingLogger;

// mod handlers; // Deleted
mod api;
mod metrics;
mod middleware;
mod models;
mod pathfinder;
mod services;

use middleware::quota_check::QuotaCheck;
use middleware::request_tracker::RequestTracker;
use services::shutdown::{ShutdownManager, perform_shutdown_cleanup};
use services::upload_quota::{QuotaConfig, UploadQuotaManager};

async fn health_check() -> impl Responder {
    HttpResponse::Ok().body("Tour Builder API is running!")
}

#[actix_web::main]
async fn main() -> io::Result<()> {
    // Initialize tracing (logging)
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    tracing::info!("Starting server at http://localhost:8080");

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

    let shutdown_manager_server = shutdown_manager.clone();
    let server = HttpServer::new(move || {
        // CORS Configuration: Permissive in debug, restricted in release
        let cors = if cfg!(debug_assertions) {
            // Development: Allow all origins for testing
            Cors::permissive()
        } else {
            // Production: Restrict to localhost and file protocol (for desktop app)
            Cors::default()
                .allowed_origin("http://localhost:5173")
                .allowed_origin("http://127.0.0.1:5173")
                .allowed_origin("http://localhost:3000")
                .allowed_origin("http://127.0.0.1:3000")
                .allowed_origin("http://localhost:9999")
                .allowed_origin("http://127.0.0.1:9999")
                .allowed_origin("http://localhost:8080")
                .allowed_origin("http://127.0.0.1:8080")
                .allowed_origin_fn(|origin, _req_head| {
                    // Allow file:// protocol for Electron/desktop apps
                    origin.as_bytes().starts_with(b"file://")
                })
                .allowed_methods(vec!["GET", "POST", "DELETE"])
                .allowed_headers(vec![
                    actix_web::http::header::CONTENT_TYPE,
                    actix_web::http::header::ACCEPT,
                ])
                .max_age(3600)
        };

        // Rate Limiting: Prevent DoS attacks and API abuse
        let governor_conf = GovernorConfigBuilder::default()
            .per_second(100)      // Increased from 30 to 100 for dev/noisy logging
            .burst_size(200)      // Increased from 50 to 200
            .finish()
            .expect("Failed to initialize rate limiter configuration. This should never fail with valid parameters.");

        App::new()
            // Increase max payload size to configured limit
            .app_data(web::PayloadConfig::new(quota_config.max_payload_size))
            .app_data(quota_manager.clone())
            .app_data(shutdown_manager_server.clone())
            .wrap(QuotaCheck) // Check upload quotas
            .wrap(RequestTracker) // Track active requests
            .wrap(TracingLogger::default()) // Structured request logging

            // Security Headers: Protect against common web vulnerabilities
            .wrap(DefaultHeaders::new()
                // Prevent MIME type sniffing
                .add(("X-Content-Type-Options", "nosniff"))

                // Prevent clickjacking by blocking iframe embedding
                .add(("X-Frame-Options", "DENY"))

                // Enable browser XSS protection (legacy, but still useful)
                .add(("X-XSS-Protection", "1; mode=block"))

                // Control referrer information
                .add(("Referrer-Policy", "strict-origin-when-cross-origin"))

                // Disable unnecessary browser features
                .add(("Permissions-Policy", "geolocation=(), microphone=(), camera=()"))

                // Prevent DNS prefetching for privacy
                .add(("X-DNS-Prefetch-Control", "off"))
            )

            // Rate Limiting: Apply to all routes
            .wrap(Governor::new(&governor_conf))

            .wrap(cors)
            .wrap(prometheus.clone()) // Prometheus metrics (Execute first)
            .route("/health", web::get().to(health_check))

            // API Scopes
            .service(web::scope("/api")
                .service(web::scope("/admin")
                    .route("/shutdown", web::post().to(api::utils::trigger_shutdown))
                )
                .service(web::scope("/telemetry")
                    .route("/log", web::post().to(api::telemetry::log_telemetry))
                    .route("/error", web::post().to(api::telemetry::log_error))
                    .route("/batch", web::post().to(api::telemetry::log_batch))
                    .route("/cleanup", web::post().to(api::telemetry::cleanup_logs))
                )
                .service(web::scope("/geocoding")
                    .route("/reverse", web::post().to(api::geocoding::reverse_geocode))
                    .route("/stats", web::get().to(api::geocoding::geocode_stats))
                    .route("/cache", web::delete().to(api::geocoding::clear_geocode_cache))
                )
                .service(web::scope("/media")
                    .route("/optimize", web::post().to(api::media::optimize_image))
                    .route("/process-full", web::post().to(api::media::process_image_full))
                    .route("/transcode-video", web::post().to(api::media::transcode_video))
                    .route("/extract-metadata", web::post().to(api::media::extract_metadata))
                    .route("/similarity", web::post().to(api::media::batch_calculate_similarity))
                    .route("/resize-batch", web::post().to(api::media::resize_image_batch))
                    .route("/generate-teaser", web::post().to(api::media::generate_teaser))
                )
                .service(web::scope("/project")
                    .route("/save", web::post().to(api::project::save_project))
                    .route("/load", web::post().to(api::project::load_project))
                    .route("/create-tour-package", web::post().to(api::project::create_tour_package))
                    .route("/validate", web::post().to(api::project::validate_project))
                    .route("/import", web::post().to(api::project::import_project))
                    .route("/calculate-path", web::post().to(api::project::calculate_path))
                )
                .service(web::scope("/session")
                     .route("/{session_id}/{filename:.*}", web::get().to(api::media::serve_session_file))
                )
                .route("/quota/stats", web::get().to(api::utils::quota_stats))
            )

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
            .service(fs::Files::new("/libs", "../public/libs")) // Pannellum and other lazy-loaded libs

            // PWA and Service Worker files
            .route("/service-worker.js", web::get().to(|| async { fs::NamedFile::open("../dist/service-worker.js") }))
            .route("/manifest.json", web::get().to(|| async { fs::NamedFile::open("../dist/manifest.json") }))
            .route("/asset-manifest.json", web::get().to(|| async { fs::NamedFile::open("../dist/asset-manifest.json") }))

            // Serve index.html for root and handle SPA routing
            .route("/", web::get().to(|| async { fs::NamedFile::open("../dist/index.html") }))
            .default_service(web::get().to(|| async {
                // Fallback for SPA routing - serve index.html for all unmatched routes
                fs::NamedFile::open("../dist/index.html")
            }))
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
