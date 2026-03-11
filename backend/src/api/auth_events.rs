use chrono::{Duration, Utc};
use sqlx::SqlitePool;
use uuid::Uuid;

use crate::models::AppError;

use super::{FAILED_LOGIN_WINDOW_MINUTES, LoginContext, TrustedDeviceRecord};

pub(super) async fn log_auth_event(
    pool: &SqlitePool,
    user_id: Option<&str>,
    event_type: &str,
    decision: &str,
    risk_score: Option<i64>,
    reason: Option<&str>,
    context: &LoginContext,
    extra_json: Option<&str>,
) -> Result<(), AppError> {
    sqlx::query(
        r#"
        INSERT INTO auth_events (
            id, user_id, event_type, decision, risk_score, reason, ip_address, user_agent,
            country, region, lat, lon, timezone, language, extra_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        "#,
    )
    .bind(Uuid::new_v4().to_string())
    .bind(user_id)
    .bind(event_type)
    .bind(decision)
    .bind(risk_score)
    .bind(reason)
    .bind(context.ip_address.clone())
    .bind(context.user_agent.clone())
    .bind(context.country.clone())
    .bind(context.region.clone())
    .bind(context.lat)
    .bind(context.lon)
    .bind(context.timezone.clone())
    .bind(context.language.clone())
    .bind(extra_json)
    .execute(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Auth event insert failed: {}", error)))?;
    Ok(())
}

pub(super) async fn log_login_attempt(
    pool: &SqlitePool,
    user_id: Option<&str>,
    email: &str,
    context: &LoginContext,
    device_token_hash: Option<&str>,
    success: bool,
    failure_reason: Option<&str>,
) -> Result<(), AppError> {
    sqlx::query(
        r#"
        INSERT INTO login_attempts (id, user_id, email, ip_address, device_token_hash, success, failure_reason)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        "#,
    )
    .bind(Uuid::new_v4().to_string())
    .bind(user_id)
    .bind(email)
    .bind(context.ip_address.clone())
    .bind(device_token_hash)
    .bind(if success { 1 } else { 0 })
    .bind(failure_reason)
    .execute(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Login attempt insert failed: {}", error)))?;
    Ok(())
}

pub(super) async fn find_trusted_device(
    pool: &SqlitePool,
    user_id: &str,
    raw_device_token: Option<&str>,
) -> Result<Option<TrustedDeviceRecord>, AppError> {
    let Some(raw_device_token) = raw_device_token else {
        return Ok(None);
    };
    let token_hash = super::hash_token(raw_device_token);
    let row = sqlx::query_as::<
        _,
        (
            chrono::DateTime<Utc>,
            chrono::DateTime<Utc>,
            Option<String>,
            Option<String>,
            Option<String>,
        ),
    >(
        r#"
        SELECT last_seen_at, trust_expires_at, user_agent_family, last_timezone, last_language
        FROM trusted_devices
        WHERE user_id = ? AND device_token_hash = ? AND revoked_at IS NULL
        "#,
    )
    .bind(user_id)
    .bind(token_hash)
    .fetch_optional(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Trusted device lookup failed: {}", error)))?;

    Ok(row.map(
        |(last_seen_at, trust_expires_at, user_agent_family, last_timezone, last_language)| {
            TrustedDeviceRecord {
                last_seen_at,
                trust_expires_at,
                user_agent_family,
                last_timezone,
                last_language,
            }
        },
    ))
}

pub(super) async fn load_last_success_login_context(
    pool: &SqlitePool,
    user_id: &str,
) -> Result<
    Option<(
        chrono::DateTime<Utc>,
        Option<String>,
        Option<String>,
        Option<f64>,
        Option<f64>,
    )>,
    AppError,
> {
    let row = sqlx::query_as::<
        _,
        (
            chrono::DateTime<Utc>,
            Option<String>,
            Option<String>,
            Option<f64>,
            Option<f64>,
        ),
    >(
        r#"
        SELECT created_at, country, region, lat, lon
        FROM auth_events
        WHERE user_id = ? AND event_type = 'signin_success'
        ORDER BY created_at DESC
        LIMIT 1
        "#,
    )
    .bind(user_id)
    .fetch_optional(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Last success auth event lookup failed: {}", error))
    })?;
    Ok(row)
}

pub(super) async fn count_recent_failed_logins(
    pool: &SqlitePool,
    user_id: Option<&str>,
    email: &str,
    context: &LoginContext,
    device_token_hash: Option<&str>,
) -> Result<(i64, i64), AppError> {
    let window_start = Utc::now() - Duration::minutes(FAILED_LOGIN_WINDOW_MINUTES);
    let account_failed = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*) FROM login_attempts
        WHERE success = 0
          AND email = ?
          AND created_at >= ?
        "#,
    )
    .bind(email)
    .bind(window_start)
    .fetch_one(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!(
            "Recent failed login(account) query failed: {}",
            error
        ))
    })?;

    let ip_failed = if let Some(ip) = context.ip_address.clone() {
        sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM login_attempts
            WHERE success = 0
              AND ip_address = ?
              AND created_at >= ?
            "#,
        )
        .bind(ip)
        .bind(window_start)
        .fetch_one(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Recent failed login(ip) query failed: {}", error))
        })?
    } else {
        0
    };

    let device_failed = if let Some(device_hash) = device_token_hash {
        sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM login_attempts
            WHERE success = 0
              AND device_token_hash = ?
              AND created_at >= ?
            "#,
        )
        .bind(device_hash)
        .bind(window_start)
        .fetch_one(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!(
                "Recent failed login(device) query failed: {}",
                error
            ))
        })?
    } else {
        0
    };

    if let Some(uid) = user_id {
        let user_failed = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM login_attempts
            WHERE success = 0
              AND user_id = ?
              AND created_at >= ?
            "#,
        )
        .bind(uid)
        .bind(window_start)
        .fetch_one(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Recent failed login(user) query failed: {}", error))
        })?;
        Ok((
            account_failed.max(user_failed).max(device_failed),
            ip_failed,
        ))
    } else {
        Ok((account_failed.max(device_failed), ip_failed))
    }
}
