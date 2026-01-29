use super::{CommonMetrics, strip_code};

pub fn analyze_rescript(content: &str, dict: &std::collections::HashMap<String, f64>) -> anyhow::Result<CommonMetrics> {
    let stripped = strip_code(content);
    let mut metrics = CommonMetrics { 
        loc: content.lines().filter(|l| !l.trim().is_empty() && !l.trim().starts_with("//")).count(), 
        logic_count: 0, 
        max_nesting: 0, 
        complexity_penalty: 0.0,
        hotspot_lines: None,
        hotspot_reason: None,
        external_calls: 0,
        internal_calls: 0,
        dependencies: Vec::new(),
    };
    
    // AI Efficiency: Tracking Dependencies
    // Extract `open Module`, `include Module`, `module X = Module`
    let lines: Vec<&str> = stripped.lines().collect();
    for line in lines {
        let trim = line.trim();
        if trim.starts_with("open ") {
            if let Some(dep) = trim.split_whitespace().nth(1) {
                metrics.dependencies.push(dep.replace(";", "").to_string());
                metrics.external_calls += 1;
            }
        } else if trim.starts_with("include ") {
            if let Some(dep) = trim.split_whitespace().nth(1) {
                metrics.dependencies.push(dep.replace(";", "").to_string());
                metrics.external_calls += 1;
            }
        } else if trim.starts_with("module ") && trim.contains("=") {
            // module X = Y
            if let Some(parts) = trim.split('=').nth(1) {
                 let dep = parts.trim().replace(";", "");
                 metrics.dependencies.push(dep);
                 metrics.external_calls += 1;
            }
        } else if trim.contains(".") {
             // Heuristic for inline usage like Module.func()
             let parts: Vec<&str> = trim.split('.').collect();
             if parts.len() > 1 {
                 let potential_module = parts[0].trim();
                 // Convention: Modules start with Uppercase
                 if !potential_module.is_empty() && potential_module.chars().next().unwrap_or(' ').is_uppercase() {
                     metrics.external_calls += 1;
                     // Reliable Fix: Capture implicit module usage for the graph
                     metrics.dependencies.push(potential_module.to_string());
                 }
             }
        }

        // JSX Component Usage: <Module ... or <Module.Sub (Anywhere in line)
        // Split by '<' to find all potential tags
        let tag_chunks: Vec<&str> = trim.split('<').collect();
        // Skip the first chunk (before the first <)
        for chunk in tag_chunks.iter().skip(1) {
             let clean_tag = chunk.replace("/>", "").replace(">", "");
             let tag_parts: Vec<&str> = clean_tag.split_whitespace().next().unwrap_or("").split('.').collect();
             if !tag_parts.is_empty() {
                 let potential_module = tag_parts[0];
                 // Must start with Uppercase to be a Module Component
                 if !potential_module.is_empty() && potential_module.chars().next().unwrap_or(' ').is_uppercase() {
                      metrics.external_calls += 1;
                      metrics.dependencies.push(potential_module.to_string());
                 }
             }
        }
    }

    metrics.logic_count += stripped.matches("->").count();
    metrics.logic_count += stripped.matches("switch ").count();
    metrics.logic_count += stripped.matches("| ").count();
    
    // Dynamic Complexity from Config
    metrics.complexity_penalty += super::apply_complexity_dictionary(&stripped, dict);

    let mut bracket_stack: usize = 0;
    let mut line_scores: Vec<f64> = Vec::new();

    for line in content.lines() {
        let stripped_line = strip_code(line);
        let mut local_score = 0.0;
        
        // Local nesting
        bracket_stack += stripped_line.matches("{").count();
        if bracket_stack > metrics.max_nesting { metrics.max_nesting = bracket_stack; }
        
        // AI Penalty: Exponential nesting cost
        local_score += (bracket_stack as f64).powi(2) * 0.2; 
        
        bracket_stack = bracket_stack.saturating_sub(stripped_line.matches("}").count());

        // Local logic
        local_score += (stripped_line.matches("->").count() as f64) * 1.0;
        local_score += (stripped_line.matches("switch").count() as f64) * 2.0;
        local_score += (stripped_line.matches("mutable").count() as f64) * 5.0;

        line_scores.push(local_score);
    }

    // Find the 5-line window with max average score (The Hotspot)
    if line_scores.len() >= 5 {
        let mut max_window_score = -1.0;
        let mut best_start = 0;
        for i in 0..line_scores.len() - 4 {
            let window_score: f64 = line_scores[i..i+5].iter().sum();
            if window_score > max_window_score {
                max_window_score = window_score;
                best_start = i;
            }
        }
        if max_window_score > 2.0 { 
            metrics.hotspot_lines = Some((best_start + 1, best_start + 5));
            metrics.hotspot_reason = Some(format!("AI Context Fog (score {:.1}): This 5-line window has extreme density and nesting. AI agents often lose track of state here, leading to logic Errors.", max_window_score));
        }
    }

    Ok(metrics)
}
