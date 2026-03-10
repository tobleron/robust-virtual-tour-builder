use super::CommonMetrics;
use regex::Regex;

fn push_dependency(metrics: &mut CommonMetrics, dep: &str) {
    let clean = dep.trim();
    if clean.is_empty() {
        return;
    }

    if !metrics
        .dependencies
        .iter()
        .any(|existing| existing == clean)
    {
        metrics.dependencies.push(clean.to_string());
        metrics.external_calls += 1;
    }
}

fn collect_import_statements(content: &str) -> Vec<String> {
    let mut statements = Vec::new();
    let mut current: Option<String> = None;

    for line in content.lines() {
        let trimmed = line.trim();

        if let Some(buffer) = current.as_mut() {
            if !trimmed.is_empty() {
                if !buffer.is_empty() {
                    buffer.push(' ');
                }
                buffer.push_str(trimmed);
            }

            let complete = trimmed.ends_with(';')
                || (buffer.contains(" from ")
                    && (buffer.contains('"') || buffer.contains('\''))
                    && (buffer.matches('"').count() >= 2 || buffer.matches('\'').count() >= 2));
            if complete {
                statements.push(current.take().unwrap_or_default());
            }
            continue;
        }

        if trimmed.starts_with("import ") && !trimmed.starts_with("import(") {
            let complete = trimmed.ends_with(';')
                || trimmed.starts_with("import \"")
                || trimmed.starts_with("import '")
                || trimmed.contains(" from ");
            if complete {
                statements.push(trimmed.to_string());
            } else {
                current = Some(trimmed.to_string());
            }
        }
    }

    if let Some(buffer) = current {
        statements.push(buffer);
    }

    statements
}

pub fn analyze_html(
    content: &str,
    dict: &std::collections::HashMap<String, f64>,
) -> anyhow::Result<CommonMetrics> {
    let mut metrics = CommonMetrics {
        loc: content.lines().filter(|l| !l.trim().is_empty()).count(),
        hotspot_symbol: None,
        ..Default::default()
    };

    let import_from_re = Regex::new(r#"from\s*["']([^"']+)["']"#)?;
    let side_effect_import_re = Regex::new(r#"^\s*import\s*["']([^"']+)["']"#)?;
    let require_re = Regex::new(r#"require\(\s*["']([^"']+)["']\s*\)"#)?;

    // Dependencies extraction for JS/JSX/HTML templates used as "web" files.
    for statement in collect_import_statements(content) {
        if let Some(caps) = import_from_re.captures(&statement) {
            if let Some(dep) = caps.get(1) {
                push_dependency(&mut metrics, dep.as_str());
            }
            continue;
        }

        if let Some(caps) = side_effect_import_re.captures(&statement) {
            if let Some(dep) = caps.get(1) {
                push_dependency(&mut metrics, dep.as_str());
            }
        }
    }

    for caps in require_re.captures_iter(content) {
        if let Some(dep) = caps.get(1) {
            push_dependency(&mut metrics, dep.as_str());
        }
    }

    metrics.logic_count = content.matches("<").count();

    // Dynamic Complexity from Config
    metrics.complexity_penalty += super::apply_complexity_dictionary(content, dict);

    for line in content.lines() {
        let indent = line.chars().take_while(|c| c.is_whitespace()).count();
        let current = indent / 2;
        if current > metrics.max_nesting {
            metrics.max_nesting = current;
        }
    }
    Ok(metrics)
}

#[cfg(test)]
mod tests {
    use super::analyze_html;
    use std::collections::HashMap;

    #[test]
    fn analyze_html_extracts_multiline_import_dependencies() {
        let content = r#"
import '../css/style.css';
import {
  normalizeProjectDataForBuilder,
  renderBuilderFramework,
  renderPageFramework,
} from './site/PageFramework.js';

const mod = require("./FeatureLoaders.js");
"#;

        let metrics = analyze_html(content, &HashMap::new()).expect("html analysis should work");

        assert!(metrics
            .dependencies
            .contains(&"../css/style.css".to_string()));
        assert!(metrics
            .dependencies
            .contains(&"./site/PageFramework.js".to_string()));
        assert!(metrics
            .dependencies
            .contains(&"./FeatureLoaders.js".to_string()));
    }
}
