mod drivers;
mod consolidator;
mod guard;

use std::fs::{self, OpenOptions};
use std::io::{Read, Write};
use std::path::Path;
use walkdir::WalkDir;
use serde::Deserialize;
use std::collections::HashMap;
use anyhow::{Context, Result};

use drivers::{parse_header, EfficiencyOverride};
use consolidator::{FolderStats, calculate_merge_score};
use drivers::rust::analyze_rust;
use drivers::rescript::analyze_rescript;
use drivers::html::analyze_html;
use drivers::css::analyze_css;
use drivers::config::analyze_config;

#[derive(Debug, Deserialize)]
struct EfficiencyConfig {
    settings: Settings,
    templates: Templates,
    exclusion_rules: ExclusionRules,
    profiles: HashMap<String, Profile>,
    taxonomy: HashMap<String, TaxonomyRole>,
    exceptions: Option<Vec<ExceptionRule>>,
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
struct ExclusionRules {
    folders: Vec<String>,
    files: Vec<String>,
    extensions: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct ExceptionRule {
    pattern: String,
    max_loc: Option<usize>,
    multiplier: Option<f64>,
}

#[derive(Debug, Deserialize)]
struct Settings {
    base_loc_limit: usize,
    hard_ceiling_loc: usize,
    soft_floor_loc: usize,
    max_session_complexity: f64,
    merge_score_threshold: f64,
    nesting_weight: f64,
    density_weight: f64,
    drag_target: f64,
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
    Ambiguity { file: String },
    Violation { file: String, pattern: String },
    Surgical { file: String, action: String, reason: String, platform: String, complexity: f64 },
    Merge { folder: String, files: Vec<String>, reason: String, platform: String },
    Structural { file: String, action: String, reason: String, platform: String },
}

fn is_project_source(path: &Path, rules: &ExclusionRules) -> bool {
    let p_str = path.to_string_lossy().replace("\\", "/");
    let file_name = path.file_name().unwrap_or_default().to_string_lossy();
    let ext = path.extension().and_then(|s| s.to_str()).unwrap_or("");
    let valid_extensions = ["rs", "res"];
    if !valid_extensions.contains(&ext) { return false; }
    for folder in &rules.folders { if p_str.contains(folder) { return false; } }
    for file in &rules.files { if file_name == *file { return false; } }
    for suffix in &rules.extensions { if file_name.ends_with(suffix) { return false; } }
    true
}

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
    if f == "main.rs" || f == "lib.rs" || f == "mod.rs" || f == "main.res" || f == "app.res" || p.contains("actions") || p.contains("serviceworker") { return "orchestrator".to_string(); }
    if p.contains("/systems/") || p.contains("logic") || p.contains("manager") { return "service-orchestrator".to_string(); }
    if p.contains("/core/") && !p.contains("types") { return "domain-logic".to_string(); }
    if p.contains("/components/") || p.contains("view") || p.contains("/public/") || ext == "css" || ext == "html" || ext == "jsx" { return "ui-component".to_string(); }
    if p.contains("reducer") || p.contains("state") { return "state-reducer".to_string(); }
    if p.contains("types") || p.contains("models") || p.contains("schemas") { return "data-model".to_string(); }
    if p.contains("api") || p.contains("client") || p.contains("bindings") || p.contains("context") { return "infra-adapter".to_string(); }
    if p.contains("utils") || p.contains("helpers") { return "util-pure".to_string(); }
    "unknown".to_string()
}

fn sync_architectural_category(category_name: &str, platform: &str, units: &[String], objective: &str) -> Result<()> {
    if units.is_empty() { return Ok(()); }
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
    
    let (path, id) = if let Some(p) = existing_path {
        let id_str = p.file_name().unwrap().to_string_lossy().split('_').next().unwrap_or("0").to_string();
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

    let mut file_content = String::new();
    if path.exists() {
        if let Ok(mut f) = fs::File::open(&path) {
            let _ = f.read_to_string(&mut file_content);
        }
    }

    let mut file = OpenOptions::new().create(true).append(true).open(path)?;
    if file_content.is_empty() {
        file.write_all(format!("# Task {}: {}\n\n## Objective\n{}\n\n## Tasks\n", id, full_category_name.replace("_", " "), objective).as_bytes())?;
    }

    for f in units {
        let line = format!("- [ ] {}\n", f);
        if !file_content.contains(f) {
            file.write_all(line.as_bytes())?;
        }
    }
    Ok(())
}

fn sync_all_architectural_tasks(buffer: &HashMap<String, Vec<WorkUnit>>, config: &EfficiencyConfig) -> Result<()> {
    let mut ambiguities = Vec::new();
    let mut violations_fe = Vec::new();
    let mut violations_be = Vec::new();
    let mut structural_fe = Vec::new();
    let mut structural_be = Vec::new();
    let mut merges_fe = Vec::new();
    let mut merges_be = Vec::new();
    let mut surgical_fe_units = Vec::new();
    let mut surgical_be_units = Vec::new();

    for units in buffer.values() {
        for unit in units {
            match unit {
                WorkUnit::Ambiguity { file } => ambiguities.push(format!("`{}`", file)),
                WorkUnit::Violation { file, pattern } => {
                    let item = format!("`{}` (Pattern: `{}`)", file, pattern);
                    if file.contains("backend") || file.ends_with(".rs") { violations_be.push(item); } else { violations_fe.push(item); }
                },
                WorkUnit::Surgical { file, reason, platform, complexity, .. } => {
                    let item = format!("**{}** - {}", file, reason);
                    if platform == "backend" { surgical_be_units.push((item, *complexity)); } 
                    else { surgical_fe_units.push((item, *complexity)); }
                },
                WorkUnit::Structural { file, reason, platform, .. } => {
                    let item = format!("**{}** - {}", file, reason);
                    if platform == "backend" { structural_be.push(item); } else { structural_fe.push(item); }
                },
                WorkUnit::Merge { folder, reason, platform, .. } => {
                    let item = format!("Folder: `{}` - {}", folder, reason);
                    if platform == "backend" { merges_be.push(item); } else { merges_fe.push(item); }
                },
            }
        }
    }

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

    let max_complexity = config.settings.max_session_complexity;
    let sync_surgical = |units: Vec<(String, f64)>, platform: &str| -> Result<()> {
        let mut batch = Vec::new();
        let mut current_complexity = 0.0;
        let mut batch_idx = 1;
        for (unit, comp) in units {
            if current_complexity + comp > max_complexity && !batch.is_empty() {
                sync_architectural_category(&format!("Surgical_Refactor_Batch_{}", batch_idx), platform, &batch, &surgical_obj)?;
                batch.clear(); current_complexity = 0.0; batch_idx += 1;
            }
            batch.push(unit); current_complexity += comp;
        }
        if !batch.is_empty() { sync_architectural_category(&format!("Surgical_Refactor_Batch_{}", batch_idx), platform, &batch, &surgical_obj)?; }
        Ok(())
    };

    // Priority Order Enforcement
    // 1. Ambiguity (Clarify)
    sync_architectural_category("Classify_Ambiguous_Files", "", &ambiguities, &ambiguity_obj)?;

    // 2. Structural (Fix hierarchy first)
    sync_architectural_category("Structural_Refactor", "Frontend", &structural_fe, &config.templates.structural_objective)?;
    sync_architectural_category("Structural_Refactor", "Backend", &structural_be, &config.templates.structural_objective)?;

    // 3. Violations (Fix critical bugs)
    sync_architectural_category("Fix_Violations", "Frontend", &violations_fe, &config.templates.violation_objective)?;
    sync_architectural_category("Fix_Violations", "Backend", &violations_be, &config.templates.violation_objective)?;

    // 4. Surgical (Optimize specific files)
    sync_surgical(surgical_fe_units, "Frontend")?;
    sync_surgical(surgical_be_units, "Backend")?;

    // 5. Merges (Cleanup)
    sync_architectural_category("Merge_Folders", "Frontend", &merges_fe, &merge_obj)?;
    sync_architectural_category("Merge_Folders", "Backend", &merges_be, &merge_obj)?;
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
                if let WorkUnit::Ambiguity { file: f_path } = unit {
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
                        file.write_all(format!("  - `{}`\n", f).as_bytes())?;
                    }
                }
            }
        }
    }
    Ok(())
}

