use crate::config::EfficiencyConfig;
use anyhow::Result;
use std::collections::{HashMap, HashSet};
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, serde::Serialize)]
pub enum WorkUnit {
    Ambiguity { file: String, strategy: String },
    Violation { file: String, pattern: String, strategy: String },
    Surgical { file: String, action: String, reason: String, strategy: String, platform: String, complexity: f64, recommended_splits: usize },
    Merge { folder: String, files: Vec<String>, reason: String, strategy: String, platform: String },
    Structural { file: String, action: String, reason: String, strategy: String, platform: String },
}

/// Generate strategic directive for a work unit
pub fn generate_strategic_directive(unit: &WorkUnit) -> String {
    match unit {
        WorkUnit::Surgical { reason, recommended_splits, .. } => {
            let base = if reason.contains("Nesting") && reason.contains("Density") {
                "Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions."
            } else if reason.contains("Nesting") {
                "Flatten Control Flow: Replace nested if/switch blocks with early returns or pattern matching."
            } else if reason.contains("Density") {
                "Extract Service Logic: Move complex calculations or data transformations into specialized sub-modules."
            } else {
                "De-bloat: Reduce module size by identifying and extracting independent domain logic."
            };
            format!("{} 🏗️ ARCHITECTURAL TARGET: Split into exactly {} cohesive modules to respect the Read Tax (avg 300 LOC/module).", base, recommended_splits)
        },
        WorkUnit::Merge { folder, .. } => {
            let folder_name = Path::new(folder).file_name()
                .map(|n| n.to_string_lossy())
                .unwrap_or_default();
            format!("Unified Context: Consolidate these fragmented files into a single cohesive module file (e.g., `{}.rs`). CRITICAL: Delete the now-empty `{}/` folder to reduce directory nesting tax and strip any existing '@efficiency' tags.", folder_name, folder)
        },
        WorkUnit::Structural { action, .. } => {
            if action.contains("Flatten") {
                "Hierarchy Cleanup: Move these modules 1-2 levels higher to reduce the directory traversal tax.".to_string()
            } else {
                "Vertical Slicing: Group related UI and Logic files into a single 'Feature Pod' folder.".to_string()
            }
        },
        WorkUnit::Violation { pattern, .. } => {
            if pattern.contains("JSON") || pattern.contains("magic") || pattern.contains("schema") {
                 format!("CSP Compliance: Replace '{}' with `rescript-json-combinators` (Zero-Eval).", pattern)
            } else {
                 format!("Pattern Fix: Replace the forbidden '{}' pattern with the recommended functional alternative.", pattern)
            }
        },
        WorkUnit::Ambiguity { .. } => {
            "Taxonomy Resolution: Add the required @efficiency-role: <role> tag (including colon) to help the analyzer apply the correct complexity limits.".to_string()
        }
    }
}

fn sync_architectural_category(
    category_name: &str, 
    platform: &str, 
    units: &[String], 
    objective: &str
) -> Result<Option<PathBuf>> {
    let pending_dir = "../../tasks/pending";
    let platform_label = if platform.is_empty() { 
        "".to_string() 
    } else { 
        format!("_{}", platform.to_uppercase()) 
    };
    let full_category_name = format!("{}{}", category_name, platform_label);
    let mut existing_path = None;
    
    if let Ok(entries) = fs::read_dir(pending_dir) {
        for entry in entries.filter_map(|e| e.ok()) {
            let name = entry.file_name().to_string_lossy().into_owned();
            if name.contains(&full_category_name) { 
                existing_path = Some(entry.path()); 
                break; 
            }
        }
    }

    if units.is_empty() {
        return Ok(None);
    }
    
    let (path, id) = if let Some(p) = existing_path {
        let id_str = p.file_name()
            .and_then(|n| n.to_str())
            .and_then(|s| s.split('_').next())
            .unwrap_or("0")
            .to_string();
        (p, id_str)
    } else {
        let mut max_id = 0;
        for dir in ["../../tasks/pending", "../../tasks/active", "../../tasks/completed", "../../tasks/postponed"] {
            if let Ok(entries) = fs::read_dir(dir) {
                for entry in entries.filter_map(|e| e.ok()) {
                    if let Some(id_str) = entry.file_name().to_string_lossy().split('_').next() {
                         if let Ok(id) = id_str.parse::<usize>() { 
                             if id > max_id { 
                                 max_id = id; 
                             } 
                         }
                    }
                }
            }
        }
        let next_id = max_id + 1;
        (Path::new(pending_dir).join(format!("{:03}_{}.md", next_id, full_category_name)), format!("{:03}", next_id))
    };

    // Idempotent: Overwrite the file to ensure dead tasks are removed and structure is clean
    let mut file = OpenOptions::new()
        .create(true)
        .write(true)
        .truncate(true)
        .open(&path)?;

    file.write_all(format!("# Task {}: {}\n\n## Objective\n{}\n\n## Tasks\n", 
        id, full_category_name.replace("_", " "), objective).as_bytes())?;

    for f in units {
        let line = if f.trim().starts_with("#") {
            format!("{}\n", f)
        } else {
            format!("- [ ] {}\n", f)
        };
        file.write_all(line.as_bytes())?;
    }
    Ok(Some(path))
}

