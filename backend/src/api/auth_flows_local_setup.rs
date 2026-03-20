use actix_web::{HttpRequest, HttpResponse, web};
use chrono::Utc;
use sqlx::SqlitePool;
use uuid::Uuid;

use crate::models::{AppError, User};
use crate::services::media::StorageManager;

use super::{
    DEVICE_COOKIE_NAME, LocalResetPayload, LocalResetResponse, LocalSetupBootstrapPayload,
    LocalSetupBootstrapResponse, LocalSetupStatusResponse,
};

fn move_storage_entry(source: &std::path::Path, target: &std::path::Path) -> Result<(), AppError> {
    if !source.exists() {
        return Ok(());
    }

    if !target.exists() {
        std::fs::rename(source, target).map_err(AppError::IoError)?;
        return Ok(());
    }

    let source_meta = std::fs::metadata(source).map_err(AppError::IoError)?;
    let target_meta = std::fs::metadata(target).map_err(AppError::IoError)?;

    if source_meta.is_dir() && target_meta.is_dir() {
        for entry in std::fs::read_dir(source).map_err(AppError::IoError)? {
            let entry = entry.map_err(AppError::IoError)?;
            let source_child = entry.path();
            let target_child = target.join(entry.file_name());
            move_storage_entry(&source_child, &target_child)?;
        }
        std::fs::remove_dir_all(source).map_err(AppError::IoError)?;
        return Ok(());
    }

    if source_meta.is_file() && target_meta.is_file() {
        std::fs::remove_file(source).map_err(AppError::IoError)?;
        return Ok(());
    }

    Ok(())
}

fn move_user_storage(source_user_id: &str, target_user_id: &str) -> Result<(), AppError> {
    if source_user_id == target_user_id {
        return Ok(());
    }

    let source_root = StorageManager::get_user_path(source_user_id).map_err(AppError::IoError)?;
    if !source_root.exists() {
        return Ok(());
    }

    let target_root = StorageManager::get_user_path(target_user_id).map_err(AppError::IoError)?;
    if !target_root.exists() {
        std::fs::create_dir_all(&target_root).map_err(AppError::IoError)?;
    }

    for entry in std::fs::read_dir(&source_root).map_err(AppError::IoError)? {
        let entry = entry.map_err(AppError::IoError)?;
        let source_path = entry.path();
        let target_path = target_root.join(entry.file_name());
        move_storage_entry(&source_path, &target_path)?;
    }

    if source_root.exists() {
        std::fs::remove_dir_all(source_root).map_err(AppError::IoError)?;
    }

    Ok(())
}

async fn consolidate_other_users(pool: &SqlitePool, owner_user_id: &str) -> Result<(), AppError> {
    let other_user_ids = sqlx::query_scalar::<_, String>(
        "SELECT id FROM users WHERE id != ? ORDER BY created_at ASC",
    )
    .bind(owner_user_id)
    .fetch_all(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!(
            "Local setup other-user lookup failed: {}",
            error
        ))
    })?;

    for other_user_id in other_user_ids {
        sqlx::query("UPDATE projects SET user_id = ? WHERE user_id = ?")
            .bind(owner_user_id)
            .bind(&other_user_id)
            .execute(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!(
                    "Local setup project reassignment failed: {}",
                    error
                ))
            })?;

        move_user_storage(&other_user_id, owner_user_id)?;

        sqlx::query("DELETE FROM users WHERE id = ?")
            .bind(&other_user_id)
            .execute(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!(
                    "Local setup extra-user cleanup failed: {}",
                    error
                ))
            })?;
    }

    Ok(())
}

async fn total_user_count(pool: &SqlitePool) -> Result<i64, AppError> {
    sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM users")
        .fetch_one(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Local setup user count failed: {}", error))
        })
}

async fn pending_setup_user_id(pool: &SqlitePool) -> Result<Option<String>, AppError> {
    sqlx::query_scalar::<_, String>(
        "SELECT id FROM users WHERE status = 'local_setup_pending' ORDER BY created_at ASC LIMIT 1",
    )
    .fetch_optional(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Local setup pending-user lookup failed: {}", error))
    })
}

