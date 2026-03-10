use crate::api::media::video_logic_runtime;
use crate::api::media::video_logic_support::{
    HeadlessControl, HeadlessMotionProfile, MotionManifestV1, headless_app_origin,
    inject_headless_control, wait_for_headless_ready,
};
use headless_chrome::{Browser, LaunchOptions, Tab, protocol::cdp::Page};
use serde_json::Value;
use std::env;
use std::sync::Arc;
use std::time::Duration;

pub(super) struct PreparedRuntime {
    pub _browser: Browser,
    pub tab: Arc<Tab>,
    pub session_id: String,
    pub capture_viewport: Page::Viewport,
}

pub(super) fn prepare_runtime(
    project_data: Value,
    session_id: String,
    width: u32,
    height: u32,
    auth_token: Option<String>,
    motion_profile: HeadlessMotionProfile,
    motion_manifest: Option<MotionManifestV1>,
) -> Result<PreparedRuntime, String> {
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

    let tab = browser
        .new_tab()
        .map_err(|e| format!("Failed to create tab: {}", e))?;
    navigate_to_app(&tab)?;

    let session_id = session_id.clone();
    let control = HeadlessControl {
        project: project_data,
        backend_origin: video_logic_runtime::headless_backend_origin_impl(),
        session_id: session_id.clone(),
        auth_token: resolve_auth_token(auth_token),
        motion_profile,
        motion_manifest,
    };

    inject_headless_control(&tab, &control)?;
    wait_for_headless_ready(&tab, &session_id, Duration::from_secs(60))?;
    super::super::apply_capture_mode(&tab, &session_id)?;
    let capture_viewport = super::super::resolve_capture_viewport(&tab, &session_id)?;

    Ok(PreparedRuntime {
        _browser: browser,
        tab,
        session_id,
        capture_viewport,
    })
}

fn navigate_to_app(tab: &Arc<Tab>) -> Result<(), String> {
    let app_origin = headless_app_origin();
    if let Err(e) = tab.navigate_to(&app_origin) {
        if app_origin != "http://localhost:8080" {
            if let Err(e2) = tab.navigate_to("http://localhost:8080") {
                return Err(format!("Nav failed: {} / fallback failed: {}", e, e2));
            }
        } else {
            return Err(format!("Nav failed: {}", e));
        }
    }

    tab.wait_until_navigated()
        .map(|_| ())
        .map_err(|e| format!("Nav timeout: {}", e))
}

fn resolve_auth_token(auth_token: Option<String>) -> Option<String> {
    auth_token
        .or_else(|| env::var("HEADLESS_API_TOKEN").ok())
        .or_else(|| {
            if cfg!(debug_assertions) {
                Some("dev-token".to_string())
            } else {
                None
            }
        })
}
