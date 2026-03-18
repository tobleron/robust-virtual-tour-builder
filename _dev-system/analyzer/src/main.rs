mod analysis;
mod config;
mod consolidator;
mod discovery;
mod drivers;
mod feedback;
mod flusher;
mod graph;
mod guard;
mod merger;
mod spec_snapshot;
mod state;
mod task_generator;
mod utils;
mod verification;

use anyhow::Result;
use efficiency_analyzer::resolver::Resolver;
use graph::DependencyGraph;
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::Path;

use analysis::calculate_dynamic_limit;
use config::EfficiencyConfig;
use discovery::discover_and_analyze;
use flusher::flush_plans;
use merger::{detect_merge_candidates, detect_recursive_clusters};
use task_generator::{sync_all_architectural_tasks, WorkUnit};
use utils::get_drag_target;
use verification::VerificationBundle;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum SurgicalTrigger {
    Oversized,
    DragRisk,
}

fn is_test_only_helper(path: &str) -> bool {
    let file_name = Path::new(path)
        .file_name()
        .and_then(|value| value.to_str())
        .unwrap_or_default();
    file_name.ends_with("_tests.rs")
        || file_name.ends_with("_test.rs")
        || file_name.ends_with("_v.test.res")
        || file_name.ends_with("_v.test.bs.js")
}

