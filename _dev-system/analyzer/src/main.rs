mod drivers;
mod consolidator;
mod guard;
mod graph;
mod state;
mod feedback;

use efficiency_analyzer::resolver::Resolver;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;
use serde::Deserialize;
use std::collections::{HashMap, HashSet};
use anyhow::{Context, Result};
use graph::DependencyGraph;

use drivers::{parse_header, EfficiencyOverride};
use consolidator::{FolderStats, calculate_merge_score, find_recursive_clusters, FileInfo};
use drivers::rust::analyze_rust;
use drivers::rescript::analyze_rescript;
use drivers::html::analyze_html;
use drivers::css::analyze_css;
use drivers::config::analyze_config;

#[derive(Debug, Deserialize)]
struct EfficiencyConfig {
    scanned_roots: Option<Vec<String>>,
    entry_points: Option<Vec<String>>,
    settings: Settings,
    templates: Templates,
    exclusion_rules: guard::ExclusionRules,
    profiles: HashMap<String, Profile>,
    taxonomy: HashMap<String, TaxonomyRole>,
    exceptions: Option<Vec<ExceptionRule>>,
    protected_patterns: Option<Vec<String>>,
}

#[derive(Debug, Deserialize)]
struct Templates {
    legend: String,
    surgical_objective: String,
    violation_objective: String,
    structural_objective: String,
    merge_objective: String,
    ambiguity_objective: String,
}


#[derive(Debug, Deserialize)]
struct ExceptionRule {
    pattern: String,
    max_loc: Option<usize>,
    multiplier: Option<f64>,
}

#[derive(Debug, Deserialize)]
struct Settings {
    min_dead_code_loc: usize,
    base_loc_limit: usize,
    hard_ceiling_loc: usize,
    soft_floor_loc: usize,
    #[allow(dead_code)]
    max_session_complexity: f64,
    merge_score_threshold: f64,
    nesting_weight: f64,
    density_weight: f64,
    drag_target: f64,
    state_weight: f64,
    max_depth_threshold: usize,
}

