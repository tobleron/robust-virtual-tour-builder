// @efficiency-role: service-orchestrator
use std::fs;
use std::path::Path;

use sqlx::SqlitePool;
use uuid::Uuid;

use crate::models::{AppError, User};
use crate::services::portal_assets::extract_portal_package;
use crate::services::portal_audit::{log_audit, log_audit_event};

pub use crate::services::portal_assets::{load_portal_launch_document, resolve_portal_asset};
pub(crate) use crate::services::portal_assignment_queries::{
    assignment_by_customer_and_tour, assignment_by_id, assignment_by_short_code,
    assignment_from_lookup_row, ensure_assignment_short_code,
};
pub(crate) use crate::services::portal_assignments::{
    assign_tour_to_customer, bulk_assign_tours_to_customers, create_or_activate_assignment_link,
    reactivate_assignment_link, revoke_assignment_link, unassign_tour_from_customer,
    update_assignment_expiry,
};
pub use crate::services::portal_customers::{
    create_customer, delete_access_links, delete_customer, regenerate_access_link,
    revoke_access_links, update_customer,
};
pub use crate::services::portal_paths::{portal_library_tour_dir, validate_slug};
pub use crate::services::portal_sessions::{
    access_session_for_token, authenticate_access_token, gallery_view_for_customer,
    load_customer_session, public_customer_view, resolve_public_tour_access,
};
pub(crate) use crate::services::portal_sessions::{
    current_access_link_for_customer, current_customer_and_access_link_by_slug,
};
pub use crate::services::portal_support::{customer_public, init_storage};
pub use crate::services::portal_types::*;
pub use crate::services::portal_views::assignment_view_by_id;
pub use crate::services::portal_views::list_library_tours;
pub use crate::services::portal_views::{
    list_customer_assignments_view, list_customers, list_tour_assignments_view,
};

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
    let now = chrono::Utc::now();

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
        .bind(chrono::Utc::now())
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
mod tests {}
