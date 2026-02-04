use crate::config::EfficiencyConfig;
use crate::drivers::{self, CommonMetrics};
use crate::analysis::infer_taxonomy;
use crate::feedback;
use crate::guard::is_project_source;
use crate::state::AnalyzerState;
use anyhow::Result;
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::PathBuf;
use walkdir::WalkDir;

/// Registry entry: (PathBuf, Content, Taxonomy, Metrics, Platform, DriverName)
pub type RegistryEntry = (PathBuf, String, String, CommonMetrics, String, String);

/// File resolver map: FileNameStem -> Vec<FullPathString>
pub type FileResolver = HashMap<String, Vec<String>>;

/// Discover and analyze all files in the project
pub fn discover_and_analyze(
    config: &EfficiencyConfig,
    state: &mut AnalyzerState,
) -> Result<(HashMap<String, RegistryEntry>, FileResolver, HashSet<String>, f64)> {
    let mut registry: HashMap<String, RegistryEntry> = HashMap::new();
    let mut file_resolver: FileResolver = HashMap::new();
    let mut all_files_set: HashSet<String> = HashSet::new();
    
    let mut total_loc = 0;
    let mut file_count = 0;
    
    let roots = config.scanned_roots.clone()
        .unwrap_or_else(|| vec!["../../".to_string()]);
    
    let failed_items = feedback::get_recent_failures();
    let default_dict: HashMap<String, f64> = HashMap::new();
    
    for root in roots {
        let walk_path = if root.starts_with("../../") { 
            root.clone() 
        } else { 
            format!("../../{}", root) 
        };
        
        for entry in WalkDir::new(walk_path).into_iter().filter_map(|e| e.ok()) {
            let path = entry.path();
            if !path.is_file() || !is_project_source(path, &config.exclusion_rules) { 
                continue; 
            }
            
            let content = match fs::read_to_string(path) {
                Ok(c) => c,
                Err(_) => continue,
            };
            
            if content.contains("@efficiency-role: ignored") || content.contains("@efficiency-role ignored") { 
                continue; 
            }
            
            let p_str = path.to_string_lossy().to_string();
            
            // Analyze file
            let taxonomy = infer_taxonomy(path, &content);
            if taxonomy == "ignored" { 
                continue; 
            }
            
            let ext = path.extension().and_then(|s| s.to_str()).unwrap_or("");
            let d_name = match ext { 
                "rs" => "rust", 
                "res" => "rescript", 
                "jsx"|"js"|"html" => "web", 
                "css" => "css", 
                _ => "config" 
            };
            let platform = if ext == "rs" || path.to_string_lossy().contains("backend") { 
                "backend" 
            } else { 
                "frontend" 
            };
            
            let dict = config.profiles.get(d_name)
                .map(|p| &p.complexity_dictionary)
                .unwrap_or(&default_dict);
            
            let metrics = match d_name {
                "rust" => drivers::rust::analyze_rust(&content, dict).unwrap_or_default(),
                "rescript" => drivers::rescript::analyze_rescript(&content, dict).unwrap_or_default(),
                "web" => drivers::html::analyze_html(&content, dict).unwrap_or_default(),
                "css" => drivers::css::analyze_css(&content, dict).unwrap_or_default(),
                _ => drivers::config::analyze_config(&content, dict).unwrap_or_default(),
            };
            
            if metrics.loc > 0 {
                total_loc += metrics.loc;
                file_count += 1;
            }
            
            // Register for graph & processing
            all_files_set.insert(p_str.clone());
            
            let file_stem = path.file_stem()
                .map(|s| s.to_string_lossy().to_string())
                .unwrap_or_default();
            
            // Feedback loop integration
            if failed_items.contains(&p_str) || failed_items.contains(&file_stem) {
                state.mark_failure(&p_str);
            }
            
            file_resolver.entry(file_stem.clone())
                .or_default()
                .push(p_str.clone());
            
            // Store in registry
            registry.insert(
                p_str, 
                (path.to_path_buf(), content, taxonomy, metrics, platform.to_string(), d_name.to_string())
            );
        }
    }
    
    let project_avg_loc = if file_count > 0 { 
        total_loc as f64 / file_count as f64 
    } else { 
        config.settings.base_loc_limit as f64 
    };
    let dynamic_base = (config.settings.base_loc_limit as f64 * 0.8) + (project_avg_loc * 0.2);
    
    Ok((registry, file_resolver, all_files_set, dynamic_base))
}
