#[path = "video_capture_cdp.rs"]
mod video_capture_cdp;
#[path = "video_capture_polling.rs"]
mod video_capture_polling;

use headless_chrome::{Tab, protocol::cdp::Page};
use std::process::ChildStdin;
use std::time::{Duration, Instant};

use super::video_logic::{TEASER_OUTPUT_FPS, TeaserOutputFormat};

const TEASER_CAPTURE_JPEG_QUALITY: u32 = 92;
const CDP_FRAME_TIMEOUT_MS: u64 = 250;
const CDP_FRAME_STALL_MS: u64 = 2500;
const CDP_LATE_FRAME_FACTOR: f64 = 1.5;

pub(super) struct CaptureStats {
    pub mode: &'static str,
    pub duration_s: f64,
    pub emitted_frames: u64,
    pub captured_frames: u64,
    pub duplicated_frames: u64,
    pub dropped_frames: u64,
    pub late_frames: u64,
    pub emitted_fps: f64,
    pub captured_fps: f64,
}

pub(super) struct CaptureFailure {
    pub message: String,
    pub emitted_frames: u64,
}

pub(super) fn start_script_content(format: TeaserOutputFormat) -> &'static str {
    match format {
        TeaserOutputFormat::Mp4 => "window.startHeadlessTeaser(true,'mp4',false)",
        TeaserOutputFormat::Webm => "window.startHeadlessTeaser(true,'webm',false)",
    }
}

pub(super) fn capture_frames_cdp(
    tab: &Tab,
    _session_id: &str,
    start_sim: Instant,
    max_dur: Duration,
    stdin: &mut ChildStdin,
    capture_viewport: &Page::Viewport,
) -> Result<CaptureStats, CaptureFailure> {
    video_capture_cdp::capture_frames_cdp(
        tab,
        _session_id,
        start_sim,
        max_dur,
        stdin,
        capture_viewport,
    )
}

pub(super) fn capture_frames_polling(
    tab: &Tab,
    session_id: &str,
    start_sim: Instant,
    max_dur: Duration,
    stdin: &mut ChildStdin,
    capture_viewport: &Page::Viewport,
) -> Result<CaptureStats, String> {
    video_capture_polling::capture_frames_polling(
        tab,
        session_id,
        start_sim,
        max_dur,
        stdin,
        capture_viewport,
    )
}