async fn non_pending_user_count(pool: &SqlitePool) -> Result<i64, AppError> {
    sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM users WHERE status IS NULL OR status != 'local_setup_pending'",
    )
    .fetch_one(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Local setup active-user count failed: {}", error))
    })
}

async fn local_setup_required(pool: &SqlitePool) -> Result<bool, AppError> {
    let total_users = total_user_count(pool).await?;
    if total_users == 0 {
        return Ok(true);
    }
    if non_pending_user_count(pool).await? > 0 {
        return Ok(false);
    }
    Ok(pending_setup_user_id(pool).await?.is_some())
}

fn remote_bootstrap_mode() -> String {
    std::env::var("LOCAL_SETUP_BOOTSTRAP_MODE")
        .unwrap_or_default()
        .trim()
        .to_ascii_lowercase()
}

fn remote_bootstrap_expires_at() -> Option<i64> {
    std::env::var("LOCAL_SETUP_BOOTSTRAP_EXPIRES_AT")
        .ok()
        .and_then(|value| value.parse::<i64>().ok())
}

fn remote_bootstrap_enabled() -> bool {
    if remote_bootstrap_mode() != "token" {
        return false;
    }

    let token_hash = std::env::var("LOCAL_SETUP_BOOTSTRAP_TOKEN_HASH").unwrap_or_default();
    if token_hash.trim().is_empty() {
        return false;
    }

    remote_bootstrap_expires_at()
        .map(|expires_at| expires_at > Utc::now().timestamp())
        .unwrap_or(false)
}

fn ensure_local_request(req: &HttpRequest) -> Result<(), AppError> {
    if !super::is_local_dev_request(req) {
        return Err(AppError::Unauthorized(
            "Local setup is unavailable outside localhost.".into(),
        ));
    }
    Ok(())
}

async fn clear_auth_state(pool: &SqlitePool) -> Result<(), AppError> {
    for statement in [
        "DELETE FROM sessions",
        "DELETE FROM trusted_devices",
        "DELETE FROM login_attempts",
        "DELETE FROM otp_challenges",
        "DELETE FROM auth_events",
        "DELETE FROM email_verification_tokens",
        "DELETE FROM password_reset_tokens",
    ] {
        sqlx::query(statement)
            .execute(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Local reset query failed: {}", error))
            })?;
    }
    Ok(())
}

fn random_placeholder_email() -> String {
    format!("reset-{}@local.invalid", Uuid::new_v4().simple())
}

fn random_placeholder_username() -> String {
    format!("reset-{}", &Uuid::new_v4().simple().to_string()[..12])
}

pub(super) async fn setup_status(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
) -> Result<HttpResponse, AppError> {
    let local_only = super::is_local_dev_request(&req);
    let has_users = total_user_count(pool.get_ref()).await? > 0;
    let setup_required = local_setup_required(pool.get_ref()).await?;
    let bootstrap_mode = if !setup_required {
        "disabled".to_string()
    } else if local_only {
        "local".to_string()
    } else if remote_bootstrap_enabled() {
        "token".to_string()
    } else {
        "disabled".to_string()
    };

    Ok(HttpResponse::Ok().json(LocalSetupStatusResponse {
        setup_required,
        local_only,
        has_users,
        reset_available: local_only,
        bootstrap_mode,
    }))
}

fn ensure_setup_bootstrap_access(
    req: &HttpRequest,
    payload: &LocalSetupBootstrapPayload,
    setup_required: bool,
) -> Result<(), AppError> {
    if !setup_required {
        return Err(AppError::ValidationError(
            "Local setup is already completed for this install.".into(),
        ));
    }

    if super::is_local_dev_request(req) {
        return Ok(());
    }

    if !remote_bootstrap_enabled() {
        return Err(AppError::Unauthorized(
            "Remote setup is disabled for this runtime.".into(),
        ));
    }

    let expires_at = remote_bootstrap_expires_at().ok_or_else(|| {
        AppError::Unauthorized("Remote setup token is missing its expiry.".into())
    })?;
    if expires_at <= Utc::now().timestamp() {
        return Err(AppError::Unauthorized(
            "Remote setup token has expired. Restart the setup launcher.".into(),
        ));
    }

    let setup_token = payload
        .setup_token
        .as_deref()
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .ok_or_else(|| {
            AppError::Unauthorized("Setup token is required for remote setup.".into())
        })?;
    let expected_hash = std::env::var("LOCAL_SETUP_BOOTSTRAP_TOKEN_HASH").unwrap_or_default();
    if expected_hash.trim().is_empty() || super::hash_token(setup_token) != expected_hash {
        return Err(AppError::Unauthorized("Setup token is invalid.".into()));
    }

    Ok(())
}

