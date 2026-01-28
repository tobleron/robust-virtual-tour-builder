// @efficiency: data-model
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ValidationReport {
    pub broken_links_removed: u32,
    pub orphaned_scenes: Vec<String>, // Scenes with no incoming links
    pub unused_files: Vec<String>,    // Files in ZIP not used by project
    pub warnings: Vec<String>,
    pub errors: Vec<String>,
}

impl Default for ValidationReport {
    fn default() -> Self {
        Self::new()
    }
}

impl ValidationReport {
    pub fn new() -> Self {
        ValidationReport {
            broken_links_removed: 0,
            orphaned_scenes: Vec::new(),
            unused_files: Vec::new(),
            warnings: Vec::new(),
            errors: Vec::new(),
        }
    }

    pub fn has_issues(&self) -> bool {
        self.broken_links_removed > 0
            || !self.orphaned_scenes.is_empty()
            || !self.unused_files.is_empty()
            || !self.errors.is_empty()
    }
}
