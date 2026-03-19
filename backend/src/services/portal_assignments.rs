// @efficiency-role: service-orchestrator
use chrono::{DateTime, Utc};
use sqlx::SqlitePool;
use uuid::Uuid;

use crate::models::{AppError, User};
use crate::services::portal::{
    AssignmentLinkLookupRow, BulkAssignPortalToursInput, PortalAccessLinkRecord,
    PortalBulkAssignmentResult, PortalCustomer, PortalCustomerOverview,
    PortalCustomerTourAssignmentRecord, PortalCustomerTourAssignmentView, PortalLibraryTour,
};
use crate::services::portal_audit::log_audit;
use crate::services::portal_codes::{
    generate_unique_short_code, validate_existing_customer_ids, validate_existing_tour_ids,
};
use crate::services::portal_support::{dedupe_ids, parse_expiry};
use crate::services::portal_views::build_customer_overview;

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
    let normalized_slug = crate::services::portal::validate_slug(slug)?;
    let customer =
        sqlx::query_as::<_, PortalCustomer>("SELECT * FROM portal_customers WHERE slug = ?")
            .bind(&normalized_slug)
            .fetch_optional(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal customer lookup failed: {}", error))
            })?
            .ok_or_else(|| AppError::Unauthorized("Portal session is invalid for this customer.".into()))?;

    let access_link = current_access_link_for_customer(pool, &customer.id)
        .await?
        .ok_or_else(|| AppError::Unauthorized("Portal access link is required.".into()))?;

    Ok((customer, access_link))
}

pub(crate) async fn assignment_by_short_code(
    pool: &SqlitePool,
    short_code: &str,
) -> Result<Option<AssignmentLinkLookupRow>, AppError> {
    sqlx::query_as::<_, AssignmentLinkLookupRow>(
        r#"
        SELECT
            a.id as assignment_id,
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
            a.tour_id as assignment_tour_id,
            a.short_code as assignment_short_code,
            a.status as assignment_status,
            a.expires_at_override as assignment_expires_at_override,
            a.revoked_at as assignment_revoked_at,
            a.revoked_reason as assignment_revoked_reason,
            a.last_opened_at as assignment_last_opened_at,
            a.open_count as assignment_open_count,
            a.geo_country_code as assignment_geo_country_code,
            a.geo_region as assignment_geo_region,
            a.created_at as assignment_created_at,
            a.updated_at as assignment_updated_at,
            t.id as tour_id,
            t.title as tour_title,
            t.slug as tour_slug,
            t.status as tour_status,
            t.storage_path as tour_storage_path,
            t.cover_path as tour_cover_path,
            t.created_at as tour_created_at,
            t.updated_at as tour_updated_at
        FROM portal_customer_tour_assignments a
        JOIN portal_customers c ON c.id = a.customer_id
        JOIN portal_library_tours t ON t.id = a.tour_id
        WHERE a.short_code = ?
        LIMIT 1
        "#,
    )
    .bind(short_code)
    .fetch_optional(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal assignment short-code lookup failed: {}", error))
    })
}

pub(crate) async fn assignment_by_customer_and_tour(
    pool: &SqlitePool,
    customer_slug: &str,
    tour_slug: &str,
) -> Result<Option<AssignmentLinkLookupRow>, AppError> {
    let normalized_slug = crate::services::portal::validate_slug(customer_slug)?;
    let normalized_tour_slug = crate::services::portal::validate_slug(tour_slug)?;
    sqlx::query_as::<_, AssignmentLinkLookupRow>(
        r#"
        SELECT
            a.id as assignment_id,
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
            a.tour_id as assignment_tour_id,
            a.short_code as assignment_short_code,
            a.status as assignment_status,
            a.expires_at_override as assignment_expires_at_override,
            a.revoked_at as assignment_revoked_at,
            a.revoked_reason as assignment_revoked_reason,
            a.last_opened_at as assignment_last_opened_at,
            a.open_count as assignment_open_count,
            a.geo_country_code as assignment_geo_country_code,
            a.geo_region as assignment_geo_region,
            a.created_at as assignment_created_at,
            a.updated_at as assignment_updated_at,
            t.id as tour_id,
            t.title as tour_title,
            t.slug as tour_slug,
            t.status as tour_status,
            t.storage_path as tour_storage_path,
            t.cover_path as tour_cover_path,
            t.created_at as tour_created_at,
            t.updated_at as tour_updated_at
        FROM portal_customer_tour_assignments a
        JOIN portal_customers c ON c.id = a.customer_id
        JOIN portal_library_tours t ON t.id = a.tour_id
        WHERE c.slug = ? AND t.slug = ?
        LIMIT 1
        "#,
    )
    .bind(&normalized_slug)
    .bind(&normalized_tour_slug)
    .fetch_optional(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal assignment lookup failed: {}", error))
    })
}

