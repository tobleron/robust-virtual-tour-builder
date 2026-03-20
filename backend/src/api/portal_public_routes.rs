use actix_files::NamedFile;
use actix_session::Session;
use actix_web::{HttpRequest, HttpResponse, http::header, web};
use serde::Deserialize;
use sqlx::SqlitePool;

use crate::api::portal_support::{
    ensure_gallery_session, ensure_slug_matches_session, normalized_requested_slug,
    portal_public_base_url, safe_next_path, safe_tour_path, store_portal_session,
};
use crate::models::AppError;
use crate::services::portal::{self, PortalAccessRedirect};

#[derive(Debug, Deserialize)]
pub struct CustomerSlugPath {
    pub slug: String,
}

#[derive(Debug, Deserialize)]
pub struct CustomerTourAssetPath {
    pub slug: String,
    pub tour_slug: String,
    pub tail: String,
}

#[derive(Debug, Deserialize)]
pub struct CustomerTourPath {
    pub slug: String,
    pub tour_slug: String,
}

#[derive(Debug, Deserialize)]
pub struct AccessTokenPath {
    pub token: String,
}

#[derive(Debug, Deserialize)]
pub struct UserAccessPath {
    pub slug: String,
    pub token: String,
}

#[derive(Debug, Deserialize)]
pub struct AccessTokenTourPath {
    pub token: String,
    pub tour_slug: String,
}

#[derive(Debug, Deserialize)]
pub struct UserAccessTourPath {
    pub slug: String,
    pub token: String,
    pub tour_slug: String,
}

#[derive(Debug, Deserialize)]
pub struct AccessTokenQuery {
    pub next: Option<String>,
}

pub async fn customer_public(
    pool: web::Data<SqlitePool>,
    path: web::Path<CustomerSlugPath>,
) -> Result<HttpResponse, AppError> {
    let view = portal::public_customer_view(pool.get_ref(), &path.slug).await?;
    Ok(HttpResponse::Ok().json(view))
}

pub async fn customer_session(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    session: Session,
    path: web::Path<CustomerSlugPath>,
) -> Result<HttpResponse, AppError> {
    let access_link_id = ensure_gallery_session(&session, &path.slug)?;
    let public_base_url = portal_public_base_url(&req);
    let view = portal::load_customer_session(
        pool.get_ref(),
        &path.slug,
        &access_link_id,
        &public_base_url,
    )
    .await?;
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "authenticated": true,
        "session": view,
    })))
}

pub async fn customer_sign_out(session: Session) -> Result<HttpResponse, AppError> {
    session.remove(crate::api::portal_support::PORTAL_SESSION_ACCESS_KIND);
    session.remove(crate::api::portal_support::PORTAL_SESSION_ACCESS_LINK_ID);
    session.remove(crate::api::portal_support::PORTAL_SESSION_CUSTOMER_SLUG);
    Ok(HttpResponse::Ok().json(serde_json::json!({ "ok": true })))
}

pub async fn customer_tours(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    session: Session,
    path: web::Path<CustomerSlugPath>,
) -> Result<HttpResponse, AppError> {
    let access_link_id = ensure_gallery_session(&session, &path.slug)?;
    let public_base_url = portal_public_base_url(&req);
    let view = portal::gallery_view_for_customer(
        pool.get_ref(),
        &path.slug,
        &access_link_id,
        &public_base_url,
    )
    .await?;
    Ok(HttpResponse::Ok().json(view))
}

pub async fn customer_tour_launch(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    session: Session,
    path: web::Path<CustomerTourPath>,
) -> Result<HttpResponse, AppError> {
    let (access_kind, access_ref) = match ensure_slug_matches_session(&session, &path.slug) {
        Ok(value) => value,
        Err(AppError::Unauthorized(_)) => {
            return Ok(HttpResponse::Found()
                .append_header((header::LOCATION, format!("/u/{}", path.slug)))
                .finish());
        }
        Err(error) => return Err(error),
    };

    let user_agent = req
        .headers()
        .get(header::USER_AGENT)
        .and_then(|value| value.to_str().ok());

    match portal::load_portal_launch_document(
        pool.get_ref(),
        &path.slug,
        &path.tour_slug,
        &access_kind,
        &access_ref,
        user_agent,
    )
    .await
    {
        Ok(document) => Ok(HttpResponse::Ok()
            .content_type("text/html; charset=utf-8")
            .body(document)),
        Err(AppError::Unauthorized(_)) => Ok(HttpResponse::Found()
            .append_header((header::LOCATION, format!("/u/{}?access=expired", path.slug)))
            .finish()),
        Err(error) => Err(error),
    }
}

pub async fn customer_tour_asset(
    pool: web::Data<SqlitePool>,
    session: Session,
    path: web::Path<CustomerTourAssetPath>,
) -> Result<NamedFile, AppError> {
    let (access_kind, access_ref) = ensure_slug_matches_session(&session, &path.slug)?;
    portal::resolve_portal_asset(
        pool.get_ref(),
        &path.slug,
        &path.tour_slug,
        &path.tail,
        &access_kind,
        &access_ref,
    )
    .await
}

