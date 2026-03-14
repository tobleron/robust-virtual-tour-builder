use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

use actix_files::NamedFile;
use chrono::{DateTime, Utc};
use image::{DynamicImage, Rgba, RgbaImage};
use regex::Regex;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use sqlx::{FromRow, SqlitePool};
use uuid::Uuid;
use zip::ZipArchive;

use crate::models::{AppError, User};

const PORTAL_STORAGE_ROOT_DEFAULT: &str = "data/portal";
const PORTAL_REQUIRED_ENTRY_SUFFIXES: [&str; 3] =
    ["index.html", "tour_4k/index.html", "tour_2k/index.html"];
const PORTAL_ACCESS_CODE_ALPHABET: &[u8; 62] =
    b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
const PORTAL_ACCESS_CODE_LEN: usize = 7;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct PortalCustomer {
    pub id: String,
    pub slug: String,
    pub display_name: String,
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
struct PortalAccessLinkRecord {
    id: String,
    customer_id: String,
    short_code: Option<String>,
    token_hash: String,
    token_value: Option<String>,
    expires_at: DateTime<Utc>,
    revoked_at: Option<DateTime<Utc>>,
    last_opened_at: Option<DateTime<Utc>>,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, FromRow)]
struct AccessTokenLookupRow {
    customer_id: String,
    customer_slug: String,
    customer_display_name: String,
    customer_contact_name: Option<String>,
    customer_contact_email: Option<String>,
    customer_contact_phone: Option<String>,
    customer_renewal_message: Option<String>,
    customer_is_active: i64,
    customer_created_at: DateTime<Utc>,
    customer_updated_at: DateTime<Utc>,
    link_id: String,
    link_customer_id: String,
    link_short_code: Option<String>,
    link_token_hash: String,
    link_token_value: Option<String>,
    link_expires_at: DateTime<Utc>,
    link_revoked_at: Option<DateTime<Utc>>,
    link_last_opened_at: Option<DateTime<Utc>>,
    link_created_at: DateTime<Utc>,
    link_updated_at: DateTime<Utc>,
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

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CreatePortalCustomerInput {
    pub slug: String,
    pub display_name: String,
    pub expires_at: String,
    pub contact_name: Option<String>,
    pub contact_email: Option<String>,
    pub contact_phone: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdatePortalCustomerInput {
    pub display_name: String,
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

pub fn portal_storage_root() -> PathBuf {
    std::env::var("PORTAL_STORAGE_ROOT")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from(PORTAL_STORAGE_ROOT_DEFAULT))
}

pub fn init_storage() -> Result<(), AppError> {
    fs::create_dir_all(portal_storage_root().join("tours")).map_err(AppError::IoError)
}

pub fn portal_library_tour_dir(tour_slug: &str) -> Result<PathBuf, AppError> {
    Ok(portal_storage_root()
        .join("tours")
        .join(validate_slug(tour_slug)?))
}

pub fn validate_slug(raw: &str) -> Result<String, AppError> {
    let normalized = slugify(raw);
    if normalized.len() < 3 {
        return Err(AppError::ValidationError(
            "Slug must normalize to at least 3 characters.".into(),
        ));
    }
    Ok(normalized)
}

pub fn parse_expiry(raw: &str) -> Result<DateTime<Utc>, AppError> {
    DateTime::parse_from_rfc3339(raw)
        .map(|value| value.with_timezone(&Utc))
        .map_err(|_| AppError::ValidationError("Expiry must be an ISO-8601 timestamp.".into()))
}

fn slugify(raw: &str) -> String {
    let lower = raw.trim().to_ascii_lowercase();
    let replaced = Regex::new(r"[^a-z0-9]+")
        .ok()
        .map(|regex| regex.replace_all(&lower, "-").into_owned())
        .unwrap_or(lower);
    replaced.trim_matches('-').to_string()
}

fn sha256_hex(raw: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(raw.as_bytes());
    format!("{:x}", hasher.finalize())
}

fn make_access_short_code() -> String {
    let mut value = Uuid::new_v4().as_u128();
    let mut chars = ['0'; PORTAL_ACCESS_CODE_LEN];

    for index in (0..PORTAL_ACCESS_CODE_LEN).rev() {
        let alphabet_index = (value % 62) as usize;
        chars[index] = PORTAL_ACCESS_CODE_ALPHABET[alphabet_index] as char;
        value /= 62;
    }

    chars.iter().collect()
}

fn public_access_code<'a>(record: &'a PortalAccessLinkRecord) -> Option<&'a str> {
    record
        .short_code
        .as_deref()
        .or(record.token_value.as_deref())
}

