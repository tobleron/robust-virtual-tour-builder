// @efficiency-role: service-orchestrator
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

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
