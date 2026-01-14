use std::collections::{HashMap, HashSet};
use std::io::{Write, Cursor};
use zip::write::FileOptions;
use rayon::prelude::*;

use crate::models::{ValidationReport};
use crate::services::media;

const WEBP_QUALITY: f32 = 92.0;

/// Validate and clean project data
/// Returns a tuple of (cleaned_project, validation_report)
/// This function takes ownership of the project and returns a new cleaned version
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

/// Create a tour package ZIP containing the tour application and assets
pub fn create_tour_package(
    image_files: Vec<(String, Vec<u8>)>,
    fields: HashMap<String, String>,
) -> Result<Vec<u8>, String> {
    let mut zip_buffer = Cursor::new(Vec::new());
    {
        let mut zip = zip::ZipWriter::new(&mut zip_buffer);
        let options = FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored)
            .unix_permissions(0o755);

        // 1. Add Static Assets (Logo)
        if let Some((_, logo_bytes)) = image_files.iter().find(|(name, _)| name == "logo.png") {
             for folder in &["tour_4k", "tour_2k", "tour_hd"] {
                 zip.start_file(format!("{}/assets/logo.png", folder), options).map_err(|e| e.to_string())?;
                 zip.write_all(logo_bytes).map_err(|e| e.to_string())?;
             }
        }

        // 2. Add Libraries
        let lib_files = ["pannellum.js", "pannellum.css"];
        for lib in lib_files {
            if let Some((_, lib_bytes)) = image_files.iter().find(|(name, _)| name == lib) {
                for folder in &["tour_4k", "tour_2k", "tour_hd"] {
                    zip.start_file(format!("{}/libs/{}", folder, lib), options).map_err(|e| e.to_string())?;
                    zip.write_all(lib_bytes).map_err(|e| e.to_string())?;
                }
            }
        }

        // 3. Add HTML Templates
        if let Some(html) = fields.get("html_4k") {
            zip.start_file("tour_4k/index.html", options).map_err(|e| e.to_string())?;
            zip.write_all(html.as_bytes()).map_err(|e| e.to_string())?;
        }
        if let Some(html) = fields.get("html_2k") {
            zip.start_file("tour_2k/index.html", options).map_err(|e| e.to_string())?;
            zip.write_all(html.as_bytes()).map_err(|e| e.to_string())?;
        }
        if let Some(html) = fields.get("html_hd") {
            zip.start_file("tour_hd/index.html", options).map_err(|e| e.to_string())?;
            zip.write_all(html.as_bytes()).map_err(|e| e.to_string())?;
        }
        if let Some(html) = fields.get("html_index") {
            zip.start_file("index.html", options).map_err(|e| e.to_string())?;
            zip.write_all(html.as_bytes()).map_err(|e| e.to_string())?;
        }
        if let Some(embed) = fields.get("embed_codes") {
            zip.start_file("embed_codes.txt", options).map_err(|e| e.to_string())?;
            zip.write_all(embed.as_bytes()).map_err(|e| e.to_string())?;
        }

        // 4. Process Scenes (Resize)
        let scene_files: Vec<_> = image_files.iter()
            .filter(|(name, _)| !name.starts_with("logo") && !name.starts_with("pannellum"))
            .collect();

        let processed_results: Vec<Result<Vec<(String, Vec<u8>)>, String>> = scene_files.par_iter()
            .map(|(name, data)| -> Result<Vec<(String, Vec<u8>)>, String> {
                let img = image::ImageReader::new(Cursor::new(data))
                    .with_guessed_format()
                    .map_err(|e| format!("Failed to guess format for {}: {}", name, e))?
                    .decode()
                    .map_err(|e| format!("Failed to decode {}: {}", name, e))?;

                let targets = [
                    ("tour_4k", 4096),
                    ("tour_2k", 2048),
                    ("tour_hd", 1280),
                ];

                let mut artifacts = Vec::new();
                for (folder, width) in targets {
                    let resized = media::resize_fast(&img, width, width)
                        .map_err(|e| format!("Resize failed: {}", e))?;
                    let webp_name = std::path::Path::new(name).with_extension("webp");
                    let fname = webp_name.file_name().ok_or("Invalid filename")?.to_str().ok_or("Invalid filename")?;
                    let zip_path = format!("{}/assets/images/{}", folder, fname);
                    
                    let webp_bytes = media::encode_webp(&resized, WEBP_QUALITY)?;
                    
                    artifacts.push((zip_path, webp_bytes));
                }
                Ok(artifacts)
            })
            .collect();

        for result in processed_results {
            let artifacts = result?;
            for (zip_path, data) in artifacts {
                zip.start_file(zip_path, options).map_err(|e| e.to_string())?;
                zip.write_all(&data).map_err(|e| e.to_string())?;
            }
        }

        zip.finish().map_err(|e| e.to_string())?;
    }
    
    Ok(zip_buffer.into_inner())
}