fn access_link_summary(record: &PortalAccessLinkRecord) -> PortalAccessLinkSummary {
    let expired = record.expires_at < Utc::now();
    PortalAccessLinkSummary {
        id: record.id.clone(),
        expires_at: record.expires_at.to_rfc3339(),
        revoked_at: record.revoked_at.map(|value| value.to_rfc3339()),
        last_opened_at: record.last_opened_at.map(|value| value.to_rfc3339()),
        active: record.revoked_at.is_none() && !expired,
        access_url: None,
    }
}

fn customer_access_link_summary(
    record: &PortalAccessLinkRecord,
    public_base_url: &str,
    customer_slug: &str,
) -> PortalAccessLinkSummary {
    let mut summary = access_link_summary(record);
    summary.access_url = public_access_code(record).map(|value| {
        format!(
            "{}/u/{}/{}",
            public_base_url.trim_end_matches('/'),
            customer_slug,
            value
        )
    });
    summary
}

fn portal_launch_entry_candidates(user_agent: Option<&str>) -> Vec<&'static str> {
    let mobile_user_agent = user_agent
        .map(|value| value.to_ascii_lowercase())
        .map(|value| {
            value.contains("android")
                || value.contains("iphone")
                || value.contains("ipad")
                || value.contains("mobile")
        })
        .unwrap_or(false);

    if mobile_user_agent {
        vec![
            "tour_2k/index.html",
            "tour_hd/index.html",
            "tour_4k/index.html",
            "index.html",
        ]
    } else {
        vec![
            "tour_4k/index.html",
            "tour_2k/index.html",
            "tour_hd/index.html",
            "index.html",
        ]
    }
}

