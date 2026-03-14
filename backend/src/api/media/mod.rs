pub mod image;
pub mod image_logic;
pub mod image_multipart;
pub mod image_tasks;
pub mod serve;
pub mod similarity;
#[cfg(feature = "video-export")]
pub mod video;
#[cfg(feature = "video-export")]
mod video_capture;
#[cfg(feature = "video-export")]
pub mod video_logic;
#[cfg(feature = "video-export")]
mod video_logic_runtime;
#[cfg(feature = "video-export")]
mod video_logic_support;
#[cfg(feature = "video-export")]
mod video_request_utils;

pub use image::*;
pub use serve::*;
pub use similarity::*;
#[cfg(feature = "video-export")]
pub use video::*;

#[cfg(not(feature = "video-export"))]
use actix_multipart::Multipart;
#[cfg(not(feature = "video-export"))]
use actix_web::{HttpRequest, HttpResponse};
#[cfg(not(feature = "video-export"))]
use crate::models::AppError;

#[cfg(not(feature = "video-export"))]
pub async fn generate_teaser(
    _req: HttpRequest,
    _payload: Multipart,
) -> Result<HttpResponse, AppError> {
    Err(AppError::NotImplemented(
        "Teaser generation is disabled in this build.".into(),
    ))
}
