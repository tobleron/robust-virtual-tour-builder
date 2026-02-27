#[path = "video_runtime_impl.rs"]
mod video_runtime_impl;

use super::video_capture;
use super::video_logic::TeaserOutputFormat;
use super::video_logic_support::{HeadlessMotionProfile, MotionManifestV1};
use headless_chrome::{Tab, protocol::cdp::Page};
use serde_json::Value;
use std::time::Duration;

type CaptureStats = video_capture::CaptureStats;
type CaptureFailure = video_capture::CaptureFailure;

pub fn headless_backend_origin_impl() -> String {
    super::video_logic_support::headless_backend_origin()
}

pub fn apply_capture_mode_impl(tab: &Tab, session_id: &str) -> Result<(), String> {
    video_runtime_impl::apply_capture_mode(tab, session_id)
}

pub fn resolve_capture_viewport_impl(tab: &Tab, session_id: &str) -> Result<Page::Viewport, String> {
    video_runtime_impl::resolve_capture_viewport(tab, session_id)
}

pub fn start_script_content_impl(format: TeaserOutputFormat) -> &'static str {
    video_capture::start_script_content(format)
}

pub fn capture_frames_cdp_impl(
    tab: &Tab,
    session_id: &str,
    start_sim: std::time::Instant,
    max_dur: Duration,
    stdin: &mut std::process::ChildStdin,
    capture_viewport: &Page::Viewport,
) -> Result<CaptureStats, CaptureFailure> {
    video_capture::capture_frames_cdp(tab, session_id, start_sim, max_dur, stdin, capture_viewport)
}

pub fn capture_frames_polling_impl(
    tab: &Tab,
    session_id: &str,
    start_sim: std::time::Instant,
    max_dur: Duration,
    stdin: &mut std::process::ChildStdin,
    capture_viewport: &Page::Viewport,
) -> Result<CaptureStats, String> {
    video_capture::capture_frames_polling(
        tab,
        session_id,
        start_sim,
        max_dur,
        stdin,
        capture_viewport,
    )
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