pub(crate) async fn assignment_by_id(
    pool: &SqlitePool,
    assignment_id: &str,
) -> Result<Option<AssignmentLinkLookupRow>, AppError> {
    sqlx::query_as::<_, AssignmentLinkLookupRow>(
        r#"
        SELECT
            a.id as assignment_id,
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
            a.tour_id as assignment_tour_id,
            a.short_code as assignment_short_code,
            a.status as assignment_status,
            a.expires_at_override as assignment_expires_at_override,
            a.revoked_at as assignment_revoked_at,
            a.revoked_reason as assignment_revoked_reason,
            a.last_opened_at as assignment_last_opened_at,
            a.open_count as assignment_open_count,
            a.geo_country_code as assignment_geo_country_code,
            a.geo_region as assignment_geo_region,
            a.created_at as assignment_created_at,
            a.updated_at as assignment_updated_at,
            t.id as tour_id,
            t.title as tour_title,
            t.slug as tour_slug,
            t.status as tour_status,
            t.storage_path as tour_storage_path,
            t.cover_path as tour_cover_path,
            t.created_at as tour_created_at,
            t.updated_at as tour_updated_at
        FROM portal_customer_tour_assignments a
        JOIN portal_customers c ON c.id = a.customer_id
        JOIN portal_library_tours t ON t.id = a.tour_id
        WHERE a.id = ?
        LIMIT 1
        "#,
    )
    .bind(assignment_id)
    .fetch_optional(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal assignment lookup failed: {}", error))
    })
}

pub(crate) fn assignment_from_lookup_row(
    row: AssignmentLinkLookupRow,
) -> (
    PortalCustomer,
    PortalCustomerTourAssignmentRecord,
    PortalLibraryTour,
) {
    let AssignmentLinkLookupRow {
        assignment_id,
        customer_id,
        customer_slug,
        customer_display_name,
        customer_recipient_type,
        customer_contact_name,
        customer_contact_email,
        customer_contact_phone,
        customer_renewal_message,
        customer_is_active,
        customer_created_at,
        customer_updated_at,
        assignment_tour_id,
        assignment_short_code,
        assignment_status,
        assignment_expires_at_override,
        assignment_revoked_at,
        assignment_revoked_reason,
        assignment_last_opened_at,
        assignment_open_count,
        assignment_geo_country_code,
        assignment_geo_region,
        assignment_created_at,
        assignment_updated_at,
        tour_id,
        tour_title,
        tour_slug,
        tour_status,
        tour_storage_path,
        tour_cover_path,
        tour_created_at,
        tour_updated_at,
    } = row;

    (
        PortalCustomer {
            id: customer_id.clone(),
            slug: customer_slug,
            display_name: customer_display_name,
            recipient_type: customer_recipient_type,
            contact_name: customer_contact_name,
            contact_email: customer_contact_email,
            contact_phone: customer_contact_phone,
            renewal_message: customer_renewal_message,
            is_active: customer_is_active,
            created_at: customer_created_at,
            updated_at: customer_updated_at,
        },
        PortalCustomerTourAssignmentRecord {
            id: assignment_id,
            customer_id,
            tour_id: assignment_tour_id,
            short_code: assignment_short_code,
            status: assignment_status,
            expires_at_override: assignment_expires_at_override,
            revoked_at: assignment_revoked_at,
            revoked_reason: assignment_revoked_reason,
            last_opened_at: assignment_last_opened_at,
            open_count: assignment_open_count,
            geo_country_code: assignment_geo_country_code,
            geo_region: assignment_geo_region,
            created_at: assignment_created_at,
            updated_at: assignment_updated_at,
        },
        PortalLibraryTour {
            id: tour_id,
            title: tour_title,
            slug: tour_slug,
            status: tour_status,
            storage_path: tour_storage_path,
            cover_path: tour_cover_path,
            created_at: tour_created_at,
            updated_at: tour_updated_at,
        },
    )
}

