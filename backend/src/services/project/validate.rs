use std::collections::HashSet;
use crate::models::ValidationReport;

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
    available_files: &HashSet<String>
) -> Result<(serde_json::Value, ValidationReport), String> {
    let mut project = project; // Take ownership, now we can mutate locally
    let mut report = ValidationReport::new();
    
    // Extract scenes array
    let scenes = project["scenes"].as_array_mut()
        .ok_or("Invalid project structure: missing 'scenes' array")?;
    
    if scenes.is_empty() {
        report.errors.push("Project has no scenes".to_string());
        return Ok((project, report));
    }
    
    // Build scene name set for validation
    let scene_names: HashSet<String> = scenes.iter()
        .filter_map(|s| s["name"].as_str())
        .map(|s| s.to_string())
        .collect();
    
    tracing::info!(module = "Validator", scene_count = scene_names.len(), "VALIDATION_START");

    let mut incoming_links = HashSet::new();
    // The first scene is the entry point
    if let Some(first_scene_name) = scenes.first().and_then(|s| s["name"].as_str()) {
        incoming_links.insert(first_scene_name.to_string());
    }
    
    // Validate and clean each scene
    for scene in scenes.iter_mut() {
        let scene_name = scene["name"].as_str().unwrap_or("unknown").to_string();
        let mut seen_link_ids = HashSet::new();

        // 1. Check if image file exists in ZIP (check root and images/ folder)
        let mut image_found = false;
        if available_files.contains(&scene_name) || available_files.contains(&format!("images/{}", scene_name)) {
            image_found = true;
        }
        
        if !image_found {
            report.warnings.push(format!("Scene '{}': Image file not found in ZIP", scene_name));
        }

        // 2. Validate hotspots
        if let Some(hotspots) = scene["hotspots"].as_array_mut() {
            let original_count = hotspots.len();
            
            // Remove broken links
            hotspots.retain(|h| {
                if let Some(target) = h["target"].as_str() {
                    let is_valid = scene_names.contains(target);
                    if !is_valid {
                        tracing::warn!("Scene '{}': Removing broken link to '{}'", scene_name, target);
                    } else {
                        incoming_links.insert(target.to_string());
                    }
                    is_valid
                } else {
                    // Hotspot missing target field
                    tracing::warn!("Scene '{}': Removing hotspot with missing target", scene_name);
                    false
                }
            });
            
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
                if let Some(link_id) = hotspot["linkId"].as_str() {
                    if !seen_link_ids.insert(link_id.to_string()) {
                        report.warnings.push(format!("Scene '{}': Duplicate linkId detected: '{}'", scene_name, link_id));
                    }
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
            report.warnings.push(format!("Scene '{}': Missing category metadata", scene_name));
            scene["category"] = serde_json::json!("indoor");
        }
        
        if scene["floor"].is_null() {
            report.warnings.push(format!("Scene '{}': Missing floor metadata", scene_name));
            scene["floor"] = serde_json::json!("ground");
        }
    }

    // 4. Check for orphaned scenes (scenes with no incoming links)
    for scene_name in &scene_names {
        if !incoming_links.contains(scene_name) {
             report.orphaned_scenes.push(scene_name.clone());
             report.warnings.push(format!("Orphaned scene detected (no incoming links): '{}'", scene_name));
        }
    }

    // 5. Check for orphaned image files in the ZIP (files not used in project)
    for file in available_files {
        if (file.ends_with(".webp") || file.ends_with(".jpg") || file.ends_with(".jpeg") || file.ends_with(".png")) 
           && !file.starts_with("project.json") {
            
            let base_name = if file.starts_with("images/") {
                file.strip_prefix("images/").unwrap_or(file)
            } else {
                file
            };
            
            if !scene_names.contains(base_name) {
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
