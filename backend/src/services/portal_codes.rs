// @efficiency-role: service-orchestrator
use sqlx::{QueryBuilder, SqlitePool};

use crate::models::AppError;

async fn short_code_exists(pool: &SqlitePool, short_code: &str) -> Result<bool, AppError> {
    let access_link_exists = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(1) FROM portal_access_links WHERE short_code = ?",
    )
    .bind(short_code)
    .fetch_one(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal access short-code lookup failed: {}", error))
    })?;

    if access_link_exists > 0 {
        return Ok(true);
    }

    let assignment_exists = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(1) FROM portal_customer_tour_assignments WHERE short_code = ?",
    )
    .bind(short_code)
    .fetch_one(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!(
            "Portal assignment short-code lookup failed: {}",
            error
        ))
    })?;

    Ok(assignment_exists > 0)
}

pub(crate) async fn generate_unique_short_code(pool: &SqlitePool) -> Result<String, AppError> {
    for _attempt in 0..10 {
        let short_code = crate::services::portal_support::make_short_code();
        if !short_code_exists(pool, &short_code).await? {
            return Ok(short_code);
        }
    }

    Err(AppError::InternalError(
        "Failed to allocate a unique portal short code.".into(),
    ))
}

pub(crate) async fn validate_existing_customer_ids(
    pool: &SqlitePool,
    customer_ids: &[String],
) -> Result<(), AppError> {
    let mut builder: QueryBuilder<'_, sqlx::Sqlite> =
        QueryBuilder::new("SELECT id FROM portal_customers WHERE id IN (");
    let mut separated = builder.separated(", ");
    for customer_id in customer_ids {
        separated.push_bind(customer_id);
    }
    separated.push_unseparated(")");

    let existing = builder
        .build_query_scalar::<String>()
        .fetch_all(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal customer validation failed: {}", error))
        })?;

    if existing.len() != customer_ids.len() {
        return Err(AppError::ValidationError(
            "One or more selected recipients no longer exist.".into(),
        ));
    }

    Ok(())
}

pub(crate) async fn validate_existing_tour_ids(
    pool: &SqlitePool,
    tour_ids: &[String],
) -> Result<(), AppError> {
    let mut builder: QueryBuilder<'_, sqlx::Sqlite> =
        QueryBuilder::new("SELECT id FROM portal_library_tours WHERE id IN (");
    let mut separated = builder.separated(", ");
    for tour_id in tour_ids {
        separated.push_bind(tour_id);
    }
    separated.push_unseparated(")");

    let existing = builder
        .build_query_scalar::<String>()
        .fetch_all(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal tour validation failed: {}", error))
        })?;

    if existing.len() != tour_ids.len() {
        return Err(AppError::ValidationError(
            "One or more selected tours no longer exist.".into(),
        ));
    }

    Ok(())
}
