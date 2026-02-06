mod drivers;
mod consolidator;
mod guard;
mod graph;
mod state;
mod feedback;
mod config;
mod discovery;
mod analysis;
mod task_generator;
mod merger;
mod flusher;

use efficiency_analyzer::resolver::Resolver;
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::Path;
use anyhow::Result;
use graph::DependencyGraph;

use config::EfficiencyConfig;
use discovery::discover_and_analyze;
use analysis::calculate_dynamic_limit;
use task_generator::{WorkUnit, sync_all_architectural_tasks};
use merger::{detect_merge_candidates, detect_recursive_clusters};
use flusher::flush_plans;

fn main() -> Result<()> {
    // Load configuration and state
    let mut state = state::AnalyzerState::load();
    let guard_config = guard::GuardConfig::default();
    let config = EfficiencyConfig::load()?;
    
    // Phase 1: Discovery & Analysis
    let (registry, file_resolver, all_files_set, dynamic_base) = 
        discover_and_analyze(&config, &mut state)?;
    
    // Phase 2: Graph Construction
    let mut dep_graph = DependencyGraph::new();
    let resolver = Resolver::new(file_resolver.clone());
    
    let mut entry_points = HashSet::new();
    if let Some(eps) = &config.entry_points {
        for ep in eps {
            entry_points.insert(format!("../../{}", ep));
        }
    }
    
    // Ensure orchestrators and mapped files are entry points
    let mapped_files = guard::get_mapped_files(&guard_config);
    entry_points.extend(mapped_files);
    
    for (p_str, (_, content, taxonomy, _, _, _)) in &registry {
        if taxonomy == "orchestrator" || taxonomy == "service-orchestrator" {
            entry_points.insert(p_str.clone());
        }
        
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
            for m in resolver.resolve(dep) {
                dep_graph.add_dependency(path_str, &m);
            }
        }
    }
    
    // Phase 3: Task Generation
    let mut buffer: HashMap<String, Vec<WorkUnit>> = HashMap::new();
    let mut dir_stats: HashMap<(String, String), Vec<(String, usize, String, f64, f64)>> = HashMap::new();
    let mut feature_map: HashMap<String, Vec<(String, String)>> = HashMap::new();
    
    let dead_files: HashSet<String> = dep_graph.find_dead_code(&all_files_set, &entry_points)
        .into_iter().collect();
    
    // Generate work units from registry
    generate_work_units(&registry, &dead_files, &config, &state, &guard_config, dynamic_base, &mut buffer, &mut dir_stats, &mut feature_map)?;
    
    // Phase 4: Merge Analysis
    let (cluster_units, mut processed_merge_files) = detect_recursive_clusters(
        &registry, &dead_files, &buffer, &config, dynamic_base
    );
    buffer.entry("system".to_string()).or_default().extend(cluster_units);
    
    let merge_units = detect_merge_candidates(
        dir_stats, &registry, &buffer, &mut processed_merge_files, &state, dynamic_base, &config
    );
    buffer.entry("system".to_string()).or_default().extend(merge_units);
    
    // Structural analysis
    generate_structural_tasks(&feature_map, &mut buffer);
    
    // Phase 5: Output
    let _ = fs::create_dir_all("../plans");
    let json_data = serde_json::to_string_pretty(&buffer).unwrap_or_default();
    let _ = fs::write("../plans/metadata.json", json_data);
    flush_plans(&buffer, &config)?;
    sync_all_architectural_tasks(&buffer, &config)?;
    
    let _ = guard::check_map(&guard_config, &config.exclusion_rules);
    let _ = guard::check_data_flow(&guard_config, &config.exclusion_rules);
    let _ = guard::check_tasks_count(&guard_config);
    state.save()?;
    
    Ok(())
}

