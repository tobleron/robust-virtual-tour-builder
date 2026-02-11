use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum TelemetryPriority {
    Critical,
    High,
    Medium,
    Low,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TelemetryEntry {
    pub level: String,
    pub module: String,
    pub message: String,
    pub data: Option<serde_json::Value>,
    pub timestamp: String,
    pub priority: TelemetryPriority,
    #[serde(default)]
    pub request_id: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TelemetryBatch {
    pub entries: Vec<TelemetryEntry>,
}
