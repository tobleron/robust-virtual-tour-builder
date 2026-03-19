use std::fs;
use std::path::Path;

use chrono::{DateTime, Utc};
use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::models::{AppError, User};
use crate::services::portal::{
    PortalAccessLinkRecord, PortalAccessLinkSummary, PortalAdminAccessLinkSummary,
    PortalAssignmentCustomerSummary, PortalAssignmentTourSummary, PortalCustomer,
    PortalCustomerPublic, PortalCustomerTourAssignmentRecord, PortalCustomerTourAssignmentView,
    PortalLibraryTour, PortalTourRecipientAssignmentView,
};
use crate::services::portal_paths::portal_storage_root;

pub fn init_storage() -> Result<(), AppError> {
    fs::create_dir_all(portal_storage_root().join("tours")).map_err(AppError::IoError)
}

pub fn normalize_recipient_type(raw: &str) -> Result<String, AppError> {
    let normalized = raw.trim().to_ascii_lowercase();
    match normalized.as_str() {
        "property_owner" | "broker" | "property_owner_broker" => Ok(normalized),
        _ => Err(AppError::ValidationError(
            "Recipient type must be property_owner, broker, or property_owner_broker.".into(),
        )),
    }
}

pub fn parse_expiry(raw: &str) -> Result<DateTime<Utc>, AppError> {
    DateTime::parse_from_rfc3339(raw)
        .map(|value| value.with_timezone(&Utc))
        .map_err(|_| AppError::ValidationError("Expiry must be an ISO-8601 timestamp.".into()))
}

pub fn sha256_hex(raw: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(raw.as_bytes());
    format!("{:x}", hasher.finalize())
}

pub fn make_short_code() -> String {
    const PORTAL_ACCESS_CODE_ALPHABET: &[u8; 62] =
        b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    const PORTAL_ACCESS_CODE_LEN: usize = 7;
    let mut value = Uuid::new_v4().as_u128();
    let mut chars = ['0'; PORTAL_ACCESS_CODE_LEN];

    for index in (0..PORTAL_ACCESS_CODE_LEN).rev() {
        let alphabet_index = (value % 62) as usize;
        chars[index] = PORTAL_ACCESS_CODE_ALPHABET[alphabet_index] as char;
        value /= 62;
    }

    chars.iter().collect()
}

pub fn public_access_code<'a>(record: &'a PortalAccessLinkRecord) -> Option<&'a str> {
    record
        .short_code
        .as_deref()
        .or(record.token_value.as_deref())
}

pub fn access_link_summary(record: &PortalAccessLinkRecord) -> PortalAccessLinkSummary {
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

pub fn customer_access_link_summary(
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

pub fn assignment_access_url(
    public_base_url: &str,
    customer_slug: &str,
    short_code: &str,
    tour_slug: &str,
) -> String {
    format!(
        "{}/u/{}/{}/tour/{}",
        public_base_url.trim_end_matches('/'),
        customer_slug,
        short_code,
        tour_slug
    )
}

pub fn assignment_effective_expiry(
    assignment: &PortalCustomerTourAssignmentRecord,
    recipient_expiry: DateTime<Utc>,
) -> DateTime<Utc> {
    assignment.expires_at_override.unwrap_or(recipient_expiry)
}

pub fn assignment_is_active(
    assignment: &PortalCustomerTourAssignmentRecord,
    recipient_expiry: DateTime<Utc>,
) -> bool {
    assignment.status == "active"
        && assignment.revoked_at.is_none()
        && assignment_effective_expiry(assignment, recipient_expiry) > Utc::now()
}

pub fn customer_tour_assignment_view(
    assignment: &PortalCustomerTourAssignmentRecord,
    customer_slug: &str,
    tour: &PortalLibraryTour,
    recipient_expiry: DateTime<Utc>,
    public_base_url: &str,
) -> PortalCustomerTourAssignmentView {
    PortalCustomerTourAssignmentView {
        assignment_id: assignment.id.clone(),
        tour: PortalAssignmentTourSummary {
            id: tour.id.clone(),
            slug: tour.slug.clone(),
            title: tour.title.clone(),
            status: tour.status.clone(),
        },
        short_code: assignment.short_code.clone(),
        status: assignment.status.clone(),
        effective_expiry: assignment_effective_expiry(assignment, recipient_expiry).to_rfc3339(),
        expires_at_override: assignment.expires_at_override.map(|value| value.to_rfc3339()),
        inherited_from_recipient: assignment.expires_at_override.is_none(),
        revoked_at: assignment.revoked_at.map(|value| value.to_rfc3339()),
        revoked_reason: assignment.revoked_reason.clone(),
        last_opened_at: assignment.last_opened_at.map(|value| value.to_rfc3339()),
        open_count: assignment.open_count,
        access_url: assignment.short_code.as_ref().map(|short_code| {
            assignment_access_url(public_base_url, customer_slug, short_code, &tour.slug)
        }),
    }
}

pub fn tour_recipient_assignment_view(
    assignment: &PortalCustomerTourAssignmentRecord,
    customer: &PortalCustomer,
    tour_slug: &str,
    recipient_expiry: DateTime<Utc>,
    public_base_url: &str,
) -> PortalTourRecipientAssignmentView {
    PortalTourRecipientAssignmentView {
        assignment_id: assignment.id.clone(),
        customer: PortalAssignmentCustomerSummary {
            id: customer.id.clone(),
            slug: customer.slug.clone(),
            display_name: customer.display_name.clone(),
            recipient_type: customer.recipient_type.clone(),
        },
        short_code: assignment.short_code.clone(),
        status: assignment.status.clone(),
        effective_expiry: assignment_effective_expiry(assignment, recipient_expiry).to_rfc3339(),
        expires_at_override: assignment.expires_at_override.map(|value| value.to_rfc3339()),
        inherited_from_recipient: assignment.expires_at_override.is_none(),
        revoked_at: assignment.revoked_at.map(|value| value.to_rfc3339()),
        revoked_reason: assignment.revoked_reason.clone(),
        last_opened_at: assignment.last_opened_at.map(|value| value.to_rfc3339()),
        open_count: assignment.open_count,
        access_url: assignment.short_code.as_ref().map(|short_code| {
            assignment_access_url(public_base_url, &customer.slug, short_code, tour_slug)
        }),
    }
}

pub fn portal_launch_entry_candidates(user_agent: Option<&str>) -> Vec<&'static str> {
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

pub fn inject_base_href(document: String, base_href: &str) -> String {
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

pub fn boost_portal_launch_branding(document: String) -> String {
    document
        .replace(
            "const LOGO_AREA_RATIO = 0.008;",
            "const LOGO_AREA_RATIO = 0.012;",
        )
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

pub fn dedupe_ids(ids: Vec<String>) -> Vec<String> {
    let mut deduped = Vec::with_capacity(ids.len());
    for id in ids {
        if !deduped.iter().any(|existing| existing == &id) {
            deduped.push(id);
        }
    }
    deduped
}

pub fn admin_access_link_summary(
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

pub fn customer_public(customer: &PortalCustomer) -> PortalCustomerPublic {
    PortalCustomerPublic {
        slug: customer.slug.clone(),
        display_name: customer.display_name.clone(),
        is_active: customer.is_active == 1,
    }
}
