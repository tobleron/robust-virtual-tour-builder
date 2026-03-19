// @efficiency-role: service-orchestrator
use chrono::Utc;
use sqlx::SqlitePool;

use crate::models::{AppError, User};
use crate::services::portal::{PortalSettings, UpdatePortalSettingsInput};
use crate::services::portal_audit::log_audit;

pub fn is_portal_admin(user: &User) -> bool {
    if user.role == "admin" {
        return true;
    }

    let allowed = std::env::var("PORTAL_ADMIN_EMAILS").unwrap_or_default();
    if allowed.trim().is_empty() {
        return false;
    }

    allowed
        .split(',')
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .any(|value| value.eq_ignore_ascii_case(&user.email))
}

async fn ensure_settings_row(pool: &SqlitePool) -> Result<(), AppError> {
    sqlx::query(
        r#"
        INSERT OR IGNORE INTO portal_settings (
            id, renewal_heading, renewal_message, contact_email, contact_phone, whatsapp_number, updated_at
        ) VALUES (1, 'Access expired', 'Contact Robust Virtual Tour Builder to renew access.', NULL, NULL, NULL, ?)
        "#,
    )
    .bind(Utc::now())
    .execute(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal settings bootstrap failed: {}", error)))?;
    Ok(())
}

pub async fn load_settings(pool: &SqlitePool) -> Result<PortalSettings, AppError> {
    ensure_settings_row(pool).await?;
    sqlx::query_as::<_, PortalSettings>("SELECT * FROM portal_settings WHERE id = 1")
        .fetch_one(pool)
        .await
        .map_err(|error| AppError::InternalError(format!("Portal settings load failed: {}", error)))
}

pub async fn update_settings(
    pool: &SqlitePool,
    input: UpdatePortalSettingsInput,
    actor: Option<&User>,
) -> Result<PortalSettings, AppError> {
    ensure_settings_row(pool).await?;
    let heading = input.renewal_heading.trim().to_string();
    let message = input.renewal_message.trim().to_string();
    if heading.is_empty() || message.is_empty() {
        return Err(AppError::ValidationError(
            "Renewal heading and message are required.".into(),
        ));
    }

    let now = Utc::now();
    sqlx::query(
        r#"
        UPDATE portal_settings
        SET renewal_heading = ?, renewal_message = ?, contact_email = ?, contact_phone = ?, whatsapp_number = ?, updated_at = ?
        WHERE id = 1
        "#,
    )
    .bind(&heading)
    .bind(&message)
    .bind(input.contact_email.as_deref())
    .bind(input.contact_phone.as_deref())
    .bind(input.whatsapp_number.as_deref())
    .bind(now)
    .execute(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal settings update failed: {}", error)))?;

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        None,
        "portal_settings_updated",
        serde_json::json!({"updatedAt": now}),
    )
    .await?;

    load_settings(pool).await
}
