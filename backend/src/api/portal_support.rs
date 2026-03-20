use actix_session::Session;
use actix_web::{HttpMessage, HttpRequest};

use crate::models::{AppError, User};
use crate::services::portal_admin::is_portal_admin;
use crate::services::portal_paths::validate_slug;

pub(crate) const PORTAL_SESSION_ACCESS_KIND: &str = "portal_access_kind";
pub(crate) const PORTAL_SESSION_ACCESS_LINK_ID: &str = "portal_access_link_id";
pub(crate) const PORTAL_SESSION_CUSTOMER_SLUG: &str = "portal_customer_slug";

pub fn require_portal_admin(req: &HttpRequest) -> Result<User, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or_else(|| AppError::Unauthorized("Authentication required.".into()))?;

    if is_portal_admin(&user) {
        Ok(user)
    } else {
        Err(AppError::Unauthorized(
            "Portal administrator access is required.".into(),
        ))
    }
}

pub fn current_portal_session(session: &Session) -> Result<(String, String, String), AppError> {
    let access_kind = session
        .get::<String>(PORTAL_SESSION_ACCESS_KIND)
        .map_err(|error| AppError::InternalError(format!("Portal session read failed: {}", error)))?
        .ok_or_else(|| AppError::Unauthorized("Portal access link is required.".into()))?;
    let access_ref = session
        .get::<String>(PORTAL_SESSION_ACCESS_LINK_ID)
        .map_err(|error| AppError::InternalError(format!("Portal session read failed: {}", error)))?
        .ok_or_else(|| AppError::Unauthorized("Portal access link is required.".into()))?;
    let customer_slug = session
        .get::<String>(PORTAL_SESSION_CUSTOMER_SLUG)
        .map_err(|error| AppError::InternalError(format!("Portal session read failed: {}", error)))?
        .ok_or_else(|| AppError::Unauthorized("Portal access link is required.".into()))?;
    Ok((access_kind, access_ref, customer_slug))
}

pub fn ensure_slug_matches_session(
    session: &Session,
    slug: &str,
) -> Result<(String, String), AppError> {
    let (access_kind, access_ref, session_slug) = current_portal_session(session)?;
    if session_slug != validate_slug(slug)? {
        return Err(AppError::Unauthorized(
            "Portal session is not valid for this customer.".into(),
        ));
    }
    Ok((access_kind, access_ref))
}

pub fn ensure_gallery_session(session: &Session, slug: &str) -> Result<String, AppError> {
    let (access_kind, access_ref) = ensure_slug_matches_session(session, slug)?;
    if access_kind != "gallery" {
        return Err(AppError::Unauthorized(
            "Portal session is not valid for this customer.".into(),
        ));
    }
    Ok(access_ref)
}

pub fn portal_public_base_url(req: &HttpRequest) -> String {
    match std::env::var("PORTAL_PUBLIC_BASE_URL") {
        Ok(value) if !value.trim().is_empty() => value.trim().trim_end_matches('/').to_string(),
        _ => {
            let info = req.connection_info();
            format!("{}://{}", info.scheme(), info.host())
        }
    }
}

pub fn safe_next_path(customer_slug: &str, next: Option<&str>) -> String {
    let fallback = format!("/u/{}", customer_slug);
    let legacy = format!("/portal/{}", customer_slug);
    match next.map(str::trim) {
        Some(value)
            if (value.starts_with(&fallback) || value.starts_with(&legacy))
                && !value.starts_with("//")
                && !value.contains('\n')
                && !value.contains('\r') =>
        {
            if value.starts_with(&legacy) {
                value.replacen(&legacy, &fallback, 1)
            } else {
                value.to_string()
            }
        }
        _ => fallback,
    }
}

pub fn safe_tour_path(customer_slug: &str, tour_slug: &str) -> String {
    let fallback = format!("/u/{}", customer_slug);
    match validate_slug(tour_slug) {
        Ok(normalized_tour_slug) => format!("{}/tour/{}", fallback, normalized_tour_slug),
        Err(_) => fallback,
    }
}

pub fn normalized_requested_slug(raw_slug: &str) -> Result<String, AppError> {
    validate_slug(raw_slug)
}

pub fn store_portal_session(
    session: &Session,
    access_kind: &str,
    access_ref: String,
    customer_slug: &str,
) -> Result<(), AppError> {
    session
        .insert(PORTAL_SESSION_ACCESS_KIND, access_kind)
        .map_err(|error| {
            AppError::InternalError(format!("Portal session write failed: {}", error))
        })?;
    session
        .insert(PORTAL_SESSION_ACCESS_LINK_ID, access_ref)
        .map_err(|error| {
            AppError::InternalError(format!("Portal session write failed: {}", error))
        })?;
    session
        .insert(PORTAL_SESSION_CUSTOMER_SLUG, customer_slug.to_string())
        .map_err(|error| {
            AppError::InternalError(format!("Portal session write failed: {}", error))
        })?;
    Ok(())
}