fn main() -> Result<()> {
    // Load configuration and state
    let mut state = state::AnalyzerState::load();
    let guard_config = guard::GuardConfig::default();
    let config = EfficiencyConfig::load()?;

    // Phase 1: Discovery & Analysis
    let (registry, file_resolver, all_files_set, dynamic_base) =
        discover_and_analyze(&config, &mut state)?;
    let spec_map = spec_snapshot::build_snapshots(&registry);

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
    let mut dir_stats: HashMap<(String, String), Vec<(String, usize, String, f64, f64)>> =
        HashMap::new();
    let mut feature_map: HashMap<String, Vec<(String, String)>> = HashMap::new();

    let dead_files: HashSet<String> = dep_graph
        .find_dead_code(&all_files_set, &entry_points)
        .into_iter()
        .collect();

    // Generate work units from registry
    generate_work_units(
        &registry,
        &dead_files,
        &config,
        &state,
        &guard_config,
        dynamic_base,
        &mut buffer,
        &mut dir_stats,
        &mut feature_map,
        &spec_map,
    )?;

    // Phase 4: Merge Analysis
    let (cluster_units, mut processed_merge_files) = detect_recursive_clusters(
        &registry,
        &dead_files,
        &buffer,
        &config,
        dynamic_base,
        &spec_map,
    );
    buffer
        .entry("system".to_string())
        .or_default()
        .extend(cluster_units);

    let merge_units = detect_merge_candidates(
        dir_stats,
        &registry,
        &buffer,
        &mut processed_merge_files,
        &state,
        dynamic_base,
        &config,
        &spec_map,
    );
    buffer
        .entry("system".to_string())
        .or_default()
        .extend(merge_units);

    // Structural analysis
    generate_structural_tasks(&feature_map, &mut buffer);

    // Phase 5: Output
    let _ = fs::create_dir_all("../plans");
    let json_data = serde_json::to_string_pretty(&buffer).unwrap_or_default();
    let _ = fs::write("../plans/metadata.json", json_data);
    flush_plans(&buffer, &config)?;
    sync_all_architectural_tasks(&buffer, &config, &dep_graph)?;

    let _ = guard::check_map(&guard_config, &config.exclusion_rules, &config);
    if let Some(map_tree_cfg) = &config.map_tree {
        let _ = guard::check_map_tree(&guard_config, map_tree_cfg);
    }
    let _ = guard::check_data_flow(&guard_config, &config.exclusion_rules, &config);
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
    spec_map: &HashMap<String, spec_snapshot::SpecSnapshot>,
) -> Result<()> {
    for (p_str, (path, content, taxonomy, metrics, platform, d_name)) in registry {
        // Ambiguity check
        if taxonomy == "unknown" {
            buffer
                .entry("system".to_string())
                .or_default()
                .push(WorkUnit::Ambiguity {
                    file: p_str.clone(),
                    strategy: String::new(),
                });
        }

        // Calculate metrics
        let density = metrics.logic_count as f64 / metrics.loc.max(1) as f64;
        let dependency_density = metrics.external_calls as f64 / metrics.loc.max(1) as f64;
        let coupling_score = metrics.external_calls as f64 / metrics.loc.max(1) as f64;

        let mut p_mod = config
            .taxonomy
            .get(taxonomy)
            .map(|t| t.multiplier)
            .unwrap_or(1.0);
        if let Some(exceptions) = &config.exceptions {
            for rule in exceptions {
                if p_str.contains(&rule.pattern) {
                    if let Some(m) = rule.multiplier {
                        p_mod *= m;
                    }
                    break;
                }
            }
        }

        let cohesion_bonus = 1.0 + (0.5 - dependency_density).max(0.0);
        let state_density = metrics.state_count as f64 / metrics.loc.max(1) as f64;

        let clean_path = p_str.replace("../../", "");
        let dir_depth = Path::new(&clean_path)
            .components()
            .count()
            .saturating_sub(config.settings.max_depth_threshold) as f64;
        let depth_penalty = if dir_depth > 0.0 {
            dir_depth * 0.5
        } else {
            0.0
        };

        let failure_penalty = state.get_drag_multiplier(p_str);

        // Formula v2.0: Removed complexity_density * 20.0 (was double-counting state)
        // Unified state penalty to state_density * state_weight (now 8.0)
        let drag = (
            1.0
            + (metrics.max_nesting as f64 * config.settings.nesting_weight)  // 0.6: Nesting critical for AI
            + (density * config.settings.density_weight)                      // 1.0: Moderate impact
            + (state_density * config.settings.state_weight)                  // 8.0: Unified state penalty
            + (depth_penalty * 0.6)
            // 0.6: Minor directory depth penalty
        ) * failure_penalty;

        let limit =
            calculate_dynamic_limit(drag, p_mod, cohesion_bonus, dynamic_base, config, p_str);

        // Dead code task
        if dead_files.contains(p_str)
            && !is_test_only_helper(p_str)
            && metrics.loc > config.settings.min_dead_code_loc
        {
            buffer
                .entry(d_name.clone())
                .or_default()
                .push(WorkUnit::Surgical {
                    file: p_str.clone(),
                    action: "Audit & Delete".to_string(),
                    reason: format!(
                        "Unreachable Module. Not referenced by any entry point. (LOC: {})",
                        metrics.loc
                    ),
                    strategy: String::new(),
                    platform: platform.clone(),
                    complexity: 0.0,
                    recommended_splits: 1,
                    verification: None,
                });
        }

        let mut is_surgical = false;
        if taxonomy != "unknown" {
            let drag_target = get_drag_target(config, p_str);
            if let Some(trigger) = surgical_trigger(
                p_str,
                content,
                taxonomy,
                d_name,
                metrics.loc,
                limit,
                drag,
                drag_target,
                metrics.hotspot_symbol.is_some(),
                metrics.max_nesting,
                density,
                coupling_score,
                metrics.hotspot_reason.as_deref(),
                config,
            ) {
                is_surgical = true;
                let nesting_factor = metrics.max_nesting as f64 * config.settings.nesting_weight;
                let density_factor = density * config.settings.density_weight;

                let mut reason = format!(
                    "[Nesting: {:.2}, Density: {:.2}, Coupling: {:.2}] | Drag: {:.2} | LOC: {}/{}",
                    nesting_factor, density_factor, coupling_score, drag, metrics.loc, limit
                );

                match trigger {
                    SurgicalTrigger::DragRisk if metrics.loc <= working_band_upper_loc(config) => {
                        reason.push_str(&format!(
                            "  ⚠️ Trigger: Drag above target ({:.2}) with file already at {} LOC.",
                            drag_target, metrics.loc
                        ));
                    }
                    SurgicalTrigger::DragRisk => {
                        reason.push_str(&format!(
                            "  ⚠️ Trigger: Drag above target ({:.2}); keep the module within the 350-450 LOC working band if you extract helpers.",
                            drag_target
                        ));
                    }
                    SurgicalTrigger::Oversized => {
                        reason.push_str(
                            "  ⚠️ Trigger: Oversized beyond the preferred 350-450 LOC working band.",
                        );
                    }
                }

                if let Some(symbol) = &metrics.hotspot_symbol {
                    reason = format!(
                        "{}  🎯 Target: {} ({})",
                        reason,
                        symbol,
                        metrics
                            .hotspot_reason
                            .as_ref()
                            .unwrap_or(&"Complex Logic".to_string())
                    );
                }

                let complexity = ((metrics.loc.saturating_sub(limit)) as f64 / 10.0) + drag;
                let recommended_splits = recommended_module_count(metrics.loc, config);
                let verification = spec_map.get(p_str).map(|snapshot| VerificationBundle {
                    headline: format!("Pre-split snapshot for `{}`", snapshot.path),
                    snapshots: vec![snapshot.clone()],
                });

                buffer
                    .entry(d_name.clone())
                    .or_default()
                    .push(WorkUnit::Surgical {
                        file: p_str.clone(),
                        action: "De-bloat".to_string(),
                        reason,
                        strategy: String::new(),
                        platform: platform.clone(),
                        complexity,
                        recommended_splits,
                        verification,
                    });
            }
        }

        // Collect stats for merging
        if !is_surgical && taxonomy != "unknown" {
            let dir = path
                .parent()
                .map(|p| p.to_string_lossy().to_string())
                .unwrap_or_else(|| ".".to_string());
            let ext_str = path
                .extension()
                .and_then(|s| s.to_str())
                .unwrap_or("")
                .to_string();
            let f_name = path
                .file_name()
                .map(|n| n.to_string_lossy().to_string())
                .unwrap_or_default();
            dir_stats.entry((dir, ext_str)).or_default().push((
                f_name,
                metrics.loc,
                platform.clone(),
                drag,
                p_mod,
            ));

            let file_stem = path
                .file_stem()
                .map(|s| s.to_string_lossy().to_string())
                .unwrap_or_default();
            if file_stem.len() > 3 {
                feature_map
                    .entry(file_stem)
                    .or_default()
                    .push((p_str.clone(), platform.clone()));
            }
        }

        // Violation check
        if let Some(profile) = config.profiles.get(d_name) {
            let treat_single_quote = d_name != "rescript" && d_name != "rust";
            let stripped = drivers::strip_code_modular(content, treat_single_quote);

            // Check for per-file violation overrides
            let skip_pattern = match drivers::parse_header(content) {
                drivers::EfficiencyOverride::SkipViolation(p) => Some(p),
                _ => None,
            };

            for pattern in &profile.forbidden_patterns {
                if Some(pattern.to_string()) == skip_pattern {
                    continue;
                }

                if stripped.contains(pattern) {
                    buffer
                        .entry(d_name.clone())
                        .or_default()
                        .push(WorkUnit::Violation {
                            file: p_str.clone(),
                            pattern: pattern.clone(),
                            strategy: String::new(),
                        });
                }
            }
        }

        let _ = guard::check_tests(&guard_config, path);
    }
    Ok(())
}

