use actix_cors::Cors;
use actix_web::{web, App, HttpServer, HttpResponse, Responder, middleware::DefaultHeaders};
use actix_files as fs;
use actix_governor::{Governor, GovernorConfigBuilder};
use std::io;
use tracing_actix_web::TracingLogger;

// mod handlers; // Deleted
mod api;
mod models;
mod services;

mod pathfinder;

async fn health_check() -> impl Responder {
    HttpResponse::Ok().body("Remax VTB Backend is running!")
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

    HttpServer::new(|| {
        // CORS Configuration: Permissive in debug, restricted in release
        let cors = if cfg!(debug_assertions) {
            // Development: Allow all origins for testing
            Cors::permissive()
        } else {
            // Production: Restrict to localhost and file protocol (for desktop app)
            Cors::default()
                .allowed_origin("http://localhost:5173")
                .allowed_origin("http://127.0.0.1:5173")
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
            .per_second(30)      // 30 requests per second (generous for image uploads)
            .burst_size(50)      // Allow bursts up to 50 requests
            .finish()
            .expect("Failed to initialize rate limiter configuration. This should never fail with valid parameters.");

        App::new()
            // Increase max payload size to 2GB
            .app_data(web::PayloadConfig::new(2 * 1024 * 1024 * 1024))
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
            .route("/health", web::get().to(health_check))

            // API Scopes
            .service(web::scope("/api")
                .service(web::scope("/telemetry")
                    .route("/log", web::post().to(api::telemetry::log_telemetry))
                    .route("/error", web::post().to(api::telemetry::log_error))
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
            )

            // --- STATIC FILES (Serve Frontend directly) ---
            // Allows running without Node.js/Vite
            .service(fs::Files::new("/css", "../css"))
            .service(fs::Files::new("/src", "../src"))
            .service(fs::Files::new("/node_modules", "../node_modules"))
            .service(fs::Files::new("/images", "../images")) // Optional, if you have an images folder
            .service(fs::Files::new("/sounds", "../sounds"))

            .route("/", web::get().to(|| async { fs::NamedFile::open("../index.html") }))
            .route("/index.html", web::get().to(|| async { fs::NamedFile::open("../index.html") }))
    })
            .bind(("0.0.0.0", 8080))?
    .run()
    .await
}
