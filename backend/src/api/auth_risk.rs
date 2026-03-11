use actix_web::HttpRequest;
use chrono::{Duration, Utc};
use sqlx::SqlitePool;

use crate::models::{AppError, User};

use super::{
    DEVICE_INACTIVITY_CHALLENGE_DAYS_DEFAULT, IpReputation, LoginContext,
    MAX_FAILED_LOGIN_BY_ACCOUNT_WINDOW_DEFAULT, MAX_FAILED_LOGIN_BY_IP_WINDOW_DEFAULT,
    MAX_OTP_ISSUES_PER_HOUR_DEFAULT, RiskDecision, TrustedDeviceRecord,
};

pub(super) async fn enforce_failed_login_rate_limit(
    pool: &SqlitePool,
    user_id: Option<&str>,
    email: &str,
    context: &LoginContext,
    device_token_hash: Option<&str>,
) -> Result<(), AppError> {
    let (account_failed, ip_failed) =
        super::count_recent_failed_logins(pool, user_id, email, context, device_token_hash).await?;
    let account_limit = super::config_i64(
        "MAX_FAILED_LOGIN_BY_ACCOUNT_WINDOW",
        MAX_FAILED_LOGIN_BY_ACCOUNT_WINDOW_DEFAULT,
    );
    let ip_limit = super::config_i64(
        "MAX_FAILED_LOGIN_BY_IP_WINDOW",
        MAX_FAILED_LOGIN_BY_IP_WINDOW_DEFAULT,
    );
    if account_failed >= account_limit || ip_failed >= ip_limit {
        return Err(AppError::Unauthorized(
            "Too many recent failed login attempts. Please wait and try again.".into(),
        ));
    }
    Ok(())
}

pub(super) fn haversine_km(lat1: f64, lon1: f64, lat2: f64, lon2: f64) -> f64 {
    let earth_radius_km = 6371.0_f64;
    let delta_lat = (lat2 - lat1).to_radians();
    let delta_lon = (lon2 - lon1).to_radians();
    let a = (delta_lat / 2.0).sin() * (delta_lat / 2.0).sin()
        + lat1.to_radians().cos()
            * lat2.to_radians().cos()
            * (delta_lon / 2.0).sin()
            * (delta_lon / 2.0).sin();
    let c = 2.0 * a.sqrt().atan2((1.0 - a).sqrt());
    earth_radius_km * c
}

pub(super) fn evaluate_geo_anomaly(
    last_success: Option<&(
        chrono::DateTime<Utc>,
        Option<String>,
        Option<String>,
        Option<f64>,
        Option<f64>,
    )>,
    context: &LoginContext,
) -> bool {
    let Some((last_at, last_country, last_region, last_lat, last_lon)) = last_success else {
        return false;
    };
    if let (Some(lat1), Some(lon1), Some(lat2), Some(lon2)) =
        (*last_lat, *last_lon, context.lat, context.lon)
    {
        let distance_km = super::haversine_km(lat1, lon1, lat2, lon2);
        let hours = (Utc::now() - *last_at).num_minutes() as f64 / 60.0;
        if hours > 0.0 && distance_km > 1200.0 && hours < 4.0 {
            return true;
        }
    }
    let country_changed = match (last_country.as_deref(), context.country.as_deref()) {
        (Some(previous), Some(current)) => previous != current,
        _ => false,
    };
    let region_changed = match (last_region.as_deref(), context.region.as_deref()) {
        (Some(previous), Some(current)) => previous != current,
        _ => false,
    };
    country_changed && region_changed
}

pub(super) fn evaluate_context_mismatch(
    trusted_device: Option<&TrustedDeviceRecord>,
    context: &LoginContext,
    risk_reasons_count_before: usize,
) -> bool {
    let Some(device) = trusted_device else {
        return false;
    };
    let ua_jump = match (
        device.user_agent_family.as_deref(),
        context.user_agent_family.as_deref(),
    ) {
        (Some(previous), Some(current)) => previous != current,
        _ => false,
    };
    let timezone_jump = match (device.last_timezone.as_deref(), context.timezone.as_deref()) {
        (Some(previous), Some(current)) => previous != current,
        _ => false,
    };
    let language_jump = match (device.last_language.as_deref(), context.language.as_deref()) {
        (Some(previous), Some(current)) => previous != current,
        _ => false,
    };
    let has_secondary_signal = risk_reasons_count_before > 0;
    (ua_jump || (timezone_jump && language_jump)) && has_secondary_signal
}

