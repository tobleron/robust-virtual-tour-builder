use chrono::Utc;
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SignUpPayload {
    pub email: String,
    pub username: String,
    pub password: String,
    pub display_name: Option<String>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SignInPayload {
    pub email: String,
    pub password: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct VerifyOtpPayload {
    pub challenge_id: String,
    pub otp_code: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ResendOtpPayload {
    pub challenge_id: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct VerifyEmailPayload {
    pub token: String,
}

#[derive(Debug, Deserialize)]
pub struct ResendVerificationPayload {
    pub email: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ForgotPasswordPayload {
    pub email: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ResetPasswordPayload {
    pub token: String,
    pub new_password: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthPublicUser {
    pub id: String,
    pub email: String,
    pub username: Option<String>,
    pub name: String,
    pub role: String,
    pub status: Option<String>,
    pub email_verified_at: Option<String>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthSuccessResponse {
    pub token: String,
    pub user: AuthPublicUser,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthChallengeResponse {
    pub challenge_required: bool,
    pub challenge_id: String,
    pub message: String,
    pub expires_at: String,
    pub resend_available_at: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MeResponse {
    pub authenticated: bool,
    pub user: Option<AuthPublicUser>,
}

#[derive(Debug, Clone)]
pub(super) struct LoginContext {
    pub(super) ip_address: Option<String>,
    pub(super) user_agent: Option<String>,
    pub(super) user_agent_family: Option<String>,
    pub(super) timezone: Option<String>,
    pub(super) language: Option<String>,
    pub(super) country: Option<String>,
    pub(super) region: Option<String>,
    pub(super) lat: Option<f64>,
    pub(super) lon: Option<f64>,
}

#[derive(Debug, Clone)]
pub(super) struct TrustedDeviceRecord {
    pub(super) last_seen_at: chrono::DateTime<Utc>,
    pub(super) trust_expires_at: chrono::DateTime<Utc>,
    pub(super) user_agent_family: Option<String>,
    pub(super) last_timezone: Option<String>,
    pub(super) last_language: Option<String>,
}

#[derive(Debug)]
pub(super) struct RiskDecision {
    pub(super) score: i64,
    pub(super) reasons: Vec<String>,
    pub(super) hard_trigger: bool,
}

#[derive(Debug)]
pub(super) enum IpReputation {
    Good,
    Bad(String),
    Unknown,
}
