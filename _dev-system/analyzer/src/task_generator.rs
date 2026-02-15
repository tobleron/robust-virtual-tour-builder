use crate::config::EfficiencyConfig;
use crate::verification::{VerificationBundle, VerificationReport};
use anyhow::Result;
use serde_json;
use std::collections::{BTreeMap, HashMap, HashSet};
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, serde::Serialize)]
pub enum WorkUnit {
    Ambiguity {
        file: String,
        strategy: String,
    },
    Violation {
        file: String,
        pattern: String,
        strategy: String,
    },
    Surgical {
        file: String,
        action: String,
        reason: String,
        strategy: String,
        platform: String,
        complexity: f64,
        recommended_splits: usize,
        verification: Option<VerificationBundle>,
    },
    Merge {
        folder: String,
        files: Vec<String>,
        reason: String,
        strategy: String,
        platform: String,
        verification: Option<VerificationBundle>,
    },
    Structural {
        file: String,
        action: String,
        reason: String,
        strategy: String,
        platform: String,
    },
}

#[derive(Debug)]
struct BaselineInfo {
    root_relative: PathBuf,
    report_relative: PathBuf,
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

fn persist_verification_baseline(
    id: &str,
    category: &str,
    verification: &[VerificationBundle],
) -> Result<BaselineInfo> {
    let repo_root = Path::new("../..");
    let baseline_root = repo_root.join("_dev-system").join("tmp").join(id);
    let files_root = baseline_root.join("files");
    fs::create_dir_all(&files_root)?;

    let mut seen_files = HashSet::new();
    for bundle in verification {
        for snapshot in &bundle.snapshots {
            if !seen_files.insert(snapshot.path.clone()) {
                continue;
            }
            let source = repo_root.join(&snapshot.path);
            if !source.exists() {
                continue;
            }
            let target = files_root.join(&snapshot.path);
            if let Some(parent) = target.parent() {
                fs::create_dir_all(parent)?;
            }
            fs::copy(&source, &target)?;
        }
    }

    let relative_root = Path::new("_dev-system").join("tmp").join(id);
    let report = VerificationReport {
        task: id.to_string(),
        category: category.to_string(),
        baseline_dir: relative_root.to_string_lossy().to_string(),
        bundles: verification.to_vec(),
        timestamp: chrono::Utc::now(),
    };
    let report_path = baseline_root.join("verification.json");
    fs::write(&report_path, serde_json::to_string_pretty(&report)?)?;

    Ok(BaselineInfo {
        root_relative: relative_root.clone(),
        report_relative: relative_root.join("verification.json"),
    })
}

fn sync_architectural_category(
    category_name: &str,
    platform: &str,
    units: &[String],
    objective: &str,
    verification: &[VerificationBundle],
) -> Result<Option<PathBuf>> {
    let dev_tasks_dir = "../../tasks/pending/dev_tasks";
    let platform_label = if platform.is_empty() {
        "".to_string()
    } else {
        format!("_{}", platform.to_uppercase())
    };
    let full_category_name = format!("{}{}", category_name, platform_label);
    let mut existing_path = None;

    // Ensure dev_tasks directory exists
    if !Path::new(dev_tasks_dir).exists() {
        fs::create_dir_all(dev_tasks_dir)?;
    }

    if let Ok(entries) = fs::read_dir(dev_tasks_dir) {
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
        let id_str = p
            .file_name()
            .and_then(|n| n.to_str())
            .and_then(|s| s.split('_').next())
            .unwrap_or("D0")
            .to_string();
        (p, id_str)
    } else {
        let mut max_id = 0;
        // Only scan dev_tasks folder for dev task IDs (those starting with D)
        if let Ok(entries) = fs::read_dir(dev_tasks_dir) {
            for entry in entries.filter_map(|e| e.ok()) {
                let name = entry.file_name().to_string_lossy().into_owned();
                if name.starts_with('D') {
                    if let Some(id_str) = name[1..].split('_').next() {
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
        let id_str = format!("D{:03}", next_id);
        (
            Path::new(dev_tasks_dir).join(format!("{}_{}.md", id_str, full_category_name)),
            id_str,
        )
    };

    // Idempotent: Overwrite the file to ensure dead tasks are removed and structure is clean
    let mut file = OpenOptions::new()
        .create(true)
        .write(true)
        .truncate(true)
        .open(&path)?;

    file.write_all(
        format!(
            "# Task {}: {}\n\n## Objective\n{}\n\n## Tasks\n",
            id,
            full_category_name.replace("_", " "),
            objective
        )
        .as_bytes(),
    )?;

    for f in units {
        let line = if f.trim().starts_with("#") {
            format!("{}\n", f)
        } else {
            format!("- [ ] {}\n", f)
        };
        file.write_all(line.as_bytes())?;
    }
    if !verification.is_empty() {
        let baseline = persist_verification_baseline(&id, &full_category_name, verification)?;
        file.write_all("\n## 🔎 Programmatic Verification\n".as_bytes())?;
        file.write_all(
            format!(
                "Baseline artifacts: `{}` (files at `{}/files/`).\n",
                baseline.report_relative.display(),
                baseline.root_relative.display()
            )
            .as_bytes(),
        )?;
        file.write_all(
            format!(
                "Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline {} --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.\n\n",
                baseline.report_relative.display()
            )
            .as_bytes(),
        )?;
        for bundle in verification {
            file.write_all(format!("### {}\n", bundle.headline).as_bytes())?;
            for snapshot in &bundle.snapshots {
                file.write_all(
                    format!(
                        "- `{}` ({} functions, fingerprint {})\n",
                        snapshot.path,
                        snapshot.functions.len(),
                        snapshot.fingerprint
                    )
                    .as_bytes(),
                )?;
                let mut grouped: BTreeMap<String, Vec<usize>> = BTreeMap::new();
                for func in &snapshot.functions {
                    grouped.entry(func.name.clone()).or_default().push(func.line);
                }
                if !grouped.is_empty() {
                    file.write_all("    - Grouped summary:\n".as_bytes())?;
                    for (name, mut lines) in grouped {
                        lines.sort_unstable();
                        let lines_text = lines
                            .iter()
                            .map(|line| line.to_string())
                            .collect::<Vec<_>>()
                            .join(", ");
                        file.write_all(
                            format!(
                                "        - {} × {} (lines: {})\n",
                                name,
                                lines.len(),
                                lines_text
                            )
                            .as_bytes(),
                        )?;
                    }
                }
                file.write_all(
                    "    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.\n"
                        .as_bytes(),
                )?;
            }
        }
    }
    Ok(Some(path))
}

/// Synchronize all architectural tasks with the task management system
pub fn sync_all_architectural_tasks(
    buffer: &HashMap<String, Vec<WorkUnit>>,
    config: &EfficiencyConfig,
) -> Result<()> {
    let mut ambiguities_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut violations_fe_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut violations_be_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut structural_fe_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut structural_be_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut merges_fe_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut merges_be_grouped: HashMap<(String, String), Vec<String>> = HashMap::new();
    let mut merges_fe_verification_map: HashMap<(String, String), Vec<VerificationBundle>> =
        HashMap::new();
    let mut merges_be_verification_map: HashMap<(String, String), Vec<VerificationBundle>> =
        HashMap::new();
    type SurgicalEntry = (
        String,
        String,
        String,
        String,
        f64,
        usize,
        Option<VerificationBundle>,
    );
    let mut surgical_fe_units: Vec<SurgicalEntry> = Vec::new();
    let mut surgical_be_units: Vec<SurgicalEntry> = Vec::new();

    for units in buffer.values() {
        for unit in units {
            let strategy = generate_strategic_directive(unit);
            match unit {
                WorkUnit::Ambiguity { file, .. } => {
                    ambiguities_grouped
                        .entry(("Classify Ambiguous Files".to_string(), strategy))
                        .or_default()
                        .push(format!("`{}`", file));
                }
                WorkUnit::Violation { file, pattern, .. } => {
                    let action = format!("Fix Pattern `{}`", pattern);
                    let groups = if file.contains("backend") || file.ends_with(".rs") {
                        &mut violations_be_grouped
                    } else {
                        &mut violations_fe_grouped
                    };
                    groups
                        .entry((action, strategy))
                        .or_default()
                        .push(format!("`{}`", file));
                }
                WorkUnit::Surgical {
                    file,
                    reason,
                    platform,
                    complexity,
                    action,
                    recommended_splits,
                    verification,
                    ..
                } => {
                    let clean_reason = reason
                        .split(" (AI Context Fog")
                        .next()
                        .unwrap_or(reason)
                        .to_string();
                    if platform == "backend" {
                        surgical_be_units.push((
                            file.clone(),
                            clean_reason,
                            action.clone(),
                            strategy,
                            *complexity,
                            *recommended_splits,
                            verification.clone(),
                        ));
                    } else {
                        surgical_fe_units.push((
                            file.clone(),
                            clean_reason,
                            action.clone(),
                            strategy,
                            *complexity,
                            *recommended_splits,
                            verification.clone(),
                        ));
                    }
                }
                WorkUnit::Structural {
                    file,
                    reason,
                    platform,
                    action,
                    ..
                } => {
                    let groups = if platform == "backend" {
                        &mut structural_be_grouped
                    } else {
                        &mut structural_fe_grouped
                    };
                    groups
                        .entry((action.clone(), strategy))
                        .or_default()
                        .push(format!("**{}** (Metric: {})", file, reason));
                }
                WorkUnit::Merge {
                    folder,
                    files,
                    reason,
                    platform,
                    verification,
                    ..
                } => {
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
                    let key = ("Merge Fragmented Folders".to_string(), strategy.clone());
                    groups.entry(key.clone()).or_default().push(item);
                    if let Some(bundle) = verification {
                        let target = if platform == "backend" {
                            &mut merges_be_verification_map
                        } else {
                            &mut merges_fe_verification_map
                        };
                        target.entry(key).or_default().push(bundle.clone());
                    }
                }
            }
        }
    }

    let format_groups = |groups: HashMap<(String, String), Vec<String>>| -> Vec<String> {
        let mut lines = Vec::new();
        let mut sorted_keys: Vec<_> = groups.keys().collect();
        sorted_keys.sort();

        for key in sorted_keys {
            lines.push(format!(
                "\n### 🔧 Action: {}\n**Directive:** {}\n",
                key.0, key.1
            ));
            let mut items = groups.get(key).unwrap().clone();
            items.sort();
            for item in items {
                lines.push(item);
            }
        }
        lines
    };

    let surgical_obj = config
        .templates
        .surgical_objective
        .replace(
            "{nesting_w}",
            &format!("{:.2}", config.settings.nesting_weight),
        )
        .replace(
            "{density_w}",
            &format!("{:.2}", config.settings.density_weight),
        )
        .replace("{drag_t}", &format!("{:.2}", config.settings.drag_target));

    let merge_obj = config.templates.merge_objective.replace(
        "{merge_t}",
        &format!("{:.2}", config.settings.merge_score_threshold),
    );

    let merges_fe_verification: Vec<VerificationBundle> = merges_fe_verification_map
        .values()
        .flat_map(|bundles| bundles.iter().cloned())
        .collect();
    let merges_be_verification: Vec<VerificationBundle> = merges_be_verification_map
        .values()
        .flat_map(|bundles| bundles.iter().cloned())
        .collect();

    let mut role_list = String::new();
    for (role, data) in &config.taxonomy {
        role_list.push_str(&format!(
            "*   **{}**: {}\n",
            role,
            data.desc.as_ref().cloned().unwrap_or_default()
        ));
    }
    let ambiguity_obj = config
        .templates
        .ambiguity_objective
        .replace("{roles}", &role_list);

    let mut active_tasks = HashSet::new();

    let sync_surgical = |units: Vec<(
        String,
        String,
        String,
        String,
        f64,
        usize,
        Option<VerificationBundle>,
    )>,
                         platform: &str|
     -> Result<Vec<PathBuf>> {
        let mut paths = Vec::new();
        let mut domain_groups: HashMap<
            String,
            Vec<(
                String,
                String,
                String,
                String,
                f64,
                usize,
                Option<VerificationBundle>,
            )>,
        > = HashMap::new();
        for unit in units {
            let parent = Path::new(&unit.0)
                .parent()
                .map(|p| p.to_string_lossy().to_string())
                .unwrap_or_default();
            domain_groups.entry(parent).or_default().push(unit);
        }

        for (domain, domain_units) in domain_groups {
            let mut action_groups: HashMap<
                String,
                Vec<(String, String, String, usize, Option<VerificationBundle>)>,
            > = HashMap::new();

            for (file, reason, action, strategy, _comp, splits, verification) in domain_units {
                action_groups.entry(action).or_default().push((
                    file,
                    reason,
                    strategy,
                    splits,
                    verification,
                ));
            }

            let domain_name = Path::new(&domain)
                .file_name()
                .map(|n| n.to_string_lossy().to_uppercase())
                .unwrap_or_default();
            let category_name = format!("Surgical_Refactor_{}", domain_name);

            let mut lines = Vec::new();
            let mut domain_verification = Vec::new();

            for (action, mut items) in action_groups {
                items.sort_by(|a, b| a.0.cmp(&b.0));
                let strategy = &items[0].2;
                lines.push(format!(
                    "\n### 🔧 Action: {}\n**Directive:** {}\n",
                    action, strategy
                ));

                for (file, reason, _, _, maybe_bundle) in &items {
                    let entry = format!("- **{}** (Metric: {})\n", file, reason);
                    lines.push(entry);
                    if let Some(bundle) = maybe_bundle {
                        domain_verification.push(bundle.clone());
                    }
                }
            }

            let path_opt = if domain_verification.is_empty() {
                sync_architectural_category(&category_name, platform, &lines, &surgical_obj, &[])?
            } else {
                sync_architectural_category(
                    &category_name,
                    platform,
                    &lines,
                    &surgical_obj,
                    &domain_verification,
                )?
            };
            if let Some(path) = path_opt {
                paths.push(path);
            }
        }
        Ok(paths)
    };

    // Priority Order Enforcement
    if let Some(p) = sync_architectural_category(
        "Classify_Ambiguous_Files",
        "",
        &format_groups(ambiguities_grouped),
        &ambiguity_obj,
        &[],
    )? {
        active_tasks.insert(p);
    }

    if let Some(p) = sync_architectural_category(
        "Structural_Refactor",
        "Frontend",
        &format_groups(structural_fe_grouped),
        &config.templates.structural_objective,
        &[],
    )? {
        active_tasks.insert(p);
    }
    if let Some(p) = sync_architectural_category(
        "Structural_Refactor",
        "Backend",
        &format_groups(structural_be_grouped),
        &config.templates.structural_objective,
        &[],
    )? {
        active_tasks.insert(p);
    }

    if let Some(p) = sync_architectural_category(
        "Fix_Violations",
        "Frontend",
        &format_groups(violations_fe_grouped),
        &config.templates.violation_objective,
        &[],
    )? {
        active_tasks.insert(p);
    }
    if let Some(p) = sync_architectural_category(
        "Fix_Violations",
        "Backend",
        &format_groups(violations_be_grouped),
        &config.templates.violation_objective,
        &[],
    )? {
        active_tasks.insert(p);
    }

    active_tasks.extend(sync_surgical(surgical_fe_units, "Frontend")?);
    active_tasks.extend(sync_surgical(surgical_be_units, "Backend")?);

    if let Some(p) = sync_architectural_category(
        "Merge_Folders",
        "Frontend",
        &format_groups(merges_fe_grouped),
        &merge_obj,
        &merges_fe_verification,
    )? {
        active_tasks.insert(p);
    }
    if let Some(p) = sync_architectural_category(
        "Merge_Folders",
        "Backend",
        &format_groups(merges_be_grouped),
        &merge_obj,
        &merges_be_verification,
    )? {
        active_tasks.insert(p);
    }

    // Zombie Elimination (only in dev_tasks folder)
    let dev_tasks_dir = "../../tasks/pending/dev_tasks";
    let arch_patterns = [
        "Surgical_Refactor_",
        "Merge_Folders_",
        "Fix_Violations_",
        "Structural_Refactor_",
        "Classify_Ambiguous_Files",
    ];

    if let Ok(entries) = fs::read_dir(dev_tasks_dir) {
        for entry in entries.filter_map(|e| e.ok()) {
            let path = entry.path();
            if !path.is_file() {
                continue;
            }
            let name = path
                .file_name()
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
