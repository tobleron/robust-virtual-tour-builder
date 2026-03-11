use actix_web::{HttpRequest, HttpResponse, web};
use chrono::{Duration, Utc};
use sqlx::SqlitePool;

use crate::auth::encode_token;
use crate::models::{AppError, User};

use super::super::super::{AuthSuccessResponse, DEVICE_COOKIE_NAME, STEP_UP_SESSION_HOURS_DEFAULT};

pub(super) async fn verify_step_up_otp(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    challenge_id: &str,
    otp_code: &str,
) -> Result<HttpResponse, AppError> {
    let context = super::super::super::extract_login_context(&req);
    if otp_code.len() < 6 {
        return Err(AppError::ValidationError(
            "Verification code must be at least 6 characters.".into(),
        ));
    }

    let challenge = sqlx::query_as::<
        _,
        (
            String,
            String,
            String,
            chrono::DateTime<Utc>,
            i64,
            i64,
            i64,
            Option<String>,
            Option<String>,
        ),
    >(
        r#"
        SELECT id, user_id, otp_hash, otp_expires_at, attempts_used, max_attempts, risk_score, status, device_token_hash
        FROM otp_challenges
        WHERE id = ?
        "#,
    )
    .bind(challenge_id)
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|error| AppError::InternalError(format!("OTP challenge lookup failed: {}", error)))?
    .ok_or_else(|| AppError::ValidationError("Verification challenge not found.".into()))?;

    let (
        challenge_id_db,
        user_id,
        otp_hash_db,
        otp_expires_at,
        attempts_used,
        max_attempts,
        risk_score,
        status,
        challenge_device_hash,
    ) = challenge;

    if status.as_deref() != Some("pending") {
        return Err(AppError::ValidationError(
            "Verification challenge is no longer active.".into(),
        ));
    }

    if Utc::now() > otp_expires_at {
        sqlx::query("UPDATE otp_challenges SET status = 'expired', consumed_at = ? WHERE id = ?")
            .bind(Utc::now())
            .bind(challenge_id_db.clone())
            .execute(pool.get_ref())
            .await
            .map_err(|error| {
                AppError::InternalError(format!("OTP expiration update failed: {}", error))
            })?;
        super::super::super::log_auth_event(
            pool.get_ref(),
            Some(&user_id),
            "step_up_otp_expired",
            "denied",
            Some(risk_score),
            Some("otp_expired"),
            &context,
            None,
        )
        .await?;
        return Err(AppError::ValidationError(
            "Verification code expired.".into(),
        ));
    }

    if attempts_used >= max_attempts {
        sqlx::query("UPDATE otp_challenges SET status = 'locked', consumed_at = ? WHERE id = ?")
            .bind(Utc::now())
            .bind(challenge_id_db.clone())
            .execute(pool.get_ref())
            .await
            .map_err(|error| {
                AppError::InternalError(format!("OTP lock update failed: {}", error))
            })?;
        super::super::super::log_auth_event(
            pool.get_ref(),
            Some(&user_id),
            "step_up_otp_lockout",
            "denied",
            Some(risk_score),
            Some("max_attempts_reached"),
            &context,
            None,
        )
        .await?;
        return Err(AppError::Unauthorized(
            "Too many verification attempts. Please sign in again.".into(),
        ));
    }

    let submitted_hash = super::super::super::hash_otp(otp_code);
    if submitted_hash != otp_hash_db {
        let next_attempts = attempts_used + 1;
        let next_status = if next_attempts >= max_attempts {
            "locked"
        } else {
            "pending"
        };
        sqlx::query("UPDATE otp_challenges SET attempts_used = ?, status = ? WHERE id = ?")
            .bind(next_attempts)
            .bind(next_status)
            .bind(challenge_id_db.clone())
            .execute(pool.get_ref())
            .await
            .map_err(|error| {
                AppError::InternalError(format!("OTP attempts update failed: {}", error))
            })?;
        super::super::super::log_auth_event(
            pool.get_ref(),
            Some(&user_id),
            "step_up_otp_failed",
            "denied",
            Some(risk_score),
            Some("invalid_otp"),
            &context,
            None,
        )
        .await?;
        return Err(AppError::Unauthorized("Invalid verification code.".into()));
    }

    sqlx::query(
        "UPDATE otp_challenges SET status = 'verified', verified_at = ?, consumed_at = ? WHERE id = ?",
    )
    .bind(Utc::now())
    .bind(Utc::now())
    .bind(challenge_id_db.clone())
    .execute(pool.get_ref())
    .await
    .map_err(|error| AppError::InternalError(format!("OTP verify update failed: {}", error)))?;

    sqlx::query(
        "UPDATE otp_challenges SET status = 'invalidated', consumed_at = ? WHERE user_id = ? AND status = 'pending' AND id != ?",
    )
    .bind(Utc::now())
    .bind(user_id.clone())
    .bind(challenge_id_db.clone())
    .execute(pool.get_ref())
    .await
    .map_err(|error| {
        AppError::InternalError(format!("OTP pending invalidation failed: {}", error))
    })?;

    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = ?")
        .bind(user_id.clone())
        .fetch_optional(pool.get_ref())
        .await
        .map_err(|error| AppError::InternalError(format!("OTP user lookup failed: {}", error)))?
        .ok_or_else(|| AppError::Unauthorized("User not found.".into()))?;

    let raw_device_token = req
        .cookie(DEVICE_COOKIE_NAME)
        .map(|cookie| cookie.value().to_string())
        .unwrap_or_else(super::super::super::make_device_token);
    super::super::upsert_trusted_device(pool.get_ref(), &user.id, &raw_device_token, &context)
        .await?;
    let device_cookie = super::super::super::create_device_cookie(&raw_device_token);

    if user.force_step_up_until.is_some() {
        sqlx::query(
            "UPDATE users SET force_step_up_reason = NULL, force_step_up_until = NULL WHERE id = ?",
        )
        .bind(user.id.clone())
        .execute(pool.get_ref())
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Clear forced step-up flags failed: {}", error))
        })?;
    }

    let step_up_hours =
        super::super::super::config_i64("STEP_UP_SESSION_HOURS", STEP_UP_SESSION_HOURS_DEFAULT);
    let step_up_until = Some((Utc::now() + Duration::hours(step_up_hours)).timestamp() as usize);
    let token = encode_token(&user.id, step_up_until)?;
    let auth_cookie = super::super::super::create_auth_cookie(&token);

    super::super::super::log_auth_event(
        pool.get_ref(),
        Some(&user.id),
        "step_up_otp_success",
        "allow",
        Some(risk_score),
        Some("otp_verified"),
        &context,
        None,
    )
    .await?;

    if let Some(hash) = challenge_device_hash {
        let extra = serde_json::json!({ "challengeDeviceTokenHash": hash }).to_string();
        super::super::super::log_auth_event(
            pool.get_ref(),
            Some(&user.id),
            "step_up_session_established",
            "allow",
            Some(risk_score),
            Some("session_rotated_after_step_up"),
            &context,
            Some(&extra),
        )
        .await?;
    }

    Ok(HttpResponse::Ok()
        .cookie(auth_cookie)
        .cookie(device_cookie)
        .json(AuthSuccessResponse {
            token,
            user: super::super::super::public_user(&user),
        }))
}
