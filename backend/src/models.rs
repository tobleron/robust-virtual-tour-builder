// backend/src/models.rs - Consolidated Backend Models

use actix_web::{HttpResponse, ResponseError};
use serde::{Deserialize, Serialize};
use std::fmt;

#[path = "models_common.rs"]
mod models_common;
#[path = "models_identity.rs"]
mod models_identity;
#[path = "models_project_session.rs"]
mod models_project_session;

#[allow(unused_imports)]
pub use models_common::{
    CacheStats, CachedGeocode, ColorHist, ColorHistogram, ExifMetadata, GeocodeKey, GeocodeRequest,
    GeocodeResponse, GpsData, HistogramData, MetadataResponse, QualityAnalysis, QualityStats,
    SimilarityPair, SimilarityRequest, SimilarityResponse, SimilarityResult, TelemetryBatch,
    TelemetryEntry, TelemetryPriority,
};
#[allow(unused_imports)]
pub use models_identity::{AuthResponse, User};
#[allow(unused_imports)]
pub use models_project_session::{Project, ProjectStatus, ProjectSyncRequest, Session};

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
    NotImplemented(String),
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
            AppError::NotImplemented(e) => write!(f, "Not Implemented: {}", e),
            AppError::ValidationError(e) => write!(f, "Validation Error: {}", e),
            AppError::Unauthorized(e) => write!(f, "Unauthorized: {}", e),
        }
    }
}

impl std::error::Error for AppError {}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        let (status, msg, details) = match self {
            AppError::IoError(e) => {
                let status = if e.kind() == std::io::ErrorKind::InvalidInput {
                    actix_web::http::StatusCode::BAD_REQUEST
                } else {
                    actix_web::http::StatusCode::INTERNAL_SERVER_ERROR
                };
                (status, "File System Error", Some(e.to_string()))
            }
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
            AppError::NotImplemented(e) => (
                actix_web::http::StatusCode::NOT_IMPLEMENTED,
                "Not Implemented",
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
        models_project_session::create_project(
            pool,
            user_id,
            name,
            data,
            status,
            scene_count,
            hotspot_count,
        )
        .await
    }
}

impl Session {
    #[allow(dead_code)]
    pub async fn create(
        pool: &sqlx::SqlitePool,
        user_id: &str,
        expires_at: chrono::DateTime<chrono::Utc>,
    ) -> Result<Session, sqlx::Error> {
        models_project_session::create_session(pool, user_id, expires_at).await
    }
}

impl User {
    #[allow(dead_code)]
    pub async fn create(
        pool: &sqlx::SqlitePool,
        email: &str,
        username: &str,
        password_hash: &str,
        name: &str,
        role: &str,
    ) -> Result<User, sqlx::Error> {
        models_identity::create_user(pool, email, username, password_hash, name, role).await
    }

    #[allow(dead_code)]
    pub async fn find_by_email(
        pool: &sqlx::SqlitePool,
        email: &str,
    ) -> Result<Option<User>, sqlx::Error> {
        models_identity::find_user_by_email(pool, email).await
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
