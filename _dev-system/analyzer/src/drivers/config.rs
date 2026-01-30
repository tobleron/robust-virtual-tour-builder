use super::CommonMetrics;
use serde_json::Value;

pub fn analyze_config(content: &str, _dict: &std::collections::HashMap<String, f64>) -> anyhow::Result<CommonMetrics> {
    let mut metrics = CommonMetrics { 
        loc: content.lines().count(), 
        logic_count: 0, 
        max_nesting: 0, 
        complexity_penalty: 0.0,
        hotspot_lines: None,
        hotspot_reason: None,
        external_calls: 0,
        internal_calls: 0,
        state_count: 0,
        dependencies: Vec::new(),
    };
    let v: Value = serde_json::from_str(content).unwrap_or(Value::Null);

    if let Value::Object(map) = v {
        metrics.logic_count = map.len();
    }
    Ok(metrics)
}