pub(super) async fn bootstrap_local_owner(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<LocalSetupBootstrapPayload>,
) -> Result<HttpResponse, AppError> {
    let payload = payload.into_inner();
    let setup_required = local_setup_required(pool.get_ref()).await?;
    ensure_setup_bootstrap_access(&req, &payload, setup_required)?;

    let email = super::normalize_email(&payload.email);
    let username = super::normalize_username(&payload.username);
    let password = payload.password.trim().to_string();
    let display_name = payload
        .display_name
        .unwrap_or_else(|| "Local Builder Owner".to_string())
        .trim()
        .to_string();

    super::validate_username(&username)?;
    super::validate_password(&password)?;

    let pending_user_id = pending_setup_user_id(pool.get_ref()).await?;
    let non_pending_users = non_pending_user_count(pool.get_ref()).await?;

    let user = if let Some(user_id) = pending_user_id {
        if non_pending_users > 0 {
            return Err(AppError::ValidationError(
                "Local setup is already completed for this install.".into(),
            ));
        }

        let password_hash = super::hash_password(&password)?;
        let now = Utc::now();
        sqlx::query(
            r#"
            UPDATE users
            SET email = ?, username = ?, password_hash = ?, name = ?, role = 'admin',
                status = 'active', email_verified_at = ?, force_step_up_reason = NULL, force_step_up_until = NULL
            WHERE id = ?
            "#,
        )
        .bind(&email)
        .bind(&username)
        .bind(&password_hash)
        .bind(&display_name)
        .bind(now)
        .bind(&user_id)
        .execute(pool.get_ref())
        .await
        .map_err(|error| AppError::InternalError(format!("Local setup user update failed: {}", error)))?;

        sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = ?")
            .bind(&user_id)
            .fetch_one(pool.get_ref())
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Local setup user reload failed: {}", error))
            })?
    } else {
        if total_user_count(pool.get_ref()).await? > 0 {
            return Err(AppError::ValidationError(
                "Local setup is already completed for this install.".into(),
            ));
        }

        let password_hash = super::hash_password(&password)?;
        let user_id = Uuid::new_v4().to_string();
        let now = Utc::now();
        sqlx::query(
            r#"
            INSERT INTO users (id, email, username, password_hash, name, role, status, email_verified_at)
            VALUES (?, ?, ?, ?, ?, 'admin', 'active', ?)
            "#,
        )
        .bind(&user_id)
        .bind(&email)
        .bind(&username)
        .bind(&password_hash)
        .bind(&display_name)
        .bind(now)
        .execute(pool.get_ref())
        .await
        .map_err(|error| AppError::InternalError(format!("Local setup user insert failed: {}", error)))?;

        sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = ?")
            .bind(&user_id)
            .fetch_one(pool.get_ref())
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Local setup user fetch failed: {}", error))
            })?
    };

    consolidate_other_users(pool.get_ref(), &user.id).await?;

    let context = super::extract_login_context(&req);
    let current_device_token = req
        .cookie(DEVICE_COOKIE_NAME)
        .map(|cookie| cookie.value().to_string())
        .unwrap_or_else(super::make_device_token);
    super::upsert_trusted_device(pool.get_ref(), &user.id, &current_device_token, &context)
        .await?;
    let auth_cookie = super::clear_auth_cookie();
    let device_cookie = super::create_device_cookie(&current_device_token);
    let prior_device_hash = req
        .cookie(DEVICE_COOKIE_NAME)
        .map(|cookie| super::hash_token(cookie.value()));

    super::log_login_attempt(
        pool.get_ref(),
        Some(&user.id),
        &user.email,
        &context,
        prior_device_hash.as_deref(),
        true,
        Some("local_setup_bootstrap"),
    )
    .await?;
    super::log_auth_event(
        pool.get_ref(),
        Some(&user.id),
        "local_setup_completed",
        "allow",
        Some(0),
        Some("localhost_bootstrap"),
        &context,
        None,
    )
    .await?;

    Ok(HttpResponse::Ok()
        .cookie(auth_cookie)
        .cookie(device_cookie)
        .json(LocalSetupBootstrapResponse {
            ok: true,
            message: "Local owner account created. Sign in to continue.".to_string(),
            email: user.email.clone(),
        }))
}

