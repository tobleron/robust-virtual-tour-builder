use super::video_logic_support::{
    HeadlessControl, inject_headless_control, wait_for_headless_ready,
};
use headless_chrome::{Browser, LaunchOptions};
use serde_json::Value;
use std::env;
use std::path::PathBuf;
use std::process::Command;
use std::time::Duration;

struct KillOnDrop(Option<std::process::Child>);

impl KillOnDrop {
    fn new(child: std::process::Child) -> Self {
        Self(Some(child))
    }

    fn take(&mut self) -> Option<std::process::Child> {
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

fn headless_backend_origin() -> String {
    super::video_logic_support::headless_backend_origin()
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
) -> Result<(), String> {
    let browser = Browser::new(LaunchOptions {
        headless: true,
        window_size: Some((width, height)),
        args: vec![
            std::ffi::OsStr::new("--force-device-scale-factor=1.0"),
            std::ffi::OsStr::new("--enable-webgl"),
            std::ffi::OsStr::new("--ignore-gpu-blacklist"),
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

    if let Err(e) = tab.navigate_to("http://localhost:8080") {
        drop(browser);
        return Err(format!("Nav failed: {}", e));
    }

    if let Err(e) = tab.wait_until_navigated() {
        drop(browser);
        return Err(format!("Nav timeout: {}", e));
    }
    let session_id_clone = session_id.clone();
    let project_session_id = project_data
        .get("sessionId")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string());
    let fallback_session_id = project_session_id.unwrap_or_else(|| session_id_clone.clone());

    let control = HeadlessControl {
        project: project_data,
        backend_origin: headless_backend_origin(),
        session_id: fallback_session_id,
        auth_token: env::var("HEADLESS_API_TOKEN").ok(),
    };

    if let Err(e) = inject_headless_control(&tab, &control) {
        drop(browser);
        return Err(e);
    }

    if let Err(e) = wait_for_headless_ready(&tab, &session_id_clone, Duration::from_secs(60)) {
        drop(browser);
        return Err(e);
    }

    let ffmpeg_cmd = get_ffmpeg_command()?;

    let child_res = Command::new(&ffmpeg_cmd)
        .args([
            "-y",
            "-f",
            "image2pipe",
            "-vcodec",
            "png",
            "-r",
            "30",
            "-i",
            "-",
            "-c:v",
            "libx264",
            "-preset",
            "ultrafast",
            "-pix_fmt",
            "yuv420p",
            "-movflags",
            "+faststart",
            &output_str,
        ])
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

    if let Err(e) = tab.evaluate("window.startCinematicTeaser(true, 'mp4', true)", false) {
        drop(guard);
        drop(browser);
        return Err(format!("Failed to start teaser: {}", e));
    }

    let start_sim = std::time::Instant::now();
    let max_dur = Duration::from_secs(duration_limit);
    let mut screenshot_failed = false;

    loop {
        if std::time::Instant::now() - start_sim > max_dur {
            break;
        }
        if let Ok(v) = tab.evaluate("window.isAutoPilotActive()", false)
            && !v.value.and_then(|x| x.as_bool()).unwrap_or(true)
        {
            break;
        }

        use std::io::Write;

        match tab.capture_screenshot(
            headless_chrome::protocol::cdp::Page::CaptureScreenshotFormatOption::Png,
            None,
            None,
            true,
        ) {
            Ok(png_data) => {
                if stdin.write_all(&png_data).is_err() {
                    break;
                }
            }
            Err(e) => {
                tracing::error!(session_id=%session_id_clone, stage="frame_capture", error=%e, "Screenshot capture failed");
                screenshot_failed = true;
                break;
            }
        }
        std::thread::sleep(Duration::from_millis(10));
    }

    drop(stdin); // Close stdin to signal EOF to ffmpeg

    if screenshot_failed {
        tracing::error!(session_id=%session_id_clone, stage="frame_capture", "Screenshot failed during generation");
        drop(guard); // Kills child
        drop(browser);
        return Err("Screenshot failed during generation".to_string());
    }

    // Now wait for ffmpeg to finish
    // We take child out of guard so guard doesn't kill it
    let mut child = match guard.take() {
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
                    tracing::error!(session_id=%session_id_clone, stage="ffmpeg", code=?status.code(), "FFmpeg exited with error");
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
                    tracing::error!(session_id=%session_id_clone, stage="ffmpeg", "Timeout waiting for FFmpeg to finish");
                    let _ = child.kill();
                    let _ = child.wait();
                    drop(browser);
                    return Err("Timeout waiting for FFmpeg to finish".to_string());
                }
                std::thread::sleep(Duration::from_millis(100));
            }
            Err(e) => {
                tracing::error!(session_id=%session_id_clone, stage="ffmpeg", error=%e, "FFmpeg wait error");
                let _ = child.kill();
                let _ = child.wait();
                drop(browser);
                return Err(format!("FFmpeg wait error: {}", e));
            }
        }
    }

    // Success
    // browser is dropped here at end of scope
    Ok(())
}

fn get_ffmpeg_command() -> Result<String, String> {
    super::video_logic_support::get_ffmpeg_command()
}
