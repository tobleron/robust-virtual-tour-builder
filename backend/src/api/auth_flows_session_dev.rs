use actix_web::{HttpRequest, HttpResponse, web};
use chrono::{Duration, Utc};
use sqlx::SqlitePool;
use uuid::Uuid;

use crate::auth::encode_token;
use crate::models::{AppError, User};

use super::super::super::{AuthSuccessResponse, DEVICE_COOKIE_NAME, STEP_UP_SESSION_HOURS_DEFAULT};

pub(super) async fn ensure_dev_bootstrap_user(pool: &SqlitePool) -> Result<User, AppError> {
    let email = super::super::super::dev_auth_email();
    let username = super::super::super::dev_auth_username();
    let display_name = super::super::super::dev_auth_name();

    if let Some(existing) = sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = ?")
        .bind(&email)
        .fetch_optional(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Dev auth user lookup failed: {}", error))
        })?
    {
        if existing.email_verified_at.is_none() || existing.status.as_deref() != Some("active") {
            let now = Utc::now();
            sqlx::query(
                r#"
                UPDATE users
                SET username = COALESCE(username, ?), name = ?, status = 'active', email_verified_at = COALESCE(email_verified_at, ?)
                WHERE id = ?
                "#,
            )
            .bind(&username)
            .bind(&display_name)
            .bind(now)
            .bind(&existing.id)
            .execute(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Dev auth user activation failed: {}", error))
            })?;
        }

        return sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = ?")
            .bind(&existing.id)
            .fetch_one(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Dev auth user reload failed: {}", error))
            });
    }

    super::super::super::validate_username(&username)?;
    super::super::super::validate_password(&super::super::super::dev_auth_password())?;
    let password_hash =
        super::super::super::hash_password(&super::super::super::dev_auth_password())?;
    let now = Utc::now();
    let user_id = Uuid::new_v4().to_string();

    sqlx::query(
        r#"
        INSERT INTO users (id, email, username, password_hash, name, role, status, email_verified_at)
        VALUES (?, ?, ?, ?, ?, 'user', 'active', ?)
        "#,
    )
    .bind(&user_id)
    .bind(&email)
    .bind(&username)
    .bind(&password_hash)
    .bind(&display_name)
    .bind(now)
    .execute(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Dev auth user insert failed: {}", error)))?;

    sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = ?")
        .bind(&user_id)
        .fetch_one(pool)
        .await
        .map_err(|error| AppError::InternalError(format!("Dev auth user fetch failed: {}", error)))
}

pub(super) async fn dev_signin(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
) -> Result<HttpResponse, AppError> {
    if !super::super::super::dev_auth_bootstrap_enabled()
        || !super::super::super::is_local_dev_request(&req)
    {
        return Err(AppError::Unauthorized(
            "Development login is unavailable in this environment.".into(),
        ));
    }

    let user = ensure_dev_bootstrap_user(pool.get_ref()).await?;
    let context = super::super::super::extract_login_context(&req);
    let current_device_token = req
        .cookie(DEVICE_COOKIE_NAME)
        .map(|cookie| cookie.value().to_string())
        .unwrap_or_else(super::super::super::make_device_token);

    super::super::super::upsert_trusted_device(
        pool.get_ref(),
        &user.id,
        &current_device_token,
        &context,
    )
    .await?;

    let step_up_hours =
        super::super::super::config_i64("STEP_UP_SESSION_HOURS", STEP_UP_SESSION_HOURS_DEFAULT);
    let step_up_until = Some((Utc::now() + Duration::hours(step_up_hours)).timestamp() as usize);
    let token = encode_token(&user.id, step_up_until)?;
    let auth_cookie = super::super::super::create_auth_cookie(&token);
    let device_cookie = super::super::super::create_device_cookie(&current_device_token);

    super::super::super::log_login_attempt(
        pool.get_ref(),
        Some(&user.id),
        &user.email,
        &context,
        Some(&super::super::super::hash_token(&current_device_token)),
        true,
        Some("dev_bootstrap_login"),
    )
    .await?;
    super::super::super::log_auth_event(
        pool.get_ref(),
        Some(&user.id),
        "signin_success",
        "allow",
        Some(0),
        Some("dev_bootstrap_login"),
        &context,
        Some(r#"{"devBootstrap":true}"#),
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
