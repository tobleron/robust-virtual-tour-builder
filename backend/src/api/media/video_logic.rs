use super::video_logic_runtime;
use super::video_logic_support::{HeadlessMotionProfile, MotionManifestV1};
use serde_json::Value;
use std::path::PathBuf;
use std::time::Duration;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TeaserOutputFormat {
    Webm,
    Mp4,
}

pub(crate) const TEASER_OUTPUT_FPS: f64 = 60.0;

impl TeaserOutputFormat {
    pub fn from_str(raw: &str) -> Self {
        match raw.to_ascii_lowercase().as_str() {
            "mp4" => Self::Mp4,
            _ => Self::Webm,
        }
    }

    pub fn extension(self) -> &'static str {
        match self {
            Self::Webm => "webm",
            Self::Mp4 => "mp4",
        }
    }

    pub fn content_type(self) -> &'static str {
        match self {
            Self::Webm => "video/webm",
            Self::Mp4 => "video/mp4",
        }
    }
}

pub(crate) struct KillOnDrop(Option<std::process::Child>);

impl KillOnDrop {
    pub(crate) fn new(child: std::process::Child) -> Self {
        Self(Some(child))
    }

    pub(crate) fn take(&mut self) -> Option<std::process::Child> {
        self.0.take()
    }
}

impl Drop for KillOnDrop {
    fn drop(&mut self) {
        if let Some(mut child) = self.0.take() {
            let _ = child.kill();
            let _ = child.wait();
        }
    }
}

pub async fn transcode_video(input_str: String, output_str: String) -> Result<PathBuf, String> {
    let ffmpeg_cmd = get_ffmpeg_command()?;
    let mut cmd = tokio::process::Command::new(&ffmpeg_cmd);
    cmd.args([
        "-y",
        "-i",
        &input_str,
        "-c:v",
        "libx264",
        "-preset",
        "medium",
        "-crf",
        "23",
        "-c:a",
        "aac",
        &output_str,
    ])
    .stdout(std::process::Stdio::piped())
    .stderr(std::process::Stdio::piped())
    .kill_on_drop(true);

    let child = cmd
        .spawn()
        .map_err(|e| format!("Failed to spawn ffmpeg: {}", e))?;

    let timeout_duration = Duration::from_secs(120);
    match tokio::time::timeout(timeout_duration, child.wait_with_output()).await {
        Ok(Ok(output)) => {
            if !output.status.success() {
                return Err(format!(
                    "FFmpeg exited with code {}: {}",
                    output.status.code().unwrap_or(-1),
                    String::from_utf8_lossy(&output.stderr)
                ));
            }
        }
        Ok(Err(e)) => return Err(format!("FFmpeg wait failed: {}", e)),
        Err(_) => {
            return Err("FFmpeg timed out".to_string());
        }
    }

    let _ = tokio::fs::remove_file(&input_str).await;
    Ok(PathBuf::from(output_str))
}

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
    video_logic_runtime::generate_teaser_sync_impl(
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

fn get_ffmpeg_command() -> Result<String, String> {
    super::video_logic_support::get_ffmpeg_command()
}

#[cfg(test)]
#[path = "video_logic_tests.rs"]
mod video_logic_tests;