pub(crate) async fn ensure_assignment_short_code(
    pool: &SqlitePool,
    assignment_id: &str,
) -> Result<String, AppError> {
    if let Some(existing) = sqlx::query_scalar::<_, Option<String>>(
        "SELECT short_code FROM portal_customer_tour_assignments WHERE id = ?",
    )
    .bind(assignment_id)
    .fetch_optional(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal assignment short-code load failed: {}", error))
    })?
    .flatten()
    {
        return Ok(existing);
    }

    for _attempt in 0..10 {
        let short_code = generate_unique_short_code(pool).await?;
        let result = sqlx::query(
            "UPDATE portal_customer_tour_assignments SET short_code = ?, updated_at = ? WHERE id = ? AND short_code IS NULL",
        )
        .bind(&short_code)
        .bind(Utc::now())
        .bind(assignment_id)
        .execute(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal assignment short-code update failed: {}", error))
        })?;

        if result.rows_affected() > 0 {
            return Ok(short_code);
        }

        if let Some(existing) = sqlx::query_scalar::<_, Option<String>>(
            "SELECT short_code FROM portal_customer_tour_assignments WHERE id = ?",
        )
        .bind(assignment_id)
        .fetch_optional(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal assignment short-code reload failed: {}", error))
        })?
        .flatten()
        {
            return Ok(existing);
        }
    }

    Err(AppError::InternalError(
        "Failed to allocate a portal assignment short code.".into(),
    ))
}

async fn load_assignment_record_for_customer_tour(
    pool: &SqlitePool,
    customer_id: &str,
    tour_id: &str,
) -> Result<Option<PortalCustomerTourAssignmentRecord>, AppError> {
    sqlx::query_as::<_, PortalCustomerTourAssignmentRecord>(
        "SELECT * FROM portal_customer_tour_assignments WHERE customer_id = ? AND tour_id = ? LIMIT 1",
    )
    .bind(customer_id)
    .bind(tour_id)
    .fetch_optional(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal assignment lookup failed: {}", error))
    })
}

async fn upsert_assignment_link(
    pool: &SqlitePool,
    customer_id: &str,
    tour_id: &str,
    _actor: Option<&User>,
    now: DateTime<Utc>,
) -> Result<PortalCustomerTourAssignmentRecord, AppError> {
    match load_assignment_record_for_customer_tour(pool, customer_id, tour_id).await? {
        Some(existing) => {
            let mut short_code = existing.short_code.clone();
            let mut status = existing.status.clone();
            let mut revoked_at = existing.revoked_at;
            let mut revoked_reason = existing.revoked_reason.clone();

            if short_code.is_none() || status != "active" || revoked_at.is_some() {
                short_code = Some(generate_unique_short_code(pool).await?);
                status = "active".to_string();
                revoked_at = None;
                revoked_reason = None;
            }

            sqlx::query(
                r#"
                UPDATE portal_customer_tour_assignments
                SET short_code = ?, status = ?, revoked_at = ?, revoked_reason = ?, updated_at = ?
                WHERE id = ?
                "#,
            )
            .bind(short_code.as_deref())
            .bind(&status)
            .bind(revoked_at)
            .bind(revoked_reason.as_deref())
            .bind(now)
            .bind(&existing.id)
            .execute(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal assignment update failed: {}", error))
            })?;

            sqlx::query_as::<_, PortalCustomerTourAssignmentRecord>(
                "SELECT * FROM portal_customer_tour_assignments WHERE id = ?",
            )
            .bind(&existing.id)
            .fetch_one(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal assignment reload failed: {}", error))
            })
        }
        None => {
            let short_code = generate_unique_short_code(pool).await?;
            let assignment_id = Uuid::new_v4().to_string();
            sqlx::query(
                r#"
                INSERT INTO portal_customer_tour_assignments (
                    id, customer_id, tour_id, short_code, status, expires_at_override, revoked_at,
                    revoked_reason, last_opened_at, open_count, geo_country_code, geo_region, created_at, updated_at
                ) VALUES (?, ?, ?, ?, 'active', NULL, NULL, NULL, NULL, 0, NULL, NULL, ?, ?)
                "#,
            )
            .bind(&assignment_id)
            .bind(customer_id)
            .bind(tour_id)
            .bind(&short_code)
            .bind(now)
            .bind(now)
            .execute(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal assignment create failed: {}", error))
            })?;

            sqlx::query_as::<_, PortalCustomerTourAssignmentRecord>(
                "SELECT * FROM portal_customer_tour_assignments WHERE id = ?",
            )
            .bind(&assignment_id)
            .fetch_one(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal assignment reload failed: {}", error))
            })
        }
    }
}

