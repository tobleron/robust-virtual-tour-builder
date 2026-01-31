// backend/src/models.rs - Consolidated Backend Models

use actix_web::{HttpResponse, ResponseError};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use std::fmt;

// --- ERROR MODELS ---

#[derive(Debug, Serialize, Deserialize)]
pub struct ErrorResponse {
    pub error: String,
    pub details: Option<String>,
}

#[derive(Debug)]
pub enum AppError {
    IoError(std::io::Error),
    MultipartError(String),
    ImageError(String),
    FFmpegError(String),
    ZipError(String),
    InternalError(String),
    #[allow(dead_code)]
    ValidationError(String),
    Unauthorized(String),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AppError::IoError(e) => write!(f, "IO Error: {}", e),
            AppError::MultipartError(e) => write!(f, "Multipart Error: {}", e),
            AppError::ImageError(e) => write!(f, "Image Processing Error: {}", e),
            AppError::FFmpegError(e) => write!(f, "FFmpeg Error: {}", e),
            AppError::ZipError(e) => write!(f, "Zip Error: {}", e),
            AppError::InternalError(e) => write!(f, "Internal Error: {}", e),
            AppError::ValidationError(e) => write!(f, "Validation Error: {}", e),
            AppError::Unauthorized(e) => write!(f, "Unauthorized: {}", e),
        }
    }
}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        let (status, msg, details) = match self {
            AppError::IoError(e) => (
                actix_web::http::StatusCode::INTERNAL_SERVER_ERROR,
                "File System Error",
                Some(e.to_string()),
            ),
            AppError::MultipartError(e) => (
                actix_web::http::StatusCode::BAD_REQUEST,
                "Upload Error",
                Some(e.to_string()),
            ),
            AppError::ImageError(e) => (
                actix_web::http::StatusCode::BAD_REQUEST,
                "Image Processing Failed",
                Some(e.clone()),
            ),
            AppError::FFmpegError(e) => (
                actix_web::http::StatusCode::INTERNAL_SERVER_ERROR,
                "Video Encoding Failed",
                Some(e.clone()),
            ),
            AppError::ZipError(e) => (
                actix_web::http::StatusCode::INTERNAL_SERVER_ERROR,
                "Zip Compression Failed",
                Some(e.clone()),
            ),
            AppError::InternalError(e) => (
                actix_web::http::StatusCode::INTERNAL_SERVER_ERROR,
                "Internal Server Error",
                Some(e.clone()),
            ),
            AppError::ValidationError(e) => (
                actix_web::http::StatusCode::BAD_REQUEST,
                "Validation Error",
                Some(e.clone()),
            ),
            AppError::Unauthorized(e) => (
                actix_web::http::StatusCode::UNAUTHORIZED,
                "Unauthorized",
                Some(e.clone()),
            ),
        };

        tracing::error!(
            module = "ErrorHandler",
            error_type = msg,
            details = %self,
            status_code = status.as_u16(),
            "REQUEST_FAILED"
        );

        HttpResponse::build(status).json(ErrorResponse {
            error: msg.to_string(),
            details,
        })
    }
}

impl From<std::io::Error> for AppError {
    fn from(err: std::io::Error) -> Self {
        AppError::IoError(err)
    }
}
impl From<actix_multipart::MultipartError> for AppError {
    fn from(err: actix_multipart::MultipartError) -> Self {
        AppError::MultipartError(err.to_string())
    }
}
impl From<zip::result::ZipError> for AppError {
    fn from(err: zip::result::ZipError) -> Self {
        AppError::ZipError(err.to_string())
    }
}
impl From<String> for AppError {
    fn from(err: String) -> Self {
        AppError::InternalError(err)
    }
}

