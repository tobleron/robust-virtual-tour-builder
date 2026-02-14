use crate::spec_snapshot::SpecSnapshot;
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerificationBundle {
    pub headline: String,
    pub snapshots: Vec<SpecSnapshot>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerificationReport {
    pub task: String,
    pub category: String,
    pub baseline_dir: String,
    pub bundles: Vec<VerificationBundle>,
    pub timestamp: DateTime<Utc>,
}
