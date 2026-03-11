use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use chrono::{Duration, Utc};
use sqlx::SqlitePool;
use uuid::Uuid;

use crate::models::{AppError, User};

use super::super::{DEVICE_TRUST_TTL_DAYS_DEFAULT, LoginContext};

pub(super) async fn upsert_trusted_device(
    pool: &SqlitePool,
    user_id: &str,
    raw_device_token: &str,
    context: &LoginContext,
) -> Result<(), AppError> {
    let trust_ttl_days =
        super::super::config_i64("TRUSTED_DEVICE_TTL_DAYS", DEVICE_TRUST_TTL_DAYS_DEFAULT);
    let token_hash = super::super::hash_token(raw_device_token);
    let now = Utc::now();
    let trust_expires_at = now + Duration::days(trust_ttl_days);

    let existing = sqlx::query_scalar::<_, String>(
        "SELECT id FROM trusted_devices WHERE user_id = ? AND device_token_hash = ?",
    )
    .bind(user_id)
    .bind(token_hash.clone())
    .fetch_optional(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!(
            "Trusted device pre-upsert lookup failed: {}",
            error
        ))
    })?;

    if let Some(device_id) = existing {
        sqlx::query(
            r#"
            UPDATE trusted_devices
            SET user_agent = ?, user_agent_family = ?, last_ip = ?, last_country = ?, last_region = ?,
                last_lat = ?, last_lon = ?, last_timezone = ?, last_language = ?, last_seen_at = ?,
                trust_expires_at = ?, revoked_at = NULL
            WHERE id = ?
            "#,
        )
        .bind(context.user_agent.clone())
        .bind(context.user_agent_family.clone())
        .bind(context.ip_address.clone())
        .bind(context.country.clone())
        .bind(context.region.clone())
        .bind(context.lat)
        .bind(context.lon)
        .bind(context.timezone.clone())
        .bind(context.language.clone())
        .bind(now)
        .bind(trust_expires_at)
        .bind(device_id)
        .execute(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Trusted device update failed: {}", error))
        })?;
    } else {
        sqlx::query(
            r#"
            INSERT INTO trusted_devices (
                id, user_id, device_token_hash, user_agent, user_agent_family, last_ip, last_country, last_region,
                last_lat, last_lon, last_timezone, last_language, first_seen_at, last_seen_at, trust_expires_at, revoked_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
            "#,
        )
        .bind(Uuid::new_v4().to_string())
        .bind(user_id)
        .bind(token_hash)
        .bind(context.user_agent.clone())
        .bind(context.user_agent_family.clone())
        .bind(context.ip_address.clone())
        .bind(context.country.clone())
        .bind(context.region.clone())
        .bind(context.lat)
        .bind(context.lon)
        .bind(context.timezone.clone())
        .bind(context.language.clone())
        .bind(now)
        .bind(now)
        .bind(trust_expires_at)
        .execute(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Trusted device insert failed: {}", error))
        })?;
    }

    Ok(())
}

pub(super) async fn revoke_all_trusted_devices(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
) -> Result<HttpResponse, AppError> {
    let context = super::super::extract_login_context(&req);
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or_else(|| AppError::Unauthorized("Not authenticated.".into()))?;
    sqlx::query("UPDATE trusted_devices SET revoked_at = ? WHERE user_id = ?")
        .bind(Utc::now())
        .bind(user.id.clone())
        .execute(pool.get_ref())
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Trusted devices revoke failed: {}", error))
        })?;
    super::super::log_auth_event(
        pool.get_ref(),
        Some(&user.id),
        "trusted_devices_revoked",
        "allow",
        None,
        Some("user_requested"),
        &context,
        None,
    )
    .await?;
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "message": "All trusted devices were revoked."
    })))
}
