#![allow(dead_code)]
// @efficiency-role: service-orchestrator
use chrono::{DateTime, Utc};
use sqlx::SqlitePool;

use crate::models::AppError;
use crate::services::portal::{
    assignment_by_id, assignment_from_lookup_row, current_access_link_for_customer,
    customer_public, ensure_assignment_short_code, AssignmentLinkLookupRow, PortalCustomer,
    PortalCustomerOverview, PortalCustomerTourAssignmentRecord,
    PortalCustomerTourAssignmentView, PortalCustomerTourAssignmentsView, PortalLibraryTour,
    PortalLibraryTourOverview, PortalTourRecipientsView,
};
use crate::services::portal_support::{
    admin_access_link_summary, customer_tour_assignment_view, tour_recipient_assignment_view,
};

async fn assigned_tour_ids_for_customer(
    pool: &SqlitePool,
    customer_id: &str,
) -> Result<Vec<String>, AppError> {
    sqlx::query_scalar::<_, String>(
        "SELECT tour_id FROM portal_customer_tour_assignments WHERE customer_id = ? AND status = 'active' AND revoked_at IS NULL ORDER BY created_at DESC",
    )
    .bind(customer_id)
    .fetch_all(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal assignment lookup failed: {}", error)))
}

pub(crate) async fn build_customer_overview(
    pool: &SqlitePool,
    customer: PortalCustomer,
    public_base_url: &str,
) -> Result<PortalCustomerOverview, AppError> {
    let assigned_tour_ids = assigned_tour_ids_for_customer(pool, &customer.id).await?;
    let access_link = current_access_link_for_customer(pool, &customer.id)
        .await?
        .map(|value| admin_access_link_summary(&value, public_base_url, &customer.slug));
    let tour_count = i64::try_from(assigned_tour_ids.len()).unwrap_or(0);

    Ok(PortalCustomerOverview {
        customer,
        access_link,
        assigned_tour_ids,
        tour_count,
    })
}

pub async fn list_customers(
    pool: &SqlitePool,
    public_base_url: &str,
) -> Result<Vec<PortalCustomerOverview>, AppError> {
    let customers = sqlx::query_as::<_, PortalCustomer>(
        "SELECT * FROM portal_customers ORDER BY updated_at DESC",
    )
    .fetch_all(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal customer list failed: {}", error)))?;

    let mut overviews = Vec::with_capacity(customers.len());
    for customer in customers {
        overviews.push(build_customer_overview(pool, customer, public_base_url).await?);
    }
    Ok(overviews)
}

pub async fn list_library_tours(
    pool: &SqlitePool,
) -> Result<Vec<PortalLibraryTourOverview>, AppError> {
    let rows = sqlx::query_as::<
        _,
        (
            String,
            String,
            String,
            String,
            String,
            Option<String>,
            DateTime<Utc>,
            DateTime<Utc>,
            i64,
        ),
    >(
        r#"
        SELECT
            t.id,
            t.title,
            t.slug,
            t.status,
            t.storage_path,
            t.cover_path,
            t.created_at,
            t.updated_at,
            COALESCE(COUNT(a.id), 0) as assignment_count
        FROM portal_library_tours t
        LEFT JOIN portal_customer_tour_assignments a ON a.tour_id = t.id
            AND a.status = 'active'
            AND a.revoked_at IS NULL
        GROUP BY t.id
        ORDER BY t.updated_at DESC
        "#,
    )
    .fetch_all(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal library tour list failed: {}", error))
    })?;

    Ok(rows
        .into_iter()
        .map(
            |(
                id,
                title,
                slug,
                status,
                storage_path,
                cover_path,
                created_at,
                updated_at,
                assignment_count,
            )| {
                PortalLibraryTourOverview {
                    tour: PortalLibraryTour {
                        id,
                        title,
                        slug,
                        status,
                        storage_path,
                        cover_path,
                        created_at,
                        updated_at,
                    },
                    assignment_count,
                }
            },
        )
        .collect())
}

pub(crate) async fn customer_assignment_rows(
    pool: &SqlitePool,
    customer_id: &str,
) -> Result<Vec<AssignmentLinkLookupRow>, AppError> {
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
        WHERE a.customer_id = ?
        ORDER BY t.updated_at DESC, a.created_at DESC
        "#,
    )
    .bind(customer_id)
    .fetch_all(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal assignment list failed: {}", error)))
}

async fn tour_assignment_rows(
    pool: &SqlitePool,
    tour_id: &str,
) -> Result<Vec<AssignmentLinkLookupRow>, AppError> {
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
        WHERE a.tour_id = ?
        ORDER BY c.updated_at DESC, a.created_at DESC
        "#,
    )
    .bind(tour_id)
    .fetch_all(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal tour assignment list failed: {}", error)))
}

async fn customer_assignment_view(
    pool: &SqlitePool,
    customer_id: &str,
    public_base_url: &str,
) -> Result<PortalCustomerTourAssignmentsView, AppError> {
    let customer = sqlx::query_as::<_, PortalCustomer>("SELECT * FROM portal_customers WHERE id = ?")
        .bind(customer_id)
        .fetch_one(pool)
        .await
        .map_err(|error| AppError::InternalError(format!("Portal customer reload failed: {}", error)))?;
    let access_link = current_access_link_for_customer(pool, customer_id)
        .await?
        .map(|value| admin_access_link_summary(&value, public_base_url, &customer.slug));
    let recipient_expiry = current_access_link_for_customer(pool, customer_id)
        .await?
        .map(|value| value.expires_at)
        .unwrap_or_else(Utc::now);
    let mut assignments = Vec::new();

    for row in customer_assignment_rows(pool, customer_id).await? {
        let (assignment_customer, assignment, tour) = assignment_from_lookup_row(row);
        let short_code = match assignment.short_code.clone() {
            Some(value) => Some(value),
            None => Some(ensure_assignment_short_code(pool, &assignment.id).await?),
        };
        let assignment = PortalCustomerTourAssignmentRecord {
            short_code,
            ..assignment
        };
        assignments.push(customer_tour_assignment_view(
            &assignment,
            &assignment_customer.slug,
            &tour,
            recipient_expiry,
            public_base_url,
        ));
    }

    Ok(PortalCustomerTourAssignmentsView {
        customer: customer_public(&customer),
        access_link,
        assignments,
    })
}

async fn tour_recipient_view(
    pool: &SqlitePool,
    tour_id: &str,
    public_base_url: &str,
) -> Result<PortalTourRecipientsView, AppError> {
    let tour = sqlx::query_as::<_, PortalLibraryTour>("SELECT * FROM portal_library_tours WHERE id = ?")
        .bind(tour_id)
        .fetch_one(pool)
        .await
        .map_err(|error| AppError::InternalError(format!("Portal tour reload failed: {}", error)))?;
    let mut recipients = Vec::new();

    for row in tour_assignment_rows(pool, tour_id).await? {
        let (customer, assignment, assignment_tour) = assignment_from_lookup_row(row);
        let short_code = match assignment.short_code.clone() {
            Some(value) => Some(value),
            None => Some(ensure_assignment_short_code(pool, &assignment.id).await?),
        };
        let assignment = PortalCustomerTourAssignmentRecord {
            short_code,
            ..assignment
        };
        let recipient_expiry = current_access_link_for_customer(pool, &customer.id)
            .await?
            .map(|value| value.expires_at)
            .unwrap_or_else(Utc::now);
        recipients.push(tour_recipient_assignment_view(
            &assignment,
            &customer,
            &assignment_tour.slug,
            recipient_expiry,
            public_base_url,
        ));
    }

    Ok(PortalTourRecipientsView { tour, recipients })
}

pub async fn list_customer_assignments_view(
    pool: &SqlitePool,
    customer_id: &str,
    public_base_url: &str,
) -> Result<PortalCustomerTourAssignmentsView, AppError> {
    customer_assignment_view(pool, customer_id, public_base_url).await
}

pub async fn list_tour_assignments_view(
    pool: &SqlitePool,
    tour_id: &str,
    public_base_url: &str,
) -> Result<PortalTourRecipientsView, AppError> {
    tour_recipient_view(pool, tour_id, public_base_url).await
}

pub async fn assignment_view_by_id(
    pool: &SqlitePool,
    assignment_id: &str,
    public_base_url: &str,
) -> Result<PortalCustomerTourAssignmentView, AppError> {
    let row = assignment_by_id(pool, assignment_id)
        .await?
        .ok_or_else(|| AppError::ValidationError("Portal assignment not found.".into()))?;
    let (customer, assignment, tour) = assignment_from_lookup_row(row);
    let short_code = match assignment.short_code.clone() {
        Some(value) => Some(value),
        None => Some(ensure_assignment_short_code(pool, &assignment.id).await?),
    };
    let assignment = PortalCustomerTourAssignmentRecord {
        short_code,
        ..assignment
    };
    let recipient_expiry = current_access_link_for_customer(pool, &customer.id)
        .await?
        .map(|value| value.expires_at)
        .unwrap_or_else(Utc::now);

    Ok(customer_tour_assignment_view(
        &assignment,
        &customer.slug,
        &tour,
        recipient_expiry,
        public_base_url,
    ))
}
