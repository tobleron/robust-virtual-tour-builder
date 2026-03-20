// @efficiency-role: service-orchestrator
use chrono::Utc;
use sqlx::SqlitePool;

use crate::models::{AppError, User};
use crate::services::portal::{
    BulkAssignPortalToursInput, PortalBulkAssignmentResult, PortalCustomer, PortalCustomerOverview,
    PortalCustomerTourAssignmentView,
};
use crate::services::portal_assignment_queries::{
    load_assignment_record_for_customer_tour, upsert_assignment_link,
};
use crate::services::portal_audit::log_audit;
use crate::services::portal_codes::{
    generate_unique_short_code, validate_existing_customer_ids, validate_existing_tour_ids,
};
use crate::services::portal_support::dedupe_ids;
use crate::services::portal_support::parse_expiry;
use crate::services::portal_views::build_customer_overview;

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
    crate::services::portal_views::assignment_view_by_id(pool, &assignment.id, public_base_url)
        .await
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

    let assignment =
        crate::services::portal_views::assignment_view_by_id(pool, assignment_id, public_base_url)
            .await?;

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

    let assignment =
        crate::services::portal_views::assignment_view_by_id(pool, assignment_id, public_base_url)
            .await?;

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

    let assignment =
        crate::services::portal_views::assignment_view_by_id(pool, assignment_id, public_base_url)
            .await?;

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
                    if existing.status != "active"
                        || existing.revoked_at.is_some()
                        || existing.short_code.is_none()
                    {
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
                    .bind(uuid::Uuid::new_v4().to_string())
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
