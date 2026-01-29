use super::CommonMetrics;

pub fn analyze_html(content: &str, dict: &std::collections::HashMap<String, f64>) -> anyhow::Result<CommonMetrics> {
    let mut metrics = CommonMetrics { 
        loc: content.lines().count(), 
        logic_count: 0, 
        max_nesting: 0, 
        complexity_penalty: 0.0,
        hotspot_lines: None,
        hotspot_reason: None,
        external_calls: 0,
        internal_calls: 0,
        dependencies: Vec::new(),
    };
    
    // Dependencies extraction for JS/JSX
    for line in content.lines() {
        let t = line.trim();
        if t.starts_with("import ") {
            // import ... from "..."
            if let Some(pos) = t.find("from") {
                let remainder = &t[pos+4..];
                let dep = remainder.trim().replace(";", "").replace("'", "").replace("\"", "");
                metrics.dependencies.push(dep);
                metrics.external_calls += 1;
            }
        } else if t.contains("require(") {
            let parts: Vec<&str> = t.split("require(").collect();
            if parts.len() > 1 {
                if let Some(end) = parts[1].find(")") {
                    let dep = parts[1][..end].replace("'", "").replace("\"", "");
                    metrics.dependencies.push(dep);
                    metrics.external_calls += 1;
                }
            }
        }
    }

    metrics.logic_count = content.matches("<").count();
    
    // Dynamic Complexity from Config
    metrics.complexity_penalty += super::apply_complexity_dictionary(content, dict);
    
    for line in content.lines() {
        let indent = line.chars().take_while(|c| c.is_whitespace()).count();
        let current = indent / 2;
        if current > metrics.max_nesting { metrics.max_nesting = current; }
    }
    Ok(metrics)
}
