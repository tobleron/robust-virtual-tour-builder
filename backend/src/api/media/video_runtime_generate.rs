use crate::api::media::video_capture;
use crate::api::media::video_logic::{KillOnDrop, TEASER_OUTPUT_FPS, TeaserOutputFormat};
use crate::api::media::video_logic_runtime;
use crate::api::media::video_logic_support;
use crate::api::media::video_logic_support::{
    HeadlessControl, HeadlessMotionProfile, MotionManifestV1, headless_app_origin,
    inject_headless_control, wait_for_headless_ready,
};
use headless_chrome::{Browser, LaunchOptions};
use serde_json::Value;
use std::env;
use std::process::Command;
use std::time::Duration;

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
    let browser = Browser::new(LaunchOptions {
        headless: true,
        window_size: Some((width, height)),
        args: vec![
            std::ffi::OsStr::new("--force-device-scale-factor=1.0"),
            std::ffi::OsStr::new("--enable-webgl"),
            std::ffi::OsStr::new("--ignore-gpu-blacklist"),
            std::ffi::OsStr::new("--ignore-gpu-blocklist"),
            std::ffi::OsStr::new("--use-gl=swiftshader"),
            std::ffi::OsStr::new("--use-angle=swiftshader"),
            std::ffi::OsStr::new("--enable-unsafe-swiftshader"),
            std::ffi::OsStr::new("--disable-background-timer-throttling"),
            std::ffi::OsStr::new("--disable-renderer-backgrounding"),
            std::ffi::OsStr::new("--disable-backgrounding-occluded-windows"),
            std::ffi::OsStr::new("--run-all-compositor-stages-before-draw"),
            std::ffi::OsStr::new("--disable-frame-rate-limit"),
            std::ffi::OsStr::new("--disable-gpu-vsync"),
        ],
        ..LaunchOptions::default()
    })
    .map_err(|e| format!("Failed to launch browser: {}", e))?;

    let tab = match browser.new_tab() {
        Ok(t) => t,
        Err(e) => {
            drop(browser);
            return Err(format!("Failed to create tab: {}", e));
        }
    };

    let app_origin = headless_app_origin();
    if let Err(e) = tab.navigate_to(&app_origin) {
        if app_origin != "http://localhost:8080" {
            if let Err(e2) = tab.navigate_to("http://localhost:8080") {
                drop(browser);
                return Err(format!("Nav failed: {} / fallback failed: {}", e, e2));
            }
        } else {
            drop(browser);
            return Err(format!("Nav failed: {}", e));
        }
    }

    if let Err(e) = tab.wait_until_navigated() {
        drop(browser);
        return Err(format!("Nav timeout: {}", e));
    }
    let session_id_clone = session_id.clone();
    let resolved_auth_token = auth_token
        .or_else(|| env::var("HEADLESS_API_TOKEN").ok())
        .or_else(|| {
            if cfg!(debug_assertions) {
                Some("dev-token".to_string())
            } else {
                None
            }
        });
    let control = HeadlessControl {
        project: project_data,
        backend_origin: video_logic_runtime::headless_backend_origin_impl(),
        session_id: session_id_clone.clone(),
        auth_token: resolved_auth_token,
        motion_profile,
        motion_manifest,
    };

    if let Err(e) = inject_headless_control(&tab, &control) {
        drop(browser);
        return Err(e);
    }

    if let Err(e) = wait_for_headless_ready(&tab, &session_id_clone, Duration::from_secs(60)) {
        drop(browser);
        return Err(e);
    }
    if let Err(e) = super::apply_capture_mode(&tab, &session_id_clone) {
        drop(browser);
        return Err(e);
    }
    let capture_viewport = super::resolve_capture_viewport(&tab, &session_id_clone)?;

    let ffmpeg_cmd = video_logic_support::get_ffmpeg_command()?;
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
                &output_str,
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
                &output_str,
            ],
        })
        .stdin(std::process::Stdio::piped())
        .stderr(std::process::Stdio::inherit())
        .spawn();

    let mut child = match child_res {
        Ok(c) => c,
        Err(e) => {
            tracing::error!(session_id=%session_id_clone, stage="ffmpeg", error=%e, "Failed to spawn ffmpeg");
            drop(browser);
            return Err(format!("Failed to spawn ffmpeg: {}", e));
        }
    };

    let mut stdin = match child.stdin.take() {
        Some(s) => s,
        None => {
            let _ = child.kill();
            let _ = child.wait();
            drop(browser);
            return Err("Failed to open ffmpeg stdin".to_string());
        }
    };

    let mut guard = KillOnDrop::new(child);
    let start_script = video_capture::start_script_content(output_format);
    if let Err(e) = tab.evaluate(start_script, false) {
        drop(guard);
        drop(browser);
        return Err(format!("Failed to start teaser: {}", e));
    }
    std::thread::sleep(Duration::from_millis(120));

    let start_sim = std::time::Instant::now();
    let max_dur = Duration::from_secs(duration_limit);
    let stats_res = video_capture::capture_frames_cdp(
        &tab,
        &session_id_clone,
        start_sim,
        max_dur,
        &mut stdin,
        &capture_viewport,
    );

    let stats = match stats_res {
        Ok(s) if s.emitted_frames > 0 => s,
        Ok(_) => video_capture::capture_frames_polling(
            &tab,
            &session_id_clone,
            std::time::Instant::now(),
            max_dur,
            &mut stdin,
            &capture_viewport,
        )?,
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
                &tab,
                &session_id_clone,
                std::time::Instant::now(),
                remaining,
                &mut stdin,
                &capture_viewport,
            )?;
            if failure.emitted_frames > 0 {
                fallback.mode = "cdp+polling";
                fallback.emitted_frames = fallback
                    .emitted_frames
                    .saturating_add(failure.emitted_frames);
            }
            fallback
        }
    };

    drop(stdin);
    let mut child: std::process::Child = match guard.take() {
        Some(c) => c,
        None => {
            drop(browser);
            return Err("Failed to retrieve ffmpeg child process".to_string());
        }
    };

    let start_wait = std::time::Instant::now();
    let wait_timeout = Duration::from_secs(60);
    loop {
        match child.try_wait() {
            Ok(Some(status)) => {
                if !status.success() {
                    drop(browser);
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
                    drop(browser);
                    return Err("Timeout waiting for FFmpeg to finish".to_string());
                }
                std::thread::sleep(Duration::from_millis(100));
            }
            Err(e) => {
                let _ = child.kill();
                let _ = child.wait();
                drop(browser);
                return Err(format!("FFmpeg wait error: {}", e));
            }
        }
    }

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
        session_id = %session_id_clone,
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

    Ok(())
}
