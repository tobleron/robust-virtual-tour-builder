mod load;
mod package;
mod validate;

// Re-export public API
pub use load::{process_uploaded_project_zip, validate_project_zip};
pub use package::create_tour_package;
pub use validate::validate_and_clean_project;

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    use std::collections::HashSet;

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

        let (cleaned, report) =
            validate_and_clean_project(project, &available_files).expect("Validation failed");

        assert_eq!(report.broken_links_removed, 1);
        assert!(
            report
                .warnings
                .iter()
                .any(|w| w.contains("Removed 1 broken link"))
        );
        // Check that the link was actually removed
        assert!(
            cleaned["scenes"][0]["hotspots"]
                .as_array()
                .expect("Hotspots array missing")
                .is_empty()
        );
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

        let (_, report) =
            validate_and_clean_project(project, &available_files).expect("Validation failed");

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

        let (_, report) =
            validate_and_clean_project(project, &available_files).expect("Validation failed");

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

        let (cleaned, report) =
            validate_and_clean_project(project, &available_files).expect("Validation failed");

        assert!(!report.has_issues());
        assert_eq!(cleaned["scenes"][0]["name"], "A");
    }
}
