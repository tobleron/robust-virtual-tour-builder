// @efficiency-role: service-orchestrator
use crate::auth::decode_token;
use crate::models::User;
use actix_web::{HttpMessage, HttpResponse, dev::ServiceRequest, http::header, web};
use chrono::Utc;
use sqlx::SqlitePool;
use uuid::Uuid;

pub(super) fn extract_token(req: &ServiceRequest) -> Option<String> {
    if let Some(header) = req.headers().get(header::AUTHORIZATION) {
        if let Ok(header_str) = header.to_str() {
            if let Some(token) = header_str.strip_prefix("Bearer ") {
                return Some(token.to_string());
            }
        }
    }
    if let Some(token) = req.cookie("auth_token") {
        return Some(token.value().to_string());
    }

    None
}

pub(super) async fn attach_user_to_request(
    req: &ServiceRequest,
    user_id: &str,
) -> Result<(), HttpResponse> {
    if user_id == "dev_user_id" {
        req.extensions_mut().insert(dev_admin_user());
        return Ok(());
    }

    let pool = req.app_data::<web::Data<SqlitePool>>().ok_or_else(|| {
        tracing::error!("Database pool not found in app_data");
        HttpResponse::InternalServerError().finish()
    })?;

    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = ?")
        .bind(user_id)
        .fetch_optional(pool.get_ref())
        .await
        .map_err(|e| {
            tracing::error!("Database error during auth: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({"error": "Database error"}))
        })?
        .ok_or_else(|| {
            HttpResponse::Unauthorized().json(serde_json::json!({"error": "User not found"}))
        })?;

    req.extensions_mut().insert(user);
    Ok(())
}

pub(super) fn headless_token() -> Option<String> {
    std::env::var("HEADLESS_API_TOKEN").ok()
}

pub(super) fn headless_user_metadata() -> (String, String, String, String) {
    let id = std::env::var("HEADLESS_USER_ID").unwrap_or_else(|_| Uuid::new_v4().to_string());
    let email = std::env::var("HEADLESS_USER_EMAIL")
        .unwrap_or_else(|_| "headless@vtb.internal".to_string());
    let name =
        std::env::var("HEADLESS_USER_NAME").unwrap_or_else(|_| "Headless Teaser".to_string());
    let role = std::env::var("HEADLESS_USER_ROLE").unwrap_or_else(|_| "system".to_string());
    (id, email, name, role)
}

pub(super) fn is_headless_token(token: &str) -> bool {
    match headless_token() {
        Some(expected) => expected == token,
        None => false,
    }
}

pub(super) async fn attach_headless_user(req: &ServiceRequest) -> Result<(), HttpResponse> {
    let (id, email, name, role) = headless_user_metadata();
    let user = User {
        id,
        email,
        username: Some("headless-runtime".to_string()),
        password_hash: String::new(),
        name,
        role,
        status: Some("active".to_string()),
        email_verified_at: Some(Utc::now()),
        force_step_up_reason: None,
        force_step_up_until: None,
        theme_preference: None,
        language_preference: None,
        created_at: Utc::now(),
    };
    req.extensions_mut().insert(user);
    Ok(())
}

pub(super) async fn process_authentication(req: &ServiceRequest) -> Result<(), HttpResponse> {
    let token = extract_token(req).ok_or_else(|| {
        HttpResponse::Unauthorized().json(serde_json::json!({
            "error": "Missing Authorization header or auth_token cookie"
        }))
    })?;

    let is_prod = crate::startup::is_production();
    let bypass_allowed = !is_prod
        && std::env::var("BYPASS_AUTH")
            .map(|v| v == "true")
            .unwrap_or(false);

    if is_headless_token(&token) {
        tracing::info!(target: "auth", "HEADLESS_TEASER_AUTHENTICATED");
        return attach_headless_user(req).await;
    }

    if bypass_allowed && token.trim() == "dev-token" {
        tracing::warn!(
            target: "auth",
            "⚠️  INSECURE: Using DEV_TOKEN bypass for authentication. This is only allowed in non-production environments."
        );
        return attach_user_to_request(req, "dev_user_id").await;
    }

    if token.trim() == "dev-token" && is_prod {
        tracing::error!(
            target: "auth",
            "🛑 SECURITY ALERT: Attempted to use dev-token in PRODUCTION environment. Request rejected."
        );
        return Err(HttpResponse::Unauthorized().json(serde_json::json!({
            "error": "Insecure authentication method rejected in production"
        })));
    }

    let claims = decode_token(&token).map_err(|e| {
        HttpResponse::Unauthorized().json(serde_json::json!({
            "error": e.to_string()
        }))
    })?;
    req.extensions_mut().insert(claims.clone());

    attach_user_to_request(req, &claims.sub).await
}

fn dev_admin_user() -> User {
    User {
        id: "dev_user_id".to_string(),
        email: "admin@dev.local".to_string(),
        username: Some("dev-admin".to_string()),
        password_hash: "".to_string(),
        name: "Dev Administrator".to_string(),
        role: "admin".to_string(),
        status: Some("active".to_string()),
        email_verified_at: Some(Utc::now()),
        force_step_up_reason: None,
        force_step_up_until: None,
        theme_preference: Some("dark".into()),
        language_preference: Some("en".into()),
        created_at: Utc::now(),
    }
}
