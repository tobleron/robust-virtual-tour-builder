use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::Path;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct FileHistory {
    pub last_action: Option<String>,
    pub last_action_timestamp: u64,
    pub stability_score: f64, // 0.0 to 1.0, where 1.0 is very stable
    pub failure_count: usize,
    pub last_failure_timestamp: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct AnalyzerState {
    pub files: HashMap<String, FileHistory>,
    #[serde(skip)]
    dirty: bool,
}

impl AnalyzerState {
    pub fn load() -> Self {
        let path = Path::new("../analyzer_state.json");
        if path.exists() {
            if let Ok(content) = fs::read_to_string(path) {
                if let Ok(state) = serde_json::from_str(&content) {
                    return state;
                }
            }
        }
        AnalyzerState::default()
    }

    pub fn save(&self) -> anyhow::Result<()> {
        if !self.dirty {
            return Ok(());
        }
        let json = serde_json::to_string_pretty(self)?;
        let mut file = OpenOptions::new()
            .create(true)
            .write(true)
            .truncate(true)
            .open("../analyzer_state.json")?;
        file.write_all(json.as_bytes())?;
        Ok(())
    }

    pub fn mark_failure(&mut self, file_path: &str) {
        let entry = self.files.entry(file_path.to_string()).or_default();
        entry.failure_count += 1;
        entry.last_failure_timestamp = Some(now());
        entry.stability_score = (entry.stability_score - 0.2).max(0.0);
        self.dirty = true;
    }

    #[allow(dead_code)]
    pub fn record_action(&mut self, file_path: &str, action: &str) {
        let entry = self.files.entry(file_path.to_string()).or_default();
        entry.last_action = Some(action.to_string());
        entry.last_action_timestamp = now();
        // Reset stability on major refactor
        entry.stability_score = 0.5;
        self.dirty = true;
    }

    pub fn get_drag_multiplier(&self, file_path: &str) -> f64 {
        if let Some(entry) = self.files.get(file_path) {
            // If recently failed, increase drag significantly
            if let Some(ts) = entry.last_failure_timestamp {
                if now().saturating_sub(ts) < 86400 { // Failed in last 24h
                     return 1.5;
                }
            }
        }
        1.0
    }

    pub fn is_locked(&self, file_path: &str) -> bool {
        if let Some(entry) = self.files.get(file_path) {
            // Lock if action was taken less than 1 hour ago
             if now().saturating_sub(entry.last_action_timestamp) < 3600 {
                 return true;
             }
        }
        false
    }
}

fn now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}
