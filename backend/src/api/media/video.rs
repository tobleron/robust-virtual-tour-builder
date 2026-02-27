/* backend/src/api/media/video.rs - Consolidated Video API */

use actix_multipart::Multipart;
use actix_web::{HttpRequest, HttpResponse, web};
use futures_util::TryStreamExt as _;
use tokio::io::{AsyncWriteExt, BufWriter};
use uuid::Uuid;

use crate::api::media::video_logic;
use crate::api::media::video_logic_support::{HeadlessMotionProfile, MotionManifestV1};
use crate::api::media::video_request_utils;
use crate::api::utils::{MAX_UPLOAD_SIZE, TEMP_DIR, get_temp_path_async, sanitize_filename};
use crate::models::AppError;

// --- HANDLERS ---

fn extract_auth_token(req: &HttpRequest) -> Option<String> {
    video_request_utils::extract_auth_token(req)
}

fn parse_motion_profile(raw: &[u8]) -> Option<HeadlessMotionProfile> {
    video_request_utils::parse_motion_profile(raw)
}

fn parse_motion_manifest(raw: &[u8]) -> Option<MotionManifestV1> {
    video_request_utils::parse_motion_manifest(raw)
}

fn validate_motion_manifest(manifest: &MotionManifestV1) -> Result<(), String> {
    video_request_utils::validate_motion_manifest(manifest)
}

/// Generates a cinematic teaser video of the virtual tour.
#[tracing::instrument(skip(payload), name = "generate_teaser")]
pub async fn generate_teaser(
    req: HttpRequest,
    mut payload: Multipart,
) -> Result<HttpResponse, AppError> {
    let session_id = Uuid::new_v4().to_string();
    let session_path = std::path::PathBuf::from(TEMP_DIR).join(&session_id);
    tokio::fs::create_dir_all(&session_path)
        .await
        .map_err(AppError::IoError)?;

    tracing::info!(module = "TeaserGenerator", session_id = %session_id, "TEASER_GENERATION_START");

    let mut project_data_value: Option<serde_json::Value> = None;
    let mut width = 1920;
    let mut height = 1080;
    let mut output_format = video_logic::TeaserOutputFormat::Webm;
    let mut motion_profile = HeadlessMotionProfile::default();
    let mut motion_manifest = None;
    let mut render_engine = "frontend_webm".to_string();
    let duration_limit = 120;

    while let Some(mut field) = payload.try_next().await? {
        let content_disposition =
            field
                .content_disposition()
                .cloned()
                .ok_or(AppError::InternalError(
                    "Missing content disposition".into(),
                ))?;
        let name = content_disposition.get_name().unwrap_or("").to_string();

        if name == "project_data" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            project_data_value = serde_json::from_slice(&bytes).ok();
        } else if name == "width" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            if let Ok(s) = String::from_utf8(bytes)
                && let Ok(val) = s.parse::<u32>()
            {
                width = val;
            }
        } else if name == "height" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            if let Ok(s) = String::from_utf8(bytes)
                && let Ok(val) = s.parse::<u32>()
            {
                height = val;
            }
        } else if name == "format" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            if let Ok(s) = String::from_utf8(bytes) {
                output_format = video_logic::TeaserOutputFormat::from_str(s.trim());
            }
        } else if name == "render_engine" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            if let Ok(s) = String::from_utf8(bytes) {
                render_engine = s.trim().to_string();
            }
        } else if name == "files" {
            let filename = content_disposition
                .get_filename()
                .map(|f| f.to_string())
                .unwrap_or_else(|| format!("img_{}.webp", Uuid::new_v4()));
            let sanitized = sanitize_filename(&filename).unwrap_or(filename);
            let file_path = session_path.join(&sanitized);
            let f = tokio::fs::File::create(file_path)
                .await
                .map_err(AppError::IoError)?;
            let mut writer = BufWriter::new(f);
            while let Some(chunk) = field.try_next().await? {
                writer.write_all(&chunk).await.map_err(AppError::IoError)?;
            }
            writer.flush().await.map_err(AppError::IoError)?;
        } else if name == "motion_profile" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            if let Some(decoded) = parse_motion_profile(&bytes) {
                motion_profile = decoded;
            }
        } else if name == "motion_manifest" {
            let mut bytes = Vec::new();
            while let Some(chunk) = field.try_next().await? {
                bytes.extend_from_slice(&chunk);
            }
            if let Some(decoded) = parse_motion_manifest(&bytes) {
                if let Err(e) = validate_motion_manifest(&decoded) {
                    tracing::warn!(module = "TeaserGenerator", error = %e, "MOTION_MANIFEST_VALIDATION_FAILED");
                    return Err(AppError::ValidationError(format!(
                        "Invalid motion manifest: {}",
                        e
                    )));
                } else {
                    tracing::info!(
                        module = "TeaserGenerator",
                        "MOTION_MANIFEST_VALIDATION_SUCCESS"
                    );
                }
                motion_manifest = Some(decoded);
            }
        }
    }

    tracing::info!(
        module = "TeaserGenerator",
        session_id = %session_id,
        render_engine = %render_engine,
        "TEASER_REQUEST_PARSED"
    );

    if render_engine == "backend_mp4" {
        return Err(AppError::NotImplemented(
            "Backend MP4 rendering engine is not yet implemented".into(),
        ));
    }

    let project_data = project_data_value
        .ok_or_else(|| AppError::InternalError("Missing project_data JSON".into()))?;
    let output_path = get_temp_path_async(output_format.extension()).await;
    let output_str = output_path.to_string_lossy().to_string();
    let session_id_clone = session_id.clone();
    let auth_token = extract_auth_token(&req);

    let result = web::block(move || {
        video_logic::generate_teaser_sync(
            project_data,
            session_id_clone,
            width,
            height,
            output_str,
            duration_limit as u64,
            output_format,
            auth_token,
            motion_profile,
            motion_manifest,
        )
    })
    .await
    .map_err(|e| AppError::InternalError(e.to_string()))?;

    let _ = tokio::fs::remove_dir_all(&session_path).await;

    match result {
        Ok(_) => {
            tracing::info!(module = "TeaserGenerator", "TEASER_GENERATION_COMPLETE");
            let file_bytes = tokio::fs::read(&output_path)
                .await
                .map_err(AppError::IoError)?;
            let _ = tokio::fs::remove_file(output_path).await;
            Ok(HttpResponse::Ok()
                .content_type(output_format.content_type())
                .body(file_bytes))
        }
        Err(e) => {
            let _ = tokio::fs::remove_file(&output_path).await;
            Err(AppError::InternalError(e))
        }
    }
}

