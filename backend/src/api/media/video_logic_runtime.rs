#[path = "video_runtime_impl.rs"]
mod video_runtime_impl;

use super::video_logic::TeaserOutputFormat;
use super::video_logic_support::{HeadlessMotionProfile, MotionManifestV1};
use serde_json::Value;

pub fn headless_backend_origin_impl() -> String {
    super::video_logic_support::headless_backend_origin()
}

pub fn generate_teaser_sync_impl(
    project_data: Value,
    session_id: String,
    width: u32,
    height: u32,
    output_str: String,
    duration_limit: u64,
    output_format: TeaserOutputFormat,
    auth_token: Option<String>,
    motion_profile: HeadlessMotionProfile,
    motion_manifest: Option<MotionManifestV1>,
) -> Result<(), String> {
    video_runtime_impl::generate_teaser_sync(
        project_data,
        session_id,
        width,
        height,
        output_str,
        duration_limit,
        output_format,
        auth_token,
        motion_profile,
        motion_manifest,
    )
}
