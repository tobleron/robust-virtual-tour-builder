// @efficiency-role: service-orchestrator
use std::fs;
use std::path::Path;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, SqlitePool};
use uuid::Uuid;

use crate::models::{AppError, User};
use crate::services::portal_audit::{log_audit, log_audit_event};
use crate::services::portal_assets::extract_portal_package;
pub use crate::services::portal_paths::{validate_slug, portal_library_tour_dir};
pub use crate::services::portal_assets::{load_portal_launch_document, resolve_portal_asset};
pub(crate) use crate::services::portal_assignments::{
    assign_tour_to_customer, assignment_by_customer_and_tour, assignment_by_id,
    assignment_by_short_code, assignment_from_lookup_row, bulk_assign_tours_to_customers,
    create_or_activate_assignment_link, current_access_link_for_customer,
    current_customer_and_access_link_by_slug, ensure_assignment_short_code,
    reactivate_assignment_link, revoke_assignment_link, unassign_tour_from_customer,
    update_assignment_expiry,
};
pub use crate::services::portal_sessions::{
    access_session_for_token, authenticate_access_token, gallery_view_for_customer,
    load_customer_session, public_customer_view,
};
pub use crate::services::portal_views::assignment_view_by_id;
pub use crate::services::portal_views::{
    list_customer_assignments_view, list_customers, list_tour_assignments_view,
};
pub use crate::services::portal_views::list_library_tours;
pub use crate::services::portal_support::{customer_public, init_storage};
pub use crate::services::portal_customers::{
    create_customer, delete_access_links, delete_customer, regenerate_access_link,
    revoke_access_links, update_customer,
};

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct PortalCustomer {
    pub id: String,
    pub slug: String,
    pub display_name: String,
    pub recipient_type: String,
    pub contact_name: Option<String>,
    pub contact_email: Option<String>,
    pub contact_phone: Option<String>,
    pub renewal_message: Option<String>,
    pub is_active: i64,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct PortalSettings {
    pub id: i64,
    pub renewal_heading: String,
    pub renewal_message: String,
    pub contact_email: Option<String>,
    pub contact_phone: Option<String>,
    pub whatsapp_number: Option<String>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, FromRow)]
pub struct PortalAccessLinkRecord {
    pub(crate) id: String,
    pub(crate) customer_id: String,
    pub(crate) short_code: Option<String>,
    pub(crate) token_hash: String,
    pub(crate) token_value: Option<String>,
    pub(crate) expires_at: DateTime<Utc>,
    pub(crate) revoked_at: Option<DateTime<Utc>>,
    pub(crate) last_opened_at: Option<DateTime<Utc>>,
    pub(crate) created_at: DateTime<Utc>,
    pub(crate) updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, FromRow)]
#[allow(dead_code)]
pub struct PortalCustomerTourAssignmentRecord {
    pub(crate) id: String,
    pub(crate) customer_id: String,
    pub(crate) tour_id: String,
    pub(crate) short_code: Option<String>,
    pub(crate) status: String,
    pub(crate) expires_at_override: Option<DateTime<Utc>>,
    pub(crate) revoked_at: Option<DateTime<Utc>>,
    pub(crate) revoked_reason: Option<String>,
    pub(crate) last_opened_at: Option<DateTime<Utc>>,
    pub(crate) open_count: i64,
    pub(crate) geo_country_code: Option<String>,
    pub(crate) geo_region: Option<String>,
    pub(crate) created_at: DateTime<Utc>,
    pub(crate) updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, FromRow)]
pub(crate) struct AccessTokenLookupRow {
    pub(crate) customer_id: String,
    pub(crate) customer_slug: String,
    pub(crate) customer_display_name: String,
    pub(crate) customer_recipient_type: String,
    pub(crate) customer_contact_name: Option<String>,
    pub(crate) customer_contact_email: Option<String>,
    pub(crate) customer_contact_phone: Option<String>,
    pub(crate) customer_renewal_message: Option<String>,
    pub(crate) customer_is_active: i64,
    pub(crate) customer_created_at: DateTime<Utc>,
    pub(crate) customer_updated_at: DateTime<Utc>,
    pub(crate) link_id: String,
    pub(crate) link_customer_id: String,
    pub(crate) link_short_code: Option<String>,
    pub(crate) link_token_hash: String,
    pub(crate) link_token_value: Option<String>,
    pub(crate) link_expires_at: DateTime<Utc>,
    pub(crate) link_revoked_at: Option<DateTime<Utc>>,
    pub(crate) link_last_opened_at: Option<DateTime<Utc>>,
    pub(crate) link_created_at: DateTime<Utc>,
    pub(crate) link_updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, FromRow)]