// --- GEOCODING MODELS ---

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GeocodeRequest {
    pub lat: f64,
    pub lon: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GeocodeResponse {
    pub address: String,
}

pub type GeocodeKey = (i32, i32);

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CachedGeocode {
    pub address: String,
    pub last_accessed: u64,
    pub access_count: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct CacheStats {
    pub hits: u64,
    pub misses: u64,
    pub evictions: u64,
    pub last_save: Option<u64>,
}

// --- METADATA MODELS ---

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GpsData {
    pub lat: f64,
    pub lon: f64,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ExifMetadata {
    pub make: Option<String>,
    pub model: Option<String>,
    pub date_time: Option<String>,
    pub gps: Option<GpsData>,
    pub width: u32,
    pub height: u32,
    pub focal_length: Option<f32>,
    pub aperture: Option<f32>,
    pub iso: Option<u32>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct QualityStats {
    pub avg_luminance: u32,
    pub black_clipping: f32,
    pub white_clipping: f32,
    pub sharpness_variance: u32,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ColorHist {
    pub r: Vec<u32>,
    pub g: Vec<u32>,
    pub b: Vec<u32>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct QualityAnalysis {
    pub score: f32,
    pub histogram: Vec<u32>,
    pub color_hist: ColorHist,
    pub stats: QualityStats,
    pub is_blurry: bool,
    pub is_soft: bool,
    pub is_severely_dark: bool,
    pub is_severely_bright: bool,
    pub is_dim: bool,
    pub has_black_clipping: bool,
    pub has_white_clipping: bool,
    pub issues: u32,
    pub warnings: u32,
    pub analysis: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct MetadataResponse {
    pub exif: ExifMetadata,
    pub quality: QualityAnalysis,
    pub is_optimized: bool,
    pub checksum: String,
    pub suggested_name: Option<String>,
}

// --- PROJECT MODELS ---

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize, Clone, sqlx::Type)]
#[serde(rename_all = "lowercase")]
pub enum ProjectStatus {
    Draft,
    Published,
    Archived,
}

impl From<String> for ProjectStatus {
    fn from(s: String) -> Self {
        match s.as_str() {
            "published" => ProjectStatus::Published,
            "archived" => ProjectStatus::Archived,
            _ => ProjectStatus::Draft,
        }
    }
}

impl ToString for ProjectStatus {
    fn to_string(&self) -> String {
        match self {
            ProjectStatus::Draft => "draft".to_string(),
            ProjectStatus::Published => "published".to_string(),
            ProjectStatus::Archived => "archived".to_string(),
        }
    }
}

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Project {
    pub id: String,
    pub user_id: String,
    pub name: String,
    pub data: String,
    pub status: String,
    pub scene_count: i64,
    pub hotspot_count: i64,
    pub updated_at: DateTime<Utc>,
}

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProjectSyncRequest {
    pub project_id: Option<String>,
    pub name: String,
    pub status: String,
    pub data: serde_json::Value,
    pub scene_count: Option<i64>,
    pub hotspot_count: Option<i64>,
}

impl Project {
    #[allow(dead_code)]
    pub async fn create(
        pool: &sqlx::SqlitePool,
        user_id: &str,
        name: &str,
        data: &str,
        status: &str,
        scene_count: i64,
        hotspot_count: i64,
    ) -> Result<Project, sqlx::Error> {
        let id = uuid::Uuid::new_v4().to_string();
        let project = sqlx::query_as::<_, Project>(
            r#"
            INSERT INTO projects (id, user_id, name, data, status, scene_count, hotspot_count)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            RETURNING id, user_id, name, data, status, scene_count, hotspot_count, updated_at
            "#,
        )
        .bind(&id)
        .bind(user_id)
        .bind(name)
        .bind(data)
        .bind(status)
        .bind(scene_count)
        .bind(hotspot_count)
        .fetch_one(pool)
        .await?;
        Ok(project)
    }
}

// --- SESSION MODELS ---

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Session {
    pub id: String,
    pub user_id: String,
    pub expires_at: DateTime<Utc>,
}

impl Session {
    #[allow(dead_code)]
    pub async fn create(
        pool: &sqlx::SqlitePool,
        user_id: &str,
        expires_at: DateTime<Utc>,
    ) -> Result<Session, sqlx::Error> {
        let id = uuid::Uuid::new_v4().to_string();
        let session = sqlx::query_as::<_, Session>(
            r#"
            INSERT INTO sessions (id, user_id, expires_at)
            VALUES (?, ?, ?)
            RETURNING id, user_id, expires_at
            "#,
        )
        .bind(&id)
        .bind(user_id)
        .bind(expires_at)
        .fetch_one(pool)
        .await?;
        Ok(session)
    }
}

// --- SIMILARITY MODELS ---

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ColorHistogram {
    pub r: Vec<f32>,
    pub g: Vec<f32>,
    pub b: Vec<f32>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct HistogramData {
    pub histogram: Option<Vec<f32>>,
    pub color_hist: Option<ColorHistogram>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SimilarityPair {
    pub id_a: String,
    pub id_b: String,
    pub histogram_a: HistogramData,
    pub histogram_b: HistogramData,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SimilarityRequest {
    pub pairs: Vec<SimilarityPair>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SimilarityResult {
    pub id_a: String,
    pub id_b: String,
    pub similarity: f32,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SimilarityResponse {
    pub results: Vec<SimilarityResult>,
    pub duration_ms: u128,
}

// --- TELEMETRY MODELS ---

#[derive(Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum TelemetryPriority {
    Critical,
    High,
    Medium,
    Low,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TelemetryEntry {
    pub level: String,
    pub module: String,
    pub message: String,
    pub data: Option<serde_json::Value>,
    pub timestamp: String,
    pub priority: TelemetryPriority,
    #[serde(default)]
    pub request_id: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TelemetryBatch {
    pub entries: Vec<TelemetryEntry>,
}

// --- USER MODELS ---

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct User {
    pub id: String,
    pub email: String,
    #[serde(skip)]
    #[allow(dead_code)]
    pub password_hash: String,
    pub name: String,
    pub theme_preference: Option<String>,
    pub language_preference: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[allow(dead_code)]
#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthResponse {
    pub token: String,
    pub user: User,
}

impl User {
    #[allow(dead_code)]
    pub async fn create(
        pool: &sqlx::SqlitePool,
        email: &str,
        password_hash: &str,
        name: &str,
    ) -> Result<User, sqlx::Error> {
        let id = uuid::Uuid::new_v4().to_string();
        let user = sqlx::query_as::<_, User>(
            r#"
            INSERT INTO users (id, email, password_hash, name)
            VALUES (?, ?, ?, ?)
            RETURNING id, email, password_hash, name, theme_preference, language_preference, created_at
            "#
        )
        .bind(&id)
        .bind(email)
        .bind(password_hash)
        .bind(name)
        .fetch_one(pool)
        .await?;

        Ok(user)
    }

    #[allow(dead_code)]
    pub async fn find_by_email(
        pool: &sqlx::SqlitePool,
        email: &str,
    ) -> Result<Option<User>, sqlx::Error> {
        sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = ?")
            .bind(email)
            .fetch_optional(pool)
            .await
    }
}

// --- VALIDATION MODELS ---

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ValidationReport {
    pub broken_links_removed: u32,
    pub orphaned_scenes: Vec<String>,
    pub unused_files: Vec<String>,
    pub warnings: Vec<String>,
    pub errors: Vec<String>,
}

impl Default for ValidationReport {
    fn default() -> Self {
        Self::new()
    }
}

impl ValidationReport {
    pub fn new() -> Self {
        ValidationReport {
            broken_links_removed: 0,
            orphaned_scenes: Vec::new(),
            unused_files: Vec::new(),
            warnings: Vec::new(),
            errors: Vec::new(),
        }
    }

    pub fn has_issues(&self) -> bool {
        self.broken_links_removed > 0
            || !self.orphaned_scenes.is_empty()
            || !self.unused_files.is_empty()
            || !self.errors.is_empty()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::ResponseError;

    #[test]
    fn test_app_error_response_format() {
        let err = AppError::ValidationError("test message".to_string());
        let resp = err.error_response();
        assert_eq!(resp.status(), actix_web::http::StatusCode::BAD_REQUEST);
    }
}