fn split_threshold(limit: usize) -> usize {
    (limit as f64 * 1.25) as usize
}

fn drag_trigger_min_loc(config: &EfficiencyConfig) -> usize {
    config
        .settings
        .soft_floor_loc
        .saturating_sub(50)
        .max(config.settings.min_extracted_module_loc)
}

fn working_band_upper_loc(config: &EfficiencyConfig) -> usize {
    config.settings.soft_floor_loc + 50
}

fn module_count_score(loc: usize, modules: usize, config: &EfficiencyConfig) -> f64 {
    let average_loc = loc as f64 / modules as f64;
    let center = config.settings.soft_floor_loc as f64;
    let lower = drag_trigger_min_loc(config) as f64;
    let upper = working_band_upper_loc(config) as f64;
    let minimum_child = config.settings.min_extracted_module_loc as f64;

    if average_loc < minimum_child {
        return f64::INFINITY;
    }

    if average_loc < lower {
        return (lower - average_loc) * 3.0;
    }
    if average_loc > upper {
        return (average_loc - upper) * 2.0;
    }

    (average_loc - center).abs() * 0.5
}

fn recommended_module_count(loc: usize, config: &EfficiencyConfig) -> usize {
    if loc <= working_band_upper_loc(config) {
        return 1;
    }

    let max_modules =
        ((loc as f64 / config.settings.min_extracted_module_loc as f64).ceil() as usize).max(1);
    let mut best_modules = 1usize;
    let mut best_score = module_count_score(loc, best_modules, config);

    for modules in 2..=max_modules {
        let score = module_count_score(loc, modules, config);
        if score < best_score {
            best_score = score;
            best_modules = modules;
        }
    }

    best_modules
}

