#[path = "video_runtime_generate.rs"]
mod video_runtime_generate;

use super::video_capture;
use super::video_logic::TeaserOutputFormat;
use super::video_logic_support::{HeadlessMotionProfile, MotionManifestV1};
use headless_chrome::{Tab, protocol::cdp::Page};
use serde_json::Value;
use std::time::Duration;

const TEASER_CAPTURE_MODE_SCRIPT: &str = r#"
(function() {
  try {
    window.__VTB_TEASER_CAPTURE__ = true;
    document.body.classList.add("vtb-teaser-capture");

    const hiddenIds = [
      "sidebar",
      "viewer-utility-bar",
      "viewer-floor-nav",
      "visual-pipeline-container",
      "viewer-hotspot-lines",
      "viewer-center-indicator",
      "v-scene-persistent-label",
      "v-scene-quality-indicator",
      "viewer-notifications-container",
      "cursor-guide",
      "placeholder-text",
      "modal-container"
    ];
    hiddenIds.forEach((id) => {
      const el = document.getElementById(id);
      if (el) el.style.display = "none";
    });

    const sceneLayer = document.getElementById("viewer-scene-elements-layer");
    if (sceneLayer) sceneLayer.style.display = "none";

    const styleId = "__vtb_teaser_capture_style";
    let style = document.getElementById(styleId);
    if (!style) {
      style = document.createElement("style");
      style.id = styleId;
      document.head.appendChild(style);
    }
    style.textContent = `
      #sidebar,
      #viewer-utility-bar,
      #viewer-floor-nav,
      #visual-pipeline-container,
      #viewer-hotspot-lines,
      #viewer-center-indicator,
      #v-scene-persistent-label,
      #v-scene-quality-indicator,
      #viewer-notifications-container,
      #cursor-guide,
      #placeholder-text,
      #modal-container,
      #viewer-scene-elements-layer { display: none !important; }
      #viewer-container {
        width: 100vw !important;
        max-width: 100vw !important;
        flex: 1 1 100% !important;
      }
      #viewer-stage {
        width: 100vw !important;
        max-width: 100vw !important;
      }
      html, body, #root {
        width: 100vw !important;
        max-width: 100vw !important;
        overflow: hidden !important;
      }
      #viewer-logo {
        display: block !important;
        visibility: visible !important;
        opacity: 1 !important;
        pointer-events: none !important;
      }
    `;

    const logo = document.getElementById("viewer-logo");
    if (logo) {
      logo.style.display = "block";
      logo.style.visibility = "visible";
      logo.style.opacity = "1";
      logo.style.pointerEvents = "none";
    }

    return true;
  } catch (err) {
    window.HEADLESS_ERROR = (err && err.message) ? err.message : String(err);
    return false;
  }
})();
"#;

type CaptureStats = video_capture::CaptureStats;
type CaptureFailure = video_capture::CaptureFailure;

pub fn apply_capture_mode(tab: &Tab, session_id: &str) -> Result<(), String> {
    let result = tab
        .evaluate(TEASER_CAPTURE_MODE_SCRIPT, false)
        .map_err(|e| format!("Failed to apply teaser capture mode: {}", e))?;

    let ok = result.value.and_then(|v| v.as_bool()).unwrap_or(false);
    if ok {
        Ok(())
    } else {
        tracing::error!(session_id=%session_id, stage="capture_mode", "Capture mode script reported failure");
        Err("Capture mode initialization failed".to_string())
    }
}

pub fn resolve_capture_viewport(tab: &Tab, session_id: &str) -> Result<Page::Viewport, String> {
    let element = tab
        .wait_for_element("#viewer-stage")
        .map_err(|e| format!("viewer-stage not found for capture: {}", e))?;
    let model = element
        .get_box_model()
        .map_err(|e| format!("viewer-stage box model unavailable: {}", e))?;
    let mut viewport = model.content_viewport();
    if viewport.width <= 1.0 || viewport.height <= 1.0 {
        tracing::error!(
            session_id=%session_id,
            stage="capture_mode",
            width=viewport.width,
            height=viewport.height,
            "viewer-stage viewport invalid"
        );
        return Err("viewer-stage viewport invalid".to_string());
    }

    let normalized_width = ((viewport.width.floor().max(2.0) as u32) / 2) * 2;
    let normalized_height = ((viewport.height.floor().max(2.0) as u32) / 2) * 2;
    viewport.width = normalized_width.max(2) as f64;
    viewport.height = normalized_height.max(2) as f64;

    Ok(viewport)
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
    video_runtime_generate::generate_teaser_sync(
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