pub async fn access_link_redirect(
    _req: HttpRequest,
    pool: web::Data<SqlitePool>,
    session: Session,
    path: web::Path<AccessTokenPath>,
    query: web::Query<AccessTokenQuery>,
) -> Result<HttpResponse, AppError> {
    match portal::authenticate_access_token(pool.get_ref(), &path.token).await? {
        PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: true,
        } => {
            let (_, access_kind, access_ref) =
                portal::access_session_for_token(pool.get_ref(), &path.token)
                    .await
                    .map(|(slug, kind, ref_id)| (slug, kind, ref_id))?;
            store_portal_session(&session, &access_kind, access_ref, &customer_slug)?;
            let redirect = safe_next_path(&customer_slug, query.next.as_deref());
            Ok(HttpResponse::Found()
                .append_header((header::LOCATION, redirect))
                .finish())
        }
        PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: false,
        } => Ok(HttpResponse::Found()
            .append_header((
                header::LOCATION,
                format!("/u/{}?access=expired", customer_slug),
            ))
            .finish()),
        PortalAccessRedirect {
            customer_slug: None,
            allowed: false,
        } => Ok(HttpResponse::Found()
            .append_header((header::LOCATION, "/?access=invalid"))
            .finish()),
        PortalAccessRedirect {
            customer_slug: None,
            allowed: true,
        } => Err(AppError::InternalError(
            "Portal access redirect was allowed without a customer slug.".into(),
        )),
    }
}

pub async fn user_access_redirect(
    pool: web::Data<SqlitePool>,
    session: Session,
    path: web::Path<UserAccessPath>,
) -> Result<HttpResponse, AppError> {
    let requested_slug = normalized_requested_slug(&path.slug)?;
    match portal::authenticate_access_token(pool.get_ref(), &path.token).await? {
        PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: true,
        } if customer_slug == requested_slug => {
            let (_, access_kind, access_ref) =
                portal::access_session_for_token(pool.get_ref(), &path.token).await?;
            store_portal_session(&session, &access_kind, access_ref, &customer_slug)?;
            Ok(HttpResponse::Found()
                .append_header((header::LOCATION, format!("/u/{}", customer_slug)))
                .finish())
        }
        PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: false,
        } if customer_slug == requested_slug => Ok(HttpResponse::Found()
            .append_header((
                header::LOCATION,
                format!("/u/{}?access=expired", customer_slug),
            ))
            .finish()),
        _ => Ok(HttpResponse::Found()
            .append_header((header::LOCATION, "/?access=invalid"))
            .finish()),
    }
}

pub async fn access_tour_redirect(
    pool: web::Data<SqlitePool>,
    session: Session,
    path: web::Path<AccessTokenTourPath>,
) -> Result<HttpResponse, AppError> {
    match portal::authenticate_access_token(pool.get_ref(), &path.token).await? {
        PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: true,
        } => {
            let (_, access_kind, access_ref) =
                portal::access_session_for_token(pool.get_ref(), &path.token)
                    .await
                    .map(|(slug, kind, ref_id)| (slug, kind, ref_id))?;
            store_portal_session(&session, &access_kind, access_ref, &customer_slug)?;
            Ok(HttpResponse::Found()
                .append_header((
                    header::LOCATION,
                    safe_tour_path(&customer_slug, &path.tour_slug),
                ))
                .finish())
        }
        PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: false,
        } => Ok(HttpResponse::Found()
            .append_header((
                header::LOCATION,
                format!("/u/{}?access=expired", customer_slug),
            ))
            .finish()),
        PortalAccessRedirect {
            customer_slug: None,
            allowed: false,
        } => Ok(HttpResponse::Found()
            .append_header((header::LOCATION, "/?access=invalid"))
            .finish()),
        PortalAccessRedirect {
            customer_slug: None,
            allowed: true,
        } => Err(AppError::InternalError(
            "Portal access redirect was allowed without a customer slug.".into(),
        )),
    }
}

pub async fn user_tour_access_redirect(
    pool: web::Data<SqlitePool>,
    session: Session,
    path: web::Path<UserAccessTourPath>,
) -> Result<HttpResponse, AppError> {
    let requested_slug = normalized_requested_slug(&path.slug)?;
    match portal::authenticate_access_token(pool.get_ref(), &path.token).await? {
        PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: true,
        } if customer_slug == requested_slug => {
            let (_, access_kind, access_ref) =
                portal::access_session_for_token(pool.get_ref(), &path.token).await?;
            store_portal_session(&session, &access_kind, access_ref, &customer_slug)?;
            Ok(HttpResponse::Found()
                .append_header((
                    header::LOCATION,
                    safe_tour_path(&customer_slug, &path.tour_slug),
                ))
                .finish())
        }
        PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: false,
        } if customer_slug == requested_slug => Ok(HttpResponse::Found()
            .append_header((
                header::LOCATION,
                format!("/u/{}?access=expired", customer_slug),
            ))
            .finish()),
        _ => Ok(HttpResponse::Found()
            .append_header((header::LOCATION, "/?access=invalid"))
            .finish()),
    }
}
