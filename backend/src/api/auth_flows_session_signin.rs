use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use chrono::{Duration, Utc};
use sqlx::SqlitePool;

use crate::auth::encode_token;
use crate::models::{AppError, User};

use super::super::super::{
    AuthChallengeResponse, AuthSuccessResponse, DEVICE_COOKIE_NAME, MeResponse,
    STEP_UP_SESSION_HOURS_DEFAULT, SignInPayload,
};

pub(super) async fn signin(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<SignInPayload>,
) -> Result<HttpResponse, AppError> {
    let payload = payload.into_inner();
    let email = super::super::super::normalize_email(&payload.email);
    let context = super::super::super::extract_login_context(&req);
    let incoming_device_token = req
        .cookie(DEVICE_COOKIE_NAME)
        .map(|cookie| cookie.value().to_string());
    let incoming_device_hash = incoming_device_token
        .as_deref()
        .map(super::super::super::hash_token);

    super::super::super::enforce_failed_login_rate_limit(
        pool.get_ref(),
        None,
        &email,
        &context,
        incoming_device_hash.as_deref(),
    )
    .await?;

    let user_opt = sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = ?")
        .bind(email.clone())
        .fetch_optional(pool.get_ref())
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Signin user lookup failed: {}", error))
        })?;
    let user = if let Some(user) = user_opt {
        user
    } else {
        super::super::super::log_login_attempt(
            pool.get_ref(),
            None,
            &email,
            &context,
            incoming_device_hash.as_deref(),
            false,
            Some("user_not_found"),
        )
        .await?;
        return Err(AppError::Unauthorized("Invalid credentials".into()));
    };

    super::super::super::enforce_failed_login_rate_limit(
        pool.get_ref(),
        Some(&user.id),
        &email,
        &context,
        incoming_device_hash.as_deref(),
    )
    .await?;
    let is_valid =
        super::super::super::verify_password(payload.password.trim(), &user.password_hash)?;
    if !is_valid {
        super::super::super::log_login_attempt(
            pool.get_ref(),
            Some(&user.id),
            &email,
            &context,
            incoming_device_hash.as_deref(),
            false,
            Some("password_mismatch"),
        )
        .await?;
        super::super::super::log_auth_event(
            pool.get_ref(),
            Some(&user.id),
            "signin_failed",
            "denied",
            None,
            Some("invalid_password"),
            &context,
            None,
        )
        .await?;
        return Err(AppError::Unauthorized("Invalid credentials".into()));
    }

    if user.email_verified_at.is_none() {
        super::super::super::log_login_attempt(
            pool.get_ref(),
            Some(&user.id),
            &email,
            &context,
            incoming_device_hash.as_deref(),
            false,
            Some("email_not_verified"),
        )
        .await?;
        return Err(AppError::Unauthorized(
            "Email is not verified yet. Please verify before signing in.".into(),
        ));
    }

    let trusted_device = super::super::super::find_trusted_device(
        pool.get_ref(),
        &user.id,
        incoming_device_token.as_deref(),
    )
    .await?;
    let force_new_device_hard_trigger = trusted_device.is_none()
        && super::super::super::config_bool("STEP_UP_HARD_TRIGGER_NEW_DEVICE", true);
    let risk = super::super::super::compute_risk_decision(
        pool.get_ref(),
        &user,
        &email,
        &context,
        trusted_device.as_ref(),
        &req,
        force_new_device_hard_trigger,
    )
    .await?;

    let should_challenge = risk.hard_trigger || risk.score >= 50;
    if should_challenge {
        super::super::super::enforce_otp_issue_rate_limit(pool.get_ref(), &user.id, &context)
            .await?;
        let (challenge_id, otp_code, otp_expires_at, resend_available_at) =
            super::super::super::issue_or_refresh_step_up_challenge(
                pool.get_ref(),
                &user,
                &context,
                &risk,
                incoming_device_hash.as_deref(),
            )
            .await?;
        let subject = "Your Robust sign-in verification code";
        let body = format!(
            "<p>We sent this code because we detected a risky sign-in.</p><p><strong>{}</strong></p><p>This code expires in 10 minutes.</p>",
            otp_code
        );
        super::super::super::send_email_or_log(&user.email, subject, &body).await?;

        super::super::super::log_login_attempt(
            pool.get_ref(),
            Some(&user.id),
            &email,
            &context,
            incoming_device_hash.as_deref(),
            true,
            Some("password_ok_challenge_required"),
        )
        .await?;
        let reasons_json = serde_json::to_string(&risk.reasons).map_err(|error| {
            AppError::InternalError(format!("Risk reasons serialization failed: {}", error))
        })?;
        super::super::super::log_auth_event(
            pool.get_ref(),
            Some(&user.id),
            "step_up_otp_issued",
            "challenge",
            Some(risk.score),
            Some("risk_threshold_or_hard_trigger"),
            &context,
            Some(&reasons_json),
        )
        .await?;

        return Ok(HttpResponse::Accepted().json(AuthChallengeResponse {
            challenge_required: true,
            challenge_id,
            message: "We sent a verification code to your email.".to_string(),
            expires_at: otp_expires_at.to_rfc3339(),
            resend_available_at: resend_available_at.to_rfc3339(),
        }));
    }

    let current_device_token =
        incoming_device_token.unwrap_or_else(super::super::super::make_device_token);
    super::super::super::upsert_trusted_device(
        pool.get_ref(),
        &user.id,
        &current_device_token,
        &context,
    )
    .await?;
    let device_cookie = super::super::super::create_device_cookie(&current_device_token);
    let step_up_hours =
        super::super::super::config_i64("STEP_UP_SESSION_HOURS", STEP_UP_SESSION_HOURS_DEFAULT);
    let step_up_until = Some((Utc::now() + Duration::hours(step_up_hours)).timestamp() as usize);
    let token = encode_token(&user.id, step_up_until)?;
    let auth_cookie = super::super::super::create_auth_cookie(&token);
    super::super::super::log_login_attempt(
        pool.get_ref(),
        Some(&user.id),
        &email,
        &context,
        Some(&super::super::super::hash_token(&current_device_token)),
        true,
        None,
    )
    .await?;
    super::super::super::log_auth_event(
        pool.get_ref(),
        Some(&user.id),
        "signin_success",
        "allow",
        Some(risk.score),
        Some("trusted_login_no_step_up"),
        &context,
        None,
    )
    .await?;

    Ok(HttpResponse::Ok()
        .cookie(auth_cookie)
        .cookie(device_cookie)
        .json(AuthSuccessResponse {
            token,
            user: super::super::super::public_user(&user),
        }))
}

pub(super) fn signout() -> Result<HttpResponse, AppError> {
    let cookie = super::super::super::clear_auth_cookie();
    Ok(HttpResponse::Ok().cookie(cookie).json(serde_json::json!({
        "ok": true
    })))
}

pub(super) fn me(req: HttpRequest) -> Result<HttpResponse, AppError> {
    let user_opt = req.extensions().get::<User>().cloned();
    match user_opt {
        Some(user) => Ok(HttpResponse::Ok().json(MeResponse {
            authenticated: true,
            user: Some(super::super::super::public_user(&user)),
        })),
        None => Ok(HttpResponse::Unauthorized().json(MeResponse {
            authenticated: false,
            user: None,
        })),
    }
}