fn matches_exception_with_max_loc(path: &str, config: &EfficiencyConfig) -> bool {
    config
        .exceptions
        .as_ref()
        .map(|rules| {
            rules
                .iter()
                .any(|rule| rule.max_loc.is_some() && path.contains(&rule.pattern))
        })
        .unwrap_or(false)
}

fn matches_protected_pattern(path: &str, content: &str, config: &EfficiencyConfig) -> bool {
    config
        .protected_patterns
        .as_ref()
        .map(|patterns| {
            patterns
                .iter()
                .any(|pattern| path.contains(pattern) || content.contains(pattern))
        })
        .unwrap_or(false)
}

fn is_drag_risk_exempt(
    path: &str,
    content: &str,
    taxonomy: &str,
    driver_name: &str,
    config: &EfficiencyConfig,
) -> bool {
    if driver_name == "css" {
        return true;
    }

    if taxonomy == "data-model" {
        return true;
    }

    if matches_exception_with_max_loc(path, config)
        || matches_protected_pattern(path, content, config)
    {
        return true;
    }

    matches!(
        Path::new(path).file_name().and_then(|name| name.to_str()),
        Some("mod.rs" | "models.rs")
    )
}

fn drag_risk_threshold(drag_target: f64, has_hotspot: bool) -> f64 {
    let margin = if has_hotspot { 0.8 } else { 1.4 };
    drag_target + margin
}

fn is_thin_shell_drag_exempt(
    loc: usize,
    max_nesting: usize,
    density: f64,
    coupling_score: f64,
    config: &EfficiencyConfig,
) -> bool {
    loc <= config.settings.soft_floor_loc
        && max_nesting <= 3
        && density <= 0.20
        && coupling_score <= 0.05
}

fn hotspot_complexity_score(hotspot_reason: Option<&str>) -> Option<f64> {
    let reason = hotspot_reason?;
    let prefix = "High Local Complexity (";
    let start = reason.find(prefix)? + prefix.len();
    let remainder = &reason[start..];
    let end = remainder.find(')')?;
    remainder[..end].parse::<f64>().ok()
}

fn is_low_value_drag_churn(
    loc: usize,
    density: f64,
    coupling_score: f64,
    hotspot_reason: Option<&str>,
    config: &EfficiencyConfig,
) -> bool {
    loc <= config.settings.soft_floor_loc
        && density <= 0.25
        && coupling_score <= 0.08
        && hotspot_complexity_score(hotspot_reason)
            .map(|value| value <= 2.5)
            .unwrap_or(false)
}

