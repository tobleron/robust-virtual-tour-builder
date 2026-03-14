use actix_web::{HttpMessage, HttpRequest, HttpResponse, web};
use chrono::{Duration, Utc};
use sqlx::SqlitePool;
use uuid::Uuid;

use crate::models::{AppError, User};

use super::super::{
    ChangePasswordPayload, ForgotPasswordPayload, PASSWORD_RESET_TOKEN_TTL_HOURS,
    ResetPasswordPayload,
};

pub(super) async fn forgot_password(
    pool: web::Data<SqlitePool>,
    payload: web::Json<ForgotPasswordPayload>,
) -> Result<HttpResponse, AppError> {
    let email = super::super::normalize_email(&payload.email);
    let user_opt = sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = ?")
        .bind(email.clone())
        .fetch_optional(pool.get_ref())
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Forgot-password user lookup failed: {}", error))
        })?;

    if let Some(user) = user_opt {
        let raw_token = format!("{}_{}", Uuid::new_v4(), Uuid::new_v4());
        let token_hash = super::super::hash_token(&raw_token);
        let expires_at = Utc::now() + Duration::hours(PASSWORD_RESET_TOKEN_TTL_HOURS);

        sqlx::query(
            r#"
            INSERT INTO password_reset_tokens (id, user_id, token_hash, expires_at)
            VALUES (?, ?, ?, ?)
            "#,
        )
        .bind(Uuid::new_v4().to_string())
        .bind(user.id)
        .bind(token_hash)
        .bind(expires_at)
        .execute(pool.get_ref())
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Password reset token insert failed: {}", error))
        })?;

        let reset_url = format!(
            "{}/reset-password?token={}",
            super::super::app_base_url(),
            raw_token
        );
        let email_body = format!(
            "<p>You requested a password reset.</p><p>Reset link: <a href=\"{0}\">{0}</a></p>",
            reset_url
        );
        super::super::send_email_or_log(&email, "Reset your Robust password", &email_body).await?;
    }

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "message": "If the email exists, a password reset link has been sent."
    })))
}

pub(super) async fn reset_password(
    pool: web::Data<SqlitePool>,
    payload: web::Json<ResetPasswordPayload>,
) -> Result<HttpResponse, AppError> {
    super::super::validate_password(payload.new_password.trim())?;
    let hashed_lookup = super::super::hash_token(payload.token.trim());
    let row = sqlx::query_as::<_, (String, chrono::DateTime<Utc>, Option<chrono::DateTime<Utc>>)>(
        r#"
        SELECT user_id, expires_at, consumed_at
        FROM password_reset_tokens
        WHERE token_hash = ?
        "#,
    )
    .bind(hashed_lookup.clone())
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|error| AppError::InternalError(format!("Reset token lookup failed: {}", error)))?;

    let (user_id, expires_at, consumed_at) =
        row.ok_or_else(|| AppError::ValidationError("Reset token is invalid or expired.".into()))?;
    if consumed_at.is_some() || Utc::now() > expires_at {
        return Err(AppError::ValidationError(
            "Reset token is invalid or expired.".into(),
        ));
    }

    let new_hash = super::super::hash_password(payload.new_password.trim())?;
    sqlx::query("UPDATE users SET password_hash = ? WHERE id = ?")
        .bind(new_hash)
        .bind(user_id.clone())
        .execute(pool.get_ref())
        .await
        .map_err(|error| AppError::InternalError(format!("Password update failed: {}", error)))?;

    let forced_until = Utc::now() + Duration::days(3);
    sqlx::query(
        "UPDATE users SET force_step_up_reason = 'password_reset_flow', force_step_up_until = ? WHERE id = ?",
    )
    .bind(forced_until)
    .bind(user_id.clone())
    .execute(pool.get_ref())
    .await
    .map_err(|error| AppError::InternalError(format!("Forced step-up set failed: {}", error)))?;

    sqlx::query("UPDATE trusted_devices SET revoked_at = ? WHERE user_id = ?")
        .bind(Utc::now())
        .bind(user_id.clone())
        .execute(pool.get_ref())
        .await
        .map_err(|error| {
            AppError::InternalError(format!(
                "Trusted device revocation on reset failed: {}",
                error
            ))
        })?;

    let context = super::super::empty_login_context();
    super::super::log_auth_event(
        pool.get_ref(),
        Some(&user_id),
        "password_reset_completed",
        "challenge_required_next_login",
        Some(60),
        Some("password_reset_flow"),
        &context,
        None,
    )
    .await?;

    sqlx::query("UPDATE password_reset_tokens SET consumed_at = ? WHERE token_hash = ?")
        .bind(Utc::now())
        .bind(hashed_lookup)
        .execute(pool.get_ref())
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Reset token consume failed: {}", error))
        })?;

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "message": "Password reset successful. Please sign in."
    })))
}

pub(super) async fn change_password(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<ChangePasswordPayload>,
) -> Result<HttpResponse, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or_else(|| AppError::Unauthorized("Authentication required.".into()))?;

    let current_password = payload.current_password.trim();
    let new_password = payload.new_password.trim();
    if !super::super::verify_password(current_password, &user.password_hash)? {
        return Err(AppError::ValidationError(
            "Current password is incorrect.".into(),
        ));
    }

    super::super::validate_password(new_password)?;
    let new_hash = super::super::hash_password(new_password)?;
    sqlx::query(
        "UPDATE users SET password_hash = ?, force_step_up_reason = NULL, force_step_up_until = NULL WHERE id = ?",
    )
    .bind(new_hash)
    .bind(&user.id)
    .execute(pool.get_ref())
    .await
    .map_err(|error| AppError::InternalError(format!("Password change failed: {}", error)))?;

    sqlx::query("UPDATE trusted_devices SET revoked_at = ? WHERE user_id = ?")
        .bind(Utc::now())
        .bind(&user.id)
        .execute(pool.get_ref())
        .await
        .map_err(|error| {
            AppError::InternalError(format!(
                "Trusted device revocation on password change failed: {}",
                error
            ))
        })?;

    let context = super::super::extract_login_context(&req);
    super::super::log_auth_event(
        pool.get_ref(),
        Some(&user.id),
        "password_changed",
        "allow",
        Some(15),
        Some("authenticated_password_change"),
        &context,
        None,
    )
    .await?;

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "message": "Password updated successfully."
    })))
}
