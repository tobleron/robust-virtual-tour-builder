use crate::analysis::calculate_dynamic_limit;
use crate::config::EfficiencyConfig;
use crate::consolidator::{calculate_merge_score, find_recursive_clusters, FileInfo, FolderStats};
use crate::discovery::RegistryEntry;
use crate::spec_snapshot::SpecSnapshot;
use crate::task_generator::WorkUnit;
use crate::verification::VerificationBundle;
use crate::utils::normalize_repo_relative_path;
use std::collections::HashMap;
use std::path::Path;

fn normalize_scope_path(path: &str) -> String {
    normalize_repo_relative_path(path)
}

fn scope_depth(path: &str) -> usize {
    normalize_scope_path(path)
        .split('/')
        .filter(|part| !part.is_empty())
        .count()
}

fn registry_contains_normalized_path(
    registry: &HashMap<String, RegistryEntry>,
    candidate: &str,
) -> bool {
    let normalized_candidate = normalize_scope_path(candidate);
    registry.keys().any(|path| normalize_scope_path(path) == normalized_candidate)
}

fn has_companion_facade(dir: &str, registry: &HashMap<String, RegistryEntry>) -> bool {
    let normalized = normalize_scope_path(dir);
    let folder_name = match Path::new(&normalized).file_name().and_then(|n| n.to_str()) {
        Some(name) if !name.is_empty() => name,
        _ => return false,
    };
    let parent = match Path::new(&normalized).parent() {
        Some(parent) => parent.to_string_lossy().to_string(),
        None => return false,
    };

    let facade_suffixes = [
        "System",
        "Generator",
        "GeneratorLogic",
        "Logic",
        "Manager",
        "Service",
        "Support",
        "Main",
        "Facade",
        "Runtime",
    ];

    facade_suffixes.iter().any(|suffix| {
        let rs = format!("{}/{}{}.rs", parent, folder_name, suffix);
        let res = format!("{}/{}{}.res", parent, folder_name, suffix);
        registry_contains_normalized_path(registry, &rs)
            || registry_contains_normalized_path(registry, &res)
    })
}

fn is_invalid_merge_scope(scope: &str, config: &EfficiencyConfig) -> bool {
    let normalized = normalize_scope_path(scope);
    if normalized.is_empty() || scope_depth(&normalized) < 2 {
        return true;
    }

    config
        .scanned_roots
        .as_ref()
        .map(|roots| {
            roots
                .iter()
                .map(|root| normalize_scope_path(root))
                .any(|root| root == normalized)
        })
        .unwrap_or(false)
}

