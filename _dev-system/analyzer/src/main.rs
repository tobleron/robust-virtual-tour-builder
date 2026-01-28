mod drivers;
mod consolidator;

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
    exclusion_rules: ExclusionRules,
    profiles: HashMap<String, Profile>,
    taxonomy: HashMap<String, TaxonomyRole>,
    exceptions: Option<Vec<ExceptionRule>>,
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
    drag_ceiling: Option<f64>,
    allow_patterns: Option<Vec<String>>,
    reason: String,
}

#[derive(Debug, Deserialize)]
struct Settings {
    base_loc_limit: usize,
    hard_ceiling_loc: usize,
    soft_floor_loc: usize,
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
}

#[derive(Debug, Clone, serde::Serialize)]
enum WorkUnit {
    Ambiguity { file: String },
    Violation { file: String, pattern: String, severity: String },
    Surgical { file: String, action: String, reason: String },
    Merge { folder: String, files: Vec<String>, reason: String },
    Structural { file: String, action: String, reason: String },
}

fn is_project_source(path: &Path, rules: &ExclusionRules) -> bool {
    let p_str = path.to_string_lossy();
    let file_name = path.file_name().unwrap_or_default().to_string_lossy();
    let ext = path.extension().and_then(|s| s.to_str()).unwrap_or("");
    let valid_extensions = ["rs", "res", "jsx", "js", "html", "css", "json", "toml", "yaml"];
    
    if !valid_extensions.contains(&ext) && file_name != "Cargo.toml" && file_name != "package.json" { return false; }
    
    for folder in &rules.folders { if p_str.contains(folder) { return false; } }
    for file in &rules.files { if file_name == *file { return false; } }
    for suffix in &rules.extensions { if file_name.ends_with(suffix) { return false; } }
    
    true
}

fn infer_taxonomy(path: &Path, content: &str) -> String {
    let p = path.to_string_lossy().to_lowercase();
    let f = path.file_name().unwrap_or_default().to_string_lossy().to_lowercase();

    match parse_header(content) {
        EfficiencyOverride::Ignore => return "ignored".to_string(),
        EfficiencyOverride::Role(name) => return name,
        _ => {}
    }

    if f=="cargo.toml" || f=="package.json" || f.contains("config") || p.contains("/scripts/") { return "infra-config".to_string(); }
    if f=="main.rs" || f=="lib.rs" || f=="mod.rs" || f=="main.res" || f=="app.res" || f=="index.js" || p.contains("actions") || p.contains("serviceworker") { return "orchestrator".to_string(); }
    if p.contains("/systems/") || p.contains("logic") || p.contains("manager") { return "service-orchestrator".to_string(); }
    if p.contains("/core/") && !p.contains("types") { return "domain-logic".to_string(); }
    if p.contains("/components/") || p.contains("view") || p.contains("/public/") || f.ends_with(".html") || f.ends_with(".css") { return "ui-component".to_string(); }
    if p.contains("reducer") || p.contains("state") { return "state-reducer".to_string(); }
    if p.contains("types") || p.contains("models") || p.contains("schemas") { return "data-model".to_string(); }
    if p.contains("api") || p.contains("client") || p.contains("bindings") || p.contains("context") { return "infra-adapter".to_string(); }
    if p.contains("utils") || p.contains("helpers") { return "util-pure".to_string(); }

    "unknown".to_string()
}

fn get_legend() -> &'static str {
    r#"## 📚 LEGEND & DEFINITIONS
*   **LOC (Lines of Code):** Source lines excluding comments and whitespace.
*   **Drag:** A calculated resistance metric based on nesting depth, logic density, and complexity penalties. Higher drag reduces the allowed LOC.
*   **Limit:** The dynamic LOC limit for a specific file, calculated as `(Base_Limit * Role_Multiplier) / Drag`.
*   **Role:** The architectural classification (e.g., `orchestrator`, `ui-component`) which determines the base allowed size.
*   **Pattern:** A specific code construct (e.g., `unwrap`, `!important`) that is restricted or forbidden.

---

"#
}

