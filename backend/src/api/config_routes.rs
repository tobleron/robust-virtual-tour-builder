// @efficiency-role: infra-adapter
use crate::auth as auth_middleware;
use crate::middleware::rate_limiter::{RateLimitResponseTransformer, RateLimiters};
use actix_governor::Governor;
use actix_web::web;

use super::{auth, portal, utils};
#[cfg(feature = "builder-runtime")]
use super::{geocoding, media, telemetry};

#[cfg(feature = "builder-runtime")]
pub(super) fn configure_api(cfg: &mut web::ServiceConfig, limiters: &RateLimiters) {
    cfg.service(
        web::scope("/api")
            .service(
                web::scope("/admin")
                    .wrap(auth_middleware::AuthMiddleware)
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
                    .route(
                        "/optimize",
                        web::post()
                            .to(media::optimize_image)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/process-full",
                        web::post()
                            .to(media::process_image_full)
                            .wrap(RateLimitResponseTransformer::new("media_heavy"))
                            .wrap(Governor::new(&limiters.media_heavy)),
                    )
                    .route(
                        "/transcode-video",
                        web::post()
                            .to(media::transcode_video)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/similarity",
                        web::post()
                            .to(media::batch_calculate_similarity)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/resize-batch",
                        web::post()
                            .to(media::resize_image_batch)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/generate-teaser",
                        web::post()
                            .to(media::generate_teaser)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/extract-metadata",
                        web::post()
                            .to(media::extract_metadata)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    ),
            )
            .service(
                web::scope("/auth")
                    .route(
                        "/signup",
                        web::post()
                            .to(auth::signup)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/verify-email",
                        web::post()
                            .to(auth::verify_email)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/resend-verification",
                        web::post()
                            .to(auth::resend_verification_email)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/signin",
                        web::post()
                            .to(auth::signin)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/dev-login",
                        web::post()
                            .to(auth::dev_signin)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/step-up/verify",
                        web::post()
                            .to(auth::verify_step_up_otp)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/step-up/resend",
                        web::post()
                            .to(auth::resend_step_up_otp)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/signout",
                        web::post()
                            .to(auth::signout)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/forgot-password",
                        web::post()
                            .to(auth::forgot_password)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/reset-password",
                        web::post()
                            .to(auth::reset_password)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/me",
                        web::get()
                            .to(auth::me)
                            .wrap(auth_middleware::AuthMiddleware)
                            .wrap(RateLimitResponseTransformer::new("read"))
                            .wrap(Governor::new(&limiters.read)),
                    )
                    .route(
                        "/change-password",
                        web::post()
                            .to(auth::change_password)
                            .wrap(auth_middleware::AuthMiddleware)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    ),
            )
            .service(
                web::scope("/auth")
                    .wrap(auth_middleware::StepUpMiddleware)
                    .route(
                        "/trusted-devices/revoke-all",
                        web::post()
                            .to(auth::revoke_all_trusted_devices)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    ),
            )
            .service(
                web::scope("/portal")
                    .service(
                        web::scope("/admin")
                            .wrap(auth_middleware::AuthMiddleware)
                            .wrap(RateLimitResponseTransformer::new("admin"))
                            .wrap(Governor::new(&limiters.admin))
                            .route("/settings", web::get().to(portal::admin_get_settings))
                            .route("/settings", web::patch().to(portal::admin_update_settings))
                            .route("/customers", web::get().to(portal::admin_list_customers))
                            .route("/customers", web::post().to(portal::admin_create_customer))
                            .route(
                                "/customers/{customer_id}",
                                web::patch().to(portal::admin_update_customer),
                            )
                            .route(
                                "/customers/{customer_id}/access-links/regenerate",
                                web::post().to(portal::admin_regenerate_access_link),
                            )
                            .route(
                                "/customers/{customer_id}/access-links/revoke",
                                web::post().to(portal::admin_revoke_access_links),
                            )
                            .route(
                                "/customers/{customer_id}/access-links",
                                web::delete().to(portal::admin_delete_access_links),
                            )
                            .route(
                                "/customers/{customer_id}",
                                web::delete().to(portal::admin_delete_customer),
                            )
                            .route(
                                "/customers/{customer_id}/assignments",
                                web::post().to(portal::admin_assign_customer_tour),
                            )
                            .route(
                                "/customers/{customer_id}/assignments/{tour_id}",
                                web::delete().to(portal::admin_unassign_customer_tour),
                            )
                            .route(
                                "/customers/{customer_id}/tours",
                                web::get().to(portal::admin_get_customer_tours),
                            )
                            .route(
                                "/customers/{customer_id}/tours/{tour_id}/link",
                                web::post().to(portal::admin_create_customer_tour_link),
                            )
                            .route(
                                "/assignments/bulk",
                                web::post().to(portal::admin_bulk_assign_tours),
                            )
                            .route(
                                "/assignments/{assignment_id}",
                                web::get().to(portal::admin_get_assignment),
                            )
                            .route(
                                "/assignments/{assignment_id}/revoke",
                                web::post().to(portal::admin_revoke_assignment_link),
                            )
                            .route(
                                "/assignments/{assignment_id}/expiry",
                                web::post().to(portal::admin_update_assignment_expiry),
                            )
                            .route(
                                "/assignments/{assignment_id}/reactivate",
                                web::post().to(portal::admin_reactivate_assignment_link),
                            )
                            .route(
                                "/tours/{tour_id}/recipients",
                                web::get().to(portal::admin_get_tour_recipients),
                            )
                            .route("/tours", web::get().to(portal::admin_list_library_tours))
                            .route(
                                "/tours/upload",
                                web::post().to(portal::admin_upload_library_tour),
                            )
                            .route(
                                "/tours/{tour_id}/status",
                                web::post().to(portal::admin_update_library_tour_status),
                            )
                            .route(
                                "/tours/{tour_id}",
                                web::delete().to(portal::admin_delete_library_tour),
                            ),
                    )
                    .route(
                        "/customers/{slug}/public",
                        web::get()
                            .to(portal::customer_public)
                            .wrap(RateLimitResponseTransformer::new("read"))
                            .wrap(Governor::new(&limiters.read)),
                    )
                    .route(
                        "/customers/{slug}/session",
                        web::get()
                            .to(portal::customer_session)
                            .wrap(RateLimitResponseTransformer::new("read"))
                            .wrap(Governor::new(&limiters.read)),
                    )
                    .route(
                        "/customers/{slug}/signout",
                        web::post()
                            .to(portal::customer_sign_out)
                            .wrap(RateLimitResponseTransformer::new("write"))
                            .wrap(Governor::new(&limiters.write)),
                    )
                    .route(
                        "/customers/{slug}/tours",
                        web::get()
                            .to(portal::customer_tours)
                            .wrap(RateLimitResponseTransformer::new("read"))
                            .wrap(Governor::new(&limiters.read)),
                    ),
            ),
    );

    super::config_routes_project::configure_project_api(cfg, limiters);

    cfg.route(
        "/portal-assets/{slug}/{tour_slug}/{tail:.*}",
        web::get().to(portal::customer_tour_asset),
    );
    cfg.route(
        "/u/{slug}/tour/{tour_slug}",
        web::get().to(portal::customer_tour_launch),
    );
    cfg.route(
        "/u/{slug}/{token}",
        web::get().to(portal::user_access_redirect),
    );
    cfg.route(
        "/u/{slug}/{token}/tour/{tour_slug}",
        web::get().to(portal::user_tour_access_redirect),
    );
    cfg.route(
        "/access/{token}/tour/{tour_slug}",
        web::get().to(portal::access_tour_redirect),
    );
    cfg.route(
        "/access/{token}",
        web::get().to(portal::access_link_redirect),
    );
}

#[cfg(not(feature = "builder-runtime"))]
pub(super) fn configure_api(_cfg: &mut web::ServiceConfig, _limiters: &RateLimiters) {}

pub(super) fn configure_portal_api(cfg: &mut web::ServiceConfig, limiters: &RateLimiters) {
    super::config_routes_portal::configure_portal_api(cfg, limiters);
}
