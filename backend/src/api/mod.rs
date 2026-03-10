#[path = "config_routes.rs"]
mod config_routes;

use crate::middleware::rate_limiter::RateLimiters;
use actix_web::web;

pub mod auth;
pub mod geocoding;
pub mod health;
pub mod media;
pub mod project;
pub mod project_export;
pub mod project_import;
pub mod project_logic;
pub mod project_multipart;
pub mod telemetry;
pub mod utils;

pub fn config(cfg: &mut web::ServiceConfig, limiters: &RateLimiters) {
    config_routes::configure_api(cfg, limiters);
}