fn surgical_trigger(
    path: &str,
    content: &str,
    taxonomy: &str,
    driver_name: &str,
    loc: usize,
    limit: usize,
    drag: f64,
    drag_target: f64,
    has_hotspot: bool,
    max_nesting: usize,
    density: f64,
    coupling_score: f64,
    hotspot_reason: Option<&str>,
    config: &EfficiencyConfig,
) -> Option<SurgicalTrigger> {
    if is_drag_risk_exempt(path, content, taxonomy, driver_name, config) {
        if loc > limit && loc > split_threshold(limit) {
            return Some(SurgicalTrigger::Oversized);
        }
        return None;
    }

    let min_loc = if has_hotspot {
        drag_trigger_min_loc(config)
    } else {
        config.settings.soft_floor_loc
    };
    if is_thin_shell_drag_exempt(loc, max_nesting, density, coupling_score, config) {
        return None;
    }
    if is_low_value_drag_churn(loc, density, coupling_score, hotspot_reason, config) {
        return None;
    }
    if drag >= drag_risk_threshold(drag_target, has_hotspot) && loc >= min_loc {
        return Some(SurgicalTrigger::DragRisk);
    }

    if loc > limit && loc > split_threshold(limit) {
        return Some(SurgicalTrigger::Oversized);
    }

    None
}

