// @efficiency-role: service-orchestrator
use chrono::{DateTime, Utc};
use sqlx::SqlitePool;
use uuid::Uuid;

use crate::models::{AppError, User};
use crate::services::portal::{
    PortalAccessLinkRecord, PortalCustomer, PortalCustomerCreateResult, PortalCustomerOverview,
    PortalGeneratedAccessLink, CreatePortalCustomerInput, UpdatePortalCustomerInput,
};
use crate::services::portal_audit::{log_audit, log_audit_event};
use crate::services::portal_codes::generate_unique_short_code;
use crate::services::portal_support::{normalize_recipient_type, parse_expiry, sha256_hex};
use crate::services::portal_views::build_customer_overview;

async fn create_access_link_in_tx(
    pool: &SqlitePool,
    tx: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    customer_id: &str,
    expires_at: DateTime<Utc>,
    now: DateTime<Utc>,
) -> Result<(PortalAccessLinkRecord, String), AppError> {
    sqlx::query(
        "UPDATE portal_access_links SET revoked_at = ?, updated_at = ? WHERE customer_id = ? AND revoked_at IS NULL",
    )
    .bind(now)
    .bind(now)
    .bind(customer_id)
    .execute(&mut **tx)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal access link revoke failed: {}", error)))?;

    for _attempt in 0..6 {
        let short_code = generate_unique_short_code(pool).await?;
        let record = PortalAccessLinkRecord {
            id: Uuid::new_v4().to_string(),
            customer_id: customer_id.to_string(),
            short_code: Some(short_code.clone()),
            token_hash: sha256_hex(&short_code),
            token_value: Some(short_code.clone()),
            expires_at,
            revoked_at: None,
            last_opened_at: None,
            created_at: now,
            updated_at: now,
        };

        let result = sqlx::query(
            r#"
            INSERT INTO portal_access_links (
                id, customer_id, short_code, token_hash, token_value, expires_at, revoked_at, last_opened_at, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, NULL, NULL, ?, ?)
            "#,
        )
        .bind(&record.id)
        .bind(&record.customer_id)
        .bind(record.short_code.as_deref())
        .bind(&record.token_hash)
        .bind(record.token_value.as_deref())
        .bind(record.expires_at)
        .bind(record.created_at)
        .bind(record.updated_at)
        .execute(&mut **tx)
        .await;

        match result {
            Ok(_) => return Ok((record, short_code)),
            Err(error) => match &error {
                sqlx::Error::Database(db_error)
                    if db_error.is_unique_violation()
                        && db_error.message().contains("short_code") =>
                {
                    continue;
                }
                _ => {
                    return Err(AppError::InternalError(format!(
                        "Portal access link create failed: {}",
                        error
                    )));
                }
            },
        }
    }

    Err(AppError::InternalError(
        "Could not allocate a unique portal access short code.".into(),
    ))
}