pub async fn create_or_activate_assignment_link(
    pool: &SqlitePool,
    customer_id: &str,
    tour_id: &str,
    expires_at_override_raw: Option<&str>,
    actor: Option<&User>,
    public_base_url: &str,
) -> Result<PortalCustomerTourAssignmentView, AppError> {
    let expires_at_override = match expires_at_override_raw {
        Some(value) => Some(parse_expiry(value)?),
        None => None,
    };
    let now = Utc::now();
    let assignment = upsert_assignment_link(pool, customer_id, tour_id, actor, now).await?;
    if expires_at_override != assignment.expires_at_override {
        sqlx::query(
            "UPDATE portal_customer_tour_assignments SET expires_at_override = ?, updated_at = ? WHERE id = ?",
        )
        .bind(expires_at_override)
        .bind(now)
        .bind(&assignment.id)
        .execute(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal assignment expiry update failed: {}", error))
        })?;
    }
    crate::services::portal_views::assignment_view_by_id(pool, &assignment.id, public_base_url).await
}

pub async fn revoke_assignment_link(
    pool: &SqlitePool,
    assignment_id: &str,
    reason: Option<&str>,
    actor: Option<&User>,
    public_base_url: &str,
) -> Result<PortalCustomerTourAssignmentView, AppError> {
    let now = Utc::now();
    sqlx::query(
        r#"
        UPDATE portal_customer_tour_assignments
        SET status = 'revoked', revoked_at = ?, revoked_reason = ?, updated_at = ?
        WHERE id = ?
        "#,
    )
    .bind(now)
    .bind(reason)
    .bind(now)
    .bind(assignment_id)
    .execute(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal assignment revoke failed: {}", error))
    })?;

    let assignment = crate::services::portal_views::assignment_view_by_id(pool, assignment_id, public_base_url).await?;

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        None,
        "portal_assignment_revoked",
        serde_json::json!({"assignmentId": assignment_id, "reason": reason}),
    )
    .await?;

    Ok(assignment)
}

pub async fn update_assignment_expiry(
    pool: &SqlitePool,
    assignment_id: &str,
    expires_at_override_raw: Option<&str>,
    actor: Option<&User>,
    public_base_url: &str,
) -> Result<PortalCustomerTourAssignmentView, AppError> {
    let expires_at_override = match expires_at_override_raw {
        Some(value) => Some(parse_expiry(value)?),
        None => None,
    };
    let now = Utc::now();
    sqlx::query(
        "UPDATE portal_customer_tour_assignments SET expires_at_override = ?, updated_at = ? WHERE id = ?",
    )
    .bind(expires_at_override)
    .bind(now)
    .bind(assignment_id)
    .execute(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal assignment expiry update failed: {}", error))
    })?;

    let assignment = crate::services::portal_views::assignment_view_by_id(pool, assignment_id, public_base_url).await?;

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        None,
        "portal_assignment_expiry_updated",
        serde_json::json!({"assignmentId": assignment_id, "expiresAtOverride": expires_at_override}),
    )
    .await?;

    Ok(assignment)
}

pub async fn reactivate_assignment_link(
    pool: &SqlitePool,
    assignment_id: &str,
    actor: Option<&User>,
    public_base_url: &str,
) -> Result<PortalCustomerTourAssignmentView, AppError> {
    let now = Utc::now();
    let short_code = generate_unique_short_code(pool).await?;
    sqlx::query(
        r#"
        UPDATE portal_customer_tour_assignments
        SET short_code = ?, status = 'active', revoked_at = NULL, revoked_reason = NULL, updated_at = ?
        WHERE id = ?
        "#,
    )
    .bind(&short_code)
    .bind(now)
    .bind(assignment_id)
    .execute(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal assignment reactivation failed: {}", error))
    })?;

    let assignment = crate::services::portal_views::assignment_view_by_id(pool, assignment_id, public_base_url).await?;

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        None,
        "portal_assignment_reactivated",
        serde_json::json!({"assignmentId": assignment_id, "shortCode": short_code}),
    )
    .await?;

    Ok(assignment)
}

pub async fn assign_tour_to_customer(
    pool: &SqlitePool,
    customer_id: &str,
    tour_id: &str,
    actor: Option<&User>,
    public_base_url: &str,
) -> Result<PortalCustomerOverview, AppError> {
    let now = Utc::now();
    let assignment = upsert_assignment_link(pool, customer_id, tour_id, actor, now).await?;

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        Some(customer_id),
        "portal_tour_assigned",
        serde_json::json!({"tourId": tour_id, "assignmentId": assignment.id, "shortCode": assignment.short_code}),
    )
    .await?;

    let customer =
        sqlx::query_as::<_, PortalCustomer>("SELECT * FROM portal_customers WHERE id = ?")
            .bind(customer_id)
            .fetch_one(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal customer reload failed: {}", error))
            })?;
    build_customer_overview(pool, customer, public_base_url).await
}

