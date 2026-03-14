#[path = "config_routes.rs"]
mod config_routes;

use crate::middleware::rate_limiter::RateLimiters;
use actix_web::web;

pub mod auth;
#[cfg(feature = "builder-runtime")]
pub mod geocoding;
pub mod health;
#[cfg(feature = "builder-runtime")]
pub mod media;
pub mod portal;
#[cfg(feature = "builder-runtime")]
pub mod project;
#[cfg(feature = "builder-runtime")]
pub mod project_export;
#[cfg(feature = "builder-runtime")]
pub mod project_import;
#[cfg(feature = "builder-runtime")]
pub mod project_logic;
#[cfg(feature = "builder-runtime")]
pub mod project_multipart;
pub mod telemetry;
pub mod utils;

pub fn config(cfg: &mut web::ServiceConfig, limiters: &RateLimiters) {
    config_routes::configure_api(cfg, limiters);
}

pub fn config_portal(cfg: &mut web::ServiceConfig, limiters: &RateLimiters) {
    config_routes::configure_portal_api(cfg, limiters);
}