pub(crate) struct AssignmentLinkLookupRow {
    pub(crate) assignment_id: String,
    pub(crate) customer_id: String,
    pub(crate) customer_slug: String,
    pub(crate) customer_display_name: String,
    pub(crate) customer_recipient_type: String,
    pub(crate) customer_contact_name: Option<String>,
    pub(crate) customer_contact_email: Option<String>,
    pub(crate) customer_contact_phone: Option<String>,
    pub(crate) customer_renewal_message: Option<String>,
    pub(crate) customer_is_active: i64,
    pub(crate) customer_created_at: DateTime<Utc>,
    pub(crate) customer_updated_at: DateTime<Utc>,
    pub(crate) assignment_tour_id: String,
    pub(crate) assignment_short_code: Option<String>,
    pub(crate) assignment_status: String,
    pub(crate) assignment_expires_at_override: Option<DateTime<Utc>>,
    pub(crate) assignment_revoked_at: Option<DateTime<Utc>>,
    pub(crate) assignment_revoked_reason: Option<String>,
    pub(crate) assignment_last_opened_at: Option<DateTime<Utc>>,
    pub(crate) assignment_open_count: i64,
    pub(crate) assignment_geo_country_code: Option<String>,
    pub(crate) assignment_geo_region: Option<String>,
    pub(crate) assignment_created_at: DateTime<Utc>,
    pub(crate) assignment_updated_at: DateTime<Utc>,
    pub(crate) tour_id: String,
    pub(crate) tour_title: String,
    pub(crate) tour_slug: String,
    pub(crate) tour_status: String,
    pub(crate) tour_storage_path: String,
    pub(crate) tour_cover_path: Option<String>,
    pub(crate) tour_created_at: DateTime<Utc>,
    pub(crate) tour_updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalAccessLinkSummary {
    pub id: String,
    pub expires_at: String,
    pub revoked_at: Option<String>,
    pub last_opened_at: Option<String>,
    pub active: bool,
    pub access_url: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalAdminAccessLinkSummary {
    pub id: String,
    pub expires_at: String,
    pub revoked_at: Option<String>,
    pub last_opened_at: Option<String>,
    pub active: bool,
    pub access_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct PortalLibraryTour {
    pub id: String,
    pub title: String,
    pub slug: String,
    pub status: String,
    pub storage_path: String,
    pub cover_path: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalLibraryTourOverview {
    pub tour: PortalLibraryTour,
    pub assignment_count: i64,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalCustomerOverview {
    pub customer: PortalCustomer,
    pub access_link: Option<PortalAdminAccessLinkSummary>,
    pub assigned_tour_ids: Vec<String>,
    pub tour_count: i64,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalGeneratedAccessLink {
    pub customer_id: String,
    pub customer_slug: String,
    pub access_url: String,
    pub expires_at: String,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalCustomerCreateResult {
    pub overview: PortalCustomerOverview,
    pub access_link: PortalGeneratedAccessLink,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalCustomerPublic {
    pub slug: String,
    pub display_name: String,
    pub is_active: bool,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalCustomerPublicView {
    pub customer: PortalCustomerPublic,
    pub settings: PortalSettings,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalCustomerSessionView {
    pub customer: PortalCustomerPublic,
    pub settings: PortalSettings,
    pub access_link: PortalAccessLinkSummary,
    pub expired: bool,
    pub can_open_tours: bool,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalTourCard {
    pub id: String,
    pub title: String,
    pub slug: String,
    pub status: String,
    pub cover_url: Option<String>,
    pub can_open: bool,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalGalleryView {
    pub customer: PortalCustomerPublic,
    pub settings: PortalSettings,
    pub access_link: PortalAccessLinkSummary,
    pub expired: bool,
    pub can_open_tours: bool,
    pub tours: Vec<PortalTourCard>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalAccessRedirect {
    pub customer_slug: Option<String>,
    pub allowed: bool,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalAssignmentTourSummary {
    pub id: String,
    pub slug: String,
    pub title: String,
    pub status: String,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalAssignmentCustomerSummary {
    pub id: String,
    pub slug: String,
    pub display_name: String,
    pub recipient_type: String,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalCustomerTourAssignmentView {
    pub assignment_id: String,
    pub tour: PortalAssignmentTourSummary,
    pub short_code: Option<String>,
    pub status: String,
    pub effective_expiry: String,
    pub expires_at_override: Option<String>,
    pub inherited_from_recipient: bool,
    pub revoked_at: Option<String>,
    pub revoked_reason: Option<String>,
    pub last_opened_at: Option<String>,
    pub open_count: i64,
    pub access_url: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalCustomerTourAssignmentsView {
    pub customer: PortalCustomerPublic,
    pub access_link: Option<PortalAdminAccessLinkSummary>,
    pub assignments: Vec<PortalCustomerTourAssignmentView>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalTourRecipientAssignmentView {
    pub assignment_id: String,
    pub customer: PortalAssignmentCustomerSummary,
    pub short_code: Option<String>,
    pub status: String,
    pub effective_expiry: String,
    pub expires_at_override: Option<String>,
    pub inherited_from_recipient: bool,
    pub revoked_at: Option<String>,
    pub revoked_reason: Option<String>,
    pub last_opened_at: Option<String>,
    pub open_count: i64,
    pub access_url: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalTourRecipientsView {
    pub tour: PortalLibraryTour,
    pub recipients: Vec<PortalTourRecipientAssignmentView>,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreatePortalCustomerInput {
    pub slug: String,
    pub display_name: String,
    pub expires_at: String,
    pub recipient_type: String,
    pub contact_name: Option<String>,
    pub contact_email: Option<String>,
    pub contact_phone: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdatePortalCustomerInput {
    pub display_name: String,
    pub recipient_type: String,
    pub contact_name: Option<String>,
    pub contact_email: Option<String>,
    pub contact_phone: Option<String>,
    pub is_active: bool,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdatePortalSettingsInput {
    pub renewal_heading: String,
    pub renewal_message: String,
    pub contact_email: Option<String>,
    pub contact_phone: Option<String>,
    pub whatsapp_number: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RegeneratePortalAccessLinkInput {
    pub expires_at: String,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AssignPortalTourInput {
    pub tour_id: String,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdateLinkExpiryInput {
    pub expires_at_override: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RevokeRecipientTourLinkInput {
    pub reason: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BulkAssignPortalToursInput {
    pub customer_ids: Vec<String>,
    pub tour_ids: Vec<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PortalBulkAssignmentResult {
    pub customer_ids: Vec<String>,
    pub tour_ids: Vec<String>,
    pub requested_count: i64,
    pub created_count: i64,
    pub skipped_count: i64,
}

async fn next_available_library_tour_slug(
    pool: &SqlitePool,
    base_slug: &str,
) -> Result<String, AppError> {
    let existing =
        sqlx::query_scalar::<_, String>("SELECT slug FROM portal_library_tours ORDER BY slug ASC")
            .fetch_all(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal tour slug lookup failed: {}", error))
            })?;

    if !existing.iter().any(|value| value == base_slug) {
        return Ok(base_slug.to_string());
    }

    for index in 2..=9999 {
        let candidate = format!("{}-{}", base_slug, index);
        if !existing.iter().any(|value| value == &candidate) {
            return Ok(candidate);
        }
    }

    Err(AppError::InternalError(
        "Could not allocate a unique portal tour slug.".into(),
    ))
}

pub async fn create_library_tour_from_zip(
    pool: &SqlitePool,
    title: &str,
    zip_path: &Path,
    actor: Option<&User>,
) -> Result<PortalLibraryTour, AppError> {
    let trimmed_title = title.trim();
    if trimmed_title.is_empty() {
        return Err(AppError::ValidationError("Tour title is required.".into()));
    }

    let base_slug = validate_slug(trimmed_title)?;
    let tour_slug = next_available_library_tour_slug(pool, &base_slug).await?;
    let destination_dir = portal_library_tour_dir(&tour_slug)?;
    if destination_dir.exists() {
        fs::remove_dir_all(&destination_dir).map_err(AppError::IoError)?;
    }
    fs::create_dir_all(&destination_dir).map_err(AppError::IoError)?;

    let extracted = extract_portal_package(zip_path, &destination_dir)?;
    let tour_id = Uuid::new_v4().to_string();
    let now = Utc::now();

    sqlx::query(
        r#"
        INSERT INTO portal_library_tours (
            id, title, slug, status, storage_path, cover_path, created_at, updated_at
        ) VALUES (?, ?, ?, 'published', ?, ?, ?, ?)
        "#,
    )
    .bind(&tour_id)
    .bind(trimmed_title)
    .bind(&tour_slug)
    .bind(destination_dir.to_string_lossy().to_string())
    .bind(extracted.cover_path.as_deref())
    .bind(now)
    .bind(now)
    .execute(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal tour insert failed: {}", error)))?;

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        None,
        "portal_library_tour_uploaded",
        serde_json::json!({"tourId": tour_id, "tourSlug": tour_slug}),
    )
    .await?;

    sqlx::query_as::<_, PortalLibraryTour>("SELECT * FROM portal_library_tours WHERE id = ?")
        .bind(&tour_id)
        .fetch_one(pool)
        .await
        .map_err(|error| AppError::InternalError(format!("Portal tour reload failed: {}", error)))
}

pub async fn update_library_tour_status(
    pool: &SqlitePool,
    tour_id: &str,
    status: &str,
    actor: Option<&User>,
) -> Result<PortalLibraryTour, AppError> {
    let normalized_status = match status.trim().to_ascii_lowercase().as_str() {
        "published" => "published",
        "archived" => "archived",
        "draft" => "draft",
        _ => {
            return Err(AppError::ValidationError(
                "Tour status must be draft, published, or archived.".into(),
            ));
        }
    };

    sqlx::query("UPDATE portal_library_tours SET status = ?, updated_at = ? WHERE id = ?")
        .bind(normalized_status)
        .bind(Utc::now())
        .bind(tour_id)
        .execute(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal tour status update failed: {}", error))
        })?;

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        None,
        "portal_library_tour_status_updated",
        serde_json::json!({"tourId": tour_id, "status": normalized_status}),
    )
    .await?;

    sqlx::query_as::<_, PortalLibraryTour>("SELECT * FROM portal_library_tours WHERE id = ?")
        .bind(tour_id)
        .fetch_one(pool)
        .await
        .map_err(|error| AppError::InternalError(format!("Portal tour reload failed: {}", error)))
}

pub async fn delete_library_tour(
    pool: &SqlitePool,
    tour_id: &str,
    actor: Option<&User>,
) -> Result<(), AppError> {
    let tour =
        sqlx::query_as::<_, PortalLibraryTour>("SELECT * FROM portal_library_tours WHERE id = ?")
            .bind(tour_id)
            .fetch_optional(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal tour lookup failed: {}", error))
            })?
            .ok_or_else(|| AppError::ValidationError("Portal tour not found.".into()))?;

    let mut tx = pool.begin().await.map_err(|error| {
        AppError::InternalError(format!("Portal tour delete transaction failed: {}", error))
    })?;

    log_audit_event(
        &mut tx,
        actor.map(|value| value.id.as_str()),
        None,
        "portal_library_tour_deleted",
        serde_json::json!({"tourId": tour.id, "tourSlug": tour.slug}),
    )
    .await?;

    sqlx::query("DELETE FROM portal_customer_tour_assignments WHERE tour_id = ?")
        .bind(tour_id)
        .execute(&mut *tx)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal assignment delete failed: {}", error))
        })?;

    sqlx::query("DELETE FROM portal_library_tours WHERE id = ?")
        .bind(tour_id)
        .execute(&mut *tx)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal tour delete failed: {}", error))
        })?;

    tx.commit().await.map_err(|error| {
        AppError::InternalError(format!("Portal tour delete commit failed: {}", error))
    })?;

    if Path::new(&tour.storage_path).exists() {
        fs::remove_dir_all(&tour.storage_path).map_err(AppError::IoError)?;
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
}