#[derive(Debug, Deserialize)]
struct Profile {
    complexity_dictionary: HashMap<String, f64>,
    forbidden_patterns: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct TaxonomyRole {
    multiplier: f64,
    desc: Option<String>,
}

#[derive(Debug, Clone, serde::Serialize)]
enum WorkUnit {
    Ambiguity { file: String, strategy: String },
    Violation { file: String, pattern: String, strategy: String },
    Surgical { file: String, action: String, reason: String, strategy: String, platform: String, complexity: f64 },
    Merge { folder: String, files: Vec<String>, reason: String, strategy: String, platform: String },
    Structural { file: String, action: String, reason: String, strategy: String, platform: String },
}

use guard::is_project_source;

fn infer_taxonomy(path: &Path, content: &str) -> String {
    let p = path.to_string_lossy().to_lowercase();
    let f = path.file_name().unwrap_or_default().to_string_lossy().to_lowercase();
    let ext = path.extension().and_then(|s| s.to_str()).unwrap_or("");
    if ext != "json" && ext != "yaml" {
        match parse_header(content) {
            EfficiencyOverride::Ignore => return "ignored".to_string(),
            EfficiencyOverride::Role(name) => return name,
            _ => {}
        }
    }
    if f == "cargo.toml" || f == "package.json" || f.contains("config") || p.contains("/scripts/") || ext == "json" || ext == "toml" || ext == "yaml" { return "infra-config".to_string(); }
    if f == "main.rs" || f == "lib.rs" || f == "mod.rs" || f == "main.res" || f == "app.res" || f == "index.js" || p.contains("actions") || p.contains("serviceworker") { return "orchestrator".to_string(); }
    if p.contains("/systems/") || p.contains("logic") || p.contains("manager") { return "service-orchestrator".to_string(); }
    if p.contains("/core/") && !p.contains("types") { return "domain-logic".to_string(); }
    if p.contains("/components/") || p.contains("view") || p.contains("/public/") || ext == "css" || ext == "html" || ext == "jsx" { return "ui-component".to_string(); }
    if p.contains("reducer") || p.contains("state") { return "state-reducer".to_string(); }
    if p.contains("types") || p.contains("models") || p.contains("schemas") { return "data-model".to_string(); }
    if p.contains("api") || p.contains("client") || p.contains("bindings") || p.contains("context") { return "infra-adapter".to_string(); }
    if p.contains("utils") || p.contains("helpers") { return "util-pure".to_string(); }
    "unknown".to_string()
}

fn generate_strategic_directive(unit: &WorkUnit) -> String {
    match unit {
        WorkUnit::Surgical { reason, .. } => {
            if reason.contains("Nesting") && reason.contains("Density") {
                "Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.".to_string()
            } else if reason.contains("Nesting") {
                "Flatten Control Flow: Replace nested if/switch blocks with early returns or pattern matching.".to_string()
            } else if reason.contains("Density") {
                "Extract Service Logic: Move complex calculations or data transformations into specialized sub-modules.".to_string()
            } else {
                "De-bloat: Reduce module size by identifying and extracting independent domain logic.".to_string()
            }
        },
        WorkUnit::Merge { .. } => {
            "Unified Context: Consolidate these fragmented files into a single cohesive module to reduce token overhead during analysis.".to_string()
        },
        WorkUnit::Structural { action, .. } => {
            if action.contains("Flatten") {
                "Hierarchy Cleanup: Move these modules 1-2 levels higher to reduce the directory traversal tax.".to_string()
            } else {
                "Vertical Slicing: Group related UI and Logic files into a single 'Feature Pod' folder.".to_string()
            }
        },
        WorkUnit::Violation { pattern, .. } => {
            format!("Pattern Fix: Replace the forbidden '{}' pattern with the recommended functional alternative (Logger, Result/Option, etc).", pattern)
        },
        WorkUnit::Ambiguity { .. } => {
            "Taxonomy Resolution: Add the required @efficiency-role: <role> tag (including colon) to help the analyzer apply the correct complexity limits.".to_string()
        }
    }
}

fn calculate_dynamic_limit(
    drag: f64, 
    p_mod: f64, 
    cohesion_bonus: f64, 
    dynamic_base: f64, 
    config: &EfficiencyConfig,
    p_str: &str
) -> usize {
    let mut limit = ((dynamic_base * p_mod * cohesion_bonus) / drag.powf(0.75)).max(config.settings.soft_floor_loc as f64) as usize;
    
    if let Some(exceptions) = &config.exceptions {
        for rule in exceptions {
            if p_str.contains(&rule.pattern) {
                if let Some(max) = rule.max_loc {
                    limit = max;
                }
                break;
            }
        }
    }
    limit.min(config.settings.hard_ceiling_loc)
}

fn sync_architectural_category(category_name: &str, platform: &str, units: &[String], objective: &str) -> Result<Option<PathBuf>> {
    let pending_dir = "../../tasks/pending";
    let platform_label = if platform.is_empty() { "".to_string() } else { format!("_{}", platform.to_uppercase()) };
    let full_category_name = format!("{}{}", category_name, platform_label);
    let mut existing_path = None;
    if let Ok(entries) = fs::read_dir(pending_dir) {
        for entry in entries.filter_map(|e| e.ok()) {
            let name = entry.file_name().to_string_lossy().into_owned();
            if name.contains(&full_category_name) { existing_path = Some(entry.path()); break; }
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
                         if let Ok(id) = id_str.parse::<usize>() { if id > max_id { max_id = id; } }
                    }
                }
            }
        }
        let next_id = max_id + 1;
        (Path::new(pending_dir).join(format!("{:03}_{}.md", next_id, full_category_name)), format!("{:03}", next_id))
    };

    // Idempotent: Overwrite the file to ensure dead tasks are removed and structure is clean
    let mut file = OpenOptions::new().create(true).write(true).truncate(true).open(&path)?;

    file.write_all(format!("# Task {}: {}\n\n## Objective\n{}\n\n## Tasks\n", id, full_category_name.replace("_", " "), objective).as_bytes())?;

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

