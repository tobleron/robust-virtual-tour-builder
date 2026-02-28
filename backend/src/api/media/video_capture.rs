use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};
use headless_chrome::{
    Tab,
    protocol::cdp::{Page, types::Event},
};
use std::io::Write;
use std::sync::Arc;
use std::time::Duration;

use super::video_logic::TeaserOutputFormat;

const TEASER_OUTPUT_FPS: f64 = 60.0;
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
    start_sim: std::time::Instant,
    max_dur: Duration,
    stdin: &mut std::process::ChildStdin,
    capture_viewport: &Page::Viewport,
) -> Result<CaptureStats, CaptureFailure> {
    let (tx, rx) = std::sync::mpsc::channel::<(Vec<u8>, Option<f64>)>();
    let tx_clone = tx.clone();

    let _listener = tab.add_event_listener(Arc::new(move |event: &Event| {
        if let Event::PageScreencastFrame(frame) = event {
            let _ = tx_clone.send((
                BASE64.decode(&frame.params.data).unwrap_or_default(),
                frame.params.metadata.timestamp,
            ));
        }
    }));

    let capture_width = capture_viewport.width.round().max(1.0) as u32;
    let capture_height = capture_viewport.height.round().max(1.0) as u32;
    if let Err(e) = tab.call_method(Page::StartScreencast {
        format: Some(Page::StartScreencastFormatOption::Jpeg),
        quality: Some(TEASER_CAPTURE_JPEG_QUALITY),
        max_width: Some(capture_width),
        max_height: Some(capture_height),
        every_nth_frame: Some(1),
    }) {
        return Err(CaptureFailure {
            message: format!("Failed to start screencast: {}", e),
            emitted_frames: 0,
        });
    }

    let target_frame_step_s = 1.0 / TEASER_OUTPUT_FPS;
    let mut emitted_frames: u64 = 0;
    let mut captured_frames: u64 = 0;
    let mut duplicated_frames: u64 = 0;
    let mut dropped_frames: u64 = 0;
    let mut late_frames: u64 = 0;
    let mut first_frame_received = false;
    let mut last_frame_wall = std::time::Instant::now();
    let mut last_frame_ts: Option<f64> = None;
    let mut last_frame_data: Option<Vec<u8>> = None;

    while std::time::Instant::now().duration_since(start_sim) <= max_dur {
        match rx.recv_timeout(Duration::from_millis(CDP_FRAME_TIMEOUT_MS)) {
            Ok((frame_data, metadata_ts)) => {
                if frame_data.is_empty() {
                    continue;
                }

                let now = std::time::Instant::now();
                let delta_s = match (metadata_ts, last_frame_ts) {
                    (Some(current), Some(prev)) if current > prev => current - prev,
                    (Some(_), _) => target_frame_step_s,
                    (None, _) => now.duration_since(last_frame_wall).as_secs_f64(),
                };

                let mut frames_to_emit = (delta_s * TEASER_OUTPUT_FPS).round() as u64;
                if frames_to_emit == 0 {
                    frames_to_emit = 1;
                }
                if first_frame_received && delta_s > target_frame_step_s * CDP_LATE_FRAME_FACTOR {
                    late_frames = late_frames.saturating_add(1);
                }

                if frames_to_emit > 1 {
                    let inferred_missing = frames_to_emit - 1;
                    duplicated_frames = duplicated_frames.saturating_add(inferred_missing);
                    dropped_frames = dropped_frames.saturating_add(inferred_missing);
                }

                for _ in 0..frames_to_emit {
                    if stdin.write_all(&frame_data).is_err() {
                        let _ = tab.call_method(Page::StopScreencast(None));
                        return Err(CaptureFailure {
                            message: "Failed to write CDP frame to ffmpeg".to_string(),
                            emitted_frames,
                        });
                    }
                }

                emitted_frames = emitted_frames.saturating_add(frames_to_emit);
                captured_frames = captured_frames.saturating_add(1);
                first_frame_received = true;
                last_frame_wall = now;
                if let Some(ts) = metadata_ts {
                    last_frame_ts = Some(ts);
                } else if let Some(prev_ts) = last_frame_ts {
                    last_frame_ts = Some(prev_ts + delta_s);
                } else {
                    last_frame_ts = Some(delta_s);
                }
                last_frame_data = Some(frame_data);
            }
            Err(std::sync::mpsc::RecvTimeoutError::Timeout) => {
                if !first_frame_received {
                    if std::time::Instant::now() - start_sim > Duration::from_secs(5) {
                        let _ = tab.call_method(Page::StopScreencast(None));
                        return Err(CaptureFailure {
                            message: "Timeout waiting for first screencast frame".to_string(),
                            emitted_frames: 0,
                        });
                    }
                    continue;
                }

                if let Ok(v) = tab.evaluate("window.isAutoPilotActive()", false)
                    && !v.value.and_then(|x| x.as_bool()).unwrap_or(true)
                {
                    break;
                }

                if last_frame_wall.elapsed() > Duration::from_millis(CDP_FRAME_STALL_MS) {
                    let _ = tab.call_method(Page::StopScreencast(None));
                    return Err(CaptureFailure {
                        message: "Screencast stalled waiting for frames".to_string(),
                        emitted_frames,
                    });
                }
            }
            Err(std::sync::mpsc::RecvTimeoutError::Disconnected) => {
                let _ = tab.call_method(Page::StopScreencast(None));
                return Err(CaptureFailure {
                    message: "Screencast channel disconnected".to_string(),
                    emitted_frames,
                });
            }
        }
    }

    let _ = tab.call_method(Page::StopScreencast(None));

    if let Some(last_frame) = last_frame_data.as_ref() {
        let expected_total_frames =
            (start_sim.elapsed().as_secs_f64() * TEASER_OUTPUT_FPS).round() as u64;
        if expected_total_frames > emitted_frames {
            let tail_pad = expected_total_frames - emitted_frames;
            duplicated_frames = duplicated_frames.saturating_add(tail_pad);
            dropped_frames = dropped_frames.saturating_add(tail_pad);
            for _ in 0..tail_pad {
                if stdin.write_all(last_frame).is_err() {
                    return Err(CaptureFailure {
                        message: "Failed to write CDP tail frame to ffmpeg".to_string(),
                        emitted_frames,
                    });
                }
            }
            emitted_frames = emitted_frames.saturating_add(tail_pad);
        }
    }

    let elapsed_secs = start_sim.elapsed().as_secs_f64();
    Ok(CaptureStats {
        mode: "cdp",
        duration_s: elapsed_secs,
        emitted_frames,
        captured_frames,
        duplicated_frames,
        dropped_frames,
        late_frames,
        emitted_fps: if elapsed_secs > 0.0 {
            emitted_frames as f64 / elapsed_secs
        } else {
            0.0
        },
        captured_fps: if elapsed_secs > 0.0 {
            captured_frames as f64 / elapsed_secs
        } else {
            0.0
        },
    })
}