/// Transcodes an uploaded video file to MP4.
#[tracing::instrument(skip(payload), name = "transcode_video")]
pub async fn transcode_video(mut payload: Multipart) -> Result<HttpResponse, AppError> {
    let input_path = get_temp_path_async("webm").await;
    let mut total_size = 0;

    while let Some(mut field) = payload.try_next().await? {
        let content_disposition = field
            .content_disposition()
            .ok_or_else(|| AppError::InternalError("Missing content disposition".to_string()))?;
        if content_disposition.get_name() == Some("file") {
            let f = tokio::fs::File::create(&input_path)
                .await
                .map_err(AppError::IoError)?;
            let mut writer = BufWriter::new(f);
            while let Some(chunk) = field.try_next().await? {
                total_size += chunk.len();
                if total_size > MAX_UPLOAD_SIZE {
                    drop(writer); // Drop writer to close file handle before removing
                    let _ = tokio::fs::remove_file(&input_path).await;
                    return Err(AppError::ImageError(format!(
                        "Video upload exceeds maximum size of {}MB",
                        MAX_UPLOAD_SIZE / (1024 * 1024)
                    )));
                }
                writer.write_all(&chunk).await.map_err(AppError::IoError)?;
            }
            writer.flush().await.map_err(AppError::IoError)?;
        }
    }

    let output_path = get_temp_path_async("mp4").await;
    let input_str = input_path.to_string_lossy().to_string();
    let output_str = output_path.to_string_lossy().to_string();

    tracing::info!(module = "VideoEncoder", input = %input_str, output = %output_str, "TRANSCODE_START");

    let result = video_logic::transcode_video(input_str, output_str).await;

    match result {
        Ok(path) => {
            tracing::info!(module = "VideoEncoder", "TRANSCODE_COMPLETE");
            let file_bytes = tokio::fs::read(&path).await.map_err(AppError::IoError)?;
            let _ = tokio::fs::remove_file(path).await;
            Ok(HttpResponse::Ok()
                .content_type("video/mp4")
                .body(file_bytes))
        }
        Err(e) => {
            let _ = tokio::fs::remove_file(&input_path).await;
            Err(AppError::FFmpegError(e))
        }
    }
}

#[cfg(test)]
#[path = "video_tests.rs"]
mod video_tests;
