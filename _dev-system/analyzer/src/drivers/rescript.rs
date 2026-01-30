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
        state_count: 0,
        dependencies: Vec::new(),
    };
    
    // AI Efficiency: Tracking Dependencies
    // Extract `open Module`, `include Module`, `module X = Module`
    for line in content.lines() {
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
             // Heuristic for inline usage like Module.func() or Module.Sub.func()
             let parts: Vec<&str> = trim.split('.').collect();
             if parts.len() > 1 {
                 for i in 0..parts.len() - 1 {
                     let potential_module_part = parts[i].trim();
                     // Extract the last valid word (token) before the dot
                     let potential_module = potential_module_part.split(|c: char| !c.is_alphanumeric() && c != '_')
                         .filter(|s| !s.is_empty())
                         .last().unwrap_or("");
                     
                     if !potential_module.is_empty() && potential_module.chars().next().unwrap_or(' ').is_uppercase() {
                         metrics.external_calls += 1;
                         metrics.dependencies.push(potential_module.to_string());
                     }
                 }
             }
        }


        // JSX Component Usage: <Module ... or <Module.Sub
        // Improved: Find all occurrences of < followed by an Uppercase letter
        let mut start_search = 0;
        while let Some(pos) = trim[start_search..].find('<') {
            let actual_pos = start_search + pos;
            if let Some(next_char) = trim.chars().nth(actual_pos + 1) {
                if next_char.is_uppercase() {
                    // Extract module name
                    let rest = &trim[actual_pos + 1..];
                    let end_pos = rest.find(|c: char| !c.is_alphanumeric() && c != '.' && c != '_').unwrap_or(rest.len());
                    let full_tag = &rest[..end_pos];
                    let potential_module = full_tag.split('.').next().unwrap_or("");
                    
                    if !potential_module.is_empty() {
                        metrics.external_calls += 1;
                        metrics.dependencies.push(potential_module.to_string());
                    }
                }
            }
            start_search = actual_pos + 1;
        }
    }

    metrics.logic_count += stripped.matches("->").count();
    metrics.logic_count += stripped.matches("=>").count();
    metrics.logic_count += stripped.matches("if ").count();
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

        let sc = stripped_line.matches("mutable").count() + stripped_line.matches("ref(").count() + stripped_line.matches("useState").count();
        metrics.state_count += sc;
        local_score += (sc as f64) * 5.0;

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
