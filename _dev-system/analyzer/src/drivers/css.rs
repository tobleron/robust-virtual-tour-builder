use super::{CommonMetrics, strip_code};

pub fn analyze_css(content: &str) -> anyhow::Result<CommonMetrics> {
    let stripped = strip_code(content);
    let mut metrics = CommonMetrics { 
        loc: content.lines().count(), 
        logic_count: 0, 
        max_nesting: 0, 
        complexity_penalty: 0.0,
        hotspot_lines: None,
        hotspot_reason: None,
        external_calls: 0,
        internal_calls: 0,
    };
    
    metrics.logic_count = stripped.matches("{").count();
    metrics.complexity_penalty += (stripped.matches("!important").count() as f64) * 3.0;
    metrics.complexity_penalty += (stripped.matches("@media").count() as f64) * 0.5;

    let mut depth = 0;
    for c in stripped.chars() {
        if c == '{' { 
            depth += 1; 
            if depth > metrics.max_nesting { metrics.max_nesting = depth; }
        }
        if c == '}' { depth = depth.saturating_sub(1); }
    }
    Ok(metrics)
}
