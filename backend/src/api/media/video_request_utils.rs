use actix_web::HttpRequest;

use super::video_logic_support::{HeadlessMotionProfile, MotionManifestV1};

pub fn extract_auth_token(req: &HttpRequest) -> Option<String> {
    if let Some(header) = req.headers().get(actix_web::http::header::AUTHORIZATION)
        && let Ok(header_str) = header.to_str()
        && let Some(token) = header_str.strip_prefix("Bearer ")
    {
        return Some(token.to_string());
    }

    req.cookie("auth_token")
        .map(|cookie| cookie.value().to_string())
}

pub fn parse_motion_profile(raw: &[u8]) -> Option<HeadlessMotionProfile> {
    serde_json::from_slice::<HeadlessMotionProfile>(raw).ok()
}

pub fn parse_motion_manifest(raw: &[u8]) -> Option<MotionManifestV1> {
    serde_json::from_slice::<MotionManifestV1>(raw).ok()
}

pub fn validate_motion_manifest(manifest: &MotionManifestV1) -> Result<(), String> {
    if manifest.version != "motion-spec-v1" {
        return Err(format!(
            "Unsupported manifest version: {}",
            manifest.version
        ));
    }
    if manifest.fps == 0 || manifest.fps > 120 {
        return Err(format!("Invalid FPS: {}", manifest.fps));
    }
    if manifest.shots.is_empty() {
        return Err("Manifest must contain at least one shot".into());
    }
    Ok(())
}