fn generate_work_units(
    registry: &HashMap<String, discovery::RegistryEntry>,
    dead_files: &HashSet<String>,
    config: &EfficiencyConfig,
    state: &state::AnalyzerState,
    guard_config: &guard::GuardConfig,
    dynamic_base: f64,
    buffer: &mut HashMap<String, Vec<WorkUnit>>,
    dir_stats: &mut HashMap<(String, String), Vec<(String, usize, String, f64, f64)>>,
    feature_map: &mut HashMap<String, Vec<(String, String)>>,
) -> Result<()> {
    for (p_str, (path, content, taxonomy, metrics, platform, d_name)) in registry {
        // Ambiguity check
        if taxonomy == "unknown" {
            buffer.entry("system".to_string()).or_default()
                .push(WorkUnit::Ambiguity { file: p_str.clone(), strategy: String::new() });
        }
        
        // Calculate metrics
        let density = metrics.logic_count as f64 / metrics.loc.max(1) as f64;
        let dependency_density = metrics.external_calls as f64 / metrics.loc.max(1) as f64;
        let coupling_score = metrics.external_calls as f64 / metrics.loc.max(1) as f64;
        
        let mut p_mod = config.taxonomy.get(taxonomy).map(|t| t.multiplier).unwrap_or(1.0);
        if let Some(exceptions) = &config.exceptions {
            for rule in exceptions {
                if p_str.contains(&rule.pattern) {
                    if let Some(m) = rule.multiplier { p_mod *= m; }
                    break;
                }
            }
        }
        
        
        let cohesion_bonus = 1.0 + (0.5 - dependency_density).max(0.0);
        let state_density = metrics.state_count as f64 / metrics.loc.max(1) as f64;
        
        let clean_path = p_str.replace("../../", "");
        let dir_depth = Path::new(&clean_path).components().count()
            .saturating_sub(config.settings.max_depth_threshold) as f64;
        let depth_penalty = if dir_depth > 0.0 { dir_depth * 0.5 } else { 0.0 };
        
        let failure_penalty = state.get_drag_multiplier(p_str);
        
        // Formula v2.0: Removed complexity_density * 20.0 (was double-counting state)
        // Unified state penalty to state_density * state_weight (now 8.0)
        let drag = (1.0 
            + (metrics.max_nesting as f64 * config.settings.nesting_weight)  // 0.6: Nesting critical for AI
            + (density * config.settings.density_weight)                      // 1.0: Moderate impact
            + (state_density * config.settings.state_weight)                  // 8.0: Unified state penalty
            + (depth_penalty * 0.6)                                           // 0.6: Minor directory depth penalty
        ) * failure_penalty;
        
        let limit = calculate_dynamic_limit(drag, p_mod, cohesion_bonus, dynamic_base, config, p_str);
        
        // Dead code task
        if dead_files.contains(p_str) && metrics.loc > config.settings.min_dead_code_loc {
            buffer.entry(d_name.clone()).or_default().push(WorkUnit::Surgical {
                file: p_str.clone(),
                action: "Audit & Delete".to_string(),
                reason: format!("Unreachable Module. Not referenced by any entry point. (LOC: {})", metrics.loc),
                strategy: String::new(),
                platform: platform.clone(),
                complexity: 0.0,
                recommended_splits: 1
            });
        }
        
        let mut is_surgical = false;
        if taxonomy != "unknown" && metrics.loc > limit {
            let split_threshold = (limit as f64 * 1.15) as usize;
            if metrics.loc > split_threshold {
                is_surgical = true;
                let nesting_factor = metrics.max_nesting as f64 * config.settings.nesting_weight;
                let density_factor = density * config.settings.density_weight;
                
                let mut reason = format!("[Nesting: {:.2}, Density: {:.2}, Coupling: {:.2}] | Drag: {:.2} | LOC: {}/{}",
                    nesting_factor, density_factor, coupling_score, drag, metrics.loc, limit);
                
                if let Some(symbol) = &metrics.hotspot_symbol {
                    reason = format!("{}  🎯 Target: {} ({})", reason, symbol, 
                        metrics.hotspot_reason.as_ref().unwrap_or(&"Complex Logic".to_string()));
                }
                
                let complexity = ((metrics.loc - limit) as f64 / 10.0) + drag;
                let recommended_splits = (metrics.loc as f64 / 300.0).ceil().max(2.0) as usize;
                
                buffer.entry(d_name.clone()).or_default().push(WorkUnit::Surgical {
                    file: p_str.clone(),
                    action: "De-bloat".to_string(),
                    reason,
                    strategy: String::new(),
                    platform: platform.clone(),
                    complexity,
                    recommended_splits
                });
            }
        }
        
        // Collect stats for merging
        if !is_surgical && taxonomy != "unknown" {
            let dir = path.parent().map(|p| p.to_string_lossy().to_string()).unwrap_or_else(|| ".".to_string());
            let ext_str = path.extension().and_then(|s| s.to_str()).unwrap_or("").to_string();
            let f_name = path.file_name().map(|n| n.to_string_lossy().to_string()).unwrap_or_default();
            dir_stats.entry((dir, ext_str)).or_default().push((f_name, metrics.loc, platform.clone(), drag, p_mod));
            
            let file_stem = path.file_stem().map(|s| s.to_string_lossy().to_string()).unwrap_or_default();
            if file_stem.len() > 3 {
                feature_map.entry(file_stem).or_default().push((p_str.clone(), platform.clone()));
            }
        }
        
        // Violation check
        if let Some(profile) = config.profiles.get(d_name) {
            let treat_single_quote = d_name != "rescript" && d_name != "rust";
            let stripped = drivers::strip_code_modular(content, treat_single_quote);
            for pattern in &profile.forbidden_patterns {
                if stripped.contains(pattern) {
                    buffer.entry(d_name.clone()).or_default().push(WorkUnit::Violation {
                        file: p_str.clone(),
                        pattern: pattern.clone(),
                        strategy: String::new()
                    });
                }
            }
        }
        
        let _ = guard::check_tests(&guard_config, path);
    }
    Ok(())
}

fn generate_structural_tasks(
    feature_map: &HashMap<String, Vec<(String, String)>>,
    buffer: &mut HashMap<String, Vec<WorkUnit>>,
) {
    for (feature, paths) in feature_map {
        if paths.len() > 2 {
            let mut unique_folders: Vec<String> = paths.iter()
                .map(|(p, _)| Path::new(p).parent().map(|pp| pp.to_string_lossy().to_string()).unwrap_or_else(|| ".".to_string()))
                .collect();
            unique_folders.sort();
            unique_folders.dedup();
            
            if unique_folders.len() > 1 {
                let locations = paths.iter().map(|(p, _)| format!("`{}`", p)).collect::<Vec<_>>().join(", ");
                buffer.entry("system".to_string()).or_default().push(WorkUnit::Structural {
                    file: feature.clone(),
                    action: "Vertical Slice".to_string(),
                    platform: paths[0].1.clone(),
                    reason: format!("Feature fragmented across {} files: [{}]", paths.len(), locations),
                    strategy: String::new()
                });
            }
        }
    }
}
