use chrono::{Duration, Utc};
use sqlx::SqlitePool;
use uuid::Uuid;

use crate::models::AppError;

use super::VERIFICATION_TOKEN_TTL_HOURS;

pub(super) fn email_provider_configured() -> bool {
    std::env::var("RESEND_API_KEY")
        .ok()
        .map(|value| !value.trim().is_empty())
        .unwrap_or(false)
}

pub(super) async fn send_email_or_log(
    to_email: &str,
    subject: &str,
    html_body: &str,
) -> Result<(), AppError> {
    let resend_api_key = std::env::var("RESEND_API_KEY").ok();
    let sender = std::env::var("EMAIL_FROM").unwrap_or_else(|_| "no-reply@robust-vtb.com".into());

    if let Some(api_key) = resend_api_key {
        let payload = serde_json::json!({
            "from": sender,
            "to": [to_email],
            "subject": subject,
            "html": html_body,
        });
        let client = reqwest::Client::new();
        let response = client
            .post("https://api.resend.com/emails")
            .header("Authorization", format!("Bearer {}", api_key))
            .header("Content-Type", "application/json")
            .json(&payload)
            .send()
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Email provider request failed: {}", error))
            })?;

        if !response.status().is_success() {
            let body = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown email provider error".to_string());
            return Err(AppError::InternalError(format!(
                "Email provider rejected request: {}",
                body
            )));
        }

        Ok(())
    } else {
        tracing::warn!(
            module = "AuthApi",
            to = %to_email,
            subject = %subject,
            "RESEND_API_KEY missing; email not sent via provider (logged for dev fallback)"
        );
        tracing::info!(module = "AuthApi", body = %html_body, "EMAIL_DEV_FALLBACK_BODY");
        if super::is_production() {
            return Err(AppError::InternalError(
                "Email provider is not configured in production.".into(),
            ));
        }
        Ok(())
    }
}

pub(super) fn app_base_url() -> String {
    std::env::var("APP_BASE_URL").unwrap_or_else(|_| "http://localhost:3000".to_string())
}

pub(super) async fn issue_verification_email(
    pool: &SqlitePool,
    user_id: &str,
    email: &str,
) -> Result<(), AppError> {
    let now = Utc::now();
    sqlx::query(
        r#"
        UPDATE email_verification_tokens
        SET consumed_at = ?
        WHERE user_id = ? AND consumed_at IS NULL
        "#,
    )
    .bind(now)
    .bind(user_id)
    .execute(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Verification token invalidate failed: {}", error))
    })?;

    let raw_token = format!("{}_{}", Uuid::new_v4(), Uuid::new_v4());
    let token_hash = super::hash_token(&raw_token);
    let expires_at = now + Duration::hours(VERIFICATION_TOKEN_TTL_HOURS);

    sqlx::query(
        r#"
        INSERT INTO email_verification_tokens (id, user_id, token_hash, expires_at)
        VALUES (?, ?, ?, ?)
        "#,
    )
    .bind(Uuid::new_v4().to_string())
    .bind(user_id)
    .bind(&token_hash)
    .bind(expires_at)
    .execute(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Verification token insert failed: {}", error))
    })?;

    let verify_url = format!("{}/verify-email?token={}", super::app_base_url(), raw_token);
    let email_body = format!(
        "<p>Welcome to Robust Virtual Tour Builder.</p><p>Verify your email: <a href=\"{0}\">{0}</a></p>",
        verify_url
    );
    super::send_email_or_log(email, "Verify your Robust account", &email_body).await
}