pub(super) async fn reset_local_owner(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<LocalResetPayload>,
) -> Result<HttpResponse, AppError> {
    ensure_local_request(&req)?;
    let reset_projects = payload.into_inner().reset_projects;

    clear_auth_state(pool.get_ref()).await?;

    if reset_projects {
        sqlx::query("DELETE FROM projects")
            .execute(pool.get_ref())
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Local reset project delete failed: {}", error))
            })?;
        sqlx::query("DELETE FROM users")
            .execute(pool.get_ref())
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Local reset user delete failed: {}", error))
            })?;

        let storage_root = StorageManager::get_storage_root();
        if storage_root.exists() {
            std::fs::remove_dir_all(&storage_root).map_err(AppError::IoError)?;
        }
        StorageManager::init().map_err(AppError::IoError)?;

        return Ok(HttpResponse::Ok().cookie(super::clear_auth_cookie()).json(
            LocalResetResponse {
                ok: true,
                message: "Local builder was reset and all projects were removed.".to_string(),
                setup_required: true,
                projects_cleared: true,
            },
        ));
    }

    let users = sqlx::query_as::<_, User>("SELECT * FROM users ORDER BY created_at ASC")
        .fetch_all(pool.get_ref())
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Local reset user lookup failed: {}", error))
        })?;

    if users.is_empty() {
        return Ok(HttpResponse::Ok().cookie(super::clear_auth_cookie()).json(
            LocalResetResponse {
                ok: true,
                message: "Local auth was reset. Setup is ready.".to_string(),
                setup_required: true,
                projects_cleared: false,
            },
        ));
    }

    let canonical_user = users
        .first()
        .cloned()
        .ok_or_else(|| AppError::InternalError("Local reset canonical user selection failed".into()))?;

    for user in users.iter().skip(1) {
        sqlx::query("UPDATE projects SET user_id = ? WHERE user_id = ?")
            .bind(&canonical_user.id)
            .bind(&user.id)
            .execute(pool.get_ref())
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Local reset project reassignment failed: {}", error))
            })?;

        move_user_storage(&user.id, &canonical_user.id)?;

        sqlx::query("DELETE FROM users WHERE id = ?")
            .bind(&user.id)
            .execute(pool.get_ref())
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Local reset extra-user delete failed: {}", error))
            })?;
    }

    let password_hash =
        super::hash_password(&format!("reset-{}-{}", canonical_user.id, Uuid::new_v4()))?;
    sqlx::query(
        r#"
        UPDATE users
        SET email = ?, username = ?, password_hash = ?, status = 'local_setup_pending',
            email_verified_at = NULL, force_step_up_reason = NULL, force_step_up_until = NULL,
            role = 'user', name = 'Local Builder Owner'
        WHERE id = ?
        "#,
    )
    .bind(random_placeholder_email())
    .bind(random_placeholder_username())
    .bind(password_hash)
    .bind(&canonical_user.id)
    .execute(pool.get_ref())
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Local reset user update failed: {}", error))
    })?;

    Ok(HttpResponse::Ok()
        .cookie(super::clear_auth_cookie())
        .json(LocalResetResponse {
            ok: true,
            message: "Local auth was reset. Projects were preserved.".to_string(),
            setup_required: true,
            projects_cleared: false,
        }))
}
