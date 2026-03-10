use actix_web::{web, HttpResponse};
use chrono::Utc;
use sqlx::SqlitePool;
use uuid::Uuid;

use crate::models::AppError;

use super::super::{ResendVerificationPayload, SignUpPayload, VerifyEmailPayload};

pub(super) async fn signup(
    pool: web::Data<SqlitePool>,
    payload: web::Json<SignUpPayload>,
) -> Result<HttpResponse, AppError> {
    let payload = payload.into_inner();
    let email = super::super::normalize_email(&payload.email);
    let username = super::super::normalize_username(&payload.username);
    let password = payload.password.trim().to_string();
    let display_name = payload
        .display_name
        .unwrap_or_else(|| "Robust User".to_string())
        .trim()
        .to_string();

    super::super::validate_username(&username)?;
    super::super::validate_password(&password)?;

    let existing_email = sqlx::query_scalar::<_, String>("SELECT id FROM users WHERE email = ?")
        .bind(&email)
        .fetch_optional(pool.get_ref())
        .await
        .map_err(|error| AppError::InternalError(format!("Signup email lookup failed: {}", error)))?;
    if existing_email.is_some() {
        return Err(AppError::ValidationError("Email already registered.".into()));
    }

    let existing_username =
        sqlx::query_scalar::<_, String>("SELECT id FROM users WHERE username = ?")
            .bind(&username)
            .fetch_optional(pool.get_ref())
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Signup username lookup failed: {}", error))
            })?;
    if existing_username.is_some() {
        return Err(AppError::ValidationError("Username already taken.".into()));
    }

    let password_hash = super::super::hash_password(&password)?;
    let user_id = Uuid::new_v4().to_string();

    sqlx::query(
        r#"
        INSERT INTO users (id, email, username, password_hash, name, role, status)
        VALUES (?, ?, ?, ?, ?, 'user', 'pending_verification')
        "#,
    )
    .bind(&user_id)
    .bind(&email)
    .bind(&username)
    .bind(&password_hash)
    .bind(&display_name)
    .execute(pool.get_ref())
    .await
    .map_err(|error| AppError::InternalError(format!("Signup user insert failed: {}", error)))?;

    super::super::issue_verification_email(pool.get_ref(), &user_id, &email).await?;

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "message": "Account created. Please verify your email before signing in."
    })))
}

pub(super) async fn resend_verification_email(
    pool: web::Data<SqlitePool>,
    payload: web::Json<ResendVerificationPayload>,
) -> Result<HttpResponse, AppError> {
    let email = super::super::normalize_email(&payload.email);
    let row = sqlx::query_as::<_, (String, Option<chrono::DateTime<Utc>>)>(
        r#"
        SELECT id, email_verified_at
        FROM users
        WHERE email = ?
        "#,
    )
    .bind(&email)
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|error| {
        AppError::InternalError(format!(
            "Resend verification user lookup failed: {}",
            error
        ))
    })?;

    if let Some((user_id, email_verified_at)) = row
        && email_verified_at.is_none()
    {
        super::super::issue_verification_email(pool.get_ref(), &user_id, &email).await?;
    }

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "message": "If this account exists and is not verified, a verification email has been sent."
    })))
}

pub(super) async fn verify_email(
    pool: web::Data<SqlitePool>,
    payload: web::Json<VerifyEmailPayload>,
) -> Result<HttpResponse, AppError> {
    let token_hash = super::super::hash_token(payload.token.trim());
    let row = sqlx::query_as::<_, (String, chrono::DateTime<Utc>, Option<chrono::DateTime<Utc>>)>(
        r#"
        SELECT user_id, expires_at, consumed_at
        FROM email_verification_tokens
        WHERE token_hash = ?
        "#,
    )
    .bind(token_hash)
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Verification token lookup failed: {}", error))
    })?;

    let (user_id, expires_at, consumed_at) = row.ok_or_else(|| {
        AppError::ValidationError("Verification token is invalid or expired.".into())
    })?;

    if consumed_at.is_some() || Utc::now() > expires_at {
        return Err(AppError::ValidationError(
            "Verification token is invalid or expired.".into(),
        ));
    }

    let now = Utc::now();
    sqlx::query("UPDATE users SET email_verified_at = ?, status = 'active' WHERE id = ?")
        .bind(now)
        .bind(&user_id)
        .execute(pool.get_ref())
        .await
        .map_err(|error| {
            AppError::InternalError(format!("User verification update failed: {}", error))
        })?;

    sqlx::query("UPDATE email_verification_tokens SET consumed_at = ? WHERE token_hash = ?")
        .bind(now)
        .bind(super::super::hash_token(payload.token.trim()))
        .execute(pool.get_ref())
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Verification token consume failed: {}", error))
        })?;

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "ok": true,
        "message": "Email verified successfully. You can now sign in."
    })))
}
