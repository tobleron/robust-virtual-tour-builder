mod import_upload;
mod load;
mod package;
mod validate;

// Re-export public API
pub use import_upload::{ChunkedProjectImportManager, MAX_IMPORT_CHUNK_SIZE_BYTES};
#[allow(unused_imports)]
pub use load::process_uploaded_project_zip;
pub use package::create_tour_package;
pub use validate::validate_and_clean_project;

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    use std::collections::HashSet;

    #[test]
    fn test_validate_and_clean_basic() -> Result<(), Box<dyn std::error::Error>> {
        let project = json!({
            "id": "p1",
            "scenes": [
                {
                    "id": "s1",
                    "name": "img1.webp",
                    "hotspots": []
                }
            ]
        });
        let available_files = HashSet::from(["img1.webp".to_string()]);
        let (project, report) = validate_and_clean_project(project, &available_files)?;
        assert_eq!(report.broken_links_removed, 0);
        assert_eq!(
            project["scenes"].as_array().ok_or("Scenes missing")?.len(),
            1
        );
        Ok(())
    }

    #[test]
    fn test_validate_and_clean_broken_link() -> Result<(), Box<dyn std::error::Error>> {
        let project = json!({
            "id": "p1",
            "scenes": [
                {
                    "id": "s1",
                    "name": "img1.webp",
                    "hotspots": [
                        { "target": "missing" }
                    ]
                }
            ]
        });
        let available_files = HashSet::from(["img1.webp".to_string()]);
        let (project, report) = validate_and_clean_project(project, &available_files)?;
        assert_eq!(report.broken_links_removed, 1);
        assert_eq!(
            project["scenes"][0]["hotspots"]
                .as_array()
                .ok_or("Hotspots array missing")?
                .len(),
            0
        );
        Ok(())
    }

    #[test]
    fn test_validate_and_clean_orphaned_scene() -> Result<(), Box<dyn std::error::Error>> {
        let project = json!({
            "id": "p1",
            "scenes": [
                {
                    "id": "s1",
                    "name": "img1.webp",
                    "hotspots": []
                },
                {
                    "id": "s2",
                    "name": "missing.webp",
                    "hotspots": []
                }
            ]
        });
        let available_files = HashSet::from(["img1.webp".to_string()]);
        let (project, report) = validate_and_clean_project(project, &available_files)?;
        assert_eq!(report.orphaned_scenes.len(), 1);
        assert_eq!(
            project["scenes"]
                .as_array()
                .ok_or("Scenes array missing")?
                .len(),
            1
        );
        Ok(())
    }

    #[test]
    fn test_validate_and_clean_circular_autoforward() -> Result<(), Box<dyn std::error::Error>> {
        let project = json!({
            "id": "p1",
            "scenes": [
                {
                    "id": "s1",
                    "name": "img1.webp",
                    "isAutoForward": true,
                    "hotspots": [{ "target": "img1.webp" }]
                }
            ]
        });
        let available_files = HashSet::from(["img1.webp".to_string()]);
        let (project, report) = validate_and_clean_project(project, &available_files)?;
        assert_eq!(project["scenes"][0]["isAutoForward"].as_bool(), Some(false));
        assert!(report.warnings.iter().any(|w| w.contains("circular")));
        Ok(())
    }

    #[test]
    fn test_validate_and_clean_unused_files() -> Result<(), Box<dyn std::error::Error>> {
        let project = json!({
            "id": "p1",
            "scenes": [
                {
                    "id": "s1",
                    "name": "img1.webp",
                    "hotspots": []
                }
            ]
        });
        let available_files = HashSet::from(["img1.webp".to_string(), "unused.webp".to_string()]);
        let (_project, report) = validate_and_clean_project(project, &available_files)?;
        assert_eq!(report.unused_files.len(), 1);
        assert_eq!(report.unused_files[0], "unused.webp");
        Ok(())
    }

    #[test]
    fn test_validate_and_clean_keeps_id_based_link_when_target_name_is_stale()
    -> Result<(), Box<dyn std::error::Error>> {
        let project = json!({
            "id": "p1",
            "scenes": [
                {
                    "id": "s1",
                    "name": "img1.webp",
                    "hotspots": [
                        { "target": "old_name.webp", "targetSceneId": "s2" }
                    ]
                },
                {
                    "id": "s2",
                    "name": "img2.webp",
                    "hotspots": []
                }
            ]
        });
        let available_files = HashSet::from(["img1.webp".to_string(), "img2.webp".to_string()]);
        let (project, report) = validate_and_clean_project(project, &available_files)?;
        assert_eq!(report.broken_links_removed, 0);
        assert_eq!(report.orphaned_scenes.len(), 0);
        assert_eq!(
            project["scenes"][0]["hotspots"]
                .as_array()
                .ok_or("Hotspots array missing")?
                .len(),
            1
        );
        Ok(())
    }

    #[test]
    fn test_validate_and_clean_backfills_target_scene_id_from_name()
    -> Result<(), Box<dyn std::error::Error>> {
        let project = json!({
            "id": "p1",
            "scenes": [
                {
                    "id": "s1",
                    "name": "img1.webp",
                    "hotspots": [
                        { "target": "img2.webp" }
                    ]
                },
                {
                    "id": "s2",
                    "name": "img2.webp",
                    "hotspots": []
                }
            ]
        });
        let available_files = HashSet::from(["img1.webp".to_string(), "img2.webp".to_string()]);
        let (project, report) = validate_and_clean_project(project, &available_files)?;
        assert_eq!(report.broken_links_removed, 0);
        assert_eq!(
            project["scenes"][0]["hotspots"][0]["targetSceneId"].as_str(),
            Some("s2")
        );
        Ok(())
    }
}
