use super::{strip_code, CommonMetrics};

pub fn analyze_css(
    content: &str,
    dict: &std::collections::HashMap<String, f64>,
) -> anyhow::Result<CommonMetrics> {
    let stripped = strip_code(content);
    let mut metrics = CommonMetrics {
        loc: content.lines().filter(|l| !l.trim().is_empty()).count(),
        hotspot_symbol: None,
        ..Default::default()
    };

    // Dependencies extraction for CSS (@import)
    for line in content.lines() {
        let trim = line.trim();
        if trim.starts_with("@import") {
            let mut path_part = trim.trim_start_matches("@import").trim();
            // Remove trailing semicolon
            path_part = path_part.trim_end_matches(';');
            path_part = path_part.trim();

            // Handle url(...) wrapper
            if path_part.starts_with("url(") && path_part.ends_with(")") {
                path_part = &path_part[4..path_part.len() - 1];
            }

            // Remove quotes
            let clean = path_part
                .replace("\"", "")
                .replace("'", "")
                .trim()
                .to_string();
            if !clean.is_empty() {
                metrics.dependencies.push(clean);
                metrics.external_calls += 1;
            }
        }
    }

    metrics.logic_count = stripped.matches("{").count();

    // Dynamic Complexity from Config
    metrics.complexity_penalty += super::apply_complexity_dictionary(&stripped, dict);

    let mut depth = 0;
    for c in stripped.chars() {
        if c == '{' {
            depth += 1;
            if depth > metrics.max_nesting {
                metrics.max_nesting = depth;
            }
        }
        if c == '}' {
            depth = depth.saturating_sub(1);
        }
    }
    Ok(metrics)
}
