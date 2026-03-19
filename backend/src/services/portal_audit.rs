// @efficiency-role: service-orchestrator
use sqlx::{SqlitePool, Transaction};
use uuid::Uuid;

use crate::models::AppError;

pub async fn log_audit(
    pool: &SqlitePool,
    actor_user_id: Option<&str>,
    customer_id: Option<&str>,
    event_type: &str,
    details_json: serde_json::Value,
) -> Result<(), AppError> {
    let mut tx = pool.begin().await.map_err(|error| {
        AppError::InternalError(format!("Portal audit transaction failed: {}", error))
    })?;
    log_audit_event(
        &mut tx,
        actor_user_id,
        customer_id,
        event_type,
        details_json,
    )
    .await?;
    tx.commit()
        .await
        .map_err(|error| AppError::InternalError(format!("Portal audit commit failed: {}", error)))
}

pub async fn log_audit_event(
    tx: &mut Transaction<'_, sqlx::Sqlite>,
    actor_user_id: Option<&str>,
    customer_id: Option<&str>,
    event_type: &str,
    details_json: serde_json::Value,
) -> Result<(), AppError> {
    sqlx::query(
        r#"
        INSERT INTO portal_audit_log (id, actor_user_id, customer_id, event_type, details_json)
        VALUES (?, ?, ?, ?, ?)
        "#,
    )
    .bind(Uuid::new_v4().to_string())
    .bind(actor_user_id)
    .bind(customer_id)
    .bind(event_type)
    .bind(details_json.to_string())
    .execute(&mut **tx)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal audit log write failed: {}", error))
    })?;
    Ok(())
}