fn inject_base_href(document: String, base_href: &str) -> String {
    if document.contains("<base ") || document.contains("<base href=") {
        return document;
    }

    let lower = document.to_ascii_lowercase();
    let base_tag = format!(r#"<base href="{}">"#, base_href);

    if let Some(index) = lower.find("<head>") {
        let insert_at = index + "<head>".len();
        let mut output = String::with_capacity(document.len() + base_tag.len());
        output.push_str(&document[..insert_at]);
        output.push_str(&base_tag);
        output.push_str(&document[insert_at..]);
        output
    } else {
        format!("{}{}", base_tag, document)
    }
}

fn boost_portal_launch_branding(document: String) -> String {
    document
        .replace("const LOGO_AREA_RATIO = 0.008;", "const LOGO_AREA_RATIO = 0.012;")
        .replace(
            "const LOGO_WIDTH_CAP_RATIO = 0.13;",
            "const LOGO_WIDTH_CAP_RATIO = 0.17;",
        )
        .replace(
            "const LOGO_HEIGHT_CAP_RATIO = 0.075;",
            "const LOGO_HEIGHT_CAP_RATIO = 0.095;",
        )
        .replace(
            "const LOGO_PORTRAIT_AREA_MULTIPLIER = 1.35;",
            "const LOGO_PORTRAIT_AREA_MULTIPLIER = 1.55;",
        )
        .replace(
            "const LOGO_PORTRAIT_WIDTH_CAP_RATIO = 0.18;",
            "const LOGO_PORTRAIT_WIDTH_CAP_RATIO = 0.22;",
        )
        .replace(
            "const LOGO_PORTRAIT_HEIGHT_CAP_RATIO = 0.10;",
            "const LOGO_PORTRAIT_HEIGHT_CAP_RATIO = 0.12;",
        )
}

fn admin_access_link_summary(
    record: &PortalAccessLinkRecord,
    public_base_url: &str,
    customer_slug: &str,
) -> PortalAdminAccessLinkSummary {
    let summary = access_link_summary(record);
    PortalAdminAccessLinkSummary {
        id: summary.id,
        expires_at: summary.expires_at,
        revoked_at: summary.revoked_at,
        last_opened_at: summary.last_opened_at,
        active: summary.active,
        access_url: public_access_code(record).map(|value| {
            format!(
                "{}/u/{}/{}",
                public_base_url.trim_end_matches('/'),
                customer_slug,
                value
            )
        }),
    }
}

fn customer_public(customer: &PortalCustomer) -> PortalCustomerPublic {
    PortalCustomerPublic {
        slug: customer.slug.clone(),
        display_name: customer.display_name.clone(),
        is_active: customer.is_active == 1,
    }
}

pub fn is_portal_admin(user: &User) -> bool {
    if user.role == "admin" {
        return true;
    }

    let allowed = std::env::var("PORTAL_ADMIN_EMAILS").unwrap_or_default();
    if allowed.trim().is_empty() {
        return false;
    }

    allowed
        .split(',')
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .any(|value| value.eq_ignore_ascii_case(&user.email))
}

async fn load_authorized_portal_tour(
    pool: &SqlitePool,
    customer_slug: &str,
    tour_slug: &str,
    access_link_id: &str,
) -> Result<PortalLibraryTour, AppError> {
    let session = load_customer_session(pool, customer_slug, access_link_id, "").await?;
    if !session.can_open_tours {
        return Err(AppError::Unauthorized(
            "Portal access is expired or inactive.".into(),
        ));
    }

    let tour = sqlx::query_as::<_, PortalLibraryTour>(
        r#"
        SELECT t.*
        FROM portal_library_tours t
        JOIN portal_customer_tour_assignments a ON a.tour_id = t.id
        JOIN portal_customers c ON c.id = a.customer_id
        WHERE c.slug = ? AND t.slug = ?
        "#,
    )
    .bind(customer_slug)
    .bind(tour_slug)
    .fetch_optional(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal asset tour lookup failed: {}", error))
    })?
    .ok_or_else(|| AppError::ValidationError("Portal tour not found.".into()))?;

    if tour.status != "published" {
        return Err(AppError::Unauthorized(
            "Portal tour is not currently published.".into(),
        ));
    }

    Ok(tour)
}

