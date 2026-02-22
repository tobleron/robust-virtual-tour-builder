/* backend/src/api/media/video.rs - Consolidated Video API */

use actix_multipart::Multipart;
use actix_web::{HttpRequest, HttpResponse, web};
use futures_util::TryStreamExt as _;
use tokio::io::{AsyncWriteExt, BufWriter};
use uuid::Uuid;

use crate::api::media::video_logic;
use crate::api::media::video_logic_support::{HeadlessMotionProfile, MotionManifestV1};
use crate::api::utils::{MAX_UPLOAD_SIZE, TEMP_DIR, get_temp_path_async, sanitize_filename};
use crate::models::AppError;

// --- HANDLERS ---

fn extract_auth_token(req: &HttpRequest) -> Option<String> {
    if let Some(header) = req.headers().get(actix_web::http::header::AUTHORIZATION)
        && let Ok(header_str) = header.to_str()
        && let Some(token) = header_str.strip_prefix("Bearer ")
    {
        return Some(token.to_string());
    }

    req.cookie("auth_token")
        .map(|cookie| cookie.value().to_string())
}

fn parse_motion_profile(raw: &[u8]) -> Option<HeadlessMotionProfile> {
    serde_json::from_slice::<HeadlessMotionProfile>(raw).ok()
}

fn parse_motion_manifest(raw: &[u8]) -> Option<MotionManifestV1> {
    serde_json::from_slice::<MotionManifestV1>(raw).ok()
}

fn validate_motion_manifest(manifest: &MotionManifestV1) -> Result<(), String> {
    if manifest.version != "motion-spec-v1" {
        return Err(format!("Unsupported manifest version: {}", manifest.version));
    }
    if manifest.fps == 0 || manifest.fps > 120 {
        return Err(format!("Invalid FPS: {}", manifest.fps));
    }
    if manifest.shots.is_empty() {
        return Err("Manifest must contain at least one shot".into());
    }
    Ok(())
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
                    return Err(AppError::ValidationError(format!("Invalid motion manifest: {}", e)));
                } else {
                    tracing::info!(module = "TeaserGenerator", "MOTION_MANIFEST_VALIDATION_SUCCESS");
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
        return Err(AppError::NotImplemented("Backend MP4 rendering engine is not yet implemented".into()));
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
mod tests {
    use super::*;
    use actix_web::http::header::{AUTHORIZATION, COOKIE};
    use actix_web::test::TestRequest;

    #[test]
    fn extract_auth_token_prefers_authorization_header() {
        let req = TestRequest::default()
            .insert_header((AUTHORIZATION, "Bearer header-token"))
            .insert_header((COOKIE, "auth_token=cookie-token"))
            .to_http_request();
        assert_eq!(extract_auth_token(&req), Some("header-token".to_string()));
    }

    #[test]
    fn extract_auth_token_falls_back_to_cookie() {
        let req = TestRequest::default()
            .insert_header((COOKIE, "auth_token=cookie-token"))
            .to_http_request();
        assert_eq!(extract_auth_token(&req), Some("cookie-token".to_string()));
    }

    #[test]
    fn parse_motion_profile_decodes_camel_case_payload() {
        let payload = br#"{"skipAutoForward":true,"startAtWaypoint":false,"includeIntroPan":true}"#;
        let parsed = parse_motion_profile(payload).expect("motion profile should parse");
        assert!(parsed.skip_auto_forward);
        assert!(!parsed.start_at_waypoint);
        assert!(parsed.include_intro_pan);
    }

    #[test]
    fn parse_motion_profile_rejects_invalid_payload() {
        let payload = br#"{"skipAutoForward":"yes","startAtWaypoint":true}"#;
        assert!(parse_motion_profile(payload).is_none());
    }

    #[test]
    fn parse_motion_manifest_decodes_valid_payload() {
        let payload = br#"{
            "version": "motion-spec-v1",
            "fps": 60,
            "canvasWidth": 1920,
            "canvasHeight": 1080,
            "includeIntroPan": false,
            "shots": [
                {
                    "sceneId": "s1",
                    "arrivalPose": {"yaw": 0.0, "pitch": 0.0, "hfov": 90.0},
                    "animationSegments": [
                        {
                            "startYaw": 0.0, "endYaw": 10.0,
                            "startPitch": 0.0, "endPitch": 0.0,
                            "startHfov": 90.0, "endHfov": 90.0,
                            "easing": "linear",
                            "durationMs": 1000
                        }
                    ],
                    "transitionOut": {"type": "crossfade", "durationMs": 500}
                }
            ]
        }"#;
        let parsed = parse_motion_manifest(payload).expect("motion manifest should parse");
        assert_eq!(parsed.version, "motion-spec-v1");
        assert_eq!(parsed.shots.len(), 1);
        assert_eq!(parsed.shots[0].scene_id, "s1");
    }

    #[test]
    fn validate_motion_manifest_rejects_invalid_version() {
        let manifest = crate::api::media::video_logic_support::MotionManifestV1 {
            version: "v2".into(),
            fps: 60,
            canvas_width: 1920,
            canvas_height: 1080,
            include_intro_pan: false,
            shots: vec![],
        };
        assert!(validate_motion_manifest(&manifest).is_err());
    }

    #[test]
    fn validate_motion_manifest_rejects_invalid_fps() {
        let manifest_zero = crate::api::media::video_logic_support::MotionManifestV1 {
            version: "motion-spec-v1".into(),
            fps: 0,
            canvas_width: 1920,
            canvas_height: 1080,
            include_intro_pan: false,
            shots: vec![],
        };
        assert!(validate_motion_manifest(&manifest_zero).is_err());

        let manifest_high = crate::api::media::video_logic_support::MotionManifestV1 {
            version: "motion-spec-v1".into(),
            fps: 144,
            canvas_width: 1920,
            canvas_height: 1080,
            include_intro_pan: false,
            shots: vec![],
        };
        assert!(validate_motion_manifest(&manifest_high).is_err());
    }

    #[test]
    fn validate_motion_manifest_rejects_empty_shots() {
        let manifest = crate::api::media::video_logic_support::MotionManifestV1 {
            version: "motion-spec-v1".into(),
            fps: 30,
            canvas_width: 1920,
            canvas_height: 1080,
            include_intro_pan: false,
            shots: vec![],
        };
        assert!(validate_motion_manifest(&manifest).is_err());
    }

    #[test]
    fn validate_motion_manifest_accepts_valid_manifest() {
        let manifest = crate::api::media::video_logic_support::MotionManifestV1 {
            version: "motion-spec-v1".into(),
            fps: 60,
            canvas_width: 1920,
            canvas_height: 1080,
            include_intro_pan: false,
            shots: vec![crate::api::media::video_logic_support::MotionShot {
                scene_id: "s1".into(),
                arrival_pose: crate::api::media::video_logic_support::ArrivalPose {
                    yaw: 0.0,
                    pitch: 0.0,
                    hfov: 90.0,
                },
                animation_segments: vec![],
                transition_out: None,
            }],
        };
        assert!(validate_motion_manifest(&manifest).is_ok());
    }
}
