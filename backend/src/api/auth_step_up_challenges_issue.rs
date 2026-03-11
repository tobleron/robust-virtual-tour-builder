use actix_web::{HttpRequest, HttpResponse, web};
use chrono::{Duration, Utc};
use sqlx::SqlitePool;
use uuid::Uuid;

use crate::models::{AppError, User};

use super::super::super::{
    LoginContext, OTP_MAX_ATTEMPTS, OTP_RESEND_COOLDOWN_SECONDS_DEFAULT, OTP_TTL_MINUTES,
    RiskDecision,
};

pub(super) async fn issue_or_refresh_step_up_challenge(
    pool: &SqlitePool,
    user: &User,
    context: &LoginContext,
    risk: &RiskDecision,
    device_token_hash: Option<&str>,
) -> Result<(String, String, chrono::DateTime<Utc>, chrono::DateTime<Utc>), AppError> {
    let user_id = &user.id;
    let cooldown_secs = super::super::super::config_i64(
        "OTP_RESEND_COOLDOWN_SECONDS",
        OTP_RESEND_COOLDOWN_SECONDS_DEFAULT,
    );
    let now = Utc::now();

    sqlx::query(
        r#"
        UPDATE otp_challenges
        SET status = 'invalidated', consumed_at = ?
        WHERE user_id = ? AND status = 'pending'
        "#,
    )
    .bind(now)
    .bind(user_id)
    .execute(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("OTP challenge invalidation failed: {}", error))
    })?;

    let challenge_id = Uuid::new_v4().to_string();
    let otp_code = super::super::super::generate_otp_code();
    let otp_hash = super::super::super::hash_otp(&otp_code);
    let otp_expires_at = now + Duration::minutes(OTP_TTL_MINUTES);
    let resend_available_at = now + Duration::seconds(cooldown_secs);
    let reasons_json = serde_json::to_string(&risk.reasons).map_err(|error| {
        AppError::InternalError(format!("Risk reasons serialization failed: {}", error))
    })?;

    sqlx::query(
        r#"
        INSERT INTO otp_challenges (
            id, user_id, challenge_type, status, risk_score, risk_reasons_json, otp_hash,
            otp_expires_at, attempts_used, max_attempts, resend_available_at, resend_count,
            ip_address, user_agent, device_token_hash
        ) VALUES (?, ?, 'email_step_up', 'pending', ?, ?, ?, ?, 0, ?, ?, 0, ?, ?, ?)
        "#,
    )
    .bind(&challenge_id)
    .bind(user_id)
    .bind(risk.score)
    .bind(reasons_json)
    .bind(otp_hash)
    .bind(otp_expires_at)
    .bind(OTP_MAX_ATTEMPTS)
    .bind(resend_available_at)
    .bind(context.ip_address.clone())
    .bind(context.user_agent.clone())
    .bind(device_token_hash)
    .execute(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("OTP challenge insert failed: {}", error)))?;

    Ok((challenge_id, otp_code, otp_expires_at, resend_available_at))
}

pub(super) async fn resend_step_up_otp(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    challenge_id: String,
) -> Result<HttpResponse, AppError> {
    let context = super::super::super::extract_login_context(&req);
    let now = Utc::now();
    let challenge = sqlx::query_as::<
        _,
        (
            String,
            String,
            String,
            chrono::DateTime<Utc>,
            chrono::DateTime<Utc>,
            i64,
            Option<String>,
            Option<String>,
            i64,
        ),
    >(
        r#"
        SELECT id, user_id, status, otp_expires_at, resend_available_at, risk_score, risk_reasons_json, device_token_hash, resend_count
        FROM otp_challenges
        WHERE id = ?
        "#,
    )
    .bind(challenge_id.clone())
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Resend OTP challenge lookup failed: {}", error))
    })?
    .ok_or_else(|| AppError::ValidationError("Verification challenge not found.".into()))?;

    let (
        id,
        user_id,
        status,
        otp_expires_at,
        resend_available_at,
        risk_score,
        risk_reasons_json,
        challenge_device_hash,
        resend_count,
    ) = challenge;

    if status != "pending" {
        return Err(AppError::ValidationError(
            "Verification challenge is no longer active.".into(),
        ));
    }
    if now > otp_expires_at {
        return Err(AppError::ValidationError(
            "Verification code expired.".into(),
        ));
    }
    if now < resend_available_at {
        return Err(AppError::ValidationError(
            "Please wait before requesting another code.".into(),
        ));
    }

    super::super::super::enforce_otp_issue_rate_limit(pool.get_ref(), &user_id, &context).await?;

    let new_code = super::super::super::generate_otp_code();
    let new_hash = super::super::super::hash_otp(&new_code);
    let cooldown_secs = super::super::super::config_i64(
        "OTP_RESEND_COOLDOWN_SECONDS",
        OTP_RESEND_COOLDOWN_SECONDS_DEFAULT,
    );
    let next_resend_at = now + Duration::seconds(cooldown_secs);
    let next_expires_at = now + Duration::minutes(OTP_TTL_MINUTES);
    sqlx::query(
        r#"
        UPDATE otp_challenges
        SET otp_hash = ?, otp_expires_at = ?, attempts_used = 0,
            resend_available_at = ?, resend_count = ?
        WHERE id = ?
        "#,
    )
    .bind(new_hash)
    .bind(next_expires_at)
    .bind(next_resend_at)
    .bind(resend_count + 1)
    .bind(id.clone())
    .execute(pool.get_ref())
    .await
    .map_err(|error| AppError::InternalError(format!("Resend OTP update failed: {}", error)))?;

    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = ?")
        .bind(user_id.clone())
        .fetch_optional(pool.get_ref())
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Resend OTP user lookup failed: {}", error))
        })?
        .ok_or_else(|| AppError::Unauthorized("User not found.".into()))?;

    let subject = "Your updated Robust verification code";
    let body = format!(
        "<p>Use this new verification code:</p><p><strong>{}</strong></p><p>This code expires in 10 minutes.</p>",
        new_code
    );
    super::super::super::send_email_or_log(&user.email, subject, &body).await?;

    let reason = if challenge_device_hash.is_some() {
        "otp_resent_with_device_context"
    } else {
        "otp_resent"
    };
    super::super::super::log_auth_event(
        pool.get_ref(),
        Some(&user.id),
        "step_up_otp_resent",
        "challenge",
        Some(risk_score),
        Some(reason),
        &context,
        risk_reasons_json.as_deref(),
    )
    .await?;

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "challengeId": id,
        "message": "We sent a new verification code to your email.",
        "expiresAt": next_expires_at.to_rfc3339(),
        "resendAvailableAt": next_resend_at.to_rfc3339()
    })))
}
