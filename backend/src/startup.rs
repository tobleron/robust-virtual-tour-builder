// @efficiency-role: orchestrator
use actix_cors::Cors;
use actix_web::cookie::Key;
use actix_web::middleware::DefaultHeaders;
use std::io;
use std::time::Duration;
use tracing_subscriber::prelude::*;

/// Initialize the unified logging system.
pub fn init_logging() -> (
    tracing_appender::non_blocking::WorkerGuard,
    tracing_appender::non_blocking::WorkerGuard,
    tracing_appender::non_blocking::WorkerGuard,
    sentry::ClientInitGuard,
) {
    // Panic Hook
    std::panic::set_hook(Box::new(|panic_info| {
        let location = panic_info.location();
        let file = location.map(|l| l.file()).unwrap_or("unknown");
        let line = location.map(|l| l.line()).unwrap_or(0);

        let msg = match panic_info.payload().downcast_ref::<&'static str>() {
            Some(s) => *s,
            None => match panic_info.payload().downcast_ref::<String>() {
                Some(s) => &s[..],
                None => "Box<Any>",
            },
        };
        tracing::error!(
            target: "panic",
            message = %msg,
            file = %file,
            line = %line,
            "🔥 API PANIC DETECTED 🔥"
        );
    }));

    // Initialize Sentry
    let sentry_guard = sentry::init(sentry::ClientOptions {
        dsn: std::env::var("SENTRY_DSN")
            .ok()
            .and_then(|s| s.parse().ok()),
        release: sentry::release_name!(),
        traces_sample_rate: 1.0,
        ..Default::default()
    });

    // Initialize tracing
    let log_dir = std::env::var("LOG_DIR").unwrap_or_else(|_| "../logs".to_string());
    let _ = std::fs::create_dir_all(&log_dir);

    let diag_appender = tracing_appender::rolling::never(&log_dir, "diagnostic.log");
    let (diag_writer, diag_guard) = tracing_appender::non_blocking(diag_appender);

    let error_appender = tracing_appender::rolling::never(&log_dir, "error.log");
    let (error_writer, error_guard) = tracing_appender::non_blocking(error_appender);

    let telemetry_appender = tracing_appender::rolling::never(&log_dir, "telemetry.log");
    let (telemetry_writer, telemetry_guard) = tracing_appender::non_blocking(telemetry_appender);

    let diag_layer = tracing_subscriber::fmt::layer()
        .json()
        .with_writer(diag_writer)
        .with_filter(tracing_subscriber::filter::LevelFilter::DEBUG);

    let error_layer = tracing_subscriber::fmt::layer()
        .with_writer(error_writer)
        .with_filter(tracing_subscriber::filter::LevelFilter::WARN);

    let telemetry_layer = tracing_subscriber::fmt::layer()
        .with_writer(telemetry_writer)
        .with_filter(tracing_subscriber::filter::LevelFilter::ERROR);

    /*
    let stdout_layer = tracing_tree::HierarchicalLayer::new(2)
        .with_targets(true)
        .with_bracketed_fields(true)
        .with_filter(tracing_subscriber::filter::LevelFilter::INFO);
    */

    let sentry_layer = sentry_tracing::layer();

    tracing_subscriber::registry()
        // .with(stdout_layer)
        .with(diag_layer)
        .with(error_layer)
        .with(telemetry_layer)
        .with(sentry_layer)
        .init();

    tracing::info!("🚀 Unified Logging System Initialized (Diagnostic + Error + Telemetry Logs)");

    (diag_guard, error_guard, telemetry_guard, sentry_guard)
}

/// Configure CORS for the application.
pub fn cors() -> Cors {
    let mut cors = Cors::default()
        .allowed_methods(vec!["GET", "POST", "DELETE"])
        .allowed_headers(vec![
            actix_web::http::header::CONTENT_TYPE,
            actix_web::http::header::ACCEPT,
        ])
        .max_age(3600);

    if is_production() {
        let configured_origins = std::env::var("CORS_ALLOWED_ORIGINS")
            .ok()
            .map(|v| {
                v.split(',')
                    .map(str::trim)
                    .filter(|v| !v.is_empty())
                    .map(str::to_owned)
                    .collect::<Vec<_>>()
            })
            .unwrap_or_default();

        if configured_origins.is_empty() {
            tracing::warn!(
                "CORS_ALLOWED_ORIGINS is not set in production; cross-origin requests are disabled"
            );
            return cors;
        }

        for origin in configured_origins {
            cors = cors.allowed_origin(&origin);
        }
        cors
    } else {
        cors.allowed_origin("http://localhost:5173")
            .allowed_origin("http://127.0.0.1:5173")
            .allowed_origin("http://localhost:3000")
            .allowed_origin("http://127.0.0.1:3000")
            .allowed_origin("http://localhost:9999")
            .allowed_origin("http://127.0.0.1:9999")
            .allowed_origin("http://localhost:8080")
            .allowed_origin("http://127.0.0.1:8080")
    }
}

pub fn is_production() -> bool {
    std::env::var("NODE_ENV")
        .map(|v| v.eq_ignore_ascii_case("production"))
        .unwrap_or(false)
}

fn read_env_usize(name: &str, default: usize) -> usize {
    std::env::var(name)
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .filter(|v| *v > 0)
        .unwrap_or(default)
}

pub fn rate_limit_settings() -> (u64, u32) {
    let (default_rps, default_burst) = if is_production() {
        (30_u64, 60_u32)
    } else {
        (500_u64, 1000_u32)
    };

    let rps = read_env_usize("RATE_LIMIT_PER_SECOND", default_rps as usize) as u64;
    let burst = read_env_usize("RATE_LIMIT_BURST_SIZE", default_burst as usize) as u32;
    (rps, burst)
}

pub fn shutdown_timeout() -> Duration {
    let secs = read_env_usize("SHUTDOWN_TIMEOUT_SECS", 30) as u64;
    Duration::from_secs(secs)
}

pub fn session_key() -> io::Result<Key> {
    let min_len = 64;
    match std::env::var("SESSION_KEY") {
        Ok(raw) => {
            if raw.len() < min_len {
                Err(io::Error::new(
                    io::ErrorKind::InvalidInput,
                    format!("SESSION_KEY must be at least {min_len} bytes"),
                ))
            } else {
                Ok(Key::from(raw.as_bytes()))
            }
        }
        Err(_) if is_production() => Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "SESSION_KEY must be set in production",
        )),
        Err(_) => {
            tracing::warn!(
                "SESSION_KEY not set in non-production environment; using ephemeral key"
            );
            Ok(Key::generate())
        }
    }
}

/// Define security headers for the application.
pub fn security_headers() -> DefaultHeaders {
    DefaultHeaders::new()
        .add(("X-Content-Type-Options", "nosniff"))
        .add(("X-Frame-Options", "DENY"))
        .add(("X-XSS-Protection", "1; mode=block"))
        .add(("Referrer-Policy", "strict-origin-when-cross-origin"))
        .add((
            "Permissions-Policy",
            "geolocation=(), microphone=(), camera=()",
        ))
        .add(("X-DNS-Prefetch-Control", "off"))
}
