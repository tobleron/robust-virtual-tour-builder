use actix_cors::Cors;
use actix_web::{web, App, HttpServer, HttpResponse, Responder};
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
                .allowed_origin("http://localhost:5173")  // Vite dev server
                .allowed_origin("http://127.0.0.1:5173")
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

        App::new()
            .wrap(TracingLogger::default()) // Structured request logging
            .wrap(cors)
            .route("/health", web::get().to(health_check))
            .route("/log-telemetry", web::post().to(handlers::log_telemetry))
            .route("/optimize-image", web::post().to(handlers::optimize_image))
            .route("/process-image-full", web::post().to(handlers::process_image_full))
            .route("/transcode-video", web::post().to(handlers::transcode_video))
            .route("/extract-metadata", web::post().to(handlers::extract_metadata))
            .route("/resize-image-batch", web::post().to(handlers::resize_image_batch))
            .route("/create-tour-package", web::post().to(handlers::create_tour_package))
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
