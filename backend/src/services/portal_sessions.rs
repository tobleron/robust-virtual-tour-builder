// @efficiency-role: service-orchestrator
use chrono::Utc;
use sqlx::SqlitePool;

use crate::models::AppError;
use crate::services::portal::{
    PortalAccessLinkRecord, PortalAccessRedirect, PortalCustomer, PortalCustomerPublicView,
    PortalCustomerSessionView, PortalCustomerTourAssignmentRecord, PortalGalleryView,
    PortalTourCard, assignment_by_customer_and_tour, assignment_by_short_code,
    assignment_from_lookup_row, customer_public, ensure_assignment_short_code, validate_slug,
};
use crate::services::portal_admin::load_settings;
use crate::services::portal_assets::ensure_portal_cover_path;
use crate::services::portal_support::{
    assignment_effective_expiry, assignment_is_active, customer_access_link_summary, sha256_hex,
};
use crate::services::portal_views::customer_assignment_rows;

pub(crate) async fn current_access_link_for_customer(
    pool: &SqlitePool,
    customer_id: &str,
) -> Result<Option<PortalAccessLinkRecord>, AppError> {
    sqlx::query_as::<_, PortalAccessLinkRecord>(
        r#"
        SELECT *
        FROM portal_access_links
        WHERE customer_id = ? AND revoked_at IS NULL
        ORDER BY created_at DESC
        LIMIT 1
        "#,
    )
    .bind(customer_id)
    .fetch_optional(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal access link lookup failed: {}", error))
    })
}

pub(crate) async fn current_customer_and_access_link_by_slug(
    pool: &SqlitePool,
    slug: &str,
) -> Result<(PortalCustomer, PortalAccessLinkRecord), AppError> {
    let normalized_slug = validate_slug(slug)?;
    let customer =
        sqlx::query_as::<_, PortalCustomer>("SELECT * FROM portal_customers WHERE slug = ?")
            .bind(&normalized_slug)
            .fetch_optional(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal customer lookup failed: {}", error))
            })?
            .ok_or_else(|| {
                AppError::Unauthorized("Portal session is invalid for this customer.".into())
            })?;

    let access_link = current_access_link_for_customer(pool, &customer.id)
        .await?
        .ok_or_else(|| AppError::Unauthorized("Portal access link is required.".into()))?;

    Ok((customer, access_link))
}

pub async fn resolve_public_tour_access(
    pool: &SqlitePool,
    customer_slug: &str,
    tour_slug: &str,
) -> Result<(String, String), AppError> {
    let normalized_slug = crate::services::portal::validate_slug(customer_slug)?;
    let normalized_tour_slug = crate::services::portal::validate_slug(tour_slug)?;

    let (customer, access_link) =
        current_customer_and_access_link_by_slug(pool, &normalized_slug).await?;
    if customer.is_active != 1 {
        return Err(AppError::Unauthorized("Customer is inactive.".into()));
    }

    if access_link.revoked_at.is_some() || access_link.expires_at <= chrono::Utc::now() {
        return Err(AppError::Unauthorized(
            "Access link is expired or revoked.".into(),
        ));
    }

    let assignment_row =
        assignment_by_customer_and_tour(pool, &normalized_slug, &normalized_tour_slug)
            .await?
            .ok_or_else(|| AppError::Unauthorized("Assignment not found.".into()))?;

    let (_, assignment, tour) = assignment_from_lookup_row(assignment_row);

    if assignment.status != "active" || assignment.revoked_at.is_some() {
        return Err(AppError::Unauthorized(
            "Assignment is inactive or revoked.".into(),
        ));
    }

    if assignment_effective_expiry(&assignment, access_link.expires_at) <= chrono::Utc::now() {
        return Err(AppError::Unauthorized("Assignment is expired.".into()));
    }

    if tour.status != "published" {
        return Err(AppError::Unauthorized("Tour is not published.".into()));
    }

    let pool_for_update = pool.clone();
    let assignment_id = assignment.id.clone();
    tokio::spawn(async move {
        let now = chrono::Utc::now();
        let _ = sqlx::query(
            "UPDATE portal_customer_tour_assignments SET open_count = open_count + 1, last_opened_at = ?, updated_at = ? WHERE id = ?",
        )
        .bind(now)
        .bind(now)
        .bind(&assignment_id)
        .execute(&pool_for_update)
        .await;
    });

    Ok(("assignment".to_string(), assignment.id))
}

