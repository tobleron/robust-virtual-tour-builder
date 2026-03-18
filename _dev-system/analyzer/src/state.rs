use crate::utils::canonicalize_tracked_file_path;
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
                if let Ok(mut state) = serde_json::from_str::<AnalyzerState>(&content) {
                    state.sanitize();
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
        let Some(normalized_path) = canonicalize_tracked_file_path(file_path) else {
            return;
        };
        let entry = self.files.entry(normalized_path).or_default();
        entry.failure_count += 1;
        entry.last_failure_timestamp = Some(now());
        entry.stability_score = (entry.stability_score - 0.2).max(0.0);
        self.dirty = true;
    }

    #[allow(dead_code)]
    pub fn record_action(&mut self, file_path: &str, action: &str) {
        let Some(normalized_path) = canonicalize_tracked_file_path(file_path) else {
            return;
        };
        let entry = self.files.entry(normalized_path).or_default();
        entry.last_action = Some(action.to_string());
        entry.last_action_timestamp = now();
        // Reset stability on major refactor
        entry.stability_score = 0.5;
        self.dirty = true;
    }

    pub fn get_drag_multiplier(&self, file_path: &str) -> f64 {
        let Some(normalized_path) = canonicalize_tracked_file_path(file_path) else {
            return 1.0;
        };
        if let Some(entry) = self.files.get(&normalized_path) {
            if let Some(ts) = entry.last_failure_timestamp {
                let age = now().saturating_sub(ts);
                if age < 86400 {
                    return 1.15;
                }
                if age < 604800 {
                    return 1.05;
                }
            }
        }
        1.0
    }

    pub fn is_locked(&self, file_path: &str) -> bool {
        let Some(normalized_path) = canonicalize_tracked_file_path(file_path) else {
            return false;
        };
        if let Some(entry) = self.files.get(&normalized_path) {
            // Lock if action was taken less than 1 hour ago
            if now().saturating_sub(entry.last_action_timestamp) < 3600 {
                return true;
            }
        }
        false
    }
}

impl AnalyzerState {
    fn sanitize(&mut self) {
        let current_time = now();
        let original_len = self.files.len();
        let mut sanitized: HashMap<String, FileHistory> = HashMap::new();
        let mut changed = false;

        for (raw_path, mut history) in std::mem::take(&mut self.files) {
            let Some(normalized_path) = canonicalize_tracked_file_path(&raw_path) else {
                changed = true;
                continue;
            };

            if normalized_path != raw_path {
                changed = true;
            }

            history.stability_score = history.stability_score.clamp(0.0, 1.0);
            history.failure_count = history.failure_count.min(25);

            if history.last_action_timestamp > current_time {
                history.last_action_timestamp = current_time;
                changed = true;
            }
            if let Some(timestamp) = history.last_failure_timestamp {
                if timestamp > current_time {
                    history.last_failure_timestamp = Some(current_time);
                    changed = true;
                }
            }

            sanitized
                .entry(normalized_path)
                .and_modify(|existing| merge_history(existing, &history))
                .or_insert(history);
        }

        if sanitized.len() != original_len {
            changed = true;
        }

        self.files = sanitized;
        if changed {
            self.dirty = true;
        }
    }
}

fn merge_history(existing: &mut FileHistory, incoming: &FileHistory) {
    if incoming.last_action_timestamp > existing.last_action_timestamp {
        existing.last_action_timestamp = incoming.last_action_timestamp;
        existing.last_action = incoming.last_action.clone();
    }
    existing.stability_score = existing.stability_score.max(incoming.stability_score);
    existing.failure_count = existing.failure_count.max(incoming.failure_count);
    existing.last_failure_timestamp =
        match (existing.last_failure_timestamp, incoming.last_failure_timestamp) {
            (Some(left), Some(right)) => Some(left.max(right)),
            (None, value) => value,
            (value, None) => value,
        };
}

fn now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sanitize_keeps_valid_paths_and_drops_malformed_entries() {
        let mut state = AnalyzerState {
            files: HashMap::from([
                (
                    "../../src/systems/Exporter.res".to_string(),
                    FileHistory {
                        failure_count: 12,
                        last_failure_timestamp: Some(100),
                        ..FileHistory::default()
                    },
                ),
                (
                    "Reference `src/core/SchemaDefinitions.res` for current shapes.".to_string(),
                    FileHistory::default(),
                ),
                (
                    "src/systems/Upload/../../src/systems/Upload/UploadProcessorUtils.res"
                        .to_string(),
                    FileHistory {
                        last_action: Some("refactored".to_string()),
                        last_action_timestamp: 50,
                        ..FileHistory::default()
                    },
                ),
            ]),
            dirty: false,
        };

        state.sanitize();

        assert!(state.files.contains_key("src/systems/Exporter.res"));
        assert!(state
            .files
            .contains_key("src/systems/Upload/UploadProcessorUtils.res"));
        assert_eq!(state.files.len(), 2);
        assert!(state.dirty);
    }

    #[test]
    fn drag_multiplier_uses_bounded_recent_failure_penalty() {
        let current_time = now();
        let state = AnalyzerState {
            files: HashMap::from([(
                "src/systems/Exporter.res".to_string(),
                FileHistory {
                    last_failure_timestamp: Some(current_time),
                    ..FileHistory::default()
                },
            )]),
            dirty: false,
        };

        assert_eq!(state.get_drag_multiplier("../../src/systems/Exporter.res"), 1.15);
    }
}