fn generate_structural_tasks(
    feature_map: &HashMap<String, Vec<(String, String)>>,
    buffer: &mut HashMap<String, Vec<WorkUnit>>,
) {
    for (feature, paths) in feature_map {
        if paths.len() > 2 {
            let mut unique_folders: Vec<String> = paths
                .iter()
                .map(|(p, _)| {
                    Path::new(p)
                        .parent()
                        .map(|pp| pp.to_string_lossy().to_string())
                        .unwrap_or_else(|| ".".to_string())
                })
                .collect();
            unique_folders.sort();
            unique_folders.dedup();

            if unique_folders.len() > 1 {
                let locations = paths
                    .iter()
                    .map(|(p, _)| format!("`{}`", p))
                    .collect::<Vec<_>>()
                    .join(", ");
                buffer
                    .entry("system".to_string())
                    .or_default()
                    .push(WorkUnit::Structural {
                        file: feature.clone(),
                        action: "Vertical Slice".to_string(),
                        platform: paths[0].1.clone(),
                        reason: format!(
                            "Feature fragmented across {} files: [{}]",
                            paths.len(),
                            locations
                        ),
                        strategy: String::new(),
                    });
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn config() -> EfficiencyConfig {
        EfficiencyConfig::load_from("../config/efficiency.json").expect("config should load")
    }

    #[test]
    fn surgical_trigger_keeps_existing_size_based_gate() {
        let config = config();
        assert_eq!(
            surgical_trigger(
                "../../src/systems/Example.res",
                "",
                "service-orchestrator",
                "rescript",
                520,
                400,
                1.2,
                2.4,
                false,
                2,
                0.08,
                0.08,
                None,
                &config,
            ),
            Some(SurgicalTrigger::Oversized)
        );
    }

    #[test]
    fn surgical_trigger_adds_drag_risk_for_medium_sized_files() {
        let config = config();
        assert_eq!(
            surgical_trigger(
                "../../src/core/HotspotHelpers.res",
                "",
                "domain-logic",
                "rescript",
                380,
                400,
                4.0,
                2.4,
                true,
                5,
                0.15,
                0.09,
                Some("High Local Complexity (5.0). Logic heavy."),
                &config,
            ),
            Some(SurgicalTrigger::DragRisk)
        );
    }

    #[test]
    fn surgical_trigger_prefers_drag_risk_when_drag_and_size_both_qualify() {
        let config = config();
        assert_eq!(
            surgical_trigger(
                "../../src/systems/Exporter/ExporterUpload.res",
                "",
                "service-orchestrator",
                "rescript",
                410,
                400,
                5.3,
                2.4,
                true,
                5,
                0.14,
                0.09,
                Some("High Local Complexity (9.0). Logic heavy."),
                &config,
            ),
            Some(SurgicalTrigger::DragRisk)
        );
    }

    #[test]
    fn surgical_trigger_ignores_small_high_drag_files() {
        let config = config();
        assert_eq!(
            surgical_trigger(
                "../../src/systems/Example.res",
                "",
                "service-orchestrator",
                "rescript",
                220,
                400,
                3.5,
                2.4,
                true,
                4,
                0.11,
                0.08,
                Some("High Local Complexity (4.0). Logic heavy."),
                &config,
            ),
            None
        );
    }

    #[test]
    fn drag_trigger_min_loc_tracks_soft_floor_with_guardrail() {
        let config = config();
        assert_eq!(drag_trigger_min_loc(&config), 350);
    }

    #[test]
    fn recommended_module_count_keeps_medium_drag_risk_modules_in_place() {
        let config = config();
        assert_eq!(recommended_module_count(450, &config), 1);
        assert_eq!(recommended_module_count(500, &config), 1);
    }

    #[test]
    fn recommended_module_count_splits_only_when_modules_stay_near_centerline() {
        let config = config();
        assert_eq!(recommended_module_count(700, &config), 2);
        assert_eq!(recommended_module_count(900, &config), 2);
        assert_eq!(recommended_module_count(1011, &config), 3);
    }

    #[test]
    fn surgical_trigger_skips_protected_entrypoints_for_drag_risk() {
        let config = config();
        assert_eq!(
            surgical_trigger(
                "../../src/Main.res",
                "@efficiency-role: orchestrator",
                "orchestrator",
                "rescript",
                362,
                500,
                4.66,
                2.4,
                true,
                4,
                0.13,
                0.08,
                Some("High Local Complexity (6.0). Logic heavy."),
                &config,
            ),
            None
        );
    }

    #[test]
    fn surgical_trigger_skips_css_drag_risk() {
        let config = config();
        assert_eq!(
            surgical_trigger(
                "../../css/components/viewer-hotspots.css",
                "",
                "ui-component",
                "css",
                269,
                408,
                2.3,
                2.2,
                false,
                2,
                0.08,
                0.04,
                None,
                &config,
            ),
            None
        );
    }

    #[test]
    fn surgical_trigger_skips_mod_rs_and_data_models_for_drag_risk() {
        let config = config();
        assert_eq!(
            surgical_trigger(
                "../../backend/src/services/project/mod.rs",
                "",
                "orchestrator",
                "rust",
                261,
                400,
                1.9,
                2.6,
                false,
                2,
                0.10,
                0.04,
                None,
                &config,
            ),
            None
        );
        assert_eq!(
            surgical_trigger(
                "../../backend/src/models.rs",
                "",
                "data-model",
                "rust",
                280,
                337,
                2.82,
                2.6,
                false,
                2,
                0.10,
                0.04,
                None,
                &config,
            ),
            None
        );
    }

    #[test]
    fn surgical_trigger_skips_thin_shell_drag_risk_modules() {
        let config = config();
        assert_eq!(
            surgical_trigger(
                "../../src/systems/Navigation/NavigationSupervisor.res",
                "",
                "service-orchestrator",
                "rescript",
                285,
                400,
                3.16,
                2.4,
                true,
                3,
                0.19,
                0.04,
                Some("High Local Complexity (7.0). Logic heavy."),
                &config,
            ),
            None
        );
    }

    #[test]
    fn surgical_trigger_keeps_real_hotspots_in_place_inside_new_band() {
        let config = config();
        assert_eq!(
            surgical_trigger(
                "../../src/systems/Navigation/NavigationController.res",
                "",
                "service-orchestrator",
                "rescript",
                420,
                400,
                4.2,
                2.4,
                true,
                5,
                0.09,
                0.10,
                Some("High Local Complexity (18.0). Logic heavy."),
                &config,
            ),
            Some(SurgicalTrigger::DragRisk)
        );
    }

    #[test]
    fn surgical_trigger_skips_low_value_in_band_drag_churn() {
        let config = config();
        assert_eq!(
            surgical_trigger(
                "../../src/systems/TeaserRecorder.res",
                "",
                "service-orchestrator",
                "rescript",
                294,
                400,
                6.64,
                2.4,
                true,
                9,
                0.22,
                0.07,
                Some("High Local Complexity (2.0). Logic heavy."),
                &config,
            ),
            None
        );
    }

    #[test]
    fn test_only_helper_files_are_not_dead_code_candidates() {
        assert!(is_test_only_helper("../../backend/src/api/auth_tests.rs"));
        assert!(is_test_only_helper(
            "../../tests/unit/PreviewArrow_v.test.res"
        ));
        assert!(!is_test_only_helper("../../backend/src/api/auth.rs"));
    }
}