pub async fn create_customer(
    pool: &SqlitePool,
    input: CreatePortalCustomerInput,
    actor: Option<&User>,
    public_base_url: &str,
) -> Result<PortalCustomerCreateResult, AppError> {
    let slug = crate::services::portal::validate_slug(&input.slug)?;
    let display_name = input.display_name.trim().to_string();
    let recipient_type = normalize_recipient_type(&input.recipient_type)?;
    let expires_at = parse_expiry(&input.expires_at)?;
    if display_name.is_empty() {
        return Err(AppError::ValidationError(
            "Customer display name is required.".into(),
        ));
    }

    let now = Utc::now();
    let customer_id = Uuid::new_v4().to_string();
    let mut tx = pool.begin().await.map_err(|error| {
        AppError::InternalError(format!("Portal customer transaction failed: {}", error))
    })?;

    sqlx::query(
        r#"
        INSERT INTO portal_customers (
            id, slug, display_name, recipient_type, contact_name, contact_email, contact_phone, renewal_message, is_active, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, NULL, 1, ?, ?)
        "#,
    )
    .bind(&customer_id)
    .bind(&slug)
    .bind(&display_name)
    .bind(&recipient_type)
    .bind(input.contact_name.as_deref())
    .bind(input.contact_email.as_deref())
    .bind(input.contact_phone.as_deref())
    .bind(now)
    .bind(now)
    .execute(&mut *tx)
    .await
    .map_err(|error| AppError::ValidationError(format!("Customer create failed: {}", error)))?;

    let (_, short_code) =
        create_access_link_in_tx(pool, &mut tx, &customer_id, expires_at, now).await?;

    log_audit_event(
        &mut tx,
        actor.map(|value| value.id.as_str()),
        Some(&customer_id),
        "portal_customer_created",
        serde_json::json!({"slug": slug, "recipientType": recipient_type, "expiresAt": expires_at}),
    )
    .await?;

    tx.commit().await.map_err(|error| {
        AppError::InternalError(format!("Portal customer commit failed: {}", error))
    })?;

    let customer =
        sqlx::query_as::<_, PortalCustomer>("SELECT * FROM portal_customers WHERE id = ?")
            .bind(&customer_id)
            .fetch_one(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal customer reload failed: {}", error))
            })?;
    let overview = build_customer_overview(pool, customer, public_base_url).await?;

    Ok(PortalCustomerCreateResult {
        access_link: PortalGeneratedAccessLink {
            customer_id: customer_id.clone(),
            customer_slug: slug.clone(),
            access_url: format!(
                "{}/u/{}/{}",
                public_base_url.trim_end_matches('/'),
                slug,
                short_code
            ),
            expires_at: expires_at.to_rfc3339(),
        },
        overview,
    })
}

pub async fn update_customer(
    pool: &SqlitePool,
    customer_id: &str,
    input: UpdatePortalCustomerInput,
    actor: Option<&User>,
    public_base_url: &str,
) -> Result<PortalCustomerOverview, AppError> {
    let display_name = input.display_name.trim().to_string();
    let recipient_type = normalize_recipient_type(&input.recipient_type)?;
    if display_name.is_empty() {
        return Err(AppError::ValidationError(
            "Customer display name is required.".into(),
        ));
    }

    let now = Utc::now();
    sqlx::query(
        r#"
        UPDATE portal_customers
        SET display_name = ?, recipient_type = ?, contact_name = ?, contact_email = ?, contact_phone = ?, is_active = ?, updated_at = ?
        WHERE id = ?
        "#,
    )
    .bind(&display_name)
    .bind(&recipient_type)
    .bind(input.contact_name.as_deref())
    .bind(input.contact_email.as_deref())
    .bind(input.contact_phone.as_deref())
    .bind(if input.is_active { 1_i64 } else { 0_i64 })
    .bind(now)
    .bind(customer_id)
    .execute(pool)
    .await
    .map_err(|error| AppError::ValidationError(format!("Customer update failed: {}", error)))?;

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        Some(customer_id),
        "portal_customer_updated",
        serde_json::json!({"recipientType": recipient_type, "isActive": input.is_active}),
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

pub async fn regenerate_access_link(
    pool: &SqlitePool,
    customer_id: &str,
    expires_at_raw: &str,
    actor: Option<&User>,
    public_base_url: &str,
) -> Result<PortalGeneratedAccessLink, AppError> {
    let expires_at = parse_expiry(expires_at_raw)?;
    let customer =
        sqlx::query_as::<_, PortalCustomer>("SELECT * FROM portal_customers WHERE id = ?")
            .bind(customer_id)
            .fetch_optional(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal customer lookup failed: {}", error))
            })?
            .ok_or_else(|| AppError::ValidationError("Portal customer not found.".into()))?;

    let now = Utc::now();
    let mut tx = pool.begin().await.map_err(|error| {
        AppError::InternalError(format!("Portal access-link transaction failed: {}", error))
    })?;
    let (_, short_code) =
        create_access_link_in_tx(pool, &mut tx, customer_id, expires_at, now).await?;
    log_audit_event(
        &mut tx,
        actor.map(|value| value.id.as_str()),
        Some(customer_id),
        "portal_access_link_regenerated",
        serde_json::json!({"expiresAt": expires_at}),
    )
    .await?;
    tx.commit().await.map_err(|error| {
        AppError::InternalError(format!("Portal access-link commit failed: {}", error))
    })?;

    let customer_slug = customer.slug;
    let access_url = format!(
        "{}/u/{}/{}",
        public_base_url.trim_end_matches('/'),
        customer_slug,
        short_code
    );

    Ok(PortalGeneratedAccessLink {
        customer_id: customer_id.to_string(),
        customer_slug,
        access_url,
        expires_at: expires_at.to_rfc3339(),
    })
}

