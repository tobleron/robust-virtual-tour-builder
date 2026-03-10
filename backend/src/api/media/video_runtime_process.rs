use crate::api::media::video_capture::{self, CaptureStats};
use crate::api::media::video_logic::{KillOnDrop, TEASER_OUTPUT_FPS, TeaserOutputFormat};
use headless_chrome::{Tab, protocol::cdp::Page};
use std::process::{ChildStdin, Command, Stdio};
use std::time::{Duration, Instant};

pub(super) struct FfmpegCapture {
    pub stdin: ChildStdin,
    pub guard: KillOnDrop,
}

pub(super) fn spawn_ffmpeg(
    output_format: TeaserOutputFormat,
    output_str: &str,
    session_id: &str,
) -> Result<FfmpegCapture, String> {
    let ffmpeg_cmd = crate::api::media::video_logic_support::get_ffmpeg_command()?;
    let child_res = Command::new(&ffmpeg_cmd)
        .args(match output_format {
            TeaserOutputFormat::Mp4 => vec![
                "-y",
                "-f",
                "image2pipe",
                "-vcodec",
                "mjpeg",
                "-framerate",
                "60",
                "-i",
                "-",
                "-vf",
                "scale=trunc(iw/2)*2:trunc(ih/2)*2",
                "-c:v",
                "libx264",
                "-preset",
                "ultrafast",
                "-pix_fmt",
                "yuv420p",
                "-r",
                "60",
                "-movflags",
                "+faststart",
                output_str,
            ],
            TeaserOutputFormat::Webm => vec![
                "-y",
                "-f",
                "image2pipe",
                "-vcodec",
                "mjpeg",
                "-framerate",
                "60",
                "-i",
                "-",
                "-an",
                "-c:v",
                "libvpx-vp9",
                "-pix_fmt",
                "yuv420p",
                "-r",
                "60",
                "-deadline",
                "good",
                "-cpu-used",
                "2",
                "-crf",
                "30",
                "-b:v",
                "0",
                output_str,
            ],
        })
        .stdin(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn();

    let mut child = match child_res {
        Ok(c) => c,
        Err(e) => {
            tracing::error!(session_id=%session_id, stage="ffmpeg", error=%e, "Failed to spawn ffmpeg");
            return Err(format!("Failed to spawn ffmpeg: {}", e));
        }
    };

    let stdin = match child.stdin.take() {
        Some(s) => s,
        None => {
            let _ = child.kill();
            let _ = child.wait();
            return Err("Failed to open ffmpeg stdin".to_string());
        }
    };

    Ok(FfmpegCapture {
        stdin,
        guard: KillOnDrop::new(child),
    })
}

pub(super) fn capture_teaser_frames(
    tab: &Tab,
    session_id: &str,
    duration_limit: u64,
    output_format: TeaserOutputFormat,
    stdin: &mut ChildStdin,
    capture_viewport: &Page::Viewport,
) -> Result<CaptureStats, String> {
    let start_script = video_capture::start_script_content(output_format);
    tab.evaluate(start_script, false)
        .map_err(|e| format!("Failed to start teaser: {}", e))?;
    std::thread::sleep(Duration::from_millis(120));

    let start_sim = Instant::now();
    let max_dur = Duration::from_secs(duration_limit);
    let stats_res = video_capture::capture_frames_cdp(
        tab,
        session_id,
        start_sim,
        max_dur,
        stdin,
        capture_viewport,
    );

    match stats_res {
        Ok(stats) if stats.emitted_frames > 0 => Ok(stats),
        Ok(_) => video_capture::capture_frames_polling(
            tab,
            session_id,
            Instant::now(),
            max_dur,
            stdin,
            capture_viewport,
        ),
        Err(failure) => {
            let elapsed = start_sim.elapsed();
            let remaining = max_dur.saturating_sub(elapsed);
            if remaining.is_zero() {
                return Err(format!(
                    "CDP capture failed with no fallback budget remaining: {}",
                    failure.message
                ));
            }

            let mut fallback = video_capture::capture_frames_polling(
                tab,
                session_id,
                Instant::now(),
                remaining,
                stdin,
                capture_viewport,
            )?;
            if failure.emitted_frames > 0 {
                fallback.mode = "cdp+polling";
                fallback.emitted_frames = fallback
                    .emitted_frames
                    .saturating_add(failure.emitted_frames);
            }
            Ok(fallback)
        }
    }
}

pub(super) fn wait_for_ffmpeg(guard: &mut KillOnDrop) -> Result<(), String> {
    let mut child = match guard.take() {
        Some(child) => child,
        None => return Err("Failed to retrieve ffmpeg child process".to_string()),
    };

    let start_wait = Instant::now();
    let wait_timeout = Duration::from_secs(60);
    loop {
        match child.try_wait() {
            Ok(Some(status)) => {
                if !status.success() {
                    return Err(format!(
                        "FFmpeg exited with error code: {:?}",
                        status.code()
                    ));
                }
                break;
            }
            Ok(None) => {
                if start_wait.elapsed() > wait_timeout {
                    let _ = child.kill();
                    let _ = child.wait();
                    return Err("Timeout waiting for FFmpeg to finish".to_string());
                }
                std::thread::sleep(Duration::from_millis(100));
            }
            Err(e) => {
                let _ = child.kill();
                let _ = child.wait();
                return Err(format!("FFmpeg wait error: {}", e));
            }
        }
    }

    Ok(())
}

pub(super) fn log_capture_stats(session_id: &str, stats: &CaptureStats) {
    let encoded_duration_s = if stats.emitted_frames > 0 {
        stats.emitted_frames as f64 / TEASER_OUTPUT_FPS
    } else {
        0.0
    };
    let duration_drift_s = (encoded_duration_s - stats.duration_s).abs();
    let duplicate_ratio = if stats.emitted_frames > 0 {
        stats.duplicated_frames as f64 / stats.emitted_frames as f64
    } else {
        0.0
    };

    tracing::info!(
        module = "TeaserGenerator",
        session_id = %session_id,
        capture_mode = stats.mode,
        duration_s = stats.duration_s,
        encoded_duration_s = encoded_duration_s,
        duration_drift_s = duration_drift_s,
        emitted_frames = stats.emitted_frames,
        captured_frames = stats.captured_frames,
        duplicated_frames = stats.duplicated_frames,
        dropped_frames = stats.dropped_frames,
        late_frames = stats.late_frames,
        duplicate_ratio = duplicate_ratio,
        emitted_fps = stats.emitted_fps,
        captured_fps = stats.captured_fps,
        "TEASER_CAPTURE_STATS"
    );
}
