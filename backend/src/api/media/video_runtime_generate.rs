#[path = "video_runtime_browser.rs"]
mod video_runtime_browser;
#[path = "video_runtime_process.rs"]
mod video_runtime_process;

use crate::api::media::video_logic::TeaserOutputFormat;
use crate::api::media::video_logic_support::{HeadlessMotionProfile, MotionManifestV1};
use serde_json::Value;

pub fn generate_teaser_sync(
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
    let runtime = video_runtime_browser::prepare_runtime(
        project_data,
        session_id,
        width,
        height,
        auth_token,
        motion_profile,
        motion_manifest,
    )?;
    let mut ffmpeg =
        video_runtime_process::spawn_ffmpeg(output_format, &output_str, &runtime.session_id)?;
    let stats = video_runtime_process::capture_teaser_frames(
        &runtime.tab,
        &runtime.session_id,
        duration_limit,
        output_format,
        &mut ffmpeg.stdin,
        &runtime.capture_viewport,
    )?;

    drop(ffmpeg.stdin);
    video_runtime_process::wait_for_ffmpeg(&mut ffmpeg.guard)?;
    video_runtime_process::log_capture_stats(&runtime.session_id, &stats);

    Ok(())
}