pub async fn unassign_tour_from_customer(
    pool: &SqlitePool,
    customer_id: &str,
    tour_id: &str,
    actor: Option<&User>,
    public_base_url: &str,
) -> Result<PortalCustomerOverview, AppError> {
    sqlx::query(
        "DELETE FROM portal_customer_tour_assignments WHERE customer_id = ? AND tour_id = ?",
    )
    .bind(customer_id)
    .bind(tour_id)
    .execute(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal tour unassign failed: {}", error)))?;

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        Some(customer_id),
        "portal_tour_unassigned",
        serde_json::json!({"tourId": tour_id}),
    )
    .await?;

    let customer =
        sqlx::query_as::<_, PortalCustomer>("SELECT * FROM portal_customers WHERE id = ?")
            .bind(customer_id)
            .fetch_one(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal customer reload failed: {}", error))
            })?;
    build_customer_overview(pool, customer, public_base_url).await
}

pub async fn bulk_assign_tours_to_customers(
    pool: &SqlitePool,
    input: BulkAssignPortalToursInput,
    actor: Option<&User>,
) -> Result<PortalBulkAssignmentResult, AppError> {
    let customer_ids = dedupe_ids(input.customer_ids);
    let tour_ids = dedupe_ids(input.tour_ids);

    if customer_ids.is_empty() {
        return Err(AppError::ValidationError(
            "Select at least one recipient before assigning tours.".into(),
        ));
    }

    if tour_ids.is_empty() {
        return Err(AppError::ValidationError(
            "Select at least one tour before assigning recipients.".into(),
        ));
    }

    validate_existing_customer_ids(pool, &customer_ids).await?;
    validate_existing_tour_ids(pool, &tour_ids).await?;

    let customer_count = i64::try_from(customer_ids.len())
        .map_err(|_| AppError::InternalError("Recipient count overflow.".into()))?;
    let tour_count = i64::try_from(tour_ids.len())
        .map_err(|_| AppError::InternalError("Tour count overflow.".into()))?;
    let requested_count = customer_count
        .checked_mul(tour_count)
        .ok_or_else(|| AppError::InternalError("Assignment count overflow.".into()))?;

    let mut created_count = 0_i64;
    let now = Utc::now();
    for customer_id in &customer_ids {
        for tour_id in &tour_ids {
            match load_assignment_record_for_customer_tour(pool, customer_id, tour_id).await? {
                Some(existing) => {
                    if existing.status != "active" || existing.revoked_at.is_some() || existing.short_code.is_none() {
                        let short_code = generate_unique_short_code(pool).await?;
                        sqlx::query(
                            r#"
                            UPDATE portal_customer_tour_assignments
                            SET short_code = ?, status = 'active', revoked_at = NULL, revoked_reason = NULL, updated_at = ?
                            WHERE id = ?
                            "#,
                        )
                        .bind(&short_code)
                        .bind(now)
                        .bind(&existing.id)
                        .execute(pool)
                        .await
                        .map_err(|error| {
                            AppError::InternalError(format!(
                                "Portal bulk assignment reactivation failed: {}",
                                error
                            ))
                        })?;
                        created_count += 1;
                    }
                }
                None => {
                    let short_code = generate_unique_short_code(pool).await?;
                    sqlx::query(
                        r#"
                        INSERT INTO portal_customer_tour_assignments (
                            id, customer_id, tour_id, short_code, status, expires_at_override,
                            revoked_at, revoked_reason, last_opened_at, open_count,
                            geo_country_code, geo_region, created_at, updated_at
                        ) VALUES (?, ?, ?, ?, 'active', NULL, NULL, NULL, NULL, 0, NULL, NULL, ?, ?)
                        "#,
                    )
                    .bind(Uuid::new_v4().to_string())
                    .bind(customer_id)
                    .bind(tour_id)
                    .bind(&short_code)
                    .bind(now)
                    .bind(now)
                    .execute(pool)
                    .await
                    .map_err(|error| {
                        AppError::InternalError(format!("Portal bulk assignment failed: {}", error))
                    })?;
                    created_count += 1;
                }
            }
        }
    }

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        None,
        "portal_tours_bulk_assigned",
        serde_json::json!({
            "customerIds": customer_ids.clone(),
            "tourIds": tour_ids.clone(),
            "requestedCount": requested_count,
            "createdCount": created_count
        }),
    )
    .await?;

    Ok(PortalBulkAssignmentResult {
        customer_ids,
        tour_ids,
        requested_count,
        created_count,
        skipped_count: requested_count - created_count,
    })
}
