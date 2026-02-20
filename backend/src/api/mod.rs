use crate::auth;
use crate::middleware::rate_limiter::{RateLimitResponseTransformer, RateLimiters};
use actix_governor::Governor;
use actix_web::web;

pub mod geocoding;
pub mod health;
pub mod media;
pub mod project;
pub mod project_import;
pub mod project_logic;
pub mod project_multipart;
pub mod telemetry;
pub mod utils;

pub fn config(cfg: &mut web::ServiceConfig, limiters: &RateLimiters) {
    cfg.service(
        web::scope("/api")
            .service(
                web::scope("/admin")
                    .wrap(auth::AuthMiddleware)
                    .wrap(RateLimitResponseTransformer::new("admin"))
                    .wrap(Governor::new(&limiters.admin))
                    .route("/shutdown", web::post().to(utils::trigger_shutdown)),
            )
            .service(
                web::scope("/telemetry")
                    .wrap(RateLimitResponseTransformer::new("write"))
                    .wrap(Governor::new(&limiters.write))
                    .route("/log", web::post().to(telemetry::log_telemetry))
                    .route("/error", web::post().to(telemetry::log_error))
                    .route("/batch", web::post().to(telemetry::log_batch))
                    .route("/cleanup", web::post().to(telemetry::cleanup_logs)),
            )
            .service(
                web::scope("/geocoding")
                    .wrap(RateLimitResponseTransformer::new("read"))
                    .wrap(Governor::new(&limiters.read))
                    .route("/reverse", web::post().to(geocoding::reverse_geocode))
                    .route("/stats", web::get().to(geocoding::geocode_stats))
                    .route("/cache", web::delete().to(geocoding::clear_geocode_cache)),
            )
            .service(
                web::scope("/media")
                    .wrap(RateLimitResponseTransformer::new("write"))
                    .wrap(Governor::new(&limiters.write))
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
                    .route(
                        "/save",
                        web::post()
                            .to(project::save_project)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/load",
                        web::post()
                            .to(project::load_project)
                            .wrap(RateLimitResponseTransformer::new("read"))
                            .wrap(Governor::new(&limiters.read)),
                    )
                    .route(
                        "/create-tour-package",
                        web::post()
                            .to(project::create_tour_package)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/validate",
                        web::post()
                            .to(project::validate_project)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/import",
                        web::post()
                            .to(project_import::import_project)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/import/init",
                        web::post()
                            .to(project_import::import_project_init)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/import/chunk",
                        web::post()
                            .to(project_import::import_project_chunk)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/import/status/{upload_id}",
                        web::get()
                            .to(project_import::import_project_status)
                            .wrap(RateLimitResponseTransformer::new("read"))
                            .wrap(Governor::new(&limiters.read)),
                    )
                    .route(
                        "/import/complete",
                        web::post()
                            .to(project_import::import_project_complete)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/import/abort",
                        web::post()
                            .to(project_import::import_project_abort)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/calculate-path",
                        web::post()
                            .to(project::calculate_path)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/{project_id}/file/{filename:.*}",
                        web::get()
                            .to(media::serve_project_file)
                            .wrap(RateLimitResponseTransformer::new("read"))
                            .wrap(Governor::new(&limiters.read)),
                    ),
            )
            .route(
                "/quota/stats",
                web::get()
                    .to(utils::quota_stats)
                    .wrap(RateLimitResponseTransformer::new("health"))
                    .wrap(Governor::new(&limiters.health)),
            )
            .route(
                "/health",
                web::get()
                    .to(health::health_check)
                    .wrap(RateLimitResponseTransformer::new("health"))
                    .wrap(Governor::new(&limiters.health)),
            ),
    );
}
