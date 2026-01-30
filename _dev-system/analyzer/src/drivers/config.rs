use super::CommonMetrics;
use serde_json::Value;

pub fn analyze_config(
    content: &str,
    _dict: &std::collections::HashMap<String, f64>,
) -> anyhow::Result<CommonMetrics> {
    let mut metrics = CommonMetrics {
        loc: content.lines().filter(|l| !l.trim().is_empty()).count(),
        hotspot_symbol: None,
        ..Default::default()
    };
    let v: Value = serde_json::from_str(content).unwrap_or(Value::Null);

    if let Value::Object(map) = v {
        metrics.logic_count = map.len();
    }
    Ok(metrics)
}
