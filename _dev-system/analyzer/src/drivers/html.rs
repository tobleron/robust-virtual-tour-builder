use super::CommonMetrics;

pub fn analyze_html(content: &str) -> anyhow::Result<CommonMetrics> {
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
    
    metrics.logic_count = content.matches("<").count();
    
    for line in content.lines() {
        let indent = line.chars().take_while(|c| c.is_whitespace()).count();
        let current = indent / 2;
        if current > metrics.max_nesting { metrics.max_nesting = current; }
    }
    Ok(metrics)
}
