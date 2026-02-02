use tracing_subscriber::prelude::*;

pub fn init() -> (
    tracing_appender::non_blocking::WorkerGuard,
    tracing_appender::non_blocking::WorkerGuard,
    tracing_appender::non_blocking::WorkerGuard,
    sentry::ClientInitGuard,
) {
    // Panic Hook
    std::panic::set_hook(Box::new(|panic_info| {
        let location = panic_info.location().unwrap();
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
            file = %location.file(),
            line = %location.line(),
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
