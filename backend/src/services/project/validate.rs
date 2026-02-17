// @efficiency: domain-logic
use crate::models::ValidationReport;
use std::collections::{HashMap, HashSet};

fn normalize_scene_key(value: &str) -> String {
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

fn scene_id_or_fallback(scene: &serde_json::Value, index: usize) -> String {
    scene
        .get("id")
        .and_then(|v| v.as_str())
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string())
        .unwrap_or_else(|| format!("__legacy_scene_{}", index))
}

fn resolve_hotspot_target_id(
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

/// Validates and sanitizes project metadata against a set of available assets.
///
/// This function performs deep validation:
/// 1. Checks for missing image files.
/// 2. Removes broken links between scenes.
/// 3. Identifies orphaned scenes and unused image files.
/// 4. Ensures required metadata (ID, category, floor) is present.
///
/// # Arguments
/// * `project` - The raw project JSON data.
/// * `available_files` - A set of filenames currently present in the project archive.
///
/// # Returns
/// A tuple containing the cleaned project JSON and a detailed `ValidationReport`.
///
/// # Errors
/// * Returns a `String` error if the root project structure is invalid.
pub fn validate_and_clean_project(
    project: serde_json::Value,
    available_files: &HashSet<String>,
) -> Result<(serde_json::Value, ValidationReport), String> {
    let mut project = project; // Take ownership, now we can mutate locally
    let mut report = ValidationReport::new();

    // Extract scenes array
    let scenes = project["scenes"]
        .as_array_mut()
        .ok_or("Invalid project structure: missing 'scenes' array")?;

    if scenes.is_empty() {
        report.errors.push("Project has no scenes".to_string());
        return Ok((project, report));
    }

    let mut scene_ids = HashSet::new();
    let mut scene_name_to_id = HashMap::new();
    let mut scene_norm_name_to_id = HashMap::new();

    for (idx, scene) in scenes.iter().enumerate() {
        let scene_name = scene["name"].as_str().unwrap_or("unknown").to_string();
        let scene_id = scene_id_or_fallback(scene, idx);
        scene_ids.insert(scene_id.clone());
        scene_name_to_id.insert(scene_name.clone(), scene_id.clone());
        scene_norm_name_to_id.insert(normalize_scene_key(&scene_name), scene_id.clone());
    }

    tracing::info!(
        module = "Validator",
        scene_count = scene_ids.len(),
        "VALIDATION_START"
    );

    let mut incoming_links = HashSet::new();
    // The first scene is the entry point
    if let Some(first_scene) = scenes.first() {
        incoming_links.insert(scene_id_or_fallback(first_scene, 0));
    }

    // Validate and clean each scene
    for (scene_index, scene) in scenes.iter_mut().enumerate() {
        let scene_id = scene_id_or_fallback(scene, scene_index);
        let scene_name = scene["name"].as_str().unwrap_or("unknown").to_string();
        let mut seen_link_ids = HashSet::new();

        // 1. Check if image file exists in ZIP (check root and images/ folder)
        let mut image_found = false;
        if available_files.contains(&scene_name)
            || available_files.contains(&format!("images/{}", scene_name))
        {
            image_found = true;
        }

        // Fallback: Check 'file' property (URL) if not found by name
        if !image_found {
            if let Some(file_url) = scene["file"].as_str() {
                if file_url.contains("/file/") {
                    if let Some(filename_segment) = file_url
                        .split("/file/")
                        .nth(1)
                        .and_then(|s| s.split('?').next())
                    {
                        if let Ok(decoded_filename) =
                            percent_encoding::percent_decode_str(filename_segment).decode_utf8()
                        {
                            let decoded_filename = decoded_filename.to_string();
                            if let Ok(safe_filename) =
                                crate::api::utils::sanitize_filename(&decoded_filename)
                            {
                                if available_files.contains(&safe_filename)
                                    || available_files
                                        .contains(&format!("images/{}", safe_filename))
                                {
                                    image_found = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        if !image_found {
            report.warnings.push(format!(
                "Scene '{}': Image file not found in ZIP",
                scene_name
            ));
        }

        // 2. Validate hotspots
        if let Some(hotspots) = scene["hotspots"].as_array_mut() {
            let original_count = hotspots.len();
            let mut cleaned_hotspots = Vec::with_capacity(original_count);

            for mut hotspot in hotspots.drain(..) {
                if let Some(resolved_target_id) = resolve_hotspot_target_id(
                    &hotspot,
                    &scene_ids,
                    &scene_name_to_id,
                    &scene_norm_name_to_id,
                ) {
                    incoming_links.insert(resolved_target_id.clone());
                    if hotspot["targetSceneId"].as_str().is_none() {
                        hotspot["targetSceneId"] = serde_json::json!(resolved_target_id);
                    }
                    cleaned_hotspots.push(hotspot);
                } else {
                    let target = hotspot["target"].as_str().unwrap_or("<missing>");
                    tracing::warn!(
                        "Scene '{}': Removing broken link to '{}'",
                        scene_name,
                        target
                    );
                    tracing::debug!(
                        "Scene '{}': unresolved target value '{}' (id='{}')",
                        scene_name,
                        target,
                        scene_id
                    );
                }
            }

            *hotspots = cleaned_hotspots;

            let removed = original_count - hotspots.len();
            if removed > 0 {
                report.broken_links_removed += removed as u32;
                report.warnings.push(format!(
                    "Scene '{}': Removed {} broken link(s)",
                    scene_name, removed
                ));
            }

            // Check for duplicate link IDs
            for hotspot in hotspots.iter() {
                if let Some(link_id) = hotspot["linkId"].as_str()
                    && !seen_link_ids.insert(link_id.to_string())
                {
                    report.warnings.push(format!(
                        "Scene '{}': Duplicate linkId detected: '{}'",
                        scene_name, link_id
                    ));
                }
            }
        }

        // 3. Validate required fields and set defaults
        if scene["id"].is_null() {
            report.warnings.push(format!(
                "Scene '{}': Missing ID, will be auto-generated",
                scene_name
            ));
        }

        if scene["category"].is_null() {
            report
                .warnings
                .push(format!("Scene '{}': Missing category metadata", scene_name));
            scene["category"] = serde_json::json!("indoor");
        }

        if scene["floor"].is_null() {
            report
                .warnings
                .push(format!("Scene '{}': Missing floor metadata", scene_name));
            scene["floor"] = serde_json::json!("ground");
        }

        // 4. Circular AutoForward Check
        if let Some(true) = scene["isAutoForward"].as_bool() {
            if let Some(hotspots) = scene["hotspots"].as_array() {
                if hotspots.iter().any(|h| {
                    resolve_hotspot_target_id(
                        h,
                        &scene_ids,
                        &scene_name_to_id,
                        &scene_norm_name_to_id,
                    )
                    .map(|target_id| target_id == scene_id)
                    .unwrap_or(false)
                }) {
                    tracing::warn!(
                        "Scene '{}': circular AutoForward detected, disabling",
                        scene_name
                    );
                    scene["isAutoForward"] = serde_json::json!(false);
                    report.warnings.push(format!(
                        "Scene '{}': circular AutoForward loop detected and disabled",
                        scene_name
                    ));
                }
            }
        }
    }

    // 4. Check for orphaned scenes (scenes with no incoming links)
    let mut scenes_to_keep = Vec::new();
    for (scene_index, scene) in scenes.drain(..).enumerate() {
        let scene_id = scene_id_or_fallback(&scene, scene_index);
        let scene_name = scene["name"].as_str().unwrap_or("unknown").to_string();
        if incoming_links.contains(&scene_id) {
            scenes_to_keep.push(scene);
        } else {
            report.orphaned_scenes.push(scene_name.clone());
            report.warnings.push(format!(
                "Orphaned scene detected (no incoming links): '{}'",
                scene_name
            ));
        }
    }
    *scenes = scenes_to_keep;

    let final_scene_names: HashSet<String> = scenes
        .iter()
        .filter_map(|s| s["name"].as_str())
        .map(|s| s.to_string())
        .collect();

    // 5. Check for orphaned image files in the ZIP (files not used in project)
    for file in available_files {
        if (file.ends_with(".webp")
            || file.ends_with(".jpg")
            || file.ends_with(".jpeg")
            || file.ends_with(".png"))
            && !file.starts_with("project.json")
        {
            let base_name = if file.starts_with("images/") {
                file.strip_prefix("images/").unwrap_or(file)
            } else {
                file
            };

            if !final_scene_names.contains(base_name) {
                report.unused_files.push(file.clone());
            }
        }
    }

    // Summary logging
    if report.has_issues() {
        tracing::info!(
            "Validation complete: {} broken links removed, {} warnings, {} errors, {} orphaned scenes, {} unused files",
            report.broken_links_removed,
            report.warnings.len(),
            report.errors.len(),
            report.orphaned_scenes.len(),
            report.unused_files.len()
        );
    } else {
        tracing::info!("Validation complete: No issues found");
    }

    Ok((project, report))
}