/// Process an uploaded project ZIP: validate using project.json and normalize structure
pub fn process_uploaded_project_zip(zip_data: Vec<u8>) -> Result<Vec<u8>, String> {
    use std::io::Read;
    
    // Open uploaded ZIP archive
    let cursor = Cursor::new(&zip_data);
    let mut archive = zip::ZipArchive::new(cursor)
        .map_err(|e| format!("Failed to read ZIP: {}", e))?;
    
    // 1. Collect list of files in ZIP for validation
    let mut available_files = HashSet::new();
    for i in 0..archive.len() {
        if let Ok(file) = archive.by_index(i) {
            available_files.insert(file.name().to_string());
        }
    }
    
    // 2. Extract project.json
    let mut project_file = archive.by_name("project.json")
        .map_err(|e| format!("Missing project.json: {}", e))?;
    let mut project_json = String::new();
    project_file.read_to_string(&mut project_json)
        .map_err(|e| format!("Failed to read project.json: {}", e))?;
    drop(project_file);
    
    let project_data: serde_json::Value = serde_json::from_str(&project_json)
        .map_err(|e| format!("Invalid project.json: {}", e))?;
    
    // 3. Validate and clean project
    let (mut validated_project, validation_report) = validate_and_clean_project(project_data, &available_files)?;
    
    // Log validation results
    if validation_report.has_issues() {
        tracing::warn!("Project validation found issues: {} broken links removed", 
            validation_report.broken_links_removed);
    }
    
    // Add validation report to project data
    validated_project["validationReport"] = serde_json::to_value(&validation_report)
        .map_err(|e| format!("Failed to serialize validation report: {}", e))?;
    
    // 4. Create response ZIP containing validated project.json + all images normalized in images/
    let mut response_zip_buffer = Cursor::new(Vec::new());
    {
        let mut zip_writer = zip::ZipWriter::new(&mut response_zip_buffer);
        let options = FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored)
            .unix_permissions(0o755);
        
        // Add validated project.json
        zip_writer.start_file("project.json", options)
            .map_err(|e| e.to_string())?;
        let updated_json = serde_json::to_string_pretty(&validated_project)
            .map_err(|e| e.to_string())?;
        zip_writer.write_all(updated_json.as_bytes())
            .map_err(|e| e.to_string())?;
        
        // Copy all image files, normalizing to images/ folder
        for i in 0..archive.len() {
            let mut file = archive.by_index(i)
                .map_err(|e| format!("Failed to read file {}: {}", i, e))?;
            
            let filename = file.name().to_string();
            
            // Skip project.json
            if filename == "project.json" {
                continue;
            }
            
            // Include files in images/ directory or root-level image files
            if filename.starts_with("images/") || 
               filename.ends_with(".webp") || 
               filename.ends_with(".jpg") || 
               filename.ends_with(".jpeg") || 
               filename.ends_with(".png") {
                
                let mut zip_path = filename.clone();
                // Normalize images into images/ folder if not already there
                if (filename.ends_with(".webp") || filename.ends_with(".jpg") || filename.ends_with(".jpeg") || filename.ends_with(".png")) 
                   && !filename.starts_with("images/") {
                    zip_path = format!("images/{}", filename);
                }
                
                zip_writer.start_file(&zip_path, options)
                    .map_err(|e| e.to_string())?;
                
                let mut buffer = Vec::new();
                file.read_to_end(&mut buffer)
                    .map_err(|e| e.to_string())?;
                
                zip_writer.write_all(&buffer)
                    .map_err(|e| e.to_string())?;
            }
        }
        
        zip_writer.finish()
            .map_err(|e| e.to_string())?;
    }
    
    Ok(response_zip_buffer.into_inner())
}