pub async fn revoke_access_links(
    pool: &SqlitePool,
    customer_id: &str,
    actor: Option<&User>,
    public_base_url: &str,
) -> Result<PortalCustomerOverview, AppError> {
    let now = Utc::now();
    sqlx::query(
        "UPDATE portal_access_links SET revoked_at = ?, updated_at = ? WHERE customer_id = ? AND revoked_at IS NULL",
    )
    .bind(now)
    .bind(now)
    .bind(customer_id)
    .execute(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal access-link revoke failed: {}", error)))?;

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        Some(customer_id),
        "portal_access_link_revoked",
        serde_json::json!({"revokedAt": now}),
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

pub async fn delete_access_links(
    pool: &SqlitePool,
    customer_id: &str,
    actor: Option<&User>,
    public_base_url: &str,
) -> Result<PortalCustomerOverview, AppError> {
    sqlx::query("DELETE FROM portal_access_links WHERE customer_id = ?")
        .bind(customer_id)
        .execute(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal access-link delete failed: {}", error))
        })?;

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        Some(customer_id),
        "portal_access_links_deleted",
        serde_json::json!({}),
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

pub async fn delete_customer(
    pool: &SqlitePool,
    customer_id: &str,
    actor: Option<&User>,
) -> Result<(), AppError> {
    let customer =
        sqlx::query_as::<_, PortalCustomer>("SELECT * FROM portal_customers WHERE id = ?")
            .bind(customer_id)
            .fetch_optional(pool)
            .await
            .map_err(|error| {
                AppError::InternalError(format!("Portal customer lookup failed: {}", error))
            })?
            .ok_or_else(|| AppError::ValidationError("Portal customer not found.".into()))?;

    let mut tx = pool.begin().await.map_err(|error| {
        AppError::InternalError(format!(
            "Portal customer delete transaction failed: {}",
            error
        ))
    })?;

    log_audit_event(
        &mut tx,
        actor.map(|value| value.id.as_str()),
        Some(customer_id),
        "portal_customer_deleted",
        serde_json::json!({"slug": customer.slug}),
    )
    .await?;

    sqlx::query("DELETE FROM portal_customer_tour_assignments WHERE customer_id = ?")
        .bind(customer_id)
        .execute(&mut *tx)
        .await
        .map_err(|error| {
            AppError::InternalError(format!(
                "Portal customer assignment delete failed: {}",
                error
            ))
        })?;

    sqlx::query("DELETE FROM portal_access_links WHERE customer_id = ?")
        .bind(customer_id)
        .execute(&mut *tx)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal customer link delete failed: {}", error))
        })?;

    sqlx::query("DELETE FROM portal_customers WHERE id = ?")
        .bind(customer_id)
        .execute(&mut *tx)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal customer delete failed: {}", error))
        })?;

    tx.commit().await.map_err(|error| {
        AppError::InternalError(format!("Portal customer delete commit failed: {}", error))
    })?;

    Ok(())
}