#[derive(Debug)]
enum AccessTokenOutcome {
    Granted {
        customer: PortalCustomer,
        access_kind: String,
        access_ref: String,
    },
    Rejected {
        customer_slug: Option<String>,
    },
}

async fn resolve_access_token(
    pool: &SqlitePool,
    token: &str,
) -> Result<AccessTokenOutcome, AppError> {
    if let Some(row) = assignment_by_short_code(pool, token).await? {
        let (customer, assignment, tour) = assignment_from_lookup_row(row);
        if customer.is_active != 1 {
            return Ok(AccessTokenOutcome::Rejected {
                customer_slug: Some(customer.slug),
            });
        }

        let access_link = current_access_link_for_customer(pool, &customer.id)
            .await?
            .ok_or_else(|| AppError::Unauthorized("Portal access link is required.".into()))?;

        if access_link.revoked_at.is_some() || access_link.expires_at <= Utc::now() {
            return Ok(AccessTokenOutcome::Rejected {
                customer_slug: Some(customer.slug),
            });
        }

        if assignment.status != "active" || assignment.revoked_at.is_some() {
            return Ok(AccessTokenOutcome::Rejected {
                customer_slug: Some(customer.slug),
            });
        }

        if assignment_effective_expiry(&assignment, access_link.expires_at) <= Utc::now() {
            return Ok(AccessTokenOutcome::Rejected {
                customer_slug: Some(customer.slug),
            });
        }

        if tour.status != "published" {
            return Ok(AccessTokenOutcome::Rejected {
                customer_slug: Some(customer.slug),
            });
        }

        let pool_for_update = pool.clone();
        let assignment_id = assignment.id.clone();
        tokio::spawn(async move {
            let now = Utc::now();
            let _ = sqlx::query(
                "UPDATE portal_customer_tour_assignments SET open_count = open_count + 1, last_opened_at = ?, updated_at = ? WHERE id = ?",
            )
            .bind(now)
            .bind(now)
            .bind(&assignment_id)
            .execute(&pool_for_update)
            .await;
        });

        return Ok(AccessTokenOutcome::Granted {
            customer,
            access_kind: "assignment".to_string(),
            access_ref: assignment.id,
        });
    }

    let token_hash = sha256_hex(token);
    let now_str = Utc::now().format("%Y-%m-%d %H:%M:%S").to_string();
    let row = sqlx::query_as::<_, crate::services::portal::AccessTokenLookupRow>(
        r#"
        SELECT
            c.id as customer_id,
            c.slug as customer_slug,
            c.display_name as customer_display_name,
            c.recipient_type as customer_recipient_type,
            c.contact_name as customer_contact_name,
            c.contact_email as customer_contact_email,
            c.contact_phone as customer_contact_phone,
            c.renewal_message as customer_renewal_message,
            c.is_active as customer_is_active,
            c.created_at as customer_created_at,
            c.updated_at as customer_updated_at,
            l.id as link_id,
            l.customer_id as link_customer_id,
            l.short_code as link_short_code,
            l.token_hash as link_token_hash,
            l.token_value as link_token_value,
            datetime(l.expires_at) as link_expires_at,
            l.revoked_at as link_revoked_at,
            l.last_opened_at as link_last_opened_at,
            l.created_at as link_created_at,
            l.updated_at as link_updated_at
        FROM portal_access_links l
        JOIN portal_customers c ON c.id = l.customer_id
        WHERE (l.short_code = ? OR l.token_hash = ?)
            AND (l.revoked_at IS NULL)
            AND (datetime(l.expires_at) > ?)
        ORDER BY CASE WHEN l.short_code = ? THEN 0 ELSE 1 END
        LIMIT 1
        "#,
    )
    .bind(token)
    .bind(token_hash)
    .bind(&now_str)
    .bind(token)
    .fetch_optional(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal access token lookup failed: {}", error))
    })?;

    let Some(row) = row else {
        return Ok(AccessTokenOutcome::Rejected {
            customer_slug: None,
        });
    };

    let customer = PortalCustomer {
        id: row.customer_id,
        slug: row.customer_slug.clone(),
        display_name: row.customer_display_name,
        recipient_type: row.customer_recipient_type,
        contact_name: row.customer_contact_name,
        contact_email: row.customer_contact_email,
        contact_phone: row.customer_contact_phone,
        renewal_message: row.customer_renewal_message,
        is_active: row.customer_is_active,
        created_at: row.customer_created_at,
        updated_at: row.customer_updated_at,
    };
    let access_link = crate::services::portal::PortalAccessLinkRecord {
        id: row.link_id,
        customer_id: row.link_customer_id,
        short_code: row.link_short_code,
        token_hash: row.link_token_hash,
        token_value: row.link_token_value,
        expires_at: row.link_expires_at,
        revoked_at: row.link_revoked_at,
        last_opened_at: row.link_last_opened_at,
        created_at: row.link_created_at,
        updated_at: row.link_updated_at,
    };

    if customer.is_active != 1 {
        return Ok(AccessTokenOutcome::Rejected {
            customer_slug: Some(customer.slug),
        });
    }

    let pool_for_update = pool.clone();
    let access_link_id = access_link.id.clone();
    tokio::spawn(async move {
        let now = Utc::now();
        let _ = sqlx::query(
            "UPDATE portal_access_links SET last_opened_at = ?, updated_at = ? WHERE id = ?",
        )
        .bind(now)
        .bind(now)
        .bind(&access_link_id)
        .execute(&pool_for_update)
        .await;
    });

    Ok(AccessTokenOutcome::Granted {
        customer,
        access_kind: "gallery".to_string(),
        access_ref: access_link.id,
    })
}

