use actix_web::{HttpResponse, ResponseError};
use serde::{Deserialize, Serialize};
use std::fmt;

#[derive(Debug, Serialize, Deserialize)]
pub struct ErrorResponse {
    pub error: String,
    pub details: Option<String>,
}

#[derive(Debug)]
pub enum AppError {
    IoError(std::io::Error),
    MultipartError(actix_multipart::MultipartError),
    ImageError(String),
    FFmpegError(String),
    ZipError(String),
    InternalError(String),
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
        AppError::MultipartError(err)
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
