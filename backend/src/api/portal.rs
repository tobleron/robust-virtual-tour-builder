use std::path::PathBuf;

use actix_files::NamedFile;
use actix_multipart::Multipart;
use actix_session::Session;
use actix_web::{HttpRequest, HttpResponse, http::header, web};
use futures_util::TryStreamExt;
use serde::Deserialize;
use sqlx::SqlitePool;

use crate::models::AppError;
use crate::services::portal::{
    self, AssignPortalTourInput, BulkAssignPortalToursInput, CreatePortalCustomerInput,
    PortalLibraryTour, RegeneratePortalAccessLinkInput, RevokeRecipientTourLinkInput,
    UpdateLinkExpiryInput, UpdatePortalCustomerInput, UpdatePortalSettingsInput,
};
use super::portal_support::{
    PORTAL_SESSION_ACCESS_KIND, PORTAL_SESSION_ACCESS_LINK_ID, PORTAL_SESSION_CUSTOMER_SLUG,
    ensure_gallery_session, ensure_slug_matches_session, normalized_requested_slug,
    portal_public_base_url, require_portal_admin, safe_next_path, safe_tour_path,
    store_portal_session,
};

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
pub struct AssignmentIdPath {
    pub assignment_id: String,
}

#[derive(Debug, Deserialize)]
pub struct CustomerTourLinkPath {
    pub customer_id: String,
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

pub async fn admin_get_customer_tours(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<CustomerIdPath>,
) -> Result<HttpResponse, AppError> {
    let _ = require_portal_admin(&req)?;
    let view = portal::list_customer_assignments_view(
        pool.get_ref(),
        &path.customer_id,
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(view))
}

pub async fn admin_get_tour_recipients(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<TourIdPath>,
) -> Result<HttpResponse, AppError> {
    let _ = require_portal_admin(&req)?;
    let view = portal::list_tour_assignments_view(
        pool.get_ref(),
        &path.tour_id,
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(view))
}

pub async fn admin_get_assignment(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<AssignmentIdPath>,
) -> Result<HttpResponse, AppError> {
    let _ = require_portal_admin(&req)?;
    let view = portal::assignment_view_by_id(
        pool.get_ref(),
        &path.assignment_id,
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(view))
}

pub async fn admin_create_customer_tour_link(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<CustomerTourLinkPath>,
    payload: web::Json<UpdateLinkExpiryInput>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let assignment = portal::create_or_activate_assignment_link(
        pool.get_ref(),
        &path.customer_id,
        &path.tour_id,
        payload.expires_at_override.as_deref(),
        Some(&admin),
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(assignment))
}

pub async fn admin_revoke_assignment_link(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<AssignmentIdPath>,
    payload: web::Json<RevokeRecipientTourLinkInput>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let assignment = portal::revoke_assignment_link(
        pool.get_ref(),
        &path.assignment_id,
        payload.reason.as_deref(),
        Some(&admin),
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(assignment))
}

pub async fn admin_update_assignment_expiry(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<AssignmentIdPath>,
    payload: web::Json<UpdateLinkExpiryInput>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let assignment = portal::update_assignment_expiry(
        pool.get_ref(),
        &path.assignment_id,
        payload.expires_at_override.as_deref(),
        Some(&admin),
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(assignment))
}

pub async fn admin_reactivate_assignment_link(
    req: HttpRequest,
    pool: web::Data<SqlitePool>,
    path: web::Path<AssignmentIdPath>,
) -> Result<HttpResponse, AppError> {
    let admin = require_portal_admin(&req)?;
    let assignment = portal::reactivate_assignment_link(
        pool.get_ref(),
        &path.assignment_id,
        Some(&admin),
        &portal_public_base_url(&req),
    )
    .await?;
    Ok(HttpResponse::Ok().json(assignment))
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
    session.remove(PORTAL_SESSION_ACCESS_KIND);
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
        portal::PortalAccessRedirect {
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
            let (_, access_kind, access_ref) =
                portal::access_session_for_token(pool.get_ref(), &path.token).await?;
            store_portal_session(&session, &access_kind, access_ref, &customer_slug)?;
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
            let (_, access_kind, access_ref) = portal::access_session_for_token(pool.get_ref(), &path.token)
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