/// Validate a project ZIP content without modifying it
pub fn validate_project_zip(zip_data: Vec<u8>) -> Result<ValidationReport, String> {
    use std::io::Read;
    
    let cursor = Cursor::new(&zip_data);
    let mut archive = zip::ZipArchive::new(cursor)
        .map_err(|e| format!("Failed to read ZIP: {}", e))?;
    
    // Collect list of files in ZIP for validation
    let mut available_files = HashSet::new();
    for i in 0..archive.len() {
        if let Ok(file) = archive.by_index(i) {
            available_files.insert(file.name().to_string());
        }
    }

    let mut project_file = archive.by_name("project.json")
        .map_err(|e| format!("Missing project.json: {}", e))?;
    let mut project_json = String::new();
    project_file.read_to_string(&mut project_json)
        .map_err(|e| format!("Failed to read project.json: {}", e))?;
    drop(project_file);
    
    let project_data: serde_json::Value = serde_json::from_str(&project_json)
        .map_err(|e| format!("Invalid project.json: {}", e))?;
    
    let (_validated_project, report) = validate_and_clean_project(project_data, &available_files)?;
    Ok(report)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_validate_project_finds_broken_links() {
        let project = json!({
            "scenes": [
                {
                    "name": "A",
                    "hotspots": [
                        { "target": "B", "linkId": "link1" }
                    ]
                }
            ]
        });
        let available_files = HashSet::from(["A".to_string()]);
        
        let (cleaned, report) = validate_and_clean_project(project, &available_files).unwrap();
        
        assert_eq!(report.broken_links_removed, 1);
        assert!(report.warnings.iter().any(|w| w.contains("Removed 1 broken link")));
        // Check that the link was actually removed
        assert!(cleaned["scenes"][0]["hotspots"].as_array().unwrap().is_empty());
    }
    
    #[test]
    fn test_validate_project_finds_orphaned_scenes() {
        let project = json!({
            "scenes": [
                { "name": "A", "hotspots": [] },
                { "name": "B", "hotspots": [] }
            ]
        });
        // B is orphaned because there's no link to it (and it's not the first scene)
        let available_files = HashSet::from(["A".to_string(), "B".to_string()]);
        
        let (_, report) = validate_and_clean_project(project, &available_files).unwrap();
        
        assert!(report.orphaned_scenes.contains(&"B".to_string()));
        assert!(!report.orphaned_scenes.contains(&"A".to_string())); // first scene is not orphaned
    }
    
    #[test]
    fn test_validate_project_clean_project() {
        let project = json!({
            "scenes": [
                {
                    "name": "A",
                    "id": "scene-a",
                    "category": "indoor",
                    "floor": "ground",
                    "hotspots": [
                        { "target": "B", "linkId": "link1" }
                    ]
                },
                {
                    "name": "B",
                    "id": "scene-b",
                    "category": "indoor",
                    "floor": "ground",
                    "hotspots": []
                }
            ]
        });
        let available_files = HashSet::from(["A".to_string(), "B".to_string()]);
        
        let (_, report) = validate_and_clean_project(project, &available_files).unwrap();
        
        assert!(!report.has_issues());
        assert_eq!(report.errors.len(), 0);
        assert_eq!(report.warnings.len(), 0);
    }
    #[test]
    fn test_validate_project_handles_missing_hotspots_array() {
        let project = json!({
            "scenes": [
                {
                    "name": "A",
                    // hotspots missing
                }
            ]
        });
        let available_files = HashSet::from(["A".to_string()]);
        
        let (cleaned, report) = validate_and_clean_project(project, &available_files).unwrap();
        
        assert!(!report.has_issues());
        assert_eq!(cleaned["scenes"][0]["name"], "A");
    }
}