/// Detect merge candidates from directory statistics
pub fn detect_merge_candidates(
    dir_stats: HashMap<(String, String), Vec<(String, usize, String, f64, f64)>>,
    _registry: &HashMap<String, RegistryEntry>,
    _buffer: &HashMap<String, Vec<WorkUnit>>,
    processed_merge_files: &mut std::collections::HashSet<String>,
    state: &crate::state::AnalyzerState,
    dynamic_base: f64,
    config: &EfficiencyConfig,
    spec_map: &HashMap<String, SpecSnapshot>,
) -> Vec<WorkUnit> {
    let mut merge_units = Vec::new();
    let surgical_files: std::collections::HashSet<String> = _buffer
        .values()
        .flat_map(|units| units.iter())
        .filter_map(|u| {
            if let WorkUnit::Surgical { file, .. } = u {
                Some(file.clone())
            } else {
                None
            }
        })
        .collect();

    for ((dir, _ext), files) in dir_stats {
        if is_invalid_merge_scope(&dir, config) {
            continue;
        }

        if has_companion_facade(&dir, _registry) {
            continue;
        }

        // Stability Guard: Don't merge if the folder is locked
        if state.is_locked(&dir) {
            continue;
        }

        // Shadow Guard: skip if a sibling orchestrator/service file exists (e.g. `.../Exporter` + `.../Exporter.res`)
        if let Some(folder_name) = Path::new(&dir).file_name().and_then(|n| n.to_str()) {
            let parent = Path::new(&dir)
                .parent()
                .map(|p| p.to_string_lossy().to_string())
                .unwrap_or_default();
            let shadow_rs = format!("{}/{}.rs", parent, folder_name);
            let shadow_res = format!("{}/{}.res", parent, folder_name);
            if _registry.contains_key(&shadow_rs) || _registry.contains_key(&shadow_res) {
                continue;
            }
        }

        // Priority Guard: don't emit merge for a folder participating in active de-bloat work
        if surgical_files
            .iter()
            .any(|f| f.starts_with(&format!("{}/", dir)))
        {
            continue;
        }

        // Filter out files that are already part of a Recursive Cluster
        let eligible_files: Vec<&(String, usize, String, f64, f64)> = files
            .iter()
            .filter(|(name, _, _, _, _)| {
                let full_path = Path::new(&dir).join(name).to_string_lossy().to_string();
                !processed_merge_files.contains(&full_path)
            })
            .collect();

        if eligible_files.len() < 2 {
            continue;
        }

        let total: usize = eligible_files.iter().map(|(_, l, _, _, _)| *l).sum();

        // Smart Merge Logic: Circularity Prevention
        let max_drag: f64 = eligible_files
            .iter()
            .map(|(_, _, _, d, _)| *d)
            .fold(0.0, f64::max);
        let min_pmod: f64 = eligible_files
            .iter()
            .map(|(_, _, _, _, m)| *m)
            .fold(100.0, f64::min);
        let safe_drag = if max_drag < 1.0 { 1.0 } else { max_drag };

        let projected_limit =
            calculate_dynamic_limit(safe_drag, min_pmod, 1.0, dynamic_base, config, &dir);

        let score = if total as f64 > projected_limit as f64 {
            0.0 // Force score to 0 to prevent merge
        } else {
            calculate_merge_score(
                FolderStats {
                    file_count: eligible_files.len(),
                    total_loc: total,
                },
                config.settings.hard_ceiling_loc,
            )
        };

        if score > config.settings.merge_score_threshold {
            let snapshots: Vec<SpecSnapshot> = eligible_files
                .iter()
                .filter_map(|(name, _, _, _, _)| {
                    let full_path = Path::new(&dir).join(name).to_string_lossy().to_string();
                    spec_map.get(&full_path).cloned()
                })
                .collect();
            let verification = if snapshots.is_empty() {
                None
            } else {
                Some(VerificationBundle {
                    headline: format!("Pre-merge snapshots for `{}`", dir),
                    snapshots,
                })
            };
            merge_units.push(WorkUnit::Merge {
                folder: dir.clone(),
                files: eligible_files
                    .iter()
                    .map(|(n, _, _, _, _)| n.clone())
                    .collect(),
                platform: eligible_files[0].2.clone(),
                reason: format!(
                    "Read Tax high (Score {:.2}). Projected Limit: {:.0} (Drag {:.2})",
                    score, projected_limit, safe_drag
                ),
                strategy: String::new(),
                verification,
            });
        }
    }

    merge_units
}

/// Detect recursive merge clusters
pub fn detect_recursive_clusters(
    registry: &HashMap<String, RegistryEntry>,
    dead_files: &std::collections::HashSet<String>,
    buffer: &HashMap<String, Vec<WorkUnit>>,
    config: &EfficiencyConfig,
    dynamic_base: f64,
    spec_map: &HashMap<String, SpecSnapshot>,
) -> (Vec<WorkUnit>, std::collections::HashSet<String>) {
    let mut recursive_groups: HashMap<(String, String), Vec<FileInfo>> = HashMap::new();
    let mut processed_merge_files = std::collections::HashSet::new();
    let mut cluster_units = Vec::new();

    for (p_str, (_, _, _, metrics, platform, _)) in registry {
        // Skip unreachable files OR surgical files for merging
        if dead_files.contains(p_str)
            || buffer.values().any(|units| {
                units.iter().any(|u| {
                    if let WorkUnit::Surgical { file, .. } = u {
                        file == p_str
                    } else {
                        false
                    }
                })
            })
        {
            continue;
        }

        let drag = 1.0
            + (metrics.max_nesting as f64 * config.settings.nesting_weight)
            + ((metrics.logic_count as f64 / metrics.loc as f64) * config.settings.density_weight)
            + ((metrics.complexity_penalty / metrics.loc as f64) * 20.0);

        let ext = Path::new(p_str)
            .extension()
            .and_then(|s| s.to_str())
            .unwrap_or("")
            .to_string();
        recursive_groups
            .entry((platform.clone(), ext))
            .or_default()
            .push(FileInfo {
                path: p_str.clone(),
                loc: metrics.loc,
                drag,
            });
    }

    // Priority 1: Recursive Feature Pods (Deep Clustering)
        for ((platform, _ext), files) in recursive_groups {
        let clusters = find_recursive_clusters(files, config.settings.hard_ceiling_loc);
        for cluster in clusters {
            if is_invalid_merge_scope(&cluster.root_folder, config) {
                continue;
            }

            if has_companion_facade(&cluster.root_folder, registry) {
                continue;
            }

            let projected_limit = calculate_dynamic_limit(
                cluster.max_drag,
                1.0,
                1.0,
                dynamic_base,
                config,
                &cluster.root_folder,
            );

            // HYSTERESIS: Only merge if total LOC is < 75% of projected limit
            let merge_max = (projected_limit as f64 * 0.75) as usize;

            if cluster.total_loc > merge_max {
                continue; // Too close to limit, avoid yoyo
            }

            // SHADOW CHECK: Do not merge if this is a "Sub-module folder" of a recently de-bloated orchestrator
            let shadow_rs = format!("../../{}.rs", cluster.root_folder);
            let shadow_res = format!("../../{}.res", cluster.root_folder);
            if registry.contains_key(&shadow_rs) || registry.contains_key(&shadow_res) {
                continue; // Protected Sub-module structure
            }

            for f in &cluster.files {
                processed_merge_files.insert(f.clone());
            }
            let snapshots: Vec<SpecSnapshot> = cluster
                .files
                .iter()
                .filter_map(|f| spec_map.get(f).cloned())
                .collect();
            let verification = if snapshots.is_empty() {
                None
            } else {
                Some(VerificationBundle {
                    headline: format!(
                        "Pre-merge snapshots for recursive cluster `{}`",
                        cluster.root_folder
                    ),
                    snapshots,
                })
            };
            cluster_units.push(WorkUnit::Merge {
                folder: cluster.root_folder.clone(),
                files: cluster.files.clone(),
                platform: platform.clone(),
                reason: format!("Recursive Feature Pod: {} files in subtree sum to {} LOC (fits in context). Max Drag: {:.2}", 
                    cluster.files.len(), cluster.total_loc, cluster.max_drag),
                strategy: String::new(),
                verification,
            });
        }
    }

    (cluster_units, processed_merge_files)
}

