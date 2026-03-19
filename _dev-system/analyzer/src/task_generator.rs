use crate::config::EfficiencyConfig;
use crate::graph::DependencyGraph;
use crate::utils::get_drag_target;
use crate::verification::{VerificationBundle, VerificationReport};
use anyhow::Result;
use serde_json;
use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

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

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
enum TaskTouchKind {
    Ambiguity,
    Violation,
    Surgical,
}

impl TaskTouchKind {
    fn label(self) -> &'static str {
        match self {
            TaskTouchKind::Ambiguity => "classification task",
            TaskTouchKind::Violation => "violation task",
            TaskTouchKind::Surgical => "split task",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
struct TaskTouch {
    kind: TaskTouchKind,
    path: String,
}

#[derive(Debug, Clone)]
struct MergeScope {
    folder: String,
    members: Vec<String>,
}

#[derive(Debug, Clone, Default)]
struct MergeConflictAdvice {
    notes: Vec<String>,
}

#[derive(Debug, Clone)]
struct DeferredStructuralItem {
    path: String,
    blockers: Vec<String>,
}

#[derive(Debug, Clone, Default)]
struct ConflictPlan {
    merge_advice: HashMap<String, MergeConflictAdvice>,
    deferred_structural: Vec<DeferredStructuralItem>,
    report_lines: Vec<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
enum GeneratedTaskKind {
    Ambiguity,
    Violation,
    Surgical,
    Merge,
    Structural,
}

impl GeneratedTaskKind {
    fn priority(self) -> usize {
        match self {
            GeneratedTaskKind::Ambiguity => 0,
            GeneratedTaskKind::Violation => 1,
            GeneratedTaskKind::Surgical => 2,
            GeneratedTaskKind::Merge => 3,
            GeneratedTaskKind::Structural => 4,
        }
    }
}

#[derive(Debug, Clone)]
struct GeneratedTaskSpec {
    key: String,
    objective: String,
    lines: Vec<String>,
    verification: Vec<VerificationBundle>,
    kind: GeneratedTaskKind,
    touch_paths: Vec<String>,
    merge_scopes: Vec<String>,
    dependencies: BTreeSet<String>,
}

fn normalize_repo_relative_path(raw: &str) -> String {
    let normalized = raw.trim().trim_matches('`').replace('\\', "/");
    let mut parts: Vec<String> = Vec::new();

    for part in normalized.split('/') {
        match part {
            "" | "." => continue,
            ".." => {
                if !parts.is_empty() {
                    parts.pop();
                }
            }
            value => parts.push(value.to_string()),
        }
    }

    parts.join("/")
}

fn path_is_same_or_descendant(parent: &str, candidate: &str) -> bool {
    candidate == parent || candidate.starts_with(&format!("{}/", parent))
}

pub(crate) fn resolve_merge_member_path(folder: &str, file: &str) -> String {
    let normalized_folder = normalize_repo_relative_path(folder);
    let normalized_file = normalize_repo_relative_path(file);

    if normalized_file.contains('/')
        && path_is_same_or_descendant(&normalized_folder, &normalized_file)
    {
        normalized_file
    } else {
        normalize_repo_relative_path(&format!("{}/{}", normalized_folder, file))
    }
}

fn collect_folder_descendants(folder: &str) -> Vec<String> {
    let repo_root = Path::new("../..");
    let folder_root = repo_root.join(folder);
    if !folder_root.exists() {
        return Vec::new();
    }

    WalkDir::new(folder_root)
        .into_iter()
        .filter_map(|entry| entry.ok())
        .filter(|entry| entry.file_type().is_file())
        .filter_map(|entry| entry.path().strip_prefix(repo_root).ok().map(PathBuf::from))
        .map(|path| path.to_string_lossy().replace('\\', "/"))
        .collect()
}

fn summarize_paths(paths: &[String], limit: usize) -> String {
    let mut items = paths.to_vec();
    items.sort();
    items.dedup();

    if items.is_empty() {
        return String::new();
    }

    let display = items.iter().take(limit).cloned().collect::<Vec<_>>();
    if items.len() > limit {
        format!("{} (+{} more)", display.join(", "), items.len() - limit)
    } else {
        display.join(", ")
    }
}

fn build_conflict_plan(buffer: &HashMap<String, Vec<WorkUnit>>) -> ConflictPlan {
    let mut plan = ConflictPlan::default();
    let mut higher_priority_touches: Vec<TaskTouch> = Vec::new();
    let mut structural_touches: Vec<DeferredStructuralItem> = Vec::new();
    let mut merge_scopes: Vec<MergeScope> = Vec::new();

    for units in buffer.values() {
        for unit in units {
            match unit {
                WorkUnit::Ambiguity { file, .. } => higher_priority_touches.push(TaskTouch {
                    kind: TaskTouchKind::Ambiguity,
                    path: normalize_repo_relative_path(file),
                }),
                WorkUnit::Violation { file, .. } => higher_priority_touches.push(TaskTouch {
                    kind: TaskTouchKind::Violation,
                    path: normalize_repo_relative_path(file),
                }),
                WorkUnit::Surgical { file, .. } => higher_priority_touches.push(TaskTouch {
                    kind: TaskTouchKind::Surgical,
                    path: normalize_repo_relative_path(file),
                }),
                WorkUnit::Structural { file, .. } => {
                    structural_touches.push(DeferredStructuralItem {
                        path: normalize_repo_relative_path(file),
                        blockers: Vec::new(),
                    })
                }
                WorkUnit::Merge { folder, files, .. } => merge_scopes.push(MergeScope {
                    folder: normalize_repo_relative_path(folder),
                    members: files
                        .iter()
                        .map(|file| resolve_merge_member_path(folder, file))
                        .collect(),
                }),
            }
        }
    }

    for structural in &mut structural_touches {
        let mut blockers = Vec::new();
        let blocking_touches: Vec<String> = higher_priority_touches
            .iter()
            .filter(|touch| {
                touch.path == structural.path
                    || path_is_same_or_descendant(&touch.path, &structural.path)
                    || path_is_same_or_descendant(&structural.path, &touch.path)
            })
            .map(|touch| format!("{} on `{}`", touch.kind.label(), touch.path))
            .collect();
        blockers.extend(blocking_touches);

        let blocking_merges: Vec<String> = merge_scopes
            .iter()
            .filter(|scope| {
                path_is_same_or_descendant(&scope.folder, &structural.path)
                    || scope
                        .members
                        .iter()
                        .any(|member| member == &structural.path)
            })
            .map(|scope| format!("merge task on `{}`", scope.folder))
            .collect();
        blockers.extend(blocking_merges);

        blockers.sort();
        blockers.dedup();
        structural.blockers = blockers;
    }

    let deferred_structural: Vec<DeferredStructuralItem> = structural_touches
        .into_iter()
        .filter(|item| !item.blockers.is_empty())
        .collect();

    if !deferred_structural.is_empty() {
        let deferred_paths = deferred_structural
            .iter()
            .map(|item| item.path.clone())
            .collect::<Vec<_>>();
        plan.report_lines.push(format!(
            "- Deferred structural tasks until local refactors finish: {}",
            summarize_paths(&deferred_paths, 6)
        ));
    }

    for scope in &merge_scopes {
        let actual_descendants = collect_folder_descendants(&scope.folder);
        let mut notes = Vec::new();
        let mut preserve_folder = false;

        let residual_descendants = actual_descendants
            .iter()
            .filter(|path| !scope.members.contains(path))
            .cloned()
            .collect::<Vec<_>>();
        if !residual_descendants.is_empty() {
            preserve_folder = true;
            notes.push(format!(
                "Conflict Guard: preserve `{}` because the folder still contains non-merged paths: `{}`.",
                scope.folder,
                summarize_paths(&residual_descendants, 4)
            ));
        }

        let overlapping_touches = higher_priority_touches
            .iter()
            .filter(|touch| {
                path_is_same_or_descendant(&scope.folder, &touch.path)
                    && !scope.members.contains(&touch.path)
            })
            .map(|touch| format!("{} `{}`", touch.kind.label(), touch.path))
            .collect::<Vec<_>>();
        if !overlapping_touches.is_empty() {
            preserve_folder = true;
            notes.push(format!(
                "Sequencing: run after descendant tasks settle because this subtree still has {}.",
                overlapping_touches.join(", ")
            ));
        }

        let overlapping_merges = merge_scopes
            .iter()
            .filter(|other| {
                other.folder != scope.folder
                    && (path_is_same_or_descendant(&scope.folder, &other.folder)
                        || path_is_same_or_descendant(&other.folder, &scope.folder))
            })
            .map(|other| other.folder.clone())
            .collect::<Vec<_>>();
        if !overlapping_merges.is_empty() {
            preserve_folder = true;
            notes.push(format!(
                "Conflict Guard: keep the subtree stable because overlapping merge candidates also exist at `{}`.",
                summarize_paths(&overlapping_merges, 4)
            ));
        }

        notes.sort();
        notes.dedup();

        if preserve_folder {
            plan.report_lines.push(format!(
                "- Merge folder `{}` is folder-preserved due to overlap/residual paths.",
                scope.folder
            ));
        }

        plan.merge_advice
            .insert(scope.folder.clone(), MergeConflictAdvice { notes });
    }

    plan.deferred_structural = deferred_structural;
    plan
}

fn write_conflict_report(plan: &ConflictPlan) -> Result<()> {
    let docs_dir = Path::new("../..").join("docs").join("_pending_integration");
    fs::create_dir_all(&docs_dir)?;
    let report_path = docs_dir.join("DEV_TASK_CONFLICT_REPORT.md");
    let mut file = OpenOptions::new()
        .create(true)
        .write(true)
        .truncate(true)
        .open(report_path)?;

    file.write_all(b"# Dev Task Conflict Report\n\n")?;
    file.write_all(
        b"Generated by `_dev-system/analyzer` to keep advisory dev tasks conflict-safe by default.\n\n",
    )?;

    if plan.report_lines.is_empty() && plan.deferred_structural.is_empty() {
        file.write_all(b"- No blocking task conflicts detected.\n")?;
        return Ok(());
    }

    if !plan.report_lines.is_empty() {
        file.write_all(b"## Auto-Resolved Conflicts\n")?;
        for line in &plan.report_lines {
            file.write_all(format!("{}\n", line).as_bytes())?;
        }
        file.write_all(b"\n")?;
    }

    if !plan.deferred_structural.is_empty() {
        file.write_all(b"## Deferred Structural Tasks\n")?;
        for item in &plan.deferred_structural {
            file.write_all(
                format!(
                    "- `{}` deferred because of {}.\n",
                    item.path,
                    item.blockers.join(", ")
                )
                .as_bytes(),
            )?;
        }
    }

    Ok(())
}

fn generated_arch_patterns() -> [&'static str; 5] {
    [
        "Surgical_Refactor_",
        "Merge_Folders_",
        "Fix_Violations_",
        "Structural_Refactor_",
        "Classify_Ambiguous_Files",
    ]
}

fn is_generated_arch_task_name(name: &str) -> bool {
    generated_arch_patterns()
        .iter()
        .any(|pattern| name.contains(pattern))
}

fn dedupe_sorted_paths(paths: Vec<String>) -> Vec<String> {
    let mut set = BTreeSet::new();
    for path in paths {
        let normalized = normalize_repo_relative_path(&path);
        if !normalized.is_empty() {
            set.insert(normalized);
        }
    }
    set.into_iter().collect()
}

fn surgical_domain_category_fragment(domain: &str) -> String {
    let normalized = normalize_repo_relative_path(domain);
    let parts = normalized
        .split('/')
        .filter(|part| !part.is_empty())
        .collect::<Vec<_>>();

    if parts.is_empty() {
        return "ROOT".to_string();
    }

    let start = parts.len().saturating_sub(2);
    parts[start..]
        .iter()
        .map(|part| part.to_uppercase())
        .collect::<Vec<_>>()
        .join("_")
}

fn build_architectural_task_spec(
    category_name: &str,
    platform: &str,
    units: &[String],
    objective: &str,
    verification: &[VerificationBundle],
    kind: GeneratedTaskKind,
    touch_paths: Vec<String>,
    merge_scopes: Vec<String>,
) -> Option<GeneratedTaskSpec> {
    if units.is_empty() {
        return None;
    }

    let platform_label = if platform.is_empty() {
        "".to_string()
    } else {
        format!("_{}", platform.to_uppercase())
    };
    let key = format!("{}{}", category_name, platform_label);

    Some(GeneratedTaskSpec {
        key,
        objective: objective.to_string(),
        lines: units.to_vec(),
        verification: verification.to_vec(),
        kind,
        touch_paths: dedupe_sorted_paths(touch_paths),
        merge_scopes: dedupe_sorted_paths(merge_scopes),
        dependencies: BTreeSet::new(),
    })
}

fn task_specs_overlap(a: &GeneratedTaskSpec, b: &GeneratedTaskSpec) -> bool {
    a.touch_paths.iter().any(|left| {
        b.touch_paths.iter().any(|right| {
            path_is_same_or_descendant(left, right) || path_is_same_or_descendant(right, left)
        })
    }) || a.merge_scopes.iter().any(|left| {
        b.merge_scopes.iter().any(|right| {
            path_is_same_or_descendant(left, right) || path_is_same_or_descendant(right, left)
        })
    })
}

fn task_spec_matches_path(spec: &GeneratedTaskSpec, path: &str) -> bool {
    let normalized = normalize_repo_relative_path(path);
    spec.touch_paths.iter().any(|candidate| {
        path_is_same_or_descendant(candidate, &normalized)
            || path_is_same_or_descendant(&normalized, candidate)
    }) || spec.merge_scopes.iter().any(|scope| {
        path_is_same_or_descendant(scope, &normalized)
            || path_is_same_or_descendant(&normalized, scope)
    })
}

fn attach_topological_dependencies(specs: &mut [GeneratedTaskSpec]) {
    let ambiguity_keys = specs
        .iter()
        .filter(|spec| spec.kind == GeneratedTaskKind::Ambiguity)
        .map(|spec| spec.key.clone())
        .collect::<Vec<_>>();

    for spec in specs.iter_mut() {
        if spec.kind != GeneratedTaskKind::Ambiguity {
            for key in &ambiguity_keys {
                spec.dependencies.insert(key.clone());
            }
        }
    }

    let len = specs.len();
    for left_idx in 0..len {
        for right_idx in (left_idx + 1)..len {
            let left = specs[left_idx].clone();
            let right = specs[right_idx].clone();
            if !task_specs_overlap(&left, &right) {
                continue;
            }

            if left.kind.priority() != right.kind.priority() {
                if left.kind.priority() > right.kind.priority() {
                    specs[left_idx].dependencies.insert(right.key.clone());
                } else {
                    specs[right_idx].dependencies.insert(left.key.clone());
                }
                continue;
            }

            if left.kind == GeneratedTaskKind::Merge && right.kind == GeneratedTaskKind::Merge {
                let left_depends_on_right = left.merge_scopes.iter().any(|scope| {
                    right
                        .merge_scopes
                        .iter()
                        .any(|other| scope != other && path_is_same_or_descendant(scope, other))
                });
                let right_depends_on_left = right.merge_scopes.iter().any(|scope| {
                    left.merge_scopes
                        .iter()
                        .any(|other| scope != other && path_is_same_or_descendant(scope, other))
                });

                if left_depends_on_right {
                    specs[left_idx].dependencies.insert(right.key.clone());
                } else if right_depends_on_left {
                    specs[right_idx].dependencies.insert(left.key.clone());
                }
            }
        }
    }
}

fn attach_file_graph_dependencies(specs: &mut [GeneratedTaskSpec], dep_graph: &DependencyGraph) {
    let normalized_edges = dep_graph
        .adj
        .iter()
        .flat_map(|(from, tos)| {
            tos.iter().map(|to| {
                (
                    normalize_repo_relative_path(from),
                    normalize_repo_relative_path(to),
                )
            })
        })
        .filter(|(from, to)| !from.is_empty() && !to.is_empty())
        .collect::<Vec<_>>();

    let len = specs.len();
    for left_idx in 0..len {
        for right_idx in (left_idx + 1)..len {
            let left_depends_on_right = normalized_edges.iter().any(|(from, to)| {
                task_spec_matches_path(&specs[left_idx], from)
                    && task_spec_matches_path(&specs[right_idx], to)
            });
            let right_depends_on_left = normalized_edges.iter().any(|(from, to)| {
                task_spec_matches_path(&specs[right_idx], from)
                    && task_spec_matches_path(&specs[left_idx], to)
            });

            if left_depends_on_right && !right_depends_on_left {
                let dependency = specs[right_idx].key.clone();
                specs[left_idx].dependencies.insert(dependency);
            } else if right_depends_on_left && !left_depends_on_right {
                let dependency = specs[left_idx].key.clone();
                specs[right_idx].dependencies.insert(dependency);
            }
        }
    }
}

fn topologically_sort_task_specs(specs: Vec<GeneratedTaskSpec>) -> Vec<GeneratedTaskSpec> {
    let mut incoming: HashMap<String, BTreeSet<String>> = specs
        .iter()
        .map(|spec| (spec.key.clone(), spec.dependencies.clone()))
        .collect();
    let mut outgoing: HashMap<String, BTreeSet<String>> = HashMap::new();
    let spec_by_key: HashMap<String, GeneratedTaskSpec> = specs
        .into_iter()
        .map(|spec| (spec.key.clone(), spec))
        .collect();

    for (key, deps) in &incoming {
        for dep in deps {
            outgoing.entry(dep.clone()).or_default().insert(key.clone());
        }
    }

    let mut ready: Vec<String> = incoming
        .iter()
        .filter(|(_, deps)| deps.is_empty())
        .map(|(key, _)| key.clone())
        .collect();

    ready.sort_by(|left, right| {
        let left_spec = spec_by_key.get(left).expect("left spec should exist");
        let right_spec = spec_by_key.get(right).expect("right spec should exist");
        left_spec
            .kind
            .priority()
            .cmp(&right_spec.kind.priority())
            .then_with(|| left.cmp(right))
    });

    let mut ordered = Vec::new();

    while let Some(key) = ready.first().cloned() {
        ready.remove(0);
        ordered.push(
            spec_by_key
                .get(&key)
                .expect("spec should exist during ordering")
                .clone(),
        );

        if let Some(children) = outgoing.get(&key).cloned() {
            for child in children {
                if let Some(deps) = incoming.get_mut(&child) {
                    deps.remove(&key);
                    if deps.is_empty() && !ordered.iter().any(|spec| spec.key == child) {
                        ready.push(child.clone());
                    }
                }
            }
            ready.sort_by(|left, right| {
                let left_spec = spec_by_key.get(left).expect("left spec should exist");
                let right_spec = spec_by_key.get(right).expect("right spec should exist");
                left_spec
                    .kind
                    .priority()
                    .cmp(&right_spec.kind.priority())
                    .then_with(|| left.cmp(right))
            });
            ready.dedup();
        }
    }

    if ordered.len() == spec_by_key.len() {
        ordered
    } else {
        let mut fallback = spec_by_key.into_values().collect::<Vec<_>>();
        fallback.sort_by(|left, right| {
            left.kind
                .priority()
                .cmp(&right.kind.priority())
                .then_with(|| left.key.cmp(&right.key))
        });
        fallback
    }
}

fn is_valid_generated_task_spec(spec: &GeneratedTaskSpec) -> bool {
    if spec.lines.is_empty() {
        return false;
    }

    match spec.kind {
        GeneratedTaskKind::Merge => {
            !spec.merge_scopes.is_empty()
                && spec
                    .merge_scopes
                    .iter()
                    .all(|scope| !normalize_repo_relative_path(scope).is_empty())
        }
        _ => {
            !spec.touch_paths.is_empty()
                && spec
                    .touch_paths
                    .iter()
                    .all(|path| !normalize_repo_relative_path(path).is_empty())
        }
    }
}

fn reserved_non_generated_dev_ids(dev_tasks_dir: &Path) -> BTreeSet<usize> {
    let mut reserved = BTreeSet::new();

    if let Ok(entries) = fs::read_dir(dev_tasks_dir) {
        for entry in entries.filter_map(|item| item.ok()) {
            let name = entry.file_name().to_string_lossy().into_owned();
            if !name.starts_with('D') || is_generated_arch_task_name(&name) {
                continue;
            }
            if let Some(id_str) = name[1..].split('_').next() {
                if let Ok(id) = id_str.parse::<usize>() {
                    reserved.insert(id);
                }
            }
        }
    }

    reserved
}

fn next_available_dev_id(cursor: &mut usize, reserved: &BTreeSet<usize>) -> usize {
    loop {
        let current = *cursor;
        *cursor += 1;
        if !reserved.contains(&current) {
            return current;
        }
    }
}

fn write_architectural_task(
    dev_tasks_dir: &Path,
    spec: &GeneratedTaskSpec,
    id: &str,
) -> Result<PathBuf> {
    let path = dev_tasks_dir.join(format!("{}_{}.md", id, spec.key));
    let mut file = OpenOptions::new()
        .create(true)
        .write(true)
        .truncate(true)
        .open(&path)?;

    file.write_all(
        format!(
            "# Task {}: {}\n\n## Objective\n",
            id,
            spec.key.replace("_", " ")
        )
        .as_bytes(),
    )?;

    let objective_paragraph = spec
        .objective
        .lines()
        .map(|line| line.trim())
        .filter(|line| !line.is_empty())
        .collect::<Vec<_>>()
        .join(" ");
    file.write_all(format!("{}\n\n", objective_paragraph).as_bytes())?;

    file.write_all("\n## Work Items\n".as_bytes())?;

    for line in &spec.lines {
        let trimmed = line.trim();
        let formatted = if trimmed.is_empty() {
            "\n".to_string()
        } else if trimmed.starts_with('#') || trimmed.starts_with("*") {
            format!("{}\n", trimmed)
        } else if trimmed.starts_with("- [ ]") || trimmed.starts_with("- [x]") {
            format!("{}\n", trimmed)
        } else if trimmed.starts_with('-') {
            format!("- [ ] {}\n", trimmed.trim_start_matches('-').trim())
        } else {
            format!("- [ ] {}\n", trimmed)
        };
        file.write_all(formatted.as_bytes())?;
    }

    if !spec.verification.is_empty() {
        let baseline = persist_verification_baseline(id, &spec.key, &spec.verification)?;
        file.write_all("\n## 🔎 Programmatic Verification\n".as_bytes())?;
        file.write_all(
            format!(
                "- Baseline artifacts: `{}` (files at `{}/files/`).\n",
                baseline.report_relative.display(),
                baseline.root_relative.display()
            )
            .as_bytes(),
        )?;
        file.write_all(
            format!(
                "- Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline {} --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.\n\n",
                baseline.report_relative.display()
            )
            .as_bytes(),
        )?;
        for bundle in &spec.verification {
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
                    grouped
                        .entry(func.name.clone())
                        .or_default()
                        .push(func.line);
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

    Ok(path)
}

fn extract_drag_from_reason(reason: &str) -> Option<f64> {
    let marker = "Drag:";
    let start = reason.find(marker)?;
    let raw_value = reason[start + marker.len()..]
        .trim_start()
        .split(|ch: char| ch.is_whitespace() || ch == '|' || ch == ')')
        .next()?;
    raw_value.parse::<f64>().ok()
}

fn surgical_reason_is_size_only(reason: &str, drag_target: f64) -> bool {
    extract_drag_from_reason(reason)
        .map(|drag| drag <= drag_target && !reason.contains("🎯 Target:"))
        .unwrap_or(false)
}

fn surgical_working_band(soft_floor_loc: usize) -> (usize, usize) {
    (soft_floor_loc.saturating_sub(50), soft_floor_loc + 50)
}

fn drag_target_for_unit(unit: &WorkUnit, config: &EfficiencyConfig) -> f64 {
    match unit {
        WorkUnit::Ambiguity { file, .. }
        | WorkUnit::Violation { file, .. }
        | WorkUnit::Structural { file, .. }
        | WorkUnit::Surgical { file, .. } => get_drag_target(config, file),
        WorkUnit::Merge { folder, .. } => get_drag_target(config, folder),
    }
}

/// Extract the base strategy text for a surgical work unit (without split count)
fn surgical_base_strategy(reason: &str, drag_target: f64) -> &'static str {
    if surgical_reason_is_size_only(reason, drag_target) {
        "Right-size Surface: Keep the module as the orchestration boundary and extract only adjacent sections that reduce file length without fragmenting the public API."
    } else if reason.contains("Nesting") && reason.contains("Density") {
        "Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions."
    } else if reason.contains("Nesting") {
        "Flatten Control Flow: Replace nested if/switch blocks with early returns or pattern matching."
    } else if reason.contains("Density") {
        "Extract Service Logic: Move complex calculations or data transformations into specialized sub-modules."
    } else {
        "De-bloat: Reduce module size by identifying and extracting independent domain logic."
    }
}

/// Generate strategic directive for a work unit (full version with split count, used in metadata/JSON)
pub fn generate_strategic_directive(
    unit: &WorkUnit,
    config: &EfficiencyConfig,
) -> String {
    let drag_target = drag_target_for_unit(unit, config);
    let soft_floor_loc = config.settings.soft_floor_loc;
    let minimum_child_loc = config.settings.min_extracted_module_loc;
    let (lower, upper) = surgical_working_band(soft_floor_loc);
    match unit {
        WorkUnit::Surgical { reason, recommended_splits, .. } => {
            let base = surgical_base_strategy(reason, drag_target);
            if *recommended_splits > 1 {
                format!(
                    "{} 🏗️ ARCHITECTURAL TARGET: Split into {} cohesive modules while keeping each module within the {}-{} LOC working band (center ~{} LOC, minimum child floor {} LOC).",
                    base, recommended_splits, lower, upper, soft_floor_loc, minimum_child_loc
                )
            } else {
                format!(
                    "{} Refactor in-place to reduce drag score while keeping the module near the ~{} LOC centerline and above the {} LOC child floor.",
                    base, soft_floor_loc, minimum_child_loc
                )
            }
        },
        WorkUnit::Merge { folder, .. } => {
            let folder_name = Path::new(folder).file_name()
                .map(|n| n.to_string_lossy())
                .unwrap_or_default();
            let example_ext = if folder.contains("/src/") && !folder.contains("/backend/") {
                "res"
            } else {
                "rs"
            };
            format!("Unified Context: Consolidate these fragmented files into a single cohesive module file (e.g., `{}.{}`). Preserve the existing folder unless it is truly empty and no other generated task still touches that subtree.", folder_name, example_ext)
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
    let baseline_folder = format!("{}_{}", id, category);
    let baseline_root = repo_root
        .join("_dev-system")
        .join("tmp")
        .join(&baseline_folder);
    if baseline_root.exists() {
        fs::remove_dir_all(&baseline_root)?;
    }
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

    let relative_root = Path::new("_dev-system").join("tmp").join(&baseline_folder);
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

/// Synchronize all architectural tasks with the task management system
pub fn sync_all_architectural_tasks(
    buffer: &HashMap<String, Vec<WorkUnit>>,
    config: &EfficiencyConfig,
    dep_graph: &DependencyGraph,
) -> Result<()> {
    let conflict_plan = build_conflict_plan(buffer);
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
    let soft_floor_loc = config.settings.soft_floor_loc;

    for units in buffer.values() {
        for unit in units {
            let strategy = generate_strategic_directive(unit, config);
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
                    let normalized_file = normalize_repo_relative_path(file);
                    if conflict_plan
                        .deferred_structural
                        .iter()
                        .any(|item| item.path == normalized_file)
                    {
                        continue;
                    }
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
                    let normalized_folder = normalize_repo_relative_path(folder);
                    let mut item = format!("Folder: `{}` (Metric: {})", normalized_folder, reason);
                    for f in sorted_files {
                        let full_path = resolve_merge_member_path(folder, &f);
                        item.push_str(&format!("\n    - `{}`", full_path));
                    }
                    if let Some(advice) = conflict_plan.merge_advice.get(&normalized_folder) {
                        for note in &advice.notes {
                            item.push_str(&format!("\n    - {}", note));
                        }
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
        );

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

    let role_list = config
        .taxonomy
        .iter()
        .map(|(role, data)| {
            format!(
                "**{}**: {}",
                role,
                data.desc.as_ref().cloned().unwrap_or_default()
            )
        })
        .collect::<Vec<_>>()
        .join("; ");
    let ambiguity_obj = config
        .templates
        .ambiguity_objective
        .replace("{roles}", &role_list);

    let mut task_specs: Vec<GeneratedTaskSpec> = Vec::new();

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
     -> Vec<GeneratedTaskSpec> {
        let (working_band_lower, working_band_upper) = surgical_working_band(soft_floor_loc);
        let mut specs = Vec::new();
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
                (String, String, i32),
                Vec<(String, String, usize, bool, Option<VerificationBundle>)>,
            > = HashMap::new();

            for (file, reason, action, _strategy, _comp, splits, verification) in domain_units {
                let drag_target = get_drag_target(config, &file);
                let base_strategy = surgical_base_strategy(&reason, drag_target).to_string();
                let size_only = surgical_reason_is_size_only(&reason, drag_target);
                action_groups
                    .entry((action, base_strategy, (drag_target * 100.0).round() as i32))
                    .or_default()
                    .push((file, reason, splits, size_only, verification));
            }

            let category_name = format!(
                "Surgical_Refactor_{}",
                surgical_domain_category_fragment(&domain)
            );

            let mut lines = Vec::new();
            let mut domain_verification = Vec::new();
            let mut domain_touch_paths = Vec::new();

            let mut action_keys = action_groups.keys().cloned().collect::<Vec<_>>();
            action_keys.sort();

            for (action, base_strategy, drag_target_key) in action_keys {
                let Some(items) = action_groups.get_mut(&(
                    action.clone(),
                    base_strategy.clone(),
                    drag_target_key,
                ))
                else {
                    continue;
                };
                items.sort_by(|a, b| a.0.cmp(&b.0));
                lines.push(format!(
                    "\n### 🔧 Action: {}\n**Directive:** {}\n",
                    action, base_strategy
                ));

                for (file, reason, splits, size_only, maybe_bundle) in items.iter() {
                    // Embed per-file split recommendation inline
                    let split_note = if *splits > 1 {
                        format!(
                            " → 🏗️ Split into {} modules (target {}-{} LOC each, center ~{} LOC, floor {} LOC)",
                            splits,
                            working_band_lower,
                            working_band_upper,
                            soft_floor_loc,
                            config.settings.min_extracted_module_loc
                        )
                    } else {
                        format!(
                            " → Refactor in-place (keep near ~{} LOC and above {} LOC floor)",
                            soft_floor_loc, config.settings.min_extracted_module_loc
                        )
                    };
                    let size_note = if *size_only {
                        " [Size-only candidate; drag already within target.]"
                    } else {
                        ""
                    };
                    let entry = format!(
                        "- **{}** (Metric: {}){}{}\n",
                        file, reason, split_note, size_note
                    );
                    lines.push(entry);
                    domain_touch_paths.push(file.clone());
                    if let Some(bundle) = maybe_bundle {
                        domain_verification.push(bundle.clone());
                    }
                }
            }

            if let Some(spec) = build_architectural_task_spec(
                &category_name,
                platform,
                &lines,
                &surgical_obj,
                &domain_verification,
                GeneratedTaskKind::Surgical,
                domain_touch_paths,
                Vec::new(),
            ) {
                specs.push(spec);
            }
        }
        specs
    };

    // Priority Order Enforcement
    if let Some(spec) = build_architectural_task_spec(
        "Classify_Ambiguous_Files",
        "",
        &format_groups(ambiguities_grouped.clone()),
        &ambiguity_obj,
        &[],
        GeneratedTaskKind::Ambiguity,
        ambiguities_grouped
            .values()
            .flat_map(|items| items.iter().cloned())
            .collect(),
        Vec::new(),
    ) {
        task_specs.push(spec);
    }

    if let Some(spec) = build_architectural_task_spec(
        "Structural_Refactor",
        "Frontend",
        &format_groups(structural_fe_grouped.clone()),
        &config.templates.structural_objective,
        &[],
        GeneratedTaskKind::Structural,
        structural_fe_grouped
            .values()
            .flat_map(|items| {
                items.iter().filter_map(|item| {
                    let start = item.find("**")?;
                    let rest = &item[start + 2..];
                    let end = rest.find("**")?;
                    Some(rest[..end].to_string())
                })
            })
            .collect(),
        Vec::new(),
    ) {
        task_specs.push(spec);
    }
    if let Some(spec) = build_architectural_task_spec(
        "Structural_Refactor",
        "Backend",
        &format_groups(structural_be_grouped.clone()),
        &config.templates.structural_objective,
        &[],
        GeneratedTaskKind::Structural,
        structural_be_grouped
            .values()
            .flat_map(|items| {
                items.iter().filter_map(|item| {
                    let start = item.find("**")?;
                    let rest = &item[start + 2..];
                    let end = rest.find("**")?;
                    Some(rest[..end].to_string())
                })
            })
            .collect(),
        Vec::new(),
    ) {
        task_specs.push(spec);
    }

    if let Some(spec) = build_architectural_task_spec(
        "Fix_Violations",
        "Frontend",
        &format_groups(violations_fe_grouped.clone()),
        &config.templates.violation_objective,
        &[],
        GeneratedTaskKind::Violation,
        violations_fe_grouped
            .values()
            .flat_map(|items| items.iter().cloned())
            .collect(),
        Vec::new(),
    ) {
        task_specs.push(spec);
    }
    if let Some(spec) = build_architectural_task_spec(
        "Fix_Violations",
        "Backend",
        &format_groups(violations_be_grouped.clone()),
        &config.templates.violation_objective,
        &[],
        GeneratedTaskKind::Violation,
        violations_be_grouped
            .values()
            .flat_map(|items| items.iter().cloned())
            .collect(),
        Vec::new(),
    ) {
        task_specs.push(spec);
    }

    task_specs.extend(sync_surgical(surgical_fe_units, "Frontend"));
    task_specs.extend(sync_surgical(surgical_be_units, "Backend"));

    if let Some(spec) = build_architectural_task_spec(
        "Merge_Folders",
        "Frontend",
        &format_groups(merges_fe_grouped.clone()),
        &merge_obj,
        &merges_fe_verification,
        GeneratedTaskKind::Merge,
        merges_fe_grouped
            .values()
            .flat_map(|items| {
                items.iter().flat_map(|item| {
                    let mut paths = Vec::new();
                    for line in item.lines() {
                        let trimmed = line.trim();
                        if let Some(folder) = trimmed
                            .strip_prefix("Folder: `")
                            .and_then(|value| value.split('`').next())
                        {
                            paths.push(folder.to_string());
                        } else if let Some(path) = trimmed
                            .strip_prefix("- `")
                            .and_then(|value| value.split('`').next())
                        {
                            paths.push(path.to_string());
                        }
                    }
                    paths
                })
            })
            .collect(),
        merges_fe_grouped
            .values()
            .flat_map(|items| {
                items.iter().filter_map(|item| {
                    item.lines().find_map(|line| {
                        let trimmed = line.trim();
                        trimmed
                            .strip_prefix("Folder: `")
                            .and_then(|value| value.split('`').next())
                            .map(|folder| folder.to_string())
                    })
                })
            })
            .collect(),
    ) {
        task_specs.push(spec);
    }
    if let Some(spec) = build_architectural_task_spec(
        "Merge_Folders",
        "Backend",
        &format_groups(merges_be_grouped.clone()),
        &merge_obj,
        &merges_be_verification,
        GeneratedTaskKind::Merge,
        merges_be_grouped
            .values()
            .flat_map(|items| {
                items.iter().flat_map(|item| {
                    let mut paths = Vec::new();
                    for line in item.lines() {
                        let trimmed = line.trim();
                        if let Some(folder) = trimmed
                            .strip_prefix("Folder: `")
                            .and_then(|value| value.split('`').next())
                        {
                            paths.push(folder.to_string());
                        } else if let Some(path) = trimmed
                            .strip_prefix("- `")
                            .and_then(|value| value.split('`').next())
                        {
                            paths.push(path.to_string());
                        }
                    }
                    paths
                })
            })
            .collect(),
        merges_be_grouped
            .values()
            .flat_map(|items| {
                items.iter().filter_map(|item| {
                    item.lines().find_map(|line| {
                        let trimmed = line.trim();
                        trimmed
                            .strip_prefix("Folder: `")
                            .and_then(|value| value.split('`').next())
                            .map(|folder| folder.to_string())
                    })
                })
            })
            .collect(),
    ) {
        task_specs.push(spec);
    }

    task_specs.retain(is_valid_generated_task_spec);
    attach_topological_dependencies(&mut task_specs);
    attach_file_graph_dependencies(&mut task_specs, dep_graph);
    let ordered_specs = topologically_sort_task_specs(task_specs);
    let dev_tasks_dir = Path::new("../../tasks/pending/dev_tasks");
    fs::create_dir_all(dev_tasks_dir)?;
    let reserved_ids = reserved_non_generated_dev_ids(dev_tasks_dir);
    let mut id_cursor = 1usize;
    let mut active_tasks = HashSet::new();

    for spec in &ordered_specs {
        let id_num = next_available_dev_id(&mut id_cursor, &reserved_ids);
        let id = format!("D{:03}", id_num);
        let path = write_architectural_task(dev_tasks_dir, spec, &id)?;
        active_tasks.insert(path);
    }

    // Zombie Elimination (only in dev_tasks folder)
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

            let is_arch = is_generated_arch_task_name(&name);
            if is_arch && !active_tasks.contains(&path) {
                println!("🧹 Deleting zombie task: {:?}", path);
                let _ = fs::remove_file(path);
            }
        }
    }

    write_conflict_report(&conflict_plan)?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{SystemTime, UNIX_EPOCH};

    fn unique_test_root(label: &str) -> String {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system time should be after epoch")
            .as_nanos();
        format!("_dev-system/tmp/task_generator_tests/{}_{}", label, nanos)
    }

    fn write_repo_file(path: &str, content: &str) {
        let full_path = Path::new("../..").join(path);
        if let Some(parent) = full_path.parent() {
            fs::create_dir_all(parent).expect("test parent should exist");
        }
        fs::write(full_path, content).expect("test file should be written");
    }

    fn remove_repo_dir(path: &str) {
        let full_path = Path::new("../..").join(path);
        if full_path.exists() {
            let _ = fs::remove_dir_all(full_path);
        }
    }

    #[test]
    fn resolve_merge_member_path_keeps_repo_relative_paths_clean() {
        let folder = "backend/src/services/geocoding";
        assert_eq!(
            resolve_merge_member_path(folder, "mod.rs"),
            "backend/src/services/geocoding/mod.rs"
        );
        assert_eq!(
            resolve_merge_member_path(folder, "../../backend/src/services/geocoding/osm.rs"),
            "backend/src/services/geocoding/osm.rs"
        );
    }

    #[test]
    fn build_conflict_plan_preserves_merge_folder_with_residual_descendants() {
        let folder = unique_test_root("merge_residual");
        write_repo_file(&format!("{}/mod.rs", folder), "mod test;");
        write_repo_file(&format!("{}/osm.rs", folder), "pub fn osm() {}");
        write_repo_file(&format!("{}/cache.rs", folder), "pub fn cache() {}");

        let mut buffer = HashMap::new();
        buffer.insert(
            "system".to_string(),
            vec![
                WorkUnit::Merge {
                    folder: folder.clone(),
                    files: vec!["mod.rs".to_string(), "osm.rs".to_string()],
                    reason: "test".to_string(),
                    strategy: String::new(),
                    platform: "backend".to_string(),
                    verification: None,
                },
                WorkUnit::Surgical {
                    file: format!("{}/cache.rs", folder),
                    action: "De-bloat".to_string(),
                    reason: "test".to_string(),
                    strategy: String::new(),
                    platform: "backend".to_string(),
                    complexity: 1.0,
                    recommended_splits: 2,
                    verification: None,
                },
            ],
        );

        let plan = build_conflict_plan(&buffer);
        let advice = plan
            .merge_advice
            .get(&folder)
            .expect("merge advice should exist");
        assert!(advice
            .notes
            .iter()
            .any(|note| note.contains("preserve") && note.contains("cache.rs")));

        remove_repo_dir(&folder);
    }

    #[test]
    fn build_conflict_plan_records_overlapping_merge_candidates() {
        let root = unique_test_root("merge_overlap");
        let parent = format!("{}/feature", root);
        let child = format!("{}/nested", parent);
        write_repo_file(&format!("{}/mod.rs", parent), "mod nested;");
        write_repo_file(&format!("{}/shared.rs", parent), "pub fn shared() {}");
        write_repo_file(&format!("{}/child.rs", child), "pub fn child() {}");

        let mut buffer = HashMap::new();
        buffer.insert(
            "system".to_string(),
            vec![
                WorkUnit::Merge {
                    folder: parent.clone(),
                    files: vec!["mod.rs".to_string(), "shared.rs".to_string()],
                    reason: "parent".to_string(),
                    strategy: String::new(),
                    platform: "backend".to_string(),
                    verification: None,
                },
                WorkUnit::Merge {
                    folder: child.clone(),
                    files: vec!["child.rs".to_string()],
                    reason: "child".to_string(),
                    strategy: String::new(),
                    platform: "backend".to_string(),
                    verification: None,
                },
            ],
        );

        let plan = build_conflict_plan(&buffer);
        let advice = plan
            .merge_advice
            .get(&parent)
            .expect("parent merge advice should exist");
        assert!(advice
            .notes
            .iter()
            .any(|note| note.contains("overlapping merge candidates") && note.contains(&child)));

        remove_repo_dir(&root);
    }

    #[test]
    fn topological_sort_orders_ambiguity_then_surgical_then_merge() {
        let mut specs = vec![
            build_architectural_task_spec(
                "Merge_Folders",
                "Backend",
                &[String::from("merge line")],
                "merge objective",
                &[],
                GeneratedTaskKind::Merge,
                vec![
                    "backend/src/services/geocoding".to_string(),
                    "backend/src/services/geocoding/mod.rs".to_string(),
                ],
                vec!["backend/src/services/geocoding".to_string()],
            )
            .expect("merge spec"),
            build_architectural_task_spec(
                "Surgical_Refactor_GEOCODING",
                "Backend",
                &[String::from("surgical line")],
                "surgical objective",
                &[],
                GeneratedTaskKind::Surgical,
                vec!["backend/src/services/geocoding/cache.rs".to_string()],
                Vec::new(),
            )
            .expect("surgical spec"),
            build_architectural_task_spec(
                "Classify_Ambiguous_Files",
                "",
                &[String::from("ambiguity line")],
                "ambiguity objective",
                &[],
                GeneratedTaskKind::Ambiguity,
                vec!["src/site/PageFramework.js".to_string()],
                Vec::new(),
            )
            .expect("ambiguity spec"),
        ];

        attach_topological_dependencies(&mut specs);
        let ordered = topologically_sort_task_specs(specs);
        let ordered_keys = ordered.into_iter().map(|spec| spec.key).collect::<Vec<_>>();

        assert_eq!(
            ordered_keys,
            vec![
                "Classify_Ambiguous_Files".to_string(),
                "Surgical_Refactor_GEOCODING_BACKEND".to_string(),
                "Merge_Folders_BACKEND".to_string(),
            ]
        );
    }

    #[test]
    fn file_graph_dependencies_order_consumers_after_providers() {
        let mut specs = vec![
            build_architectural_task_spec(
                "App",
                "Frontend",
                &[String::from("app line")],
                "app objective",
                &[],
                GeneratedTaskKind::Surgical,
                vec!["src/App.res".to_string()],
                Vec::new(),
            )
            .expect("app spec"),
            build_architectural_task_spec(
                "ProjectSystem",
                "Frontend",
                &[String::from("project line")],
                "project objective",
                &[],
                GeneratedTaskKind::Surgical,
                vec!["src/systems/ProjectSystem.res".to_string()],
                Vec::new(),
            )
            .expect("project spec"),
        ];

        let mut graph = DependencyGraph::new();
        graph.add_dependency("../../src/App.res", "../../src/systems/ProjectSystem.res");

        attach_topological_dependencies(&mut specs);
        attach_file_graph_dependencies(&mut specs, &graph);

        let ordered = topologically_sort_task_specs(specs);
        let ordered_keys = ordered.into_iter().map(|spec| spec.key).collect::<Vec<_>>();

        assert_eq!(
            ordered_keys,
            vec![
                "ProjectSystem_FRONTEND".to_string(),
                "App_FRONTEND".to_string(),
            ]
        );
    }

    #[test]
    fn invalid_merge_specs_are_filtered_out() {
        let invalid = build_architectural_task_spec(
            "Merge_Folders",
            "Frontend",
            &[String::from("merge line")],
            "merge objective",
            &[],
            GeneratedTaskKind::Merge,
            vec!["src/index.js".to_string()],
            Vec::new(),
        )
        .expect("invalid merge spec should still build");

        assert!(!is_valid_generated_task_spec(&invalid));
    }

    #[test]
    fn surgical_domain_category_fragment_disambiguates_same_basename_paths() {
        assert_eq!(
            surgical_domain_category_fragment("css/components"),
            "CSS_COMPONENTS".to_string()
        );
        assert_eq!(
            surgical_domain_category_fragment("src/components"),
            "SRC_COMPONENTS".to_string()
        );
        assert_eq!(
            surgical_domain_category_fragment("src/components/Sidebar"),
            "COMPONENTS_SIDEBAR".to_string()
        );
    }

    #[test]
    fn surgical_reason_is_size_only_when_drag_is_within_target_without_hotspot() {
        assert!(surgical_reason_is_size_only(
            "[Nesting: 0.60, Density: 0.00, Coupling: 0.04] | Drag: 1.60 | LOC: 390/300",
            1.8
        ));
        assert!(!surgical_reason_is_size_only(
            "[Nesting: 3.00, Density: 0.03, Coupling: 0.02] | Drag: 4.08 | LOC: 927/300  🎯 Target: Function: `load_project` (High Local Complexity (9.0). Logic heavy.)",
            1.8
        ));
    }

    #[test]
    fn surgical_base_strategy_uses_right_size_surface_for_size_only_modules() {
        assert_eq!(
            surgical_base_strategy(
                "[Nesting: 0.60, Density: 0.00, Coupling: 0.04] | Drag: 1.60 | LOC: 390/300",
                1.8
            ),
            "Right-size Surface: Keep the module as the orchestration boundary and extract only adjacent sections that reduce file length without fragmenting the public API."
        );
    }

    #[test]
    fn generate_strategic_directive_uses_working_band_for_split_targets() {
        let config =
            EfficiencyConfig::load_from("../config/efficiency.json").expect("config should load");
        let directive = generate_strategic_directive(
            &WorkUnit::Surgical {
                file: "src/App.res".to_string(),
                action: "De-bloat".to_string(),
                reason: "[Nesting: 6.60, Density: 0.34, Coupling: 0.11] | Drag: 7.94 | LOC: 429/300  🎯 Target: Function: `make` (High Local Complexity (35.3). Logic heavy.)".to_string(),
                strategy: String::new(),
                platform: "frontend".to_string(),
                complexity: 7.94,
                recommended_splits: 2,
                verification: None,
            },
            &config,
        );
        assert!(directive.contains("350-450 LOC working band"));
        assert!(directive.contains("center ~400 LOC"));
        assert!(directive.contains("minimum child floor 220 LOC"));
    }

    #[test]
    fn generate_strategic_directive_keeps_in_place_drag_work_near_centerline() {
        let config =
            EfficiencyConfig::load_from("../config/efficiency.json").expect("config should load");
        let directive = generate_strategic_directive(
            &WorkUnit::Surgical {
                file: "src/systems/Navigation/NavigationController.res".to_string(),
                action: "De-bloat".to_string(),
                reason: "[Nesting: 4.20, Density: 0.10, Coupling: 0.09] | Drag: 5.30 | LOC: 293/300  ⚠️ Trigger: Drag above target (1.80) with file already at 293 LOC.  🎯 Target: Function: `taskInfo` (High Local Complexity (18.2). Logic heavy.)".to_string(),
                strategy: String::new(),
                platform: "frontend".to_string(),
                complexity: 5.30,
                recommended_splits: 1,
                verification: None,
            },
            &config,
        );
        assert!(directive.contains("Refactor in-place"));
        assert!(directive.contains("~400 LOC centerline"));
        assert!(directive.contains("220 LOC child floor"));
    }
}
