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
    profiles: HashMap<String, Profile>,
    taxonomy: HashMap<String, TaxonomyRole>,
    exceptions: Option<Vec<ExceptionRule>>,
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

#[derive(Debug, Clone)]
enum WorkUnit {
    Ambiguity { file: String },
    Violation { file: String, pattern: String, severity: String },
    Surgical { file: String, action: String, reason: String },
    Merge { folder: String, files: Vec<String>, reason: String },
}

fn count_lines(content: &str) -> usize {
    content.lines().filter(|l| !l.trim().is_empty() && !l.trim().starts_with("//")).count()
}
fn is_project_source(path: &Path) -> bool {
    let p_str = path.to_string_lossy();
    let file_name = path.file_name().unwrap_or_default().to_string_lossy();
    let ext = path.extension().and_then(|s| s.to_str()).unwrap_or("");
    let valid_extensions = ["rs", "res", "jsx", "js", "html", "css", "json", "toml", "yaml"];
    if !valid_extensions.contains(&ext) && file_name != "Cargo.toml" && file_name != "package.json" { return false; }
    if file_name.ends_with(".bs.js") || file_name.contains(".test.") || file_name.contains("_v.test") { return false; }
    let ignored = ["/node_modules/", "/target/", "/lib/", "/.git/", "/.next/", "/old_ref/", "/dist/", "/build/", "/cache/", "/_dev-system/"];
    for folder in ignored { if p_str.contains(folder) { return false; } }
    true
}

fn infer_taxonomy(path: &Path, content: &str) -> String {
    let p = path.to_string_lossy().to_lowercase();
    let f = path.file_name().unwrap_or_default().to_string_lossy().to_lowercase();

    match parse_header(content) {
        EfficiencyOverride::Ignore => return "ignored".to_string(),
        EfficiencyOverride::Singleton => return "orchestrator".to_string(),
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

        // 4. MERGE TASKS
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
                    file.write_all(b"\n")?;
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

    for entry in WalkDir::new("../../").into_iter().filter_map(|e| e.ok()) {
        let path = entry.path();
        if !path.is_file() || !is_project_source(path) { continue; }
        
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
        let metrics = match ext {
            "rs" => analyze_rust(&content).unwrap_or(drivers::CommonMetrics{loc:0, logic_count:0, max_nesting:0, complexity_penalty:0.0, hotspot_lines: None, hotspot_reason: None}),
            "res" => analyze_rescript(&content).unwrap_or(drivers::CommonMetrics{loc:0, logic_count:0, max_nesting:0, complexity_penalty:0.0, hotspot_lines: None, hotspot_reason: None}),
            "html" => analyze_html(&content).unwrap_or(drivers::CommonMetrics{loc:0, logic_count:0, max_nesting:0, complexity_penalty:0.0, hotspot_lines: None, hotspot_reason: None}),
            "css" => analyze_css(&content).unwrap_or(drivers::CommonMetrics{loc:0, logic_count:0, max_nesting:0, complexity_penalty:0.0, hotspot_lines: None, hotspot_reason: None}),
            _ => analyze_config(&content).unwrap_or(drivers::CommonMetrics{loc:0, logic_count:0, max_nesting:0, complexity_penalty:0.0, hotspot_lines: None, hotspot_reason: None}),
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

        // 3. LIMITS & EXCEPTIONS (with Drag Ceiling & Hotspots)
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
        let drag = 1.0 + (metrics.max_nesting as f64 * 0.05) + (density * 2.0) + metrics.complexity_penalty;
        let mut limit = ((config.settings.base_loc_limit as f64 * p_mod) / drag).max(config.settings.soft_floor_loc as f64) as usize;
        
        if let Some(max) = exception_limit {
            limit = max;
        }

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
    }

    // 4. MERGE
    for (dir, files) in dir_stats {
        let avg = files.iter().map(|(_,l)| *l).sum::<usize>() / files.len().max(1);
        let score = calculate_merge_score(FolderStats { file_count: files.len(), avg_loc: avg });
        if score > 1.5 {
            let names: Vec<String> = files.iter().map(|(n,_)| n.clone()).collect();
            buffer.entry("system".to_string()).or_default().push(WorkUnit::Merge { folder: dir, files: names, reason: format!("Score {:.2} > 1.5", score) });
        }
    }

    flush_plans(&buffer)?;
    println!("✅ Scan v8 Complete. Fully Aggregated.");
    Ok(())
}
