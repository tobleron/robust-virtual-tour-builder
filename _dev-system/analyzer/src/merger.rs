use crate::consolidator::{FolderStats, calculate_merge_score, find_recursive_clusters, FileInfo};
use crate::config::EfficiencyConfig;
use crate::analysis::calculate_dynamic_limit;
use crate::task_generator::WorkUnit;
use crate::discovery::RegistryEntry;
use std::collections::HashMap;
use std::path::Path;

/// Detect merge candidates from directory statistics
pub fn detect_merge_candidates(
    dir_stats: HashMap<(String, String), Vec<(String, usize, String, f64, f64)>>,
    _registry: &HashMap<String, RegistryEntry>,
    _buffer: &HashMap<String, Vec<WorkUnit>>,
    processed_merge_files: &mut std::collections::HashSet<String>,
    state: &crate::state::AnalyzerState,
    dynamic_base: f64,
    config: &EfficiencyConfig,
) -> Vec<WorkUnit> {
    let mut merge_units = Vec::new();
    
    for ((dir, _ext), files) in dir_stats {
        // Stability Guard: Don't merge if the folder is locked
        if state.is_locked(&dir) {
            continue;
        }

        // Filter out files that are already part of a Recursive Cluster
        let eligible_files: Vec<&(String, usize, String, f64, f64)> = files.iter()
            .filter(|(name, _, _, _, _)| {
                let full_path = Path::new(&dir).join(name).to_string_lossy().to_string();
                !processed_merge_files.contains(&full_path)
            })
            .collect();

        if eligible_files.len() < 2 { continue; }

        let total: usize = eligible_files.iter().map(|(_, l, _, _, _)| *l).sum();

        // Smart Merge Logic: Circularity Prevention
        let max_drag: f64 = eligible_files.iter()
            .map(|(_, _, _, d, _)| *d)
            .fold(0.0, f64::max);
        let min_pmod: f64 = eligible_files.iter()
            .map(|(_, _, _, _, m)| *m)
            .fold(100.0, f64::min);
        let safe_drag = if max_drag < 1.0 { 1.0 } else { max_drag };
        
        let projected_limit = calculate_dynamic_limit(safe_drag, min_pmod, 1.0, dynamic_base, config, &dir);

        let score = if total as f64 > projected_limit as f64 {
            0.0 // Force score to 0 to prevent merge
        } else {
            calculate_merge_score(
                FolderStats { 
                    file_count: eligible_files.len(), 
                    total_loc: total 
                }, 
                config.settings.hard_ceiling_loc
            )
        };

        if score > config.settings.merge_score_threshold {
            merge_units.push(WorkUnit::Merge { 
                folder: dir.clone(), 
                files: eligible_files.iter().map(|(n, _, _, _, _)| n.clone()).collect(),
                platform: eligible_files[0].2.clone(),
                reason: format!("Read Tax high (Score {:.2}). Projected Limit: {:.0} (Drag {:.2})", score, projected_limit, safe_drag),
                strategy: String::new()
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
) -> (Vec<WorkUnit>, std::collections::HashSet<String>) {
    let mut recursive_groups: HashMap<(String, String), Vec<FileInfo>> = HashMap::new();
    let mut processed_merge_files = std::collections::HashSet::new();
    let mut cluster_units = Vec::new();
    
    for (p_str, (_, _, _, metrics, platform, _)) in registry {
        // Skip unreachable files OR surgical files for merging
        if dead_files.contains(p_str) || buffer.values().any(|units| {
            units.iter().any(|u| {
                if let WorkUnit::Surgical { file, .. } = u { 
                    file == p_str 
                } else { 
                    false 
                }
            })
        }) { 
            continue; 
        }

        let drag = 1.0 + (metrics.max_nesting as f64 * config.settings.nesting_weight) 
            + ((metrics.logic_count as f64 / metrics.loc as f64) * config.settings.density_weight) 
            + ((metrics.complexity_penalty / metrics.loc as f64) * 20.0);

        let ext = Path::new(p_str).extension()
            .and_then(|s| s.to_str())
            .unwrap_or("")
            .to_string();
        recursive_groups.entry((platform.clone(), ext))
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
            let projected_limit = calculate_dynamic_limit(
                cluster.max_drag, 
                1.0, 
                1.0, 
                dynamic_base, 
                config, 
                &cluster.root_folder
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
            cluster_units.push(WorkUnit::Merge {
                folder: cluster.root_folder.clone(),
                files: cluster.files.clone(),
                platform: platform.clone(),
                reason: format!("Recursive Feature Pod: {} files in subtree sum to {} LOC (fits in context). Max Drag: {:.2}", 
                    cluster.files.len(), cluster.total_loc, cluster.max_drag),
                strategy: String::new()
            });
        }
    }
    
    (cluster_units, processed_merge_files)
}
