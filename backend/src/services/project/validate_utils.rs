/* backend/src/services/project/validate_utils.rs - Validation Helper Functions */

use percent_encoding::percent_decode_str;
use std::collections::{HashMap, HashSet};

pub fn normalize_scene_key(value: &str) -> String {
    let lowered = value.trim().to_lowercase();
    if let Some((base, ext)) = lowered.rsplit_once('.') {
        match ext {
            "webp" | "jpg" | "jpeg" | "png" => base.to_string(),
            _ => lowered,
        }
    } else {
        lowered
    }
}

pub fn scene_id_or_fallback(scene: &serde_json::Value, index: usize) -> String {
    scene
        .get("id")
        .and_then(|v| v.as_str())
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string())
        .unwrap_or_else(|| format!("__legacy_scene_{}", index))
}

pub fn extract_sanitized_filename(raw_value: &str) -> Option<String> {
    let trimmed = raw_value.trim();
    if trimmed.is_empty() {
        return None;
    }

    let from_file_segment = if let Some((_, after_file)) = trimmed.rsplit_once("/file/") {
        after_file
    } else {
        trimmed
    };

    let without_query = from_file_segment
        .split('?')
        .next()
        .unwrap_or(from_file_segment)
        .split('#')
        .next()
        .unwrap_or(from_file_segment);

    let candidate = if without_query.starts_with("/images/") {
        without_query.trim_start_matches("/images/")
    } else if without_query.starts_with("images/") {
        without_query.trim_start_matches("images/")
    } else {
        without_query.rsplit('/').next().unwrap_or(without_query)
    };

    if candidate.is_empty() {
        return None;
    }

    let decoded = percent_decode_str(candidate)
        .decode_utf8()
        .ok()?
        .to_string();
    crate::api::utils::sanitize_filename(&decoded).ok()
}

pub fn archive_contains_file(available_files: &HashSet<String>, filename: &str) -> bool {
    available_files.contains(filename) || available_files.contains(&format!("images/{}", filename))
}

pub fn get_scene_filename(scene: &serde_json::Value, key: &str) -> Option<String> {
    scene
        .get(key)
        .and_then(|value| value.as_str())
        .and_then(extract_sanitized_filename)
}

pub fn resolve_hotspot_target_id(
    hotspot: &serde_json::Value,
    scene_ids: &HashSet<String>,
    scene_name_to_id: &HashMap<String, String>,
    scene_norm_name_to_id: &HashMap<String, String>,
) -> Option<String> {
    if let Some(target_id) = hotspot.get("targetSceneId").and_then(|v| v.as_str())
        && scene_ids.contains(target_id)
    {
        return Some(target_id.to_string());
    }

    let target = hotspot.get("target").and_then(|v| v.as_str())?.trim();
    if target.is_empty() {
        return None;
    }

    if scene_ids.contains(target) {
        return Some(target.to_string());
    }

    if let Some(id) = scene_name_to_id.get(target) {
        return Some(id.clone());
    }

    let normalized = normalize_scene_key(target);
    scene_norm_name_to_id.get(&normalized).cloned()
}