pub async fn authenticate_access_token(
    pool: &SqlitePool,
    token: &str,
) -> Result<PortalAccessRedirect, AppError> {
    match resolve_access_token(pool, token).await? {
        AccessTokenOutcome::Granted { customer, .. } => Ok(PortalAccessRedirect {
            customer_slug: Some(customer.slug),
            allowed: true,
        }),
        AccessTokenOutcome::Rejected { customer_slug } => Ok(PortalAccessRedirect {
            customer_slug,
            allowed: false,
        }),
    }
}

pub async fn access_session_for_token(
    pool: &SqlitePool,
    token: &str,
) -> Result<(String, String, String), AppError> {
    match resolve_access_token(pool, token).await? {
        AccessTokenOutcome::Granted {
            customer,
            access_kind,
            access_ref,
        } => Ok((customer.slug, access_kind, access_ref)),
        AccessTokenOutcome::Rejected { .. } => Err(AppError::Unauthorized(
            "Portal access link is invalid or expired.".into(),
        )),
    }
}

pub async fn public_customer_view(
    pool: &SqlitePool,
    slug: &str,
) -> Result<PortalCustomerPublicView, AppError> {
    let normalized_slug = validate_slug(slug)?;
    let customer =
        sqlx::query_as::<_, PortalCustomer>("SELECT * FROM portal_customers WHERE slug = ?")
            .bind(&normalized_slug)
            .fetch_optional(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal customer lookup failed: {}", error))
            })?
            .ok_or_else(|| AppError::ValidationError("Portal customer not found.".into()))?;

    Ok(PortalCustomerPublicView {
        customer: customer_public(&customer),
        settings: load_settings(pool).await?,
    })
}