async fn ensure_settings_row(pool: &SqlitePool) -> Result<(), AppError> {
    sqlx::query(
        r#"
        INSERT OR IGNORE INTO portal_settings (
            id, renewal_heading, renewal_message, contact_email, contact_phone, whatsapp_number, updated_at
        ) VALUES (1, 'Access expired', 'Contact Robust Virtual Tour Builder to renew access.', NULL, NULL, NULL, ?)
        "#,
    )
    .bind(Utc::now())
    .execute(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal settings bootstrap failed: {}", error)))?;
    Ok(())
}

pub async fn load_settings(pool: &SqlitePool) -> Result<PortalSettings, AppError> {
    ensure_settings_row(pool).await?;
    sqlx::query_as::<_, PortalSettings>("SELECT * FROM portal_settings WHERE id = 1")
        .fetch_one(pool)
        .await
        .map_err(|error| AppError::InternalError(format!("Portal settings load failed: {}", error)))
}

pub async fn update_settings(
    pool: &SqlitePool,
    input: UpdatePortalSettingsInput,
    actor: Option<&User>,
) -> Result<PortalSettings, AppError> {
    ensure_settings_row(pool).await?;
    let heading = input.renewal_heading.trim().to_string();
    let message = input.renewal_message.trim().to_string();
    if heading.is_empty() || message.is_empty() {
        return Err(AppError::ValidationError(
            "Renewal heading and message are required.".into(),
        ));
    }

    let now = Utc::now();
    sqlx::query(
        r#"
        UPDATE portal_settings
        SET renewal_heading = ?, renewal_message = ?, contact_email = ?, contact_phone = ?, whatsapp_number = ?, updated_at = ?
        WHERE id = 1
        "#,
    )
    .bind(&heading)
    .bind(&message)
    .bind(input.contact_email.as_deref())
    .bind(input.contact_phone.as_deref())
    .bind(input.whatsapp_number.as_deref())
    .bind(now)
    .execute(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal settings update failed: {}", error)))?;

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        None,
        "portal_settings_updated",
        serde_json::json!({"updatedAt": now}),
    )
    .await?;

    load_settings(pool).await
}

async fn current_access_link_for_customer(
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

async fn assigned_tour_ids_for_customer(
    pool: &SqlitePool,
    customer_id: &str,
) -> Result<Vec<String>, AppError> {
    sqlx::query_scalar::<_, String>(
        "SELECT tour_id FROM portal_customer_tour_assignments WHERE customer_id = ? ORDER BY created_at DESC",
    )
    .bind(customer_id)
    .fetch_all(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal assignment lookup failed: {}", error)))
}

async fn build_customer_overview(
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

async fn create_access_link_in_tx(
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
        let short_code = make_access_short_code();
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
    let slug = validate_slug(&input.slug)?;
    let display_name = input.display_name.trim().to_string();
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
            id, slug, display_name, contact_name, contact_email, contact_phone, renewal_message, is_active, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, NULL, 1, ?, ?)
        "#,
    )
    .bind(&customer_id)
    .bind(&slug)
    .bind(&display_name)
    .bind(input.contact_name.as_deref())
    .bind(input.contact_email.as_deref())
    .bind(input.contact_phone.as_deref())
    .bind(now)
    .bind(now)
    .execute(&mut *tx)
    .await
    .map_err(|error| AppError::ValidationError(format!("Customer create failed: {}", error)))?;

    let (_, short_code) = create_access_link_in_tx(&mut tx, &customer_id, expires_at, now).await?;

    log_audit_event(
        &mut tx,
        actor.map(|value| value.id.as_str()),
        Some(&customer_id),
        "portal_customer_created",
        serde_json::json!({"slug": slug, "expiresAt": expires_at}),
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
    if display_name.is_empty() {
        return Err(AppError::ValidationError(
            "Customer display name is required.".into(),
        ));
    }

    let now = Utc::now();
    sqlx::query(
        r#"
        UPDATE portal_customers
        SET display_name = ?, contact_name = ?, contact_email = ?, contact_phone = ?, is_active = ?, updated_at = ?
        WHERE id = ?
        "#,
    )
    .bind(&display_name)
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
        serde_json::json!({"isActive": input.is_active}),
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
    let (_, short_code) = create_access_link_in_tx(&mut tx, customer_id, expires_at, now).await?;
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

pub async fn assign_tour_to_customer(
    pool: &SqlitePool,
    customer_id: &str,
    tour_id: &str,
    actor: Option<&User>,
    public_base_url: &str,
) -> Result<PortalCustomerOverview, AppError> {
    sqlx::query(
        r#"
        INSERT OR IGNORE INTO portal_customer_tour_assignments (id, customer_id, tour_id, created_at)
        VALUES (?, ?, ?, ?)
        "#,
    )
    .bind(Uuid::new_v4().to_string())
    .bind(customer_id)
    .bind(tour_id)
    .bind(Utc::now())
    .execute(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal tour assignment failed: {}", error)))?;

    log_audit(
        pool,
        actor.map(|value| value.id.as_str()),
        Some(customer_id),
        "portal_tour_assigned",
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

#[derive(Debug)]
enum AccessTokenOutcome {
    Granted {
        customer: PortalCustomer,
        access_link: PortalAccessLinkRecord,
    },
    Rejected {
        customer_slug: Option<String>,
    },
}

async fn resolve_access_token(
    pool: &SqlitePool,
    token: &str,
) -> Result<AccessTokenOutcome, AppError> {
    let token_hash = sha256_hex(token);
    let row = sqlx::query_as::<_, AccessTokenLookupRow>(
        r#"
        SELECT
            c.id as customer_id,
            c.slug as customer_slug,
            c.display_name as customer_display_name,
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
            l.expires_at as link_expires_at,
            l.revoked_at as link_revoked_at,
            l.last_opened_at as link_last_opened_at,
            l.created_at as link_created_at,
            l.updated_at as link_updated_at
        FROM portal_access_links l
        JOIN portal_customers c ON c.id = l.customer_id
        WHERE l.short_code = ? OR l.token_hash = ?
        ORDER BY CASE WHEN l.short_code = ? THEN 0 ELSE 1 END
        LIMIT 1
        "#,
    )
    .bind(token)
    .bind(token_hash)
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
        contact_name: row.customer_contact_name,
        contact_email: row.customer_contact_email,
        contact_phone: row.customer_contact_phone,
        renewal_message: row.customer_renewal_message,
        is_active: row.customer_is_active,
        created_at: row.customer_created_at,
        updated_at: row.customer_updated_at,
    };
    let access_link = PortalAccessLinkRecord {
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

    let is_valid = customer.is_active == 1
        && access_link.revoked_at.is_none()
        && access_link.expires_at >= Utc::now();

    if !is_valid {
        return Ok(AccessTokenOutcome::Rejected {
            customer_slug: Some(customer.slug),
        });
    }

    let now = Utc::now();
    sqlx::query("UPDATE portal_access_links SET last_opened_at = ?, updated_at = ? WHERE id = ?")
        .bind(now)
        .bind(now)
        .bind(&access_link.id)
        .execute(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal access-link touch failed: {}", error))
        })?;

    Ok(AccessTokenOutcome::Granted {
        customer,
        access_link: PortalAccessLinkRecord {
            last_opened_at: Some(now),
            updated_at: now,
            ..access_link
        },
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
) -> Result<(String, String), AppError> {
    match resolve_access_token(pool, token).await? {
        AccessTokenOutcome::Granted {
            customer,
            access_link,
        } => Ok((customer.slug, access_link.id)),
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
    access_link_id: &str,
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

    let access_link = sqlx::query_as::<_, PortalAccessLinkRecord>(
        "SELECT * FROM portal_access_links WHERE id = ? AND customer_id = ?",
    )
    .bind(access_link_id)
    .bind(&customer.id)
    .fetch_optional(pool)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal session link lookup failed: {}", error))
    })?
    .ok_or_else(|| AppError::Unauthorized("Portal session is invalid for this customer.".into()))?;

    let summary = customer_access_link_summary(&access_link, public_base_url, &customer.slug);
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
    access_link_id: &str,
    public_base_url: &str,
) -> Result<PortalGalleryView, AppError> {
    let session = load_customer_session(pool, slug, access_link_id, public_base_url).await?;
    let tours = sqlx::query_as::<_, PortalLibraryTour>(
        r#"
        SELECT t.*
        FROM portal_library_tours t
        JOIN portal_customer_tour_assignments a ON a.tour_id = t.id
        JOIN portal_customers c ON c.id = a.customer_id
        WHERE c.slug = ? AND t.status != 'archived'
        ORDER BY t.updated_at DESC
        "#,
    )
    .bind(&session.customer.slug)
    .fetch_all(pool)
    .await
    .map_err(|error| AppError::InternalError(format!("Portal gallery lookup failed: {}", error)))?;

    let mut cards = Vec::with_capacity(tours.len());
    for tour in tours {
        let cover_path = ensure_portal_cover_path(pool, &tour).await?;
        cards.push(PortalTourCard {
            id: tour.id.clone(),
            title: tour.title,
            slug: tour.slug.clone(),
            status: tour.status.clone(),
            cover_url: cover_path.map(|cover| {
                format!(
                    "/portal-assets/{}/{}/{}",
                    session.customer.slug, tour.slug, cover
                )
            }),
            can_open: session.can_open_tours && tour.status == "published",
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

pub async fn load_portal_launch_document(
    pool: &SqlitePool,
    customer_slug: &str,
    tour_slug: &str,
    access_link_id: &str,
    user_agent: Option<&str>,
) -> Result<String, AppError> {
    let tour = load_authorized_portal_tour(pool, customer_slug, tour_slug, access_link_id).await?;
    let storage_root = PathBuf::from(&tour.storage_path);

    for candidate in portal_launch_entry_candidates(user_agent) {
        let resolved = storage_root.join(candidate);
        if !resolved.exists() {
            continue;
        }

        crate::api::utils::validate_path_safe(&storage_root, &resolved)?;
        let document = fs::read_to_string(&resolved).map_err(AppError::IoError)?;
        let base_href = match candidate.rsplit_once('/') {
            Some((dir, _)) => format!("/portal-assets/{}/{}/{}/", customer_slug, tour_slug, dir),
            None => format!("/portal-assets/{}/{}/", customer_slug, tour_slug),
        };
        return Ok(boost_portal_launch_branding(inject_base_href(document, &base_href)));
    }

    Err(AppError::ValidationError(
        "Portal launch document not found.".into(),
    ))
}

pub async fn resolve_portal_asset(
    pool: &SqlitePool,
    customer_slug: &str,
    tour_slug: &str,
    relative_path: &str,
    access_link_id: &str,
) -> Result<NamedFile, AppError> {
    let tour = load_authorized_portal_tour(pool, customer_slug, tour_slug, access_link_id).await?;
    let storage_root = PathBuf::from(&tour.storage_path);
    let safe_relative = sanitize_relative_path(relative_path)?;
    let resolved = storage_root.join(&safe_relative);
    if !resolved.exists() {
        return Err(AppError::ValidationError("Portal asset not found.".into()));
    }

    crate::api::utils::validate_path_safe(&storage_root, &resolved)?;
    NamedFile::open_async(resolved)
        .await
        .map_err(AppError::IoError)
}

struct ExtractedPackage {
    cover_path: Option<String>,
}

fn generate_portal_cover_thumbnail(
    source_path: &Path,
    destination_path: &Path,
) -> Result<(), AppError> {
    let source_image = image::open(source_path).map_err(|error| {
        AppError::ValidationError(format!("Portal cover decode failed: {}", error))
    })?;
    let source_rgba = source_image.to_rgba8();
    let src_w = source_rgba.width();
    let src_h = source_rgba.height();

    if src_w == 0 || src_h == 0 {
        return Err(AppError::ValidationError(
            "Portal cover source image is empty.".into(),
        ));
    }

    let width: u32 = 640;
    let height: u32 = 360;
    let hfov = std::f32::consts::FRAC_PI_2;
    let half_tan_h = (hfov / 2.0).tan();
    let aspect = width as f32 / height as f32;
    let half_tan_v = half_tan_h / aspect;
    let mut output = RgbaImage::new(width, height);

    for y in 0..height {
        for x in 0..width {
            let u = (x as f32 / width as f32) * 2.0 - 1.0;
            let v = 1.0 - (y as f32 / height as f32) * 2.0;

            let theta = (u * half_tan_h).atan();
            let phi = (v * half_tan_v * theta.cos()).atan();

            let lon = theta / (2.0 * std::f32::consts::PI) + 0.5;
            let lat = 0.5 - phi / std::f32::consts::PI;

            let sx = (lon * src_w as f32).floor().clamp(0.0, (src_w - 1) as f32) as u32;
            let sy = (lat * src_h as f32).floor().clamp(0.0, (src_h - 1) as f32) as u32;
            let pixel = source_rgba.get_pixel(sx, sy);
            output.put_pixel(x, y, Rgba([pixel[0], pixel[1], pixel[2], 255]));
        }
    }

    if let Some(parent) = destination_path.parent() {
        fs::create_dir_all(parent).map_err(AppError::IoError)?;
    }
    let cover_image = DynamicImage::ImageRgba8(output);
    let cover_bytes = encode_portal_cover_webp(&cover_image, 82.0)
        .map_err(AppError::ValidationError)?;
    fs::write(destination_path, cover_bytes).map_err(AppError::IoError)?;
    Ok(())
}

fn encode_portal_cover_webp(img: &DynamicImage, quality: f32) -> Result<Vec<u8>, String> {
    let rgba = img.to_rgba8();
    let encoder = webp::Encoder::from_rgba(&rgba, img.width(), img.height());
    Ok(encoder.encode(quality).to_vec())
}

async fn ensure_portal_cover_path(
    pool: &SqlitePool,
    tour: &PortalLibraryTour,
) -> Result<Option<String>, AppError> {
    let generated_relative = "portal_cover.webp".to_string();
    let generated_path = Path::new(&tour.storage_path).join(&generated_relative);
    if generated_path.exists() {
        return Ok(Some(generated_relative));
    }

    let source_relative = tour.cover_path.clone().or_else(|| {
        let fallback = Path::new(&tour.storage_path)
            .join("assets")
            .join("images")
            .join("2k");
        fs::read_dir(fallback)
            .ok()?
            .filter_map(|entry| entry.ok())
            .find(|entry| entry.path().extension().and_then(|value| value.to_str()) == Some("webp"))
            .and_then(|entry| {
                entry
                    .path()
                    .strip_prefix(&tour.storage_path)
                    .ok()
                    .map(|path| path.to_string_lossy().replace('\\', "/"))
            })
    });

    let Some(source_relative) = source_relative else {
        return Ok(None);
    };

    let source_path = Path::new(&tour.storage_path).join(&source_relative);
    if !source_path.exists() {
        return Ok(None);
    }

    generate_portal_cover_thumbnail(&source_path, &generated_path)?;
    sqlx::query("UPDATE portal_library_tours SET cover_path = ?, updated_at = ? WHERE id = ?")
        .bind(&generated_relative)
        .bind(Utc::now())
        .bind(&tour.id)
        .execute(pool)
        .await
        .map_err(|error| {
            AppError::InternalError(format!("Portal cover-path update failed: {}", error))
        })?;

    Ok(Some(generated_relative))
}

fn extract_portal_package(
    zip_path: &Path,
    destination_dir: &Path,
) -> Result<ExtractedPackage, AppError> {
    let file = std::fs::File::open(zip_path).map_err(AppError::IoError)?;
    let mut archive = ZipArchive::new(file).map_err(|error| {
        AppError::ValidationError(format!("Portal ZIP could not be opened: {}", error))
    })?;

    let mut entry_names: Vec<String> = Vec::new();
    for index in 0..archive.len() {
        let entry = archive.by_index(index).map_err(|error| {
            AppError::ValidationError(format!("Portal ZIP entry could not be read: {}", error))
        })?;
        let enclosed = entry.enclosed_name().ok_or_else(|| {
            AppError::ValidationError("Portal ZIP contains an unsafe path.".into())
        })?;
        let entry_name = enclosed.to_string_lossy().replace('\\', "/");
        if !entry.is_dir() {
            entry_names.push(entry_name);
        }
    }

    let package_root = detect_portal_package_root(&entry_names)?;
    let mut found_entries: Vec<&str> = Vec::new();
    let mut source_cover_path: Option<String> = None;

    for index in 0..archive.len() {
        let mut entry = archive.by_index(index).map_err(|error| {
            AppError::ValidationError(format!("Portal ZIP entry could not be read: {}", error))
        })?;
        let enclosed = entry.enclosed_name().ok_or_else(|| {
            AppError::ValidationError("Portal ZIP contains an unsafe path.".into())
        })?;
        let entry_name = enclosed.to_string_lossy().replace('\\', "/");
        if !entry_name.starts_with(&package_root) || entry.is_dir() {
            continue;
        }

        let relative_path = entry_name
            .strip_prefix(&package_root)
            .ok_or_else(|| AppError::ValidationError("Portal ZIP entry prefix mismatch.".into()))?;

        if !should_keep_portal_relative_path(relative_path) {
            continue;
        }

        for required in PORTAL_REQUIRED_ENTRY_SUFFIXES {
            if relative_path == required && !found_entries.contains(&required) {
                found_entries.push(required);
            }
        }

        let destination = destination_dir.join(relative_path);
        if let Some(parent) = destination.parent() {
            fs::create_dir_all(parent).map_err(AppError::IoError)?;
        }
        let mut output = std::fs::File::create(&destination).map_err(AppError::IoError)?;
        std::io::copy(&mut entry, &mut output).map_err(AppError::IoError)?;
        output.flush().map_err(AppError::IoError)?;

        if source_cover_path.is_none()
            && relative_path.starts_with("assets/images/2k/")
            && relative_path.ends_with(".webp")
        {
            source_cover_path = Some(relative_path.to_string());
        }
    }

    if PORTAL_REQUIRED_ENTRY_SUFFIXES
        .iter()
        .any(|required| !found_entries.contains(required))
    {
        return Err(AppError::ValidationError(
            "Portal ZIP must include web_only/index.html plus both tour_4k/index.html and tour_2k/index.html.".into(),
        ));
    }

    let generated_cover_path = source_cover_path
        .as_ref()
        .map(|relative| {
            let source_path = destination_dir.join(relative);
            let destination_relative = "portal_cover.webp".to_string();
            let destination_path = destination_dir.join(&destination_relative);
            generate_portal_cover_thumbnail(&source_path, &destination_path)?;
            Ok::<String, AppError>(destination_relative)
        })
        .transpose()?;

    Ok(ExtractedPackage {
        cover_path: generated_cover_path.or(source_cover_path),
    })
}

fn should_keep_portal_relative_path(relative_path: &str) -> bool {
    relative_path == "index.html"
        || relative_path.starts_with("tour_4k/")
        || relative_path.starts_with("tour_2k/")
        || relative_path.starts_with("assets/")
        || relative_path.starts_with("libs/")
}

fn detect_portal_package_root(entry_names: &[String]) -> Result<String, AppError> {
    let mut preferred_root: Option<String> = None;
    let mut fallback_root: Option<String> = None;

    for entry_name in entry_names {
        if let Some(prefix) = entry_name.strip_suffix("tour_4k/index.html") {
            let normalized = prefix.to_string();
            if normalized.ends_with("web_only/") {
                preferred_root = Some(normalized.clone());
            }
            if fallback_root.is_none() {
                fallback_root = Some(normalized);
            }
        }
    }

    preferred_root.or(fallback_root).ok_or_else(|| {
        AppError::ValidationError(
            "Portal ZIP must include a valid web_only package with tour_4k/index.html and tour_2k/index.html.".into(),
        )
    })
}

fn sanitize_relative_path(relative_path: &str) -> Result<PathBuf, AppError> {
    if relative_path.trim().is_empty() {
        return Err(AppError::ValidationError(
            "Portal asset path is required.".into(),
        ));
    }

    let candidate = Path::new(relative_path);
    if candidate.is_absolute() {
        return Err(AppError::ValidationError(
            "Portal asset path must be relative.".into(),
        ));
    }

    let mut clean = PathBuf::new();
    for component in candidate.components() {
        match component {
            std::path::Component::Normal(part) => clean.push(part),
            _ => {
                return Err(AppError::ValidationError(
                    "Portal asset path contains unsupported segments.".into(),
                ));
            }
        }
    }

    Ok(clean)
}

async fn log_audit(
    pool: &SqlitePool,
    actor_user_id: Option<&str>,
    customer_id: Option<&str>,
    event_type: &str,
    details_json: serde_json::Value,
) -> Result<(), AppError> {
    let mut tx = pool.begin().await.map_err(|error| {
        AppError::InternalError(format!("Portal audit transaction failed: {}", error))
    })?;
    log_audit_event(
        &mut tx,
        actor_user_id,
        customer_id,
        event_type,
        details_json,
    )
    .await?;
    tx.commit()
        .await
        .map_err(|error| AppError::InternalError(format!("Portal audit commit failed: {}", error)))
}

async fn log_audit_event(
    tx: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    actor_user_id: Option<&str>,
    customer_id: Option<&str>,
    event_type: &str,
    details_json: serde_json::Value,
) -> Result<(), AppError> {
    sqlx::query(
        r#"
        INSERT INTO portal_audit_log (id, actor_user_id, customer_id, event_type, details_json)
        VALUES (?, ?, ?, ?, ?)
        "#,
    )
    .bind(Uuid::new_v4().to_string())
    .bind(actor_user_id)
    .bind(customer_id)
    .bind(event_type)
    .bind(details_json.to_string())
    .execute(&mut **tx)
    .await
    .map_err(|error| {
        AppError::InternalError(format!("Portal audit log write failed: {}", error))
    })?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn slugify_normalizes_and_strips_noise() {
        assert_eq!(slugify("  ACME Tower  "), "acme-tower");
        assert_eq!(slugify("Unit # 19 / Showroom"), "unit-19-showroom");
    }

    #[test]
    fn sanitize_relative_path_blocks_parent_segments() {
        assert!(sanitize_relative_path("../tour_4k/index.html").is_err());
        assert!(sanitize_relative_path("/tmp/tour_4k/index.html").is_err());
        assert!(sanitize_relative_path("tour_4k/index.html").is_ok());
    }
}