fn flush_plans(buffer: &HashMap<String, Vec<WorkUnit>>) -> Result<()> {
    for (driver_name, units) in buffer {
        if units.is_empty() { continue; } 
        
        let plan_path = format!("../pending/{}_PLAN.md", driver_name.to_uppercase());
        let mut file = OpenOptions::new().create(true).truncate(true).write(true).open(plan_path).context("Open fail")?;

        file.write_all(format!("# {} MASTER PLAN\n", driver_name.to_uppercase()).as_bytes())?;
        file.write_all(get_legend().as_bytes())?;

        // 1. AMBIGUITIES (Aggregated)
        let ambiguities: Vec<&WorkUnit> = units.iter().filter(|u| matches!(u, WorkUnit::Ambiguity { .. })).collect();
        if !ambiguities.is_empty() {
            file.write_all(format!("## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION ({})\n", ambiguities.len()).as_bytes())?;
            file.write_all(b"**Action:** The AI Agent must analyze these files and update `_dev-system/config/efficiency.json` or add `@efficiency` headers.\n\n")?;
            for unit in ambiguities {
                if let WorkUnit::Ambiguity { file: f_path } = unit {
                    file.write_all(format!("- [ ] `{}`\n", f_path).as_bytes())?;
                }
            }
            file.write_all(b"\n---\n\n")?;
        }

        // 2. VIOLATIONS (Aggregated by Pattern)
        let violations: Vec<&WorkUnit> = units.iter().filter(|u| matches!(u, WorkUnit::Violation { .. })).collect();
        if !violations.is_empty() {
            file.write_all(format!("## 🚨 CRITICAL VIOLATIONS ({})\n", violations.len()).as_bytes())?;
            file.write_all(b"**Action:** Fix these patterns immediately using project standards.\n\n")?;
            
            let mut by_pattern: HashMap<String, Vec<String>> = HashMap::new();
            for unit in &violations {
                if let WorkUnit::Violation { file, pattern, .. } = unit {
                    by_pattern.entry(pattern.clone()).or_default().push(file.clone());
                }
            }

            for (pattern, files) in by_pattern {
                file.write_all(format!("### Pattern: `{}`\n", pattern).as_bytes())?;
                for f in files {
                    file.write_all(format!("- [ ] `{}`\n", f).as_bytes())?;
                }
                file.write_all(b"\n")?;
            }
            file.write_all(b"---\n\n")?;
        }

        // 3. SURGICAL TASKS (Aggregated)
        let surgicals: Vec<&WorkUnit> = units.iter().filter(|u| matches!(u, WorkUnit::Surgical { .. })).collect();
        if !surgicals.is_empty() {
            file.write_all(format!("## 🛠️ SURGICAL REFACTOR TASKS ({})\n", surgicals.len()).as_bytes())?;
            file.write_all(b"**Action:** Extract logic to new modules to reduce complexity/bloat.\n")?;
            file.write_all(b"**Target:** To be determined by AI Agent (Create new modules as needed).\n\n")?;
            
            for unit in surgicals {
                if let WorkUnit::Surgical { file: f_path, action: _, reason } = unit {
                    file.write_all(format!("- [ ] **{}**\n  - *Reason:* {}\n", f_path, reason).as_bytes())?;
                }
            }
            file.write_all(b"\n---\n\n")?;
        }

        // 4. STRUCTURAL TASKS
        let structural: Vec<&WorkUnit> = units.iter().filter(|u| matches!(u, WorkUnit::Structural { .. })).collect();
        if !structural.is_empty() {
            file.write_all(format!("## 🏗️ STRUCTURAL REFACTOR TASKS ({})\n", structural.len()).as_bytes())?;
            file.write_all(b"**Action:** Implement Vertical Slicing to reduce directory traversal overhead.\n\n")?;
            for unit in structural {
                if let WorkUnit::Structural { file: feature, action, reason } = unit {
                    file.write_all(format!("- [ ] **{}** (Action: {})\n  - *Reason:* {}\n", feature, action, reason).as_bytes())?;
                }
            }
            file.write_all(b"\n---\n\n")?;
        }

        // 5. MERGE TASKS
        let merges: Vec<&WorkUnit> = units.iter().filter(|u| matches!(u, WorkUnit::Merge { .. })).collect();
        if !merges.is_empty() {
            file.write_all(format!("## 🧩 MERGE TASKS ({})\n", merges.len()).as_bytes())?;
            for unit in merges {
                if let WorkUnit::Merge { folder, files, reason } = unit {
                    file.write_all(format!("### Merge Folder: `{}`\n", folder).as_bytes())?;
                    file.write_all(format!("- **Reason:** {}\n", reason).as_bytes())?;
                    file.write_all(format!("- **Files:**\n").as_bytes())?;
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
    let config_raw = fs::read_to_string("../config/efficiency.json")?;
    let config: EfficiencyConfig = serde_json::from_str(&config_raw)?;
    let _ = fs::remove_dir_all("../pending");
    let _ = fs::create_dir("../pending");

    let mut buffer: HashMap<String, Vec<WorkUnit>> = HashMap::new();
    let mut dir_stats: HashMap<String, Vec<(String, usize)>> = HashMap::new();
    let mut feature_map: HashMap<String, Vec<String>> = HashMap::new(); // For Vertical Slicing detection

    for entry in WalkDir::new("../../").into_iter().filter_map(|e| e.ok()) {
        let path = entry.path();
        if !path.is_file() || !is_project_source(path, &config.exclusion_rules) { continue; }
        
        let mut content = String::new();
        if let Ok(mut f) = fs::File::open(path) { let _ = f.read_to_string(&mut content); } else { continue; }
        
        let taxonomy = infer_taxonomy(path, &content);
        if taxonomy == "ignored" { continue; }
        let ext = path.extension().and_then(|s| s.to_str()).unwrap_or("");
        let d_name = match ext { "rs" => "rust", "res" => "rescript", "jsx"|"js"|"html" => "web", "css" => "css", _ => "config" };

        if taxonomy == "unknown" {
            buffer.entry("system".to_string()).or_default().push(WorkUnit::Ambiguity { file: path.to_string_lossy().to_string() });
            continue;
        }

        // 1. METRICS
        let default_dict = HashMap::new();
        let dict = config.profiles.get(d_name).map(|p| &p.complexity_dictionary).unwrap_or(&default_dict);

        let metrics = match d_name {
            "rust" => analyze_rust(&content, dict).unwrap_or(drivers::CommonMetrics::default()),
            "rescript" => analyze_rescript(&content, dict).unwrap_or(drivers::CommonMetrics::default()),
            "web" => analyze_html(&content, dict).unwrap_or(drivers::CommonMetrics::default()),
            "css" => analyze_css(&content, dict).unwrap_or(drivers::CommonMetrics::default()),
            _ => analyze_config(&content, dict).unwrap_or(drivers::CommonMetrics::default()),
        };

        if metrics.loc == 0 { continue; }

        // 2. VIOLATIONS (with Amnesty)
        let is_binding = content.contains("@val") || content.contains("@send") || path.to_string_lossy().contains("bindings");
        let mut allowed_violations: Vec<String> = Vec::new();

        let path_str = path.to_string_lossy().replace("\\", "/"); 
        let mut current_exception: Option<&ExceptionRule> = None;

        if let Some(exceptions) = &config.exceptions {
            for rule in exceptions {
                let clean_pattern = rule.pattern.replace("\\", "/");
                if path_str.contains(&clean_pattern) || glob::Pattern::new(&clean_pattern).map(|p| p.matches(&path_str)).unwrap_or(false) {
                    current_exception = Some(rule);
                    if let Some(am) = &rule.allow_patterns { allowed_violations.extend(am.clone()); }
                    break;
                }
            }
        }

        if let Some(profile) = config.profiles.get(d_name) {
            for pattern in &profile.forbidden_patterns {
                if is_binding && (pattern == "mutable " || pattern == "Obj.magic") { continue; }
                if allowed_violations.contains(pattern) { continue; } // Amnesty
                
                if content.contains(pattern) {
                    buffer.entry(d_name.to_string()).or_default().push(WorkUnit::Violation { file: path.to_string_lossy().to_string(), pattern: pattern.clone(), severity: "CRITICAL".to_string() });
                }
            }
        }

        // 3. LIMITS & EXCEPTIONS (AI-Optimized Math)
        let mut p_mod = config.taxonomy.get(&taxonomy).map(|t| t.multiplier).unwrap_or(1.0);
        let mut reason_prefix = String::new();
        let mut exception_limit: Option<usize> = None;
        let mut drag_ceiling: Option<f64> = None;

        if let Some(rule) = current_exception {
            if let Some(m) = rule.multiplier { p_mod *= m; }
            if let Some(max) = rule.max_loc { exception_limit = Some(max); }
            if let Some(dc) = rule.drag_ceiling { drag_ceiling = Some(dc); }
            reason_prefix = format!("[Exception: {}] ", rule.reason);
        }

        let density = if metrics.loc > 0 { metrics.logic_count as f64 / metrics.loc as f64 } else { 0.0 };
        
        // AI-Native logic: 
        // 1. Nesting cost is non-linear (AI loses state)
        // 2. Cohesion bonus: If (External_Calls / LOC) is low, the file can be larger
        let dependency_density = metrics.external_calls as f64 / metrics.loc.max(1) as f64;
        let cohesion_bonus = 1.0 + (0.5 - dependency_density).max(0.0); // Up to 50% bonus for low density

        // Traversal Penalty: Depths > Threshold increase Drag
        let depth = path.components().count().saturating_sub(1); // Relative to root
        let depth_penalty = if depth > config.settings.max_depth_threshold {
            (depth - config.settings.max_depth_threshold) as f64 * 0.25
        } else {
            0.0
        };

        let drag = 1.0 + (metrics.max_nesting as f64 * 0.15) + (density * 2.0) + metrics.complexity_penalty + depth_penalty;
        
        // Formula Revision: Drag^1.5 significantly tightens window for complex files
        let mut limit = ((config.settings.base_loc_limit as f64 * p_mod * cohesion_bonus) / drag.powf(1.5)).max(config.settings.soft_floor_loc as f64) as usize;
        
        if let Some(max) = exception_limit {
            limit = max;
        }

        // Hard Ceiling Clamp: Never allow a file to exceed the cognitive window limit
        limit = limit.min(config.settings.hard_ceiling_loc);

        let loc_violation = metrics.loc > limit;
        let ceiling_violation = drag_ceiling.map(|c| drag > c).unwrap_or(false);

        if loc_violation || ceiling_violation {
            let mut reason = if loc_violation {
                if exception_limit.is_some() {
                    format!("{}LOC {} > Exception Limit {}", reason_prefix, metrics.loc, limit)
                } else {
                    format!("{}LOC {} > Limit {} (Role: {}, Drag: {:.2})", reason_prefix, metrics.loc, limit, taxonomy, drag)
                }
            } else {
                format!("{}Drag {:.2} > Ceiling {} [Strict Path]", reason_prefix, drag, drag_ceiling.unwrap())
            };

            if let Some((start, end)) = metrics.hotspot_lines {
                reason = format!("{}\n    🔥 Hotspot: Lines {}-{} ({})", reason, start, end, metrics.hotspot_reason.unwrap_or_default());
            }

            buffer.entry(d_name.to_string()).or_default().push(WorkUnit::Surgical {
                file: path.to_string_lossy().to_string(),
                action: "De-bloat".to_string(),
                reason,
            });
        }

        dir_stats.entry(path.parent().unwrap().to_string_lossy().to_string()).or_default().push((path.file_name().unwrap().to_string_lossy().to_string(), metrics.loc));

        // Track features for fragmentation (Simple name-based heuristic)
        let file_stem = path.file_stem().unwrap_or_default().to_string_lossy().to_string();
        let feature_name = if file_stem.len() > 3 {
            let mut result = String::new();
            for (i, c) in file_stem.chars().enumerate() {
                if i > 0 && c.is_uppercase() { break; }
                result.push(c);
            }
            result
        } else {
            file_stem.clone()
        };
        if !feature_name.is_empty() {
            feature_map.entry(feature_name).or_default().push(path.to_string_lossy().to_string());
        }
    }

    // 4. MERGE & STRUCTURE
    for (dir, files) in dir_stats {
        let total: usize = files.iter().map(|(_,l)| *l).sum();
        let score = calculate_merge_score(FolderStats { 
            file_count: files.len(), 
            total_loc: total, 
        });
        if score > 1.0 {
            let names: Vec<String> = files.iter().map(|(n,_)| n.clone()).collect();
            buffer.entry("system".to_string()).or_default().push(WorkUnit::Merge { folder: dir, files: names, reason: format!("Score {:.2} > 1.0", score) });
        }
    }

    for (feature, paths) in feature_map {
        if paths.len() > 2 {
            let mut folders: Vec<String> = paths.iter().map(|p| Path::new(p).parent().unwrap().to_string_lossy().to_string()).collect();
            folders.sort();
            folders.dedup();
            if folders.len() > 1 {
                buffer.entry("system".to_string()).or_default().push(WorkUnit::Structural {
                    file: feature.clone(),
                    action: "Vertical Slice".to_string(),
                    reason: format!("Feature '{}' spread across {} folders (Fragmentation Tax)", feature, folders.len())
                });
            }
        }
    }

    // 5. EXPORT METADATA (for Dashboard)
    let json_data = serde_json::to_string_pretty(&buffer)?;
    fs::write("../pending/metadata.json", json_data)?;

    flush_plans(&buffer)?;
    println!("✅ Scan v8 Complete. Fully Aggregated.");
    Ok(())
}