#[cfg(test)]
mod tests {
    use super::{detect_merge_candidates, is_invalid_merge_scope};
    use crate::drivers::CommonMetrics;
    use crate::state::AnalyzerState;
    use crate::task_generator::WorkUnit;
    use crate::config::EfficiencyConfig;
    use crate::discovery::RegistryEntry;
    use crate::spec_snapshot::SpecSnapshot;
    use std::collections::{HashMap, HashSet};
    use std::path::PathBuf;

    fn config() -> EfficiencyConfig {
        EfficiencyConfig::load_from("../config/efficiency.json").expect("config should load")
    }

    fn registry_entry(path: &str) -> RegistryEntry {
        (
            PathBuf::from(path),
            String::new(),
            "orchestrator".to_string(),
            CommonMetrics::default(),
            "frontend".to_string(),
            "test".to_string(),
        )
    }

    #[test]
    fn merge_scope_rejects_empty_and_scanned_root_paths() {
        let config = config();

        assert!(is_invalid_merge_scope("", &config));
        assert!(is_invalid_merge_scope("src", &config));
        assert!(is_invalid_merge_scope("backend/src", &config));
        assert!(!is_invalid_merge_scope("src/site", &config));
        assert!(!is_invalid_merge_scope(
            "backend/src/services/geocoding",
            &config
        ));
    }

    #[test]
    fn merge_candidates_skip_folders_with_companion_facades() {
        let config = config();
        let state = AnalyzerState::default();
        let mut processed_merge_files = HashSet::new();
        let mut registry: HashMap<String, RegistryEntry> = HashMap::new();
        registry.insert(
            "../../src/systems/Viewer/ViewerPool.res".to_string(),
            registry_entry("../../src/systems/Viewer/ViewerPool.res"),
        );
        registry.insert(
            "../../src/systems/Viewer/ViewerFollow.res".to_string(),
            registry_entry("../../src/systems/Viewer/ViewerFollow.res"),
        );
        registry.insert(
            "../../src/systems/ViewerSystem.res".to_string(),
            registry_entry("../../src/systems/ViewerSystem.res"),
        );

        assert!(super::has_companion_facade("src/systems/Viewer", &registry));

        let mut dir_stats: HashMap<(String, String), Vec<(String, usize, String, f64, f64)>> =
            HashMap::new();
        dir_stats.insert(
            ("src/systems/Viewer".to_string(), "res".to_string()),
            vec![
                ("ViewerPool.res".to_string(), 120, "frontend".to_string(), 0.2, 0.0),
                ("ViewerFollow.res".to_string(), 110, "frontend".to_string(), 0.2, 0.0),
            ],
        );
        let spec_map: HashMap<String, SpecSnapshot> = HashMap::new();

        let merges = detect_merge_candidates(
            dir_stats,
            &registry,
            &HashMap::<String, Vec<WorkUnit>>::new(),
            &mut processed_merge_files,
            &state,
            1.0,
            &config,
            &spec_map,
        );

        assert!(
            merges.is_empty(),
            "expected companion facade to suppress merge candidate generation"
        );
    }
}
