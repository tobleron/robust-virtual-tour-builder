use std::path::PathBuf;

use actix_files::NamedFile;
use actix_multipart::Multipart;
use actix_session::Session;
use actix_web::{HttpMessage, HttpRequest, HttpResponse, http::header, web};
use futures_util::TryStreamExt;
use serde::Deserialize;
use sqlx::SqlitePool;

use crate::models::{AppError, User};
use crate::services::portal::{
    self, AssignPortalTourInput, BulkAssignPortalToursInput, CreatePortalCustomerInput,
    PortalLibraryTour, RegeneratePortalAccessLinkInput, UpdatePortalCustomerInput,
    UpdatePortalSettingsInput,
};

const PORTAL_SESSION_ACCESS_LINK_ID: &str = "portal_access_link_id";
const PORTAL_SESSION_CUSTOMER_SLUG: &str = "portal_customer_slug";

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalTourStatusPayload {
    pub status: String,
}

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
pub struct CustomerIdPath {
    pub customer_id: String,
}

#[derive(Debug, Deserialize)]
pub struct TourIdPath {
    pub tour_id: String,
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

fn require_portal_admin(req: &HttpRequest) -> Result<User, AppError> {
    let user = req
        .extensions()
        .get::<User>()
        .cloned()
        .ok_or_else(|| AppError::Unauthorized("Authentication required.".into()))?;

    if portal::is_portal_admin(&user) {
        Ok(user)
    } else {
        Err(AppError::Unauthorized(
            "Portal administrator access is required.".into(),
        ))
    }
}

fn current_portal_session(session: &Session) -> Result<(String, String), AppError> {
    let access_link_id = session
        .get::<String>(PORTAL_SESSION_ACCESS_LINK_ID)
        .map_err(|error| AppError::InternalError(format!("Portal session read failed: {}", error)))?
        .ok_or_else(|| AppError::Unauthorized("Portal access link is required.".into()))?;
    let customer_slug = session
        .get::<String>(PORTAL_SESSION_CUSTOMER_SLUG)
        .map_err(|error| AppError::InternalError(format!("Portal session read failed: {}", error)))?
        .ok_or_else(|| AppError::Unauthorized("Portal access link is required.".into()))?;
    Ok((access_link_id, customer_slug))
}

fn ensure_slug_matches_session(session: &Session, slug: &str) -> Result<String, AppError> {
    let (access_link_id, session_slug) = current_portal_session(session)?;
    if session_slug != portal::validate_slug(slug)? {
        return Err(AppError::Unauthorized(
            "Portal session is not valid for this customer.".into(),
        ));
    }
    Ok(access_link_id)
}

fn portal_public_base_url(req: &HttpRequest) -> String {
    match std::env::var("PORTAL_PUBLIC_BASE_URL") {
        Ok(value) if !value.trim().is_empty() => value.trim().trim_end_matches('/').to_string(),
        _ => {
            let info = req.connection_info();
            format!("{}://{}", info.scheme(), info.host())
        }
    }
}

fn safe_next_path(customer_slug: &str, next: Option<&str>) -> String {
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

fn safe_tour_path(customer_slug: &str, tour_slug: &str) -> String {
    let fallback = format!("/u/{}", customer_slug);
    match portal::validate_slug(tour_slug) {
        Ok(normalized_tour_slug) => format!("{}/tour/{}", fallback, normalized_tour_slug),
        Err(_) => fallback,
    }
}

fn normalized_requested_slug(raw_slug: &str) -> Result<String, AppError> {
    portal::validate_slug(raw_slug)
}

fn store_portal_session(
    session: &Session,
    access_link_id: String,
    customer_slug: &str,
) -> Result<(), AppError> {
    session
        .insert(PORTAL_SESSION_ACCESS_LINK_ID, access_link_id)
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

pub async fn admin_list_customers(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
) -> Result<HttpResponse, AppError> {
    let _ = require_portal_admin(&req)?;
    let customers = portal::list_customers(pool.get_ref(), &portal_public_base_url(&req)).await?;
    Ok(HttpResponse::Ok().json(customers))
}

pub async fn admin_create_customer(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<CreatePortalCustomerInput>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let customer = portal::create_customer(
        pool.get_ref(),
        payload.into_inner(),
        Some(&admin),
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(customer))
}

pub async fn admin_update_customer(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<CustomerIdPath>,
    payload: web::Json<UpdatePortalCustomerInput>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let customer = portal::update_customer(
        pool.get_ref(),
        &path.customer_id,
        payload.into_inner(),
        Some(&admin),
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(customer))
}

pub async fn admin_get_settings(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
) -> Result<HttpResponse, AppError> {
    let _ = require_portal_admin(&req)?;
    let settings = portal::load_settings(pool.get_ref()).await?;
    Ok(HttpResponse::Ok().json(settings))
}

pub async fn admin_update_settings(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<UpdatePortalSettingsInput>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let settings =
        portal::update_settings(pool.get_ref(), payload.into_inner(), Some(&admin)).await?;
    Ok(HttpResponse::Ok().json(settings))
}

pub async fn admin_list_library_tours(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
) -> Result<HttpResponse, AppError> {
    let _ = require_portal_admin(&req)?;
    let tours = portal::list_library_tours(pool.get_ref()).await?;
    Ok(HttpResponse::Ok().json(tours))
}

pub async fn admin_upload_library_tour(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: Multipart,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let (title, zip_path) = read_portal_zip_upload(payload).await?;
    let tour =
        portal::create_library_tour_from_zip(pool.get_ref(), &title, &zip_path, Some(&admin)).await;
    let cleanup = std::fs::remove_file(&zip_path);
    if let Err(error) = cleanup {
        tracing::warn!(%error, path = %zip_path.display(), "Failed to remove portal temp zip");
    }
    Ok(HttpResponse::Ok().json(tour?))
}

pub async fn admin_update_library_tour_status(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<TourIdPath>,
    payload: web::Json<PortalTourStatusPayload>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let tour: PortalLibraryTour = portal::update_library_tour_status(
        pool.get_ref(),
        &path.tour_id,
        &payload.status,
        Some(&admin),
    )
    .await?;
    Ok(HttpResponse::Ok().json(tour))
}

pub async fn admin_assign_customer_tour(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<CustomerIdPath>,
    payload: web::Json<AssignPortalTourInput>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let overview = portal::assign_tour_to_customer(
        pool.get_ref(),
        &path.customer_id,
        &payload.tour_id,
        Some(&admin),
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(overview))
}

pub async fn admin_unassign_customer_tour(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<(String, String)>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let (customer_id, tour_id) = path.into_inner();
    let overview = portal::unassign_tour_from_customer(
        pool.get_ref(),
        &customer_id,
        &tour_id,
        Some(&admin),
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(overview))
}

pub async fn admin_bulk_assign_tours(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    payload: web::Json<BulkAssignPortalToursInput>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let result =
        portal::bulk_assign_tours_to_customers(pool.get_ref(), payload.into_inner(), Some(&admin))
            .await?;
    Ok(HttpResponse::Ok().json(result))
}

pub async fn admin_regenerate_access_link(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<CustomerIdPath>,
    payload: web::Json<RegeneratePortalAccessLinkInput>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let result = portal::regenerate_access_link(
        pool.get_ref(),
        &path.customer_id,
        &payload.expires_at,
        Some(&admin),
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(result))
}

pub async fn admin_revoke_access_links(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<CustomerIdPath>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let overview = portal::revoke_access_links(
        pool.get_ref(),
        &path.customer_id,
        Some(&admin),
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(overview))
}

pub async fn admin_delete_access_links(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<CustomerIdPath>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let overview = portal::delete_access_links(
        pool.get_ref(),
        &path.customer_id,
        Some(&admin),
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(overview))
}

pub async fn admin_delete_customer(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<CustomerIdPath>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    portal::delete_customer(pool.get_ref(), &path.customer_id, Some(&admin)).await?;
    Ok(HttpResponse::Ok().json(serde_json::json!({ "ok": true })))
}

pub async fn admin_delete_library_tour(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<TourIdPath>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    portal::delete_library_tour(pool.get_ref(), &path.tour_id, Some(&admin)).await?;
    Ok(HttpResponse::Ok().json(serde_json::json!({ "ok": true })))
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
    let access_link_id = ensure_slug_matches_session(&session, &path.slug)?;
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
    session.remove(PORTAL_SESSION_ACCESS_LINK_ID);
    session.remove(PORTAL_SESSION_CUSTOMER_SLUG);
    Ok(HttpResponse::Ok().json(serde_json::json!({ "ok": true })))
}

pub async fn customer_tours(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    session: Session,
    path: web::Path<CustomerSlugPath>,
) -> Result<HttpResponse, AppError> {
    let access_link_id = ensure_slug_matches_session(&session, &path.slug)?;
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
    let access_link_id = match ensure_slug_matches_session(&session, &path.slug) {
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
        &access_link_id,
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
    let access_link_id = ensure_slug_matches_session(&session, &path.slug)?;
    portal::resolve_portal_asset(
        pool.get_ref(),
        &path.slug,
        &path.tour_slug,
        &path.tail,
        &access_link_id,
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
        portal::PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: true,
        } => {
            let (_, access_link_id) = portal::access_session_for_token(pool.get_ref(), &path.token)
                .await
                .map(|(slug, link_id)| (slug, link_id))?;
            store_portal_session(&session, access_link_id, &customer_slug)?;
            let redirect = safe_next_path(&customer_slug, query.next.as_deref());
            Ok(HttpResponse::Found()
                .append_header((header::LOCATION, redirect))
                .finish())
        }
        portal::PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: false,
        } => Ok(HttpResponse::Found()
            .append_header((
                header::LOCATION,
                format!("/u/{}?access=expired", customer_slug),
            ))
            .finish()),
        portal::PortalAccessRedirect {
            customer_slug: None,
            allowed: false,
        } => Ok(HttpResponse::Found()
            .append_header((header::LOCATION, "/?access=invalid"))
            .finish()),
        portal::PortalAccessRedirect {
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
        portal::PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: true,
        } if customer_slug == requested_slug => {
            let (_, access_link_id) =
                portal::access_session_for_token(pool.get_ref(), &path.token).await?;
            store_portal_session(&session, access_link_id, &customer_slug)?;
            Ok(HttpResponse::Found()
                .append_header((header::LOCATION, format!("/u/{}", customer_slug)))
                .finish())
        }
        portal::PortalAccessRedirect {
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
        portal::PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: true,
        } => {
            let (_, access_link_id) = portal::access_session_for_token(pool.get_ref(), &path.token)
                .await
                .map(|(slug, link_id)| (slug, link_id))?;
            store_portal_session(&session, access_link_id, &customer_slug)?;
            Ok(HttpResponse::Found()
                .append_header((
                    header::LOCATION,
                    safe_tour_path(&customer_slug, &path.tour_slug),
                ))
                .finish())
        }
        portal::PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: false,
        } => Ok(HttpResponse::Found()
            .append_header((
                header::LOCATION,
                format!("/u/{}?access=expired", customer_slug),
            ))
            .finish()),
        portal::PortalAccessRedirect {
            customer_slug: None,
            allowed: false,
        } => Ok(HttpResponse::Found()
            .append_header((header::LOCATION, "/?access=invalid"))
            .finish()),
        portal::PortalAccessRedirect {
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
        portal::PortalAccessRedirect {
            customer_slug: Some(customer_slug),
            allowed: true,
        } if customer_slug == requested_slug => {
            let (_, access_link_id) =
                portal::access_session_for_token(pool.get_ref(), &path.token).await?;
            store_portal_session(&session, access_link_id, &customer_slug)?;
            Ok(HttpResponse::Found()
                .append_header((
                    header::LOCATION,
                    safe_tour_path(&customer_slug, &path.tour_slug),
                ))
                .finish())
        }
        portal::PortalAccessRedirect {
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

async fn read_portal_zip_upload(mut payload: Multipart) -> Result<(String, PathBuf), AppError> {
    let mut title: Option<String> = None;
    let temp_zip_path = crate::api::utils::get_temp_path("zip");
    let mut found_zip = false;

    while let Some(mut field) = payload.try_next().await? {
        let field_name = field
            .content_disposition()
            .and_then(|value| value.get_name())
            .unwrap_or_default()
            .to_string();

        if field_name == "title" {
            let mut bytes = web::BytesMut::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            title = Some(String::from_utf8(bytes.to_vec()).map_err(|_| {
                AppError::ValidationError("Portal tour title must be valid UTF-8.".into())
            })?);
            continue;
        }

        if field_name == "zip" {
            found_zip = true;
            let mut file = std::fs::File::create(&temp_zip_path).map_err(AppError::IoError)?;
            while let Some(chunk) = field.try_next().await? {
                use std::io::Write as _;
                file.write_all(&chunk).map_err(AppError::IoError)?;
            }
            continue;
        }
    }

    if !found_zip {
        return Err(AppError::ValidationError(
            "Portal upload requires a ZIP file.".into(),
        ));
    }

    Ok((
        title
            .map(|value| value.trim().to_string())
            .filter(|value| !value.is_empty())
            .ok_or_else(|| {
                AppError::ValidationError("Portal upload requires a tour title.".into())
            })?,
        temp_zip_path,
    ))
}
