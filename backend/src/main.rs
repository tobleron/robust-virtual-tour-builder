use actix_cors::Cors;
use actix_web::{web, App, HttpServer, HttpResponse, Responder, middleware::DefaultHeaders};
use actix_files as fs;
use actix_governor::{Governor, GovernorConfigBuilder};
use std::io;
use tracing_actix_web::TracingLogger;

mod handlers;

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
                .allowed_methods(vec!["GET", "POST"])
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
            .unwrap();

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
            .route("/log-telemetry", web::post().to(handlers::log_telemetry))
            .route("/optimize-image", web::post().to(handlers::optimize_image))
            .route("/process-image-full", web::post().to(handlers::process_image_full))
            .route("/transcode-video", web::post().to(handlers::transcode_video))
            .route("/extract-metadata", web::post().to(handlers::extract_metadata))
            .route("/resize-image-batch", web::post().to(handlers::resize_image_batch))
            .route("/create-tour-package", web::post().to(handlers::create_tour_package))
            .route("/save-project", web::post().to(handlers::save_project))
            .route("/load-project", web::post().to(handlers::load_project))
            .route("/generate-teaser", web::post().to(handlers::generate_teaser))
            .route("/session/{session_id}/{filename:.*}", web::get().to(handlers::serve_session_file))

            // --- STATIC FILES (Serve Frontend directly) ---
            // Allows running without Node.js/Vite
            .service(fs::Files::new("/css", "../css"))
            .service(fs::Files::new("/src", "../src"))
            .service(fs::Files::new("/images", "../images")) // Optional, if you have an images folder
            .route("/", web::get().to(|| async { fs::NamedFile::open("../index.html") }))
            .route("/index.html", web::get().to(|| async { fs::NamedFile::open("../index.html") }))
    })
            .bind(("0.0.0.0", 8080))?
    .run()
    .await
}
