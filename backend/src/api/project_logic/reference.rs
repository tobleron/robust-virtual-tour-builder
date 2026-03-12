use percent_encoding::percent_decode_str;
use serde_json::Value;
use std::collections::HashSet;

fn extract_sanitized_filename(raw_value: &str) -> Option<String> {
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

    let last_segment = without_query.rsplit('/').next().unwrap_or(without_query);

    if last_segment.is_empty() {
        return None;
    }

    let decoded = percent_decode_str(last_segment)
        .decode_utf8()
        .ok()?
        .to_string();
    crate::api::utils::sanitize_filename(&decoded).ok()
}

fn is_active_inventory_entry(entry: &Value) -> bool {
    match entry
        .get("status")
        .and_then(|status| status.as_object())
        .and_then(|obj| obj.get("status"))
        .and_then(|status| status.as_str())
    {
        Some("Deleted") => false,
        _ => true,
    }
}

fn collect_scene_file_references(scene: &Value, acc: &mut HashSet<String>) {
    if let Some(name) = scene.get("name").and_then(|v| v.as_str())
        && let Some(file) = extract_sanitized_filename(name)
    {
        acc.insert(file);
    }

    for prop in ["file", "tinyFile", "originalFile"] {
        if let Some(raw) = scene.get(prop).and_then(|v| v.as_str())
            && let Some(file) = extract_sanitized_filename(raw)
        {
            acc.insert(file);
        }
    }
}

pub fn collect_referenced_project_files(project_val: &Value) -> HashSet<String> {
    let mut referenced = HashSet::new();

    if let Some(raw_logo) = project_val.get("logo").and_then(|v| v.as_str())
        && let Some(file) = extract_sanitized_filename(raw_logo)
    {
        referenced.insert(file);
    }

    if let Some(scenes) = project_val.get("scenes").and_then(|v| v.as_array()) {
        for scene in scenes {
            collect_scene_file_references(scene, &mut referenced);
        }
    }

    if let Some(inventory) = project_val.get("inventory").and_then(|v| v.as_array()) {
        for item in inventory {
            if let Some(entry) = item.get("entry") {
                if !is_active_inventory_entry(entry) {
                    continue;
                }
                if let Some(scene) = entry.get("scene") {
                    collect_scene_file_references(scene, &mut referenced);
                }
            }
        }
    }

    referenced
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn collect_referenced_project_files_includes_logo_and_scene_assets() {
        let project = serde_json::json!({
            "logo": "/api/project/old-session/file/logo_upload",
            "scenes": [
                {
                    "name": "Living Room",
                    "file": "assets/images/living-room.webp",
                    "tinyFile": "assets/images/living-room_tiny.webp",
                    "originalFile": "assets/images/living-room.jpg",
                }
            ],
            "inventory": [],
        });

        let referenced = collect_referenced_project_files(&project);

        assert!(referenced.contains("logo_upload"));
        assert!(referenced.contains("living-room.webp"));
        assert!(referenced.contains("living-room_tiny.webp"));
        assert!(referenced.contains("living-room.jpg"));
    }
}
