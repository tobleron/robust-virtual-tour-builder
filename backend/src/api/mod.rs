use crate::auth;
use actix_web::web;

pub mod geocoding;
pub mod media;
pub mod project;
pub mod project_logic;
pub mod project_multipart;
pub mod telemetry;
pub mod utils;

pub fn config(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api")
            .service(
                web::scope("/admin")
                    .wrap(auth::AuthMiddleware)
                    .route("/shutdown", web::post().to(utils::trigger_shutdown)),
            )
            .service(
                web::scope("/telemetry")
                    .route("/log", web::post().to(telemetry::log_telemetry))
                    .route("/error", web::post().to(telemetry::log_error))
                    .route("/batch", web::post().to(telemetry::log_batch))
                    .route("/cleanup", web::post().to(telemetry::cleanup_logs)),
            )
            .service(
                web::scope("/geocoding")
                    .route("/reverse", web::post().to(geocoding::reverse_geocode))
                    .route("/stats", web::get().to(geocoding::geocode_stats))
                    .route("/cache", web::delete().to(geocoding::clear_geocode_cache)),
            )
            .service(
                web::scope("/media")
                    .route("/optimize", web::post().to(media::optimize_image))
                    .route("/process-full", web::post().to(media::process_image_full))
                    .route("/transcode-video", web::post().to(media::transcode_video))
                    .route("/extract-metadata", web::post().to(media::extract_metadata))
                    .route(
                        "/similarity",
                        web::post().to(media::batch_calculate_similarity),
                    )
                    .route("/resize-batch", web::post().to(media::resize_image_batch))
                    .route("/generate-teaser", web::post().to(media::generate_teaser)),
            )
            .service(
                web::scope("/project")
                    .wrap(auth::AuthMiddleware)
                    .route("/save", web::post().to(project::save_project))
                    .route("/load", web::post().to(project::load_project))
                    .route(
                        "/create-tour-package",
                        web::post().to(project::create_tour_package),
                    )
                    .route("/validate", web::post().to(project::validate_project))
                    .route("/import", web::post().to(project::import_project))
                    .route("/calculate-path", web::post().to(project::calculate_path))
                    .route(
                        "/{project_id}/file/{filename:.*}",
                        web::get().to(media::serve_project_file),
                    ),
            )
            .route("/quota/stats", web::get().to(utils::quota_stats)),
    );
}