pub(super) fn capture_frames_polling(
    tab: &Tab,
    session_id: &str,
    start_sim: std::time::Instant,
    max_dur: Duration,
    stdin: &mut std::process::ChildStdin,
    capture_viewport: &Page::Viewport,
) -> Result<CaptureStats, String> {
    let mut screenshot_failed = false;
    let frame_interval = Duration::from_secs_f64(1.0 / TEASER_OUTPUT_FPS);
    let mut next_frame_deadline = start_sim;
    let mut emitted_frames: u64 = 0;
    let mut captured_frames: u64 = 0;
    let mut duplicated_frames: u64 = 0;
    let mut last_png: Option<Vec<u8>> = None;

    loop {
        let now = std::time::Instant::now();
        if now - start_sim > max_dur {
            break;
        }

        if now < next_frame_deadline {
            std::thread::sleep(next_frame_deadline - now);
            continue;
        }

        if let Ok(v) = tab.evaluate("window.isAutoPilotActive()", false)
            && !v.value.and_then(|x| x.as_bool()).unwrap_or(true)
        {
            break;
        }

        let current_frame = match tab.capture_screenshot(
            headless_chrome::protocol::cdp::Page::CaptureScreenshotFormatOption::Jpeg,
            Some(TEASER_CAPTURE_JPEG_QUALITY),
            Some(capture_viewport.clone()),
            true,
        ) {
            Ok(frame_data) => {
                last_png = Some(frame_data.clone());
                captured_frames = captured_frames.saturating_add(1);
                frame_data
            }
            Err(e) => {
                if let Some(previous) = last_png.clone() {
                    tracing::warn!(
                        session_id=%session_id,
                        stage="frame_capture",
                        error=%e,
                        "Screenshot failed; reusing previous frame"
                    );
                    previous
                } else {
                    tracing::error!(session_id=%session_id, stage="frame_capture", error=%e, "Screenshot capture failed");
                    screenshot_failed = true;
                    break;
                }
            }
        };

        let elapsed_secs = std::time::Instant::now()
            .duration_since(start_sim)
            .as_secs_f64();
        let expected_frames = (elapsed_secs * TEASER_OUTPUT_FPS).floor() as u64;
        let frames_to_emit = std::cmp::max(1, expected_frames.saturating_sub(emitted_frames));
        if frames_to_emit > 1 {
            duplicated_frames = duplicated_frames.saturating_add(frames_to_emit - 1);
        }
        for _ in 0..frames_to_emit {
            if stdin.write_all(&current_frame).is_err() {
                screenshot_failed = true;
                break;
            }
        }
        if screenshot_failed {
            break;
        }
        emitted_frames = emitted_frames.saturating_add(frames_to_emit);

        while next_frame_deadline <= std::time::Instant::now() {
            next_frame_deadline += frame_interval;
        }
    }

    if screenshot_failed {
        return Err("Screenshot failed during generation".to_string());
    }

    let elapsed_secs = start_sim.elapsed().as_secs_f64();
    Ok(CaptureStats {
        mode: "polling",
        duration_s: elapsed_secs,
        emitted_frames,
        captured_frames,
        duplicated_frames,
        dropped_frames: duplicated_frames,
        late_frames: 0,
        emitted_fps: if elapsed_secs > 0.0 {
            emitted_frames as f64 / elapsed_secs
        } else {
            0.0
        },
        captured_fps: if elapsed_secs > 0.0 {
            captured_frames as f64 / elapsed_secs
        } else {
            0.0
        },
    })
}