pub(super) async fn compute_risk_decision(
    pool: &SqlitePool,
    user: &User,
    email: &str,
    context: &LoginContext,
    trusted_device: Option<&TrustedDeviceRecord>,
    req: &HttpRequest,
    force_new_device_hard_trigger: bool,
) -> Result<RiskDecision, AppError> {
    let mut score = 0_i64;
    let mut reasons: Vec<String> = Vec::new();
    let mut hard_trigger = force_new_device_hard_trigger;

    if force_new_device_hard_trigger {
        score += 50;
        reasons.push("new_device".to_string());
    }

    let inactivity_days = super::config_i64(
        "STEP_UP_INACTIVITY_DAYS",
        DEVICE_INACTIVITY_CHALLENGE_DAYS_DEFAULT,
    );
    if let Some(device) = trusted_device
        && (Utc::now() > device.trust_expires_at
            || Utc::now() - device.last_seen_at >= Duration::days(inactivity_days))
    {
        score += 25;
        reasons.push("long_inactivity".to_string());
    }

    let last_success = super::load_last_success_login_context(pool, &user.id).await?;
    if super::evaluate_geo_anomaly(last_success.as_ref(), context) {
        score += 40;
        reasons.push("geo_anomaly".to_string());
    }

    if let IpReputation::Bad(reason) = super::evaluate_ip_reputation(req) {
        score += 40;
        reasons.push(reason);
    }

    let (failed_account_or_user, failed_ip) =
        super::count_recent_failed_logins(pool, Some(&user.id), email, context, None).await?;
    if failed_account_or_user >= 3 || failed_ip >= 5 {
        score += 30;
        reasons.push("recent_failed_attempts".to_string());
    }

    if super::evaluate_context_mismatch(trusted_device, context, reasons.len()) {
        score += 20;
        reasons.push("context_mismatch".to_string());
    }

    if let Some(force_until) = user.force_step_up_until
        && Utc::now() <= force_until
    {
        score += 60;
        hard_trigger = true;
        reasons.push(
            user.force_step_up_reason
                .clone()
                .unwrap_or_else(|| "forced_step_up".to_string()),
        );
    }

    Ok(RiskDecision {
        score,
        reasons,
        hard_trigger,
    })
}

pub(super) async fn enforce_otp_issue_rate_limit(
    pool: &SqlitePool,
    user_id: &str,
    context: &LoginContext,
) -> Result<(), AppError> {
    let max_per_hour =
        super::config_i64("MAX_OTP_ISSUES_PER_HOUR", MAX_OTP_ISSUES_PER_HOUR_DEFAULT);
    let window_start = Utc::now() - Duration::hours(1);
    let issued_by_user = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM otp_challenges WHERE user_id = ? AND issued_at >= ?",
    )
    .bind(user_id)
    .bind(window_start)
    .fetch_one(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!(
            "OTP issue rate-limit(user) query failed: {}",
            error
        ))
    })?;
    if issued_by_user >= max_per_hour {
        return Err(AppError::Unauthorized(
            "Too many verification code requests. Please try again later.".into(),
        ));
    }
    if let Some(ip) = context.ip_address.clone() {
        let issued_by_ip = sqlx::query_scalar::<_, i64>(
            "SELECT COUNT(*) FROM otp_challenges WHERE ip_address = ? AND issued_at >= ?",
        )
        .bind(ip)
        .bind(window_start)
        .fetch_one(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("OTP issue rate-limit(ip) query failed: {}", error))
        })?;
        if issued_by_ip >= max_per_hour {
            return Err(AppError::Unauthorized(
                "Too many verification code requests. Please try again later.".into(),
            ));
        }
    }
    Ok(())
}
