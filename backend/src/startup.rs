// @efficiency-role: orchestrator
use actix_cors::Cors;
use actix_web::middleware::DefaultHeaders;
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
    let diag_appender = tracing_appender::rolling::never("../logs", "diagnostic.log");
    let (diag_writer, diag_guard) = tracing_appender::non_blocking(diag_appender);

    let error_appender = tracing_appender::rolling::never("../logs", "error.log");
    let (error_writer, error_guard) = tracing_appender::non_blocking(error_appender);

    let telemetry_appender = tracing_appender::rolling::never("../logs", "telemetry.log");
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

    let stdout_layer = tracing_tree::HierarchicalLayer::new(2)
        .with_targets(true)
        .with_bracketed_fields(true)
        .with_filter(tracing_subscriber::filter::LevelFilter::INFO);

    let sentry_layer = sentry_tracing::layer();

    tracing_subscriber::registry()
        .with(stdout_layer)
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
    if cfg!(debug_assertions) {
        Cors::permissive()
    } else {
        Cors::default()
            .allowed_origin("http://localhost:5173")
            .allowed_origin("http://127.0.0.1:5173")
            .allowed_origin("http://localhost:3000")
            .allowed_origin("http://127.0.0.1:3000")
            .allowed_origin("http://localhost:9999")
            .allowed_origin("http://127.0.0.1:9999")
            .allowed_origin("http://localhost:8080")
            .allowed_origin("http://127.0.0.1:8080")
            .allowed_origin_fn(|origin, _req_head| origin.as_bytes().starts_with(b"file://"))
            .allowed_methods(vec!["GET", "POST", "DELETE"])
            .allowed_headers(vec![
                actix_web::http::header::CONTENT_TYPE,
                actix_web::http::header::ACCEPT,
            ])
            .max_age(3600)
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