fn sync_all_architectural_tasks(buffer: &HashMap<String, Vec<WorkUnit>>, config: &EfficiencyConfig) -> Result<()> {
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
                    ambiguities_grouped.entry(("Classify Ambiguous Files".to_string(), strategy)).or_default().push(format!("`{}`", file));
                },
                WorkUnit::Violation { file, pattern, .. } => {
                    let action = format!("Fix Pattern `{}`", pattern);
                    let groups = if file.contains("backend") || file.ends_with(".rs") { &mut violations_be_grouped } else { &mut violations_fe_grouped };
                    groups.entry((action, strategy)).or_default().push(format!("`{}`", file));
                },
                WorkUnit::Surgical { file, reason, platform, complexity, action, .. } => {
                    // Clean up reason: remove the verbose AI explanation, keep the metrics
                    let clean_reason = reason.split(" (AI Context Fog").next().unwrap_or(reason).to_string();
                    if platform == "backend" { surgical_be_units.push((file.clone(), clean_reason, action.clone(), strategy, *complexity)); }
                    else { surgical_fe_units.push((file.clone(), clean_reason, action.clone(), strategy, *complexity)); }
                },
                WorkUnit::Structural { file, reason, platform, action, .. } => {
                    let groups = if platform == "backend" { &mut structural_be_grouped } else { &mut structural_fe_grouped };
                    groups.entry((action.clone(), strategy)).or_default().push(format!("**{}** (Metric: {})", file, reason));
                },
                WorkUnit::Merge { folder, files, reason, platform, .. } => {
                    let mut sorted_files = files.clone();
                    sorted_files.sort();
                    let mut item = format!("Folder: `{}` (Metric: {})", folder, reason);
                    for f in sorted_files {
                        // Concatenate folder and filename to provide full path context
                        let full_path = Path::new(folder).join(f);
                        item.push_str(&format!("\n    - `{}`", full_path.to_string_lossy()));
                    }
                    let groups = if platform == "backend" { &mut merges_be_grouped } else { &mut merges_fe_grouped };
                    groups.entry(("Merge Fragmented Folders".to_string(), strategy)).or_default().push(item);
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

    let sync_surgical = |units: Vec<(String, String, String, String, f64)>, platform: &str| -> Result<Vec<PathBuf>> {
        let mut paths = Vec::new();
        // Group by Parent Directory (Domain) to minimize context switching
        let mut domain_groups: HashMap<String, Vec<(String, String, String, String, f64)>> = HashMap::new();
        for unit in units {
            let parent = Path::new(&unit.0).parent().unwrap_or(Path::new("")).to_string_lossy().to_string();
            domain_groups.entry(parent).or_default().push(unit);
        }

        for (domain, domain_units) in domain_groups {
            // Group by Action (Directive)
            let mut action_groups: HashMap<String, Vec<(String, String, String)>> = HashMap::new(); // Action -> Vec<(File, Reason, Strategy)>
            
            for (file, reason, action, strategy, _comp) in domain_units {
                action_groups.entry(action).or_default().push((file, reason, strategy));
            }

            // Heuristic for naming: Use the last part of the path (e.g., "systems", "core")
            let domain_name = Path::new(&domain).file_name().unwrap_or_default().to_string_lossy().to_uppercase();
            let category_name = format!("Surgical_Refactor_{}", domain_name);

            let mut lines = Vec::new();

            for (action, mut items) in action_groups {
                // Sort items for determinism
                items.sort();
                // Extract strategy from the first item (assuming consistent strategy per action)
                let strategy = &items[0].2;
                lines.push(format!("\n### 🔧 Action: {}\n**Directive:** {}\n", action, strategy));

                for (file, reason, _) in items {
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
    // 1. Ambiguity (Clarify)
    if let Some(p) = sync_architectural_category("Classify_Ambiguous_Files", "", &format_groups(ambiguities_grouped), &ambiguity_obj)? { active_tasks.insert(p); }

    // 2. Structural (Fix hierarchy first)
    if let Some(p) = sync_architectural_category("Structural_Refactor", "Frontend", &format_groups(structural_fe_grouped), &config.templates.structural_objective)? { active_tasks.insert(p); }
    if let Some(p) = sync_architectural_category("Structural_Refactor", "Backend", &format_groups(structural_be_grouped), &config.templates.structural_objective)? { active_tasks.insert(p); }

    // 3. Violations (Fix critical bugs)
    if let Some(p) = sync_architectural_category("Fix_Violations", "Frontend", &format_groups(violations_fe_grouped), &config.templates.violation_objective)? { active_tasks.insert(p); }
    if let Some(p) = sync_architectural_category("Fix_Violations", "Backend", &format_groups(violations_be_grouped), &config.templates.violation_objective)? { active_tasks.insert(p); }

    // 4. Surgical (Optimize specific files)
    active_tasks.extend(sync_surgical(surgical_fe_units, "Frontend")?);
    active_tasks.extend(sync_surgical(surgical_be_units, "Backend")?);

    // 5. Merges (Cleanup)
    if let Some(p) = sync_architectural_category("Merge_Folders", "Frontend", &format_groups(merges_fe_grouped), &merge_obj)? { active_tasks.insert(p); }
    if let Some(p) = sync_architectural_category("Merge_Folders", "Backend", &format_groups(merges_be_grouped), &merge_obj)? { active_tasks.insert(p); }

    // --- Zombie Elimination ---
    // Cleanup any pending architectural tasks that were NOT updated in this run
    let pending_dir = "../../tasks/pending";
    let arch_patterns = ["Surgical_Refactor_", "Merge_Folders_", "Fix_Violations_", "Structural_Refactor_", "Classify_Ambiguous_Files"];
    
    if let Ok(entries) = fs::read_dir(pending_dir) {
        for entry in entries.filter_map(|e| e.ok()) {
            let path = entry.path();
            if !path.is_file() { continue; }
            let name = path.file_name().unwrap_or_default().to_string_lossy();
            
            let is_arch = arch_patterns.iter().any(|p| name.contains(p));
            if is_arch && !active_tasks.contains(&path) {
                println!("🧹 Deleting zombie task: {:?}", path);
                let _ = fs::remove_file(path);
            }
        }
    }

    Ok(())
}

fn flush_plans(buffer: &HashMap<String, Vec<WorkUnit>>, config: &EfficiencyConfig) -> Result<()> {
    for (driver_name, units) in buffer {
        if units.is_empty() { continue; } 
        let plan_path = format!("../plans/{}_PLAN.md", driver_name.to_uppercase());
        let mut file = OpenOptions::new().create(true).truncate(true).write(true).open(&plan_path).context("Open fail")?;
        file.write_all(format!("# {} MASTER PLAN\n", driver_name.to_uppercase()).as_bytes())?;
        file.write_all(config.templates.legend.as_bytes())?;

        let ambiguities: Vec<&WorkUnit> = units.iter().filter(|u| matches!(u, WorkUnit::Ambiguity { .. })).collect();
        if !ambiguities.is_empty() {
            file.write_all(format!("## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION ({})\n", ambiguities.len()).as_bytes())?;
            for unit in ambiguities {
                if let WorkUnit::Ambiguity { file: f_path, .. } = unit {
                    file.write_all(format!("- [ ] `{}`\n", f_path).as_bytes())?;
                }
            }
            file.write_all(b"\n---\n\n")?;
        }

        let surgicals: Vec<&WorkUnit> = units.iter().filter(|u| matches!(u, WorkUnit::Surgical { .. })).collect();
        if !surgicals.is_empty() {
            file.write_all(format!("## 🛠️ SURGICAL REFACTOR TASKS ({})\n", surgicals.len()).as_bytes())?;
            for unit in surgicals {
                if let WorkUnit::Surgical { file: f_path, reason, .. } = unit {
                    file.write_all(format!("- [ ] **{}**\n  - *Reason:* {}\n", f_path, reason).as_bytes())?;
                }
            }
            file.write_all(b"\n---\n\n")?;
        }

        let structural: Vec<&WorkUnit> = units.iter().filter(|u| matches!(u, WorkUnit::Structural { .. })).collect();
        if !structural.is_empty() {
            file.write_all(format!("## 🏗️ STRUCTURAL REFACTOR TASKS ({})\n", structural.len()).as_bytes())?;
            for unit in structural {
                if let WorkUnit::Structural { file: f, action, reason, .. } = unit {
                    file.write_all(format!("- [ ] **{}** (Action: {})\n  - *Reason:* {}\n", f, action, reason).as_bytes())?;
                }
            }
            file.write_all(b"\n---\n\n")?;
        }

        let merges: Vec<&WorkUnit> = units.iter().filter(|u| matches!(u, WorkUnit::Merge { .. })).collect();
        if !merges.is_empty() {
            file.write_all(format!("## 🧩 MERGE TASKS ({})\n", merges.len()).as_bytes())?;
            for unit in merges {
                if let WorkUnit::Merge { folder, files, reason, .. } = unit {
                    file.write_all(format!("### Merge Folder: `{}`\n- **Reason:** {}\n- **Files:**\n", folder, reason).as_bytes())?;
                    for f in files {
                         let full_path = Path::new(folder).join(f);
                        file.write_all(format!("  - `{}`\n", full_path.to_string_lossy()).as_bytes())?;
                    }
                }
            }
        }
    }
    Ok(())
}

fn main() -> Result<()> {
    // println!("🚀 _dev-system: Starting AGGREGATED Scan (v8)...");
    let mut state = state::AnalyzerState::load();
    let guard_config = guard::GuardConfig::default();
    let config_raw = fs::read_to_string("../config/efficiency.json")?;
    let config: EfficiencyConfig = serde_json::from_str(&config_raw)?;
    let mut buffer: HashMap<String, Vec<WorkUnit>> = HashMap::new();
    let mut dir_stats: HashMap<(String, String), Vec<(String, usize, String, f64, f64)>> = HashMap::new();
    let mut feature_map: HashMap<String, Vec<(String, String)>> = HashMap::new(); 
    let default_dict: HashMap<String, f64> = HashMap::new();

    // --- Phase 0: Feedback Loop ---
    let failed_items = feedback::get_recent_failures();
    // We can't map failures to full paths yet, so we'll do it during discovery or registry building.

    // --- Phase 1: Discovery & Analysis ---
    // In this phase, we load all files, run the language drivers to get metrics (including dependencies),
    // and build a registry of everything in the project.

    // Registry: PathString -> (PathBuf, Content, Taxonomy, Metrics, Platform, DriverName)
    let mut registry: HashMap<String, (PathBuf, String, String, drivers::CommonMetrics, String, String)> = HashMap::new();
    // Resolver Map: FileNameStem -> Vec<FullPathString> (For resolving "User" to "src/core/User.res")
    let mut file_resolver: HashMap<String, Vec<String>> = HashMap::new();
    let mut all_files_set: HashSet<String> = HashSet::new();

    let mut total_loc = 0;
    let mut file_count = 0;

    let roots = config.scanned_roots.clone().unwrap_or_else(|| vec!["../../".to_string()]);

    // Entry Points setup
    let mut entry_points = HashSet::new();
    if let Some(eps) = &config.entry_points {
        for ep in eps {
             entry_points.insert(format!("../../{}", ep));
        }
    }

    for root in roots {
        let walk_path = if root.starts_with("../../") { root.clone() } else { format!("../../{}", root) };
        // println!("📂 Scanning Root: {}", walk_path);

        for entry in WalkDir::new(walk_path).into_iter().filter_map(|e| e.ok()) {
            let path = entry.path();
            if !path.is_file() || !is_project_source(path, &config.exclusion_rules) { continue; }

            if let Ok(content) = fs::read_to_string(path) {
                if content.contains("@efficiency-role: ignored") || content.contains("@efficiency-role ignored") { continue; }

                let p_str = path.to_string_lossy().to_string();

                // --- Analyze File ---
                let taxonomy = infer_taxonomy(path, &content);
                // Skip analysis for ignored files early
                if taxonomy == "ignored" { continue; }

                let ext = path.extension().and_then(|s| s.to_str()).unwrap_or("");
                let d_name = match ext { "rs" => "rust", "res" => "rescript", "jsx"|"js"|"html" => "web", "css" => "css", _ => "config" };
                let platform = if ext == "rs" || path.to_string_lossy().contains("backend") { "backend" } else { "frontend" };

                let dict = config.profiles.get(d_name).map(|p| &p.complexity_dictionary).unwrap_or(&default_dict);

                let metrics = match d_name {
                    "rust" => analyze_rust(&content, dict).unwrap_or_default(),
                    "rescript" => analyze_rescript(&content, dict).unwrap_or_default(),
                    "web" => analyze_html(&content, dict).unwrap_or_default(),
                    "css" => analyze_css(&content, dict).unwrap_or_default(),
                    _ => analyze_config(&content, dict).unwrap_or_default(),
                };

                if metrics.loc > 0 {
                    total_loc += metrics.loc;
                    file_count += 1;
                }

                // Register for Graph & Processing
                all_files_set.insert(p_str.clone());

                let file_stem = path.file_stem().unwrap_or_default().to_string_lossy().to_string();

                // Feedback Loop Integration
                // Check if this file matches any failure logs (by full path or stem/module name)
                if failed_items.contains(&p_str) || failed_items.contains(&file_stem) {
                     state.mark_failure(&p_str);
                     // println!("⚠️ Marked Failure for: {}", p_str);
                }

                file_resolver.entry(file_stem.clone()).or_default().push(p_str.clone());

                // Store in registry
                registry.insert(p_str, (path.to_path_buf(), content, taxonomy, metrics, platform.to_string(), d_name.to_string()));
            }
        }
    }

    let project_avg_loc = if file_count > 0 { total_loc as f64 / file_count as f64 } else { config.settings.base_loc_limit as f64 };
    let dynamic_base = (config.settings.base_loc_limit as f64 * 0.8) + (project_avg_loc * 0.2);
    // println!("📊 Project Stats: Avg LOC {:.0} -> Dynamic Base Adjusted to {:.0}", project_avg_loc, dynamic_base);

    // --- Phase 2: Graph Construction ---
    let mut dep_graph = DependencyGraph::new();
    let resolver = Resolver::new(file_resolver.clone());

    // Sanity Guard: Ensure all orchestrators are treated as entry points
    // Protection 3.0: Also treat everything in MAP.md as an entry point (Vital Modules)
    let mapped_files = guard::get_mapped_files(&guard_config);
    for f in mapped_files {
        entry_points.insert(f);
    }

    for (p_str, (_, content, taxonomy, _, _, _)) in &registry {
        // Any file with a specific role that is NOT ignored is likely an entry point or vital
        if taxonomy == "orchestrator" || taxonomy == "service-orchestrator" {
            entry_points.insert(p_str.clone());
        }
        
        // Entry Point Protection 2.0: Check for protected patterns
        if let Some(protected) = &config.protected_patterns {
            for pattern in protected {
                if p_str.contains(pattern) || content.contains(pattern) {
                    entry_points.insert(p_str.clone());
                }
            }
        }
    }

    for (path_str, (_, _, _, metrics, _, _)) in &registry {
        for dep in &metrics.dependencies {
            let matches = resolver.resolve(dep);
            for m in matches {
                dep_graph.add_dependency(path_str, &m);
            }
        }
    }

    // --- Phase 3: Task Generation (Synthesis) ---

    // Dead Code Pass
    let reachable_files = dep_graph.find_dead_code(&all_files_set, &entry_points);
    // Note: find_dead_code returns *Dead* files (unreachable), naming is confusing in graph mod?
    // Checking graph/mod.rs: "all_files.difference(&visited).cloned().collect()" -> YES, it returns DEAD files.
    let dead_files: HashSet<String> = reachable_files.into_iter().collect();

    for (p_str, (path, content, taxonomy, metrics, platform, d_name)) in &registry {
        let path = path.as_path();

        // 1. Ambiguity Check
        if taxonomy == "unknown" {
             buffer.entry("system".to_string()).or_default().push(WorkUnit::Ambiguity { file: p_str.clone(), strategy: String::new() });
        }

        // 2. Metrics Calculation (Common for all files)
        let density = metrics.logic_count as f64 / metrics.loc as f64;
        let dependency_density = metrics.external_calls as f64 / metrics.loc as f64;
        let coupling_score = if metrics.loc > 0 { metrics.external_calls as f64 / metrics.loc as f64 } else { 0.0 };

        // Taxonomy Multiplier
        let mut p_mod = config.taxonomy.get(taxonomy).map(|t| t.multiplier).unwrap_or(1.0);
        if let Some(exceptions) = &config.exceptions { for rule in exceptions { if p_str.contains(&rule.pattern) { if let Some(m) = rule.multiplier { p_mod *= m; } break; } } }

        let cohesion_bonus = 1.0 + (0.5 - dependency_density).max(0.0);
        let complexity_density = if metrics.loc > 0 { metrics.complexity_penalty / metrics.loc as f64 } else { 0.0 };
        let state_density = if metrics.loc > 0 { metrics.state_count as f64 / metrics.loc as f64 } else { 0.0 };

        let clean_path_from_root = p_str.replace("../../", "");
        let clean_path_obj = Path::new(&clean_path_from_root);
        let dir_depth = clean_path_obj.components().count().saturating_sub(config.settings.max_depth_threshold) as f64;
        let depth_penalty = if dir_depth > 0.0 { dir_depth * 0.5 } else { 0.0 };

        let failure_penalty_mult = state.get_drag_multiplier(p_str);
        let drag = (1.0 + (metrics.max_nesting as f64 * config.settings.nesting_weight) + (density * config.settings.density_weight) + (complexity_density * 20.0) + (state_density * config.settings.state_weight) + depth_penalty) * failure_penalty_mult;

        let limit = calculate_dynamic_limit(drag, p_mod, cohesion_bonus, dynamic_base, &config, p_str);

        // 3. Dead Code Task (Check for ALL files)
        if dead_files.contains(p_str) && metrics.loc > config.settings.min_dead_code_loc {
             buffer.entry(d_name.clone()).or_default().push(WorkUnit::Surgical {
                file: p_str.clone(),
                action: "Audit & Delete".to_string(),
                reason: format!("Unreachable Module. Not referenced by any entry point. (LOC: {})", metrics.loc),
                strategy: String::new(),
                platform: platform.clone(),
                complexity: 0.0
             });
        }

        let mut is_surgical = false;
        if taxonomy != "unknown" {
            // 4. Surgical Refactor Task (De-bloat) - Only for known modules
            if metrics.loc > limit {
                is_surgical = true;
                let nesting_factor = metrics.max_nesting as f64 * config.settings.nesting_weight;
                let density_factor = density * config.settings.density_weight;
                let breakdown = format!("[Nesting: {:.2}, Density: {:.2}, Coupling: {:.2}] | Drag: {:.2} | LOC: {}/{}",
                    nesting_factor, density_factor, coupling_score, drag, metrics.loc, limit);
                let mut reason = breakdown;

                // Enhanced Semantic Hotspot
                if let Some(symbol) = &metrics.hotspot_symbol {
                    reason = format!("{}  🎯 Target: {} ({})", reason, symbol, metrics.hotspot_reason.as_ref().unwrap_or(&"Complex Logic".to_string()));
                } else if let Some((s, e)) = metrics.hotspot_lines {
                    reason = format!("{}  Hotspot: Lines {}-{} ({})", reason, s, e, metrics.hotspot_reason.as_ref().unwrap_or(&String::new()));
                }

                let complexity = ((metrics.loc - limit) as f64 / 10.0) + drag;

                let action = "De-bloat".to_string();

                buffer.entry(d_name.clone()).or_default().push(WorkUnit::Surgical {
                    file: p_str.clone(),
                    action, 
                    reason, 
                    strategy: String::new(),
                    platform: platform.clone(),
                    complexity 
                });
            }

            // Conflict Locking: If a file is surgical, it cannot be merged.
            // Also, only known taxonomies are considered for merging.
            if !is_surgical && taxonomy != "unknown" {
                // 5. Stats Aggregation for Merges - Only for known modules AND non-surgical files (Conflict Locking)
                let dir = path.parent().map(|p| p.to_string_lossy().to_string()).unwrap_or_else(|| ".".to_string());
                let ext_str = path.extension().and_then(|s| s.to_str()).unwrap_or("").to_string();
                let f_name = path.file_name().map(|n| n.to_string_lossy().to_string()).unwrap_or_default();
                dir_stats.entry((dir, ext_str)).or_default().push((f_name, metrics.loc, platform.clone(), drag, p_mod));

                let file_stem = path.file_stem().unwrap_or_default().to_string_lossy().to_string();
                if file_stem.len() > 3 { feature_map.entry(file_stem).or_default().push((p_str.clone(), platform.clone())); }
            }
        }

        // 6. Violation Check (Check for ALL files)
        if let Some(profile) = config.profiles.get(d_name) {
             let treat_single_quote_as_string = d_name != "rescript" && d_name != "rust";
             let stripped = drivers::strip_code_modular(&content, treat_single_quote_as_string);
             for pattern in &profile.forbidden_patterns {
                 if stripped.contains(pattern) {
                     let unit = WorkUnit::Violation {
                         file: p_str.clone(),
                         pattern: pattern.clone(),
                         strategy: String::new()
                     };
                     buffer.entry(d_name.clone()).or_default().push(unit);
                 }
             }
         }

         let _ = guard::check_tests(&guard_config, path);
    }
    // --- Phase 4: Recursive Cluster Analysis ---
    // Group files by (Platform, Extension) to find "Feature Pods" across subdirectories
    let mut recursive_groups: HashMap<(String, String), Vec<FileInfo>> = HashMap::new();
    let mut processed_merge_files: HashSet<String> = HashSet::new();

    for (p_str, (_, _, _, metrics, platform, _)) in &registry {
        // --- Circularity Prevention: Skip unreachable files OR surgical files for merging ---
        if dead_files.contains(p_str) || buffer.values().any(|units| units.iter().any(|u| if let WorkUnit::Surgical { file, .. } = u { file == p_str } else { false })) { continue; }

        let drag = 1.0 + (metrics.max_nesting as f64 * config.settings.nesting_weight) + ((metrics.logic_count as f64 / metrics.loc as f64) * config.settings.density_weight) + ((metrics.complexity_penalty / metrics.loc as f64) * 20.0);

        // We use extension as a proxy for language/compatibility
        let ext = Path::new(p_str).extension().and_then(|s| s.to_str()).unwrap_or("").to_string();
        recursive_groups.entry((platform.clone(), ext)).or_default().push(FileInfo {
            path: p_str.clone(),
            loc: metrics.loc,
            drag,
        });
    }

    // Priority 1: Recursive Feature Pods (Deep Clustering)
    for ((platform, _ext), files) in recursive_groups {
        let clusters = find_recursive_clusters(files, config.settings.hard_ceiling_loc);
        for cluster in clusters {
             // NEW: Recommendation 4 - Check if this cluster would violate the dynamic limit
             let projected_limit = calculate_dynamic_limit(cluster.max_drag, 1.0, 1.0, dynamic_base, &config, &cluster.root_folder);
             
             if cluster.total_loc as f64 > projected_limit as f64 {
                 continue; // Too complex to merge as a pod
             }

             for f in &cluster.files { processed_merge_files.insert(f.clone()); }
             buffer.entry("system".to_string()).or_default().push(WorkUnit::Merge {
                folder: cluster.root_folder.clone(),
                files: cluster.files.clone(),
                platform: platform.clone(),
                reason: format!("Recursive Feature Pod: {} files in subtree sum to {} LOC (fits in context). Max Drag: {:.2}", cluster.files.len(), cluster.total_loc, cluster.max_drag),
                strategy: String::new()
            });
        }
    }

    // Priority 2: Shallow Folder Merges (with De-duplication)
    for ((dir, _ext), files) in dir_stats {
        // Stability Guard: Don't merge if the folder is locked (recently modified/split)
        if state.is_locked(&dir) {
             continue;
        }

        // Filter out files that are already part of a Recursive Cluster
        let eligible_files: Vec<&(String, usize, String, f64, f64)> = files.iter().filter(|(name, _, _, _, _)| {
             let full_path = Path::new(&dir).join(name).to_string_lossy().to_string();
             !processed_merge_files.contains(&full_path)
        }).collect();

        if eligible_files.len() < 2 { continue; }

        let total: usize = eligible_files.iter().map(|(_,l,_,_,_)| *l).sum();

        // Smart Merge Logic: Circularity Prevention
        // Check if merging these files would create a file that immediately violates the Split limit.
        let max_drag: f64 = eligible_files.iter().map(|(_,_,_,d,_)| *d).fold(0.0, f64::max);
        let min_pmod: f64 = eligible_files.iter().map(|(_,_,_,_,m)| *m).fold(100.0, f64::min);
        let safe_drag = if max_drag < 1.0 { 1.0 } else { max_drag };
        
        let projected_limit = calculate_dynamic_limit(safe_drag, min_pmod, 1.0, dynamic_base, &config, &dir);

        let score = if total as f64 > projected_limit as f64 {
             0.0 // Force score to 0 to prevent merge
        } else {
             calculate_merge_score(FolderStats { file_count: eligible_files.len(), total_loc: total }, config.settings.hard_ceiling_loc)
        };

        if score > config.settings.merge_score_threshold {
            buffer.entry("system".to_string()).or_default().push(WorkUnit::Merge { 
                folder: dir.clone(), 
                files: eligible_files.iter().map(|(n,_,_,_,_)| n.clone()).collect(),
                platform: eligible_files[0].2.clone(),
                reason: format!("Read Tax high (Score {:.2}). Projected Limit: {:.0} (Drag {:.2})", score, projected_limit, safe_drag),
                strategy: String::new()
            });
        }

        // Structural: Deep nesting check
        let clean_dir_str = dir.replace("../../", "");
        let clean_dir = Path::new(&clean_dir_str);
        let dir_depth = clean_dir.components().count().saturating_sub(config.settings.max_depth_threshold);
        if dir_depth > 0 {
             buffer.entry("system".to_string()).or_default().push(WorkUnit::Structural {
                file: dir.clone(),
                action: "Flatten Hierarchy".to_string(),
                platform: files[0].2.clone(),
                reason: format!("Folder depth is {}. Flatten to reduce traversal tax.", clean_dir.components().count()),
                strategy: String::new()
            });
        }
    }
    for (feature, paths) in feature_map {
        if paths.len() > 2 {
            let mut unique_folders: Vec<String> = paths.iter().map(|(p, _)| {
                Path::new(p).parent()
                    .map(|pp| pp.to_string_lossy().to_string())
                    .unwrap_or_else(|| ".".to_string())
            }).collect();
            unique_folders.sort();
            unique_folders.dedup();

            if unique_folders.len() > 1 {
                let mut sorted_paths = paths.clone();
                sorted_paths.sort_by(|a, b| a.0.cmp(&b.0));

                let locations = sorted_paths.iter().map(|(p, _)| format!("`{}`", p)).collect::<Vec<_>>().join(", ");
                buffer.entry("system".to_string()).or_default().push(WorkUnit::Structural {
                    file: feature.clone(), action: "Vertical Slice".to_string(), platform: paths[0].1.clone(),
                    reason: format!("Feature fragmented across {} files: [{}]", paths.len(), locations),
                    strategy: String::new()
                });
            }
        }
    }
    let _ = fs::create_dir_all("../plans");
    let json_data = serde_json::to_string_pretty(&buffer).unwrap_or_default();
    let _ = fs::write("../plans/metadata.json", json_data);
    let _ = flush_plans(&buffer, &config);
    let _ = sync_all_architectural_tasks(&buffer, &config);
    let _ = guard::check_map(&guard_config, &config.exclusion_rules);
    let _ = guard::check_tasks_count(&guard_config);
    state.save()?;
    Ok(())
}