/// Synchronize all architectural tasks with the task management system
pub fn sync_all_architectural_tasks(
    buffer: &HashMap<String, Vec<WorkUnit>>, 
    config: &EfficiencyConfig
) -> Result<()> {
    let mut ambiguities_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut violations_fe_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut violations_be_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut structural_fe_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut structural_be_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut merges_fe_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut merges_be_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut surgical_fe_units = Vec::new();
    let mut surgical_be_units = Vec::new();

    for units in buffer.values() {
        for unit in units {
            let strategy = generate_strategic_directive(unit);
            match unit {
                WorkUnit::Ambiguity { file, .. } => {
                    ambiguities_grouped.entry(("Classify Ambiguous Files".to_string(), strategy))
                        .or_default()
                        .push(format!("`{}`", file));
                },
                WorkUnit::Violation { file, pattern, .. } => {
                    let action = format!("Fix Pattern `{}`", pattern);
                    let groups = if file.contains("backend") || file.ends_with(".rs") { 
                        &mut violations_be_grouped 
                    } else { 
                        &mut violations_fe_grouped 
                    };
                    groups.entry((action, strategy))
                        .or_default()
                        .push(format!("`{}`", file));
                },
                WorkUnit::Surgical { file, reason, platform, complexity, action, recommended_splits, .. } => {
                    let clean_reason = reason.split(" (AI Context Fog").next().unwrap_or(reason).to_string();
                    if platform == "backend" { 
                        surgical_be_units.push((file.clone(), clean_reason, action.clone(), strategy, *complexity, *recommended_splits)); 
                    } else { 
                        surgical_fe_units.push((file.clone(), clean_reason, action.clone(), strategy, *complexity, *recommended_splits)); 
                    }
                },
                WorkUnit::Structural { file, reason, platform, action, .. } => {
                    let groups = if platform == "backend" { 
                        &mut structural_be_grouped 
                    } else { 
                        &mut structural_fe_grouped 
                    };
                    groups.entry((action.clone(), strategy))
                        .or_default()
                        .push(format!("**{}** (Metric: {})", file, reason));
                },
                WorkUnit::Merge { folder, files, reason, platform, .. } => {
                    let mut sorted_files = files.clone();
                    sorted_files.sort();
                    let mut item = format!("Folder: `{}` (Metric: {})", folder, reason);
                    for f in sorted_files {
                        let full_path = Path::new(folder).join(f);
                        item.push_str(&format!("\n    - `{}`", full_path.to_string_lossy()));
                    }
                    let groups = if platform == "backend" { 
                        &mut merges_be_grouped 
                    } else { 
                        &mut merges_fe_grouped 
                    };
                    groups.entry(("Merge Fragmented Folders".to_string(), strategy))
                        .or_default()
                        .push(item);
                },
            }
        }
    }

    let format_groups = |groups: HashMap<(String, String), Vec<String>>| -> Vec<String> {
        let mut lines = Vec::new();
        let mut sorted_keys: Vec<_> = groups.keys().collect();
        sorted_keys.sort();

        for key in sorted_keys {
            lines.push(format!("\n### 🔧 Action: {}\n**Directive:** {}\n", key.0, key.1));
            let mut items = groups.get(key).unwrap().clone();
            items.sort();
            for item in items {
                lines.push(item);
            }
        }
        lines
    };

    let surgical_obj = config.templates.surgical_objective
        .replace("{nesting_w}", &format!("{:.2}", config.settings.nesting_weight))
        .replace("{density_w}", &format!("{:.2}", config.settings.density_weight))
        .replace("{drag_t}", &format!("{:.2}", config.settings.drag_target));

    let merge_obj = config.templates.merge_objective
        .replace("{merge_t}", &format!("{:.2}", config.settings.merge_score_threshold));

    let mut role_list = String::new();
    for (role, data) in &config.taxonomy {
        role_list.push_str(&format!("*   **{}**: {}\n", role, data.desc.as_ref().cloned().unwrap_or_default()));
    }
    let ambiguity_obj = config.templates.ambiguity_objective.replace("{roles}", &role_list);

    let mut active_tasks = HashSet::new();

    let sync_surgical = |units: Vec<(String, String, String, String, f64, usize)>, platform: &str| -> Result<Vec<PathBuf>> {
        let mut paths = Vec::new();
        let mut domain_groups: HashMap<String, Vec<(String, String, String, String, f64, usize)>> = HashMap::new();
        for unit in units {
            let parent = Path::new(&unit.0).parent()
                .map(|p| p.to_string_lossy().to_string())
                .unwrap_or_default();
            domain_groups.entry(parent).or_default().push(unit);
        }

        for (domain, domain_units) in domain_groups {
            let mut action_groups: HashMap<String, Vec<(String, String, String, usize)>> = HashMap::new();
            
            for (file, reason, action, strategy, _comp, splits) in domain_units {
                action_groups.entry(action).or_default().push((file, reason, strategy, splits));
            }

            let domain_name = Path::new(&domain).file_name()
                .map(|n| n.to_string_lossy().to_uppercase())
                .unwrap_or_default();
            let category_name = format!("Surgical_Refactor_{}", domain_name);

            let mut lines = Vec::new();

            for (action, mut items) in action_groups {
                items.sort();
                let strategy = &items[0].2;
                lines.push(format!("\n### 🔧 Action: {}\n**Directive:** {}\n", action, strategy));

                for (file, reason, _, _) in items {
                    let entry = format!("- **{}** (Metric: {})\n", file, reason);
                    lines.push(entry);
                }
            }

            if let Some(path) = sync_architectural_category(&category_name, platform, &lines, &surgical_obj)? {
                paths.push(path);
            }
        }
        Ok(paths)
    };

    // Priority Order Enforcement
    if let Some(p) = sync_architectural_category("Classify_Ambiguous_Files", "", &format_groups(ambiguities_grouped), &ambiguity_obj)? { 
        active_tasks.insert(p); 
    }

    if let Some(p) = sync_architectural_category("Structural_Refactor", "Frontend", &format_groups(structural_fe_grouped), &config.templates.structural_objective)? { 
        active_tasks.insert(p); 
    }
    if let Some(p) = sync_architectural_category("Structural_Refactor", "Backend", &format_groups(structural_be_grouped), &config.templates.structural_objective)? { 
        active_tasks.insert(p); 
    }

    if let Some(p) = sync_architectural_category("Fix_Violations", "Frontend", &format_groups(violations_fe_grouped), &config.templates.violation_objective)? { 
        active_tasks.insert(p); 
    }
    if let Some(p) = sync_architectural_category("Fix_Violations", "Backend", &format_groups(violations_be_grouped), &config.templates.violation_objective)? { 
        active_tasks.insert(p); 
    }

    active_tasks.extend(sync_surgical(surgical_fe_units, "Frontend")?);
    active_tasks.extend(sync_surgical(surgical_be_units, "Backend")?);

    if let Some(p) = sync_architectural_category("Merge_Folders", "Frontend", &format_groups(merges_fe_grouped), &merge_obj)? { 
        active_tasks.insert(p); 
    }
    if let Some(p) = sync_architectural_category("Merge_Folders", "Backend", &format_groups(merges_be_grouped), &merge_obj)? { 
        active_tasks.insert(p); 
    }

    // Zombie Elimination
    let pending_dir = "../../tasks/pending";
    let arch_patterns = ["Surgical_Refactor_", "Merge_Folders_", "Fix_Violations_", "Structural_Refactor_", "Classify_Ambiguous_Files"];
    
    if let Ok(entries) = fs::read_dir(pending_dir) {
        for entry in entries.filter_map(|e| e.ok()) {
            let path = entry.path();
            if !path.is_file() { continue; }
            let name = path.file_name()
                .map(|n| n.to_string_lossy())
                .unwrap_or_default();
            
            let is_arch = arch_patterns.iter().any(|p| name.contains(p));
            if is_arch && !active_tasks.contains(&path) {
                println!("🧹 Deleting zombie task: {:?}", path);
                let _ = fs::remove_file(path);
            }
        }
    }

    Ok(())
}
