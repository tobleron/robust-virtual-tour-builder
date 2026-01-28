use super::{CommonMetrics, strip_code};

pub fn analyze_rescript(content: &str) -> anyhow::Result<CommonMetrics> {
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
    };
    
    // AI Efficiency: Tracking Dependencies
    metrics.external_calls += content.matches("open ").count();
    metrics.external_calls += content.matches("import ").count();
    // Count Module access (simplified)
    for line in stripped.lines() {
        if line.contains(".") {
            let parts: Vec<&str> = line.split('.').collect();
            if parts.len() > 1 {
                let potential_module = parts[0].trim();
                if !potential_module.is_empty() && potential_module.chars().next().unwrap_or(' ').is_uppercase() {
                    metrics.external_calls += 1;
                }
            }
        }
    }

    metrics.logic_count += stripped.matches("->").count();
    metrics.logic_count += stripped.matches("switch ").count();
    metrics.logic_count += stripped.matches("| ").count();
    metrics.complexity_penalty += (stripped.matches("Obj.magic").count() as f64) * 2.5;
    metrics.complexity_penalty += (stripped.matches("mutable ").count() as f64) * 1.5;

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
            metrics.hotspot_reason = Some(format!("AI Context Fog (score {:.1})", max_window_score));
        }
    }

    Ok(metrics)
}
