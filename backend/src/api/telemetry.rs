// @efficiency: infra-adapter
use super::telemetry_logic::*;
use crate::models::{AppError, TelemetryEntry};
use actix_web::{HttpResponse, web};

#[tracing::instrument(name = "cleanup_logs")]
pub async fn cleanup_logs() -> impl actix_web::Responder {
    let log_dir_str = std::env::var("LOG_DIR").unwrap_or_else(|_| "../logs".to_string());

    // Use spawn_blocking for fs traversal as it's sync
    let result = web::block(move || cleanup_logs_sync(&log_dir_str)).await;

    match result {
        Ok(Ok(count)) => HttpResponse::Ok().json(serde_json::json!({ "deleted": count })),
        _ => HttpResponse::InternalServerError().finish(),
    }
}

#[tracing::instrument(skip(entry), name = "log_telemetry")]
pub async fn log_telemetry(entry: web::Json<TelemetryEntry>) -> Result<HttpResponse, AppError> {
    let entry_inner = entry.into_inner();
    process_entry(&entry_inner).await;
    Ok(HttpResponse::Ok().finish())
}

#[tracing::instrument(skip(entry), name = "log_error")]
pub async fn log_error(entry: web::Json<TelemetryEntry>) -> Result<HttpResponse, AppError> {
    let entry_inner = entry.into_inner();
    process_entry(&entry_inner).await;
    Ok(HttpResponse::Ok().finish())
}

#[tracing::instrument(skip(batch), name = "log_batch")]
pub async fn log_batch(
    batch: web::Json<crate::models::TelemetryBatch>,
) -> Result<HttpResponse, AppError> {
    let entries = batch.into_inner().entries;
    for entry in entries {
        process_entry(&entry).await;
    }
    Ok(HttpResponse::Ok().finish())
}

async fn process_entry(entry: &TelemetryEntry) {
    use crate::models::TelemetryPriority;

    // 1. Critical/High logs always go to error.log (plaintext)
    if entry.priority == TelemetryPriority::Critical || entry.priority == TelemetryPriority::High {
        let line = format!(
            "[{}] [{:?}] [{}] {} - {:?}\n",
            entry.timestamp, entry.priority, entry.module, entry.message, entry.data
        );
        let _ = append_to_log("error.log", &line).await;
    }

    // 2. All logs except Low go to telemetry.log (JSON)
    if entry.priority != TelemetryPriority::Low {
        let line = serde_json::to_string(entry).unwrap_or_default() + "\n";
        let _ = append_to_log("telemetry.log", &line).await;
    }
}