pub async fn load_customer_session(
    pool: &SqlitePool,
    slug: &str,
    access_kind: &str,
    access_ref: &str,
    public_base_url: &str,
) -> Result<PortalCustomerSessionView, AppError> {
    let normalized_slug = validate_slug(slug)?;
    let customer =
        sqlx::query_as::<_, PortalCustomer>("SELECT * FROM portal_customers WHERE slug = ?")
            .bind(&normalized_slug)
            .fetch_optional(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal session customer lookup failed: {}", error))
            })?
            .ok_or_else(|| {
                AppError::Unauthorized("Portal session is invalid for this customer.".into())
            })?;

    let summary = if access_kind == "gallery" {
        let access_link = sqlx::query_as::<_, crate::services::portal::PortalAccessLinkRecord>(
            "SELECT * FROM portal_access_links WHERE id = ? AND customer_id = ?",
        )
        .bind(access_ref)
        .bind(&customer.id)
        .fetch_optional(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal session link lookup failed: {}", error))
        })?
        .ok_or_else(|| {
            AppError::Unauthorized("Portal session is invalid for this customer.".into())
        })?;

        customer_access_link_summary(&access_link, public_base_url, &customer.slug)
    } else if access_kind == "assignment" {
        let assignment =
            sqlx::query_as::<_, crate::services::portal::PortalCustomerTourAssignmentRecord>(
                "SELECT * FROM portal_customer_tour_assignments WHERE id = ? AND customer_id = ?",
            )
            .bind(access_ref)
            .bind(&customer.id)
            .fetch_optional(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!(
                    "Portal session assignment lookup failed: {}",
                    error
                ))
            })?
            .ok_or_else(|| {
                AppError::Unauthorized("Portal session is invalid for this customer.".into())
            })?;

        let active = assignment.status == "active" && assignment.revoked_at.is_some() == false;

        // Synthesize a summary for the assignment session
        crate::services::portal_types::PortalAccessLinkSummary {
            id: assignment.id.clone(),
            expires_at: assignment
                .expires_at_override
                .map(|t| t.to_rfc3339())
                .unwrap_or_else(|| "".to_string()),
            revoked_at: assignment.revoked_at.map(|t| t.to_rfc3339()),
            last_opened_at: assignment.last_opened_at.map(|t| t.to_rfc3339()),
            active,
            access_url: None,
        }
    } else {
        return Err(AppError::Unauthorized("Invalid session type.".into()));
    };
    let can_open_tours = customer.is_active == 1 && summary.active;

    Ok(PortalCustomerSessionView {
        customer: customer_public(&customer),
        settings: load_settings(pool).await?,
        access_link: summary.clone(),
        expired: !summary.active,
        can_open_tours,
    })
}

pub async fn gallery_view_for_customer(
    pool: &SqlitePool,
    slug: &str,
    access_kind: &str,
    access_ref: &str,
    public_base_url: &str,
) -> Result<PortalGalleryView, AppError> {
    let session =
        load_customer_session(pool, slug, access_kind, access_ref, public_base_url).await?;
    let customer =
        sqlx::query_as::<_, PortalCustomer>("SELECT * FROM portal_customers WHERE slug = ?")
            .bind(&session.customer.slug)
            .fetch_one(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal gallery customer reload failed: {}", error))
            })?;
    let access_link = current_access_link_for_customer(pool, &customer.id)
        .await?
        .ok_or_else(|| AppError::Unauthorized("Portal access link is required.".into()))?;
    let recipient_expiry = access_link.expires_at;
    let mut cards = Vec::new();

    for row in customer_assignment_rows(pool, &customer.id).await? {
        let (assignment_customer, assignment, tour) = assignment_from_lookup_row(row);
        if tour.status == "archived" {
            continue;
        }
        let short_code = match assignment.short_code.clone() {
            Some(value) => Some(value),
            None => Some(ensure_assignment_short_code(pool, &assignment.id).await?),
        };
        let assignment = PortalCustomerTourAssignmentRecord {
            short_code,
            ..assignment
        };
        let cover_path = ensure_portal_cover_path(pool, &tour).await?;
        cards.push(PortalTourCard {
            id: tour.id.clone(),
            title: tour.title,
            slug: tour.slug.clone(),
            status: tour.status.clone(),
            cover_url: cover_path.map(|cover| {
                format!(
                    "/portal-assets/{}/{}/{}",
                    assignment_customer.slug, tour.slug, cover
                )
            }),
            can_open: session.can_open_tours
                && assignment_is_active(&assignment, recipient_expiry)
                && tour.status == "published",
        });
    }

    Ok(PortalGalleryView {
        customer: session.customer,
        settings: session.settings,
        access_link: session.access_link,
        expired: session.expired,
        can_open_tours: session.can_open_tours,
        tours: cards,
    })
}
