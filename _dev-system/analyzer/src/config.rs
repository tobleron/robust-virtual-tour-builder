use serde::Deserialize;
use std::collections::HashMap;
use anyhow::{Context, Result};
use std::fs;

#[derive(Debug, Deserialize)]
pub struct EfficiencyConfig {
    pub scanned_roots: Option<Vec<String>>,
    pub entry_points: Option<Vec<String>>,
    pub settings: Settings,
    pub templates: Templates,
    pub exclusion_rules: crate::guard::ExclusionRules,
    pub profiles: HashMap<String, Profile>,
    pub taxonomy: HashMap<String, TaxonomyRole>,
    pub exceptions: Option<Vec<ExceptionRule>>,
    pub protected_patterns: Option<Vec<String>>,
}

#[derive(Debug, Deserialize)]
pub struct Templates {
    pub legend: String,
    pub surgical_objective: String,
    pub violation_objective: String,
    pub structural_objective: String,
    pub merge_objective: String,
    pub ambiguity_objective: String,
}

#[derive(Debug, Deserialize)]
pub struct ExceptionRule {
    pub pattern: String,
    pub max_loc: Option<usize>,
    pub multiplier: Option<f64>,
}

#[derive(Debug, Deserialize)]
pub struct Settings {
    pub min_dead_code_loc: usize,
    pub base_loc_limit: usize,
    pub hard_ceiling_loc: usize,
    pub soft_floor_loc: usize,
    #[allow(dead_code)]
    pub max_session_complexity: f64,
    pub merge_score_threshold: f64,
    pub nesting_weight: f64,
    pub density_weight: f64,
    pub drag_target: f64,
    pub state_weight: f64,
    pub max_depth_threshold: usize,
}

#[derive(Debug, Deserialize)]
pub struct Profile {
    pub complexity_dictionary: HashMap<String, f64>,
    pub forbidden_patterns: Vec<String>,
}

#[derive(Debug, Deserialize)]
pub struct TaxonomyRole {
    pub multiplier: f64,
    pub desc: Option<String>,
}

impl EfficiencyConfig {
    /// Load configuration from the default path
    pub fn load() -> Result<Self> {
        Self::load_from("../config/efficiency.json")
    }

    /// Load configuration from a custom path
    pub fn load_from(path: &str) -> Result<Self> {
        let config_raw = fs::read_to_string(path)
            .with_context(|| format!("Failed to read config file: {}", path))?;
        
        let config: EfficiencyConfig = serde_json::from_str(&config_raw)
            .with_context(|| format!("Failed to parse config file: {}", path))?;
        
        Ok(config)
    }
}