fn main() -> Result<()> {
    println!("🚀 _dev-system: Starting AGGREGATED Scan (v8)...");
    let guard_config = guard::GuardConfig::default();
    let config_raw = fs::read_to_string("../config/efficiency.json")?;
    let config: EfficiencyConfig = serde_json::from_str(&config_raw)?;
    let mut buffer: HashMap<String, Vec<WorkUnit>> = HashMap::new();
    let mut dir_stats: HashMap<String, Vec<(String, usize, String)>> = HashMap::new();
    let mut feature_map: HashMap<String, Vec<(String, String)>> = HashMap::new(); 
    let default_dict: HashMap<String, f64> = HashMap::new();

    for entry in WalkDir::new("../../").into_iter().filter_map(|e| e.ok()) {
        let path = entry.path();
        if path.to_string_lossy().contains("/tests/") || !path.is_file() || !is_project_source(path, &config.exclusion_rules) { continue; }
        let mut content = String::new();
        if let Ok(mut f) = fs::File::open(path) { let _ = f.read_to_string(&mut content); } else { continue; }
        let taxonomy = infer_taxonomy(path, &content);
        if taxonomy == "ignored" { continue; }
        let ext = path.extension().and_then(|s| s.to_str()).unwrap_or("");
        let d_name = match ext { "rs" => "rust", "res" => "rescript", "jsx"|"js"|"html" => "web", "css" => "css", _ => "config" };
        let platform = if ext == "rs" || path.to_string_lossy().contains("backend") { "backend" } else { "frontend" };
        if taxonomy == "unknown" { buffer.entry("system".to_string()).or_default().push(WorkUnit::Ambiguity { file: path.to_string_lossy().to_string() }); continue; }
        
        let dict = config.profiles.get(d_name).map(|p| &p.complexity_dictionary).unwrap_or(&default_dict);
        let metrics = match d_name {
            "rust" => analyze_rust(&content, dict).unwrap_or_default(),
            "rescript" => analyze_rescript(&content, dict).unwrap_or_default(),
            "web" => analyze_html(&content, dict).unwrap_or_default(),
            "css" => analyze_css(&content, dict).unwrap_or_default(),
            _ => analyze_config(&content, dict).unwrap_or_default(),
        };
        if metrics.loc == 0 { continue; }
        
        let _ = guard::check_tests(&guard_config, path);

        if let Some(profile) = config.profiles.get(d_name) {
            let stripped = drivers::strip_code(&content);
            for pattern in &profile.forbidden_patterns {
                if stripped.contains(pattern) {
                    buffer.entry(d_name.to_string()).or_default().push(WorkUnit::Violation { file: path.to_string_lossy().to_string(), pattern: pattern.clone() });
                }
            }
        }

        let mut p_mod = config.taxonomy.get(&taxonomy).map(|t| t.multiplier).unwrap_or(1.0);
        if let Some(exceptions) = &config.exceptions { for rule in exceptions { if path.to_string_lossy().contains(&rule.pattern) { if let Some(m) = rule.multiplier { p_mod *= m; } break; } } }
        let density = metrics.logic_count as f64 / metrics.loc as f64;
        let dependency_density = metrics.external_calls as f64 / metrics.loc as f64;
        let cohesion_bonus = 1.0 + (0.5 - dependency_density).max(0.0);
        // Tuned: Normalized complexity penalty to be a density metric (intensive) rather than extensive.
        // This prevents the "squared penalty" effect where larger files get exponentially tighter limits.
        let complexity_density = if metrics.loc > 0 { metrics.complexity_penalty / metrics.loc as f64 } else { 0.0 };
        // We weight the specific complexity density (keywords) higher (x50) to make it impactful but fair.
        // Depth Penalty: Folders deeper than 4 levels incur a drag penalty.
        // Fix: Clean the path (remove ../..) before counting depth to ensure we only count actual project structure.
        let clean_path_str = path.to_string_lossy().replace("../../", "");
        let clean_path = Path::new(&clean_path_str);
        let dir_depth = clean_path.components().count().saturating_sub(config.settings.max_depth_threshold) as f64;
        let depth_penalty = if dir_depth > 0.0 { dir_depth * 0.5 } else { 0.0 };

        let drag = 1.0 + (metrics.max_nesting as f64 * config.settings.nesting_weight) + (density * config.settings.density_weight) + (complexity_density * 50.0) + depth_penalty;

        // Tuned: Math updated to use a gentler curve (Drag^0.75) with a higher base (450).
        // This ensures the limit curve distributes nicely between 80 (complex) and 400 (simple).
        let mut limit = ((config.settings.base_loc_limit as f64 * p_mod * cohesion_bonus) / drag.powf(0.75)).max(config.settings.soft_floor_loc as f64) as usize;
        if let Some(exceptions) = &config.exceptions { for rule in exceptions { if path.to_string_lossy().contains(&rule.pattern) { if let Some(max) = rule.max_loc { limit = max; } break; } } }
        limit = limit.min(config.settings.hard_ceiling_loc);
        if metrics.loc > limit {
            let nesting_factor = metrics.max_nesting as f64 * config.settings.nesting_weight;
            let density_factor = density * config.settings.density_weight;
            let breakdown = format!("[Nesting: {:.2}, Density: {:.2}, Deps: {:.2}] | Drag: {:.2} | LOC: {}/{}", 
                nesting_factor, density_factor, dependency_density, drag, metrics.loc, limit);
            let mut reason = breakdown;
            if let Some((s, e)) = metrics.hotspot_lines { reason = format!("{}  Hotspot: Lines {}-{} ({})", reason, s, e, metrics.hotspot_reason.unwrap_or_default()); }
            let complexity = ((metrics.loc - limit) as f64 / 10.0) + drag;
            buffer.entry(d_name.to_string()).or_default().push(WorkUnit::Surgical { file: path.to_string_lossy().to_string(), action: "De-bloat".to_string(), reason, platform: platform.to_string(), complexity });
        }
        dir_stats.entry(path.parent().unwrap().to_string_lossy().to_string()).or_default().push((path.file_name().unwrap().to_string_lossy().to_string(), metrics.loc, platform.to_string()));
        let file_stem = path.file_stem().unwrap_or_default().to_string_lossy().to_string();
        if file_stem.len() > 3 { feature_map.entry(file_stem).or_default().push((path.to_string_lossy().to_string(), platform.to_string())); }
    }
    for (dir, files) in dir_stats {
        let total: usize = files.iter().map(|(_,l,_)| *l).sum();
        let score = calculate_merge_score(FolderStats { file_count: files.len(), total_loc: total }, config.settings.hard_ceiling_loc);
        if score > config.settings.merge_score_threshold {
            buffer.entry("system".to_string()).or_default().push(WorkUnit::Merge { 
                folder: dir.clone(), files: files.iter().map(|(n,_,_)| n.clone()).collect(), platform: files[0].2.clone(),
                reason: format!("Read Tax high (Score {:.2}).", score) 
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
                reason: format!("Folder depth is {}. Flatten to reduce traversal tax.", clean_dir.components().count())
            });
        }
    }
    for (feature, paths) in feature_map {
        if paths.len() > 2 {
            let folders: Vec<String> = paths.iter().map(|(p, _)| Path::new(p).parent().unwrap().to_string_lossy().to_string()).collect();
            if folders.len() > 1 {
                buffer.entry("system".to_string()).or_default().push(WorkUnit::Structural {
                    file: feature.clone(), action: "Vertical Slice".to_string(), platform: paths[0].1.clone(),
                    reason: format!("Feature fragmented across {} folders.", folders.len())
                });
            }
        }
    }
    let _ = fs::create_dir_all("../plans");
    let json_data = serde_json::to_string_pretty(&buffer).unwrap_or_default();
    let _ = fs::write("../plans/metadata.json", json_data);
    let _ = flush_plans(&buffer, &config);
    let _ = sync_all_architectural_tasks(&buffer, &config);
    let _ = guard::check_map(&guard_config);
    let _ = guard::check_tasks_count(&guard_config);
    Ok(())
}

