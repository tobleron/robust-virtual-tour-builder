use std::collections::HashMap;
use std::path::Path;

pub struct Resolver {
    // Map of Stem -> Vec<FullPaths>
    registry: HashMap<String, Vec<String>>,
}

impl Resolver {
    pub fn new(registry: HashMap<String, Vec<String>>) -> Self {
        Self { registry }
    }

    pub fn resolve(&self, dep: &str) -> Vec<String> {
        let mut matches = Vec::new();
        let dep = dep.trim();

        // Debug: Show what we're trying to resolve
        // println!("🎯 RESOLVER: Looking for dependency: '{}'", dep);

        // Strategy 1: ReScript/Dot-Notation Support
        // "TeaserRecorder.Recorder" -> Try "TeaserRecorder"
        if dep.contains('.') && !dep.starts_with('.') {
            let parts: Vec<&str> = dep.split('.').collect();
            if let Some(first) = parts.first() {
                if let Some(hits) = self.registry.get(*first) {
                    matches.extend(hits.clone());
                }
            }
        }

        // Strategy 2: Rust/Colon-Notation Support
        // "Generic::System::Logic" -> Try "Logic", then "System" (if Logic is inline)
        if dep.contains("::") {
            // Check Last Segment first (Standard Import)
            if let Some(last) = dep.split("::").last() {
                if let Some(hits) = self.registry.get(last) {
                    matches.extend(hits.clone());
                }
            }

            // If empty, try Second to Last (Inline Module Parent)
            // e.g. "Auth::Service" -> Service not found -> Try Auth.rs
            if matches.is_empty() {
                let parts: Vec<&str> = dep.split("::").collect();
                if parts.len() > 1 {
                    if let Some(parent) = parts.get(parts.len() - 2) {
                        if let Some(hits) = self.registry.get(*parent) {
                            matches.extend(hits.clone());
                        }
                    }
                }
            }
        }

        // Strategy 3: Direct Stem Match (Standard)
        if matches.is_empty() {
            if let Some(hits) = self.registry.get(dep) {
                matches.extend(hits.clone());
            }
        }

        // Strategy 4: Fallback cleanup (Original logic preserved for legacy)
        if matches.is_empty() {
            let clean = if dep.contains("::") {
                dep.split("::").last().unwrap_or(dep).trim()
            } else {
                dep
            };
            if let Some(hits) = self.registry.get(clean) {
                matches.extend(hits.clone());
            }
        }

        // Strategy 5: File Stem Match (for relative paths like ./utils/MyHelper)
        // This covers "MyHelper" extraction from "./utils/MyHelper"
        if matches.is_empty() {
            let path_obj = Path::new(dep);
            if let Some(stem) = path_obj.file_stem().and_then(|s| s.to_str()) {
                if let Some(hits) = self.registry.get(stem) {
                    matches.extend(hits.clone());
                }
            }
        }

        // Strategy 6: ReScript JSX component resolution (handled by Stem Match above, 
        // but preserved as a documented hook for future specific JSX resolution rules if needed)

        if std::env::var("DEBUG_RESOLVER").is_ok() {
            println!(
                "🎯 RESOLVER: Found {} matches for '{}': {:?}",
                matches.len(),
                dep,
                matches
            );
        }
        matches.sort();
        matches.dedup();
        matches
    }
}
