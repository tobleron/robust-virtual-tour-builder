use crate::spec_snapshot::SpecSnapshot;
use serde::Serialize;

#[derive(Debug, Clone, Serialize)]
pub struct VerificationBundle {
    pub headline: String,
    pub snapshots: Vec<SpecSnapshot>,
}

#[derive(Debug, Clone, Serialize)]
pub struct VerificationReport {
    pub task: String,
    pub category: String,
    pub baseline_dir: String,
    pub bundles: Vec<VerificationBundle>,
}
