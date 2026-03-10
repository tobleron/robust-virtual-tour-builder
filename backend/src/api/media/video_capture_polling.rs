use headless_chrome::{Tab, protocol::cdp::Page};
use std::cmp;
use std::io::Write;
use std::process::ChildStdin;
use std::time::{Duration, Instant};

use super::{CaptureStats, TEASER_CAPTURE_JPEG_QUALITY, TEASER_OUTPUT_FPS};

pub(super) fn capture_frames_polling(
    tab: &Tab,
    session_id: &str,
    start_sim: Instant,
    max_dur: Duration,
    stdin: &mut ChildStdin,
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
        let now = Instant::now();
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
            Page::CaptureScreenshotFormatOption::Jpeg,
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

        let elapsed_secs = Instant::now().duration_since(start_sim).as_secs_f64();
        let expected_frames = (elapsed_secs * TEASER_OUTPUT_FPS).floor() as u64;
        let frames_to_emit = cmp::max(1, expected_frames.saturating_sub(emitted_frames));
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

        while next_frame_deadline <= Instant::now() {
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
