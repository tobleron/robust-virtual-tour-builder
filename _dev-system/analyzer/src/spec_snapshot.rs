use crate::discovery;
use regex::Regex;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::path::Path;

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct FunctionDetail {
    pub name: String,
    pub signature: String,
    pub line: usize,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct SpecSnapshot {
    pub path: String,
    pub functions: Vec<FunctionDetail>,
    pub fingerprint: String,
}

impl SpecSnapshot {
    pub fn from_content(path: &str, content: &str) -> Self {
        let normalized = normalize_path(path);
        let ext = Path::new(path)
            .extension()
            .and_then(|s| s.to_str())
            .unwrap_or("")
            .to_lowercase();
        let functions = parse_functions(content, &ext);
        let fingerprint = fingerprint_functions(&functions);
        SpecSnapshot {
            path: normalized,
            functions,
            fingerprint,
        }
    }
}

pub fn build_snapshots(
    registry: &HashMap<String, discovery::RegistryEntry>,
) -> HashMap<String, SpecSnapshot> {
    let mut map = HashMap::new();
    for (path, (_, content, _, _, _, _)) in registry {
        map.insert(path.clone(), SpecSnapshot::from_content(path, content));
    }
    map
}

fn parse_functions(content: &str, ext: &str) -> Vec<FunctionDetail> {
    match ext {
        "res" | "rescript" => parse_rescript_functions(content),
        "rs" => parse_rust_functions(content),
        _ => Vec::new(),
    }
}

fn parse_rescript_functions(content: &str) -> Vec<FunctionDetail> {
    let mut functions = Vec::new();
    let let_re = Regex::new(r"^\s*let(?:[\s\t]+rec)?[\s\t]+([a-zA-Z_][a-zA-Z0-9_']*)").unwrap();
    // Simplified regex to just catch 'let name' at start of line, checking indentation manually

    let lines: Vec<&str> = content.lines().collect();
    let mut current_module_depth = 0;

    for (i, line) in lines.iter().enumerate() {
        let trimmed = line.trim();
        if trimmed.starts_with("//") || trimmed.starts_with("/*") {
            continue;
        }

        let indent = line.chars().take_while(|c| *c == ' ').count();
        let expected_indent = current_module_depth * 2; // Assuming 2 spaces per indentation level

        // Check for module opening
        if trimmed.starts_with("module") && trimmed.ends_with("{") {
            current_module_depth += 1;
        }

        // Check for block closing
        // This is a naive heuristic: if a line is just "}" or "};" or "}," it closes a block.
        // It might be closing a module or a function.
        // Since we only care about module depth for filtering 'let', and modules usually wrap functions,
        // we need to differentiate closing a module vs closing a function.
        // But since we track indentation, maybe we can just use indentation to guess context?
        // If "}" is at indent 0, it closes module at indent 0 (if any).
        // If "}" is at indent 2, it closes something at indent 2.

        if trimmed == "}" || trimmed == "};" || trimmed == "}," {
             // If we are closing a block that matches current module depth
             // But wait, closing a function inside a module also looks like this.
             // Indentation of "}" matches the start of the block.
             // module X = { -> indent 0
             //   ...
             // } -> indent 0

             let close_indent = indent;
             if current_module_depth > 0 {
                 let expected_close = (current_module_depth - 1) * 2;
                 if close_indent == expected_close {
                     current_module_depth -= 1;
                 }
             }
        }

        // Check for let binding
        if let Some(cap) = let_re.captures(line) {
            // Check if it's an assignment (contains =)
            if line.contains("=") {
                let name = cap[1].to_string();
                if !should_skip_rescript(&name) {
                    // Strict indentation check to avoid capturing local variables
                    // Allow small variance? No, usually strict.
                    if indent == expected_indent {
                         functions.push(FunctionDetail {
                            name,
                            signature: trimmed.to_string(),
                            line: i + 1,
                        });
                    }
                }
            }
        }
    }
    functions
}

fn should_skip_rescript(name: &str) -> bool {
    if name
        .chars()
        .next()
        .map(|c| c.is_uppercase())
        .unwrap_or(false)
    {
        return true;
    }
    matches!(name, "module" | "type" | "open")
}

fn parse_rust_functions(content: &str) -> Vec<FunctionDetail> {
    let mut functions = Vec::new();
    let regex = Regex::new(r"\b(?:pub\s+)?(?:async\s+)?fn\s+([a-zA-Z_][a-zA-Z0-9_]*)").unwrap();
    for capture in regex.captures_iter(content) {
        let name = capture[1].to_string();
        if let Some(mat) = capture.get(0) {
            let start = mat.start();
            let line = line_number_at(content, start);
            let signature = extract_line(content, start);
            functions.push(FunctionDetail {
                name,
                signature,
                line,
            });
        }
    }
    functions.sort_by_key(|f| f.line);
    functions
}

fn fingerprint_functions(functions: &[FunctionDetail]) -> String {
    let mut hasher = Sha256::new();
    for func in functions {
        hasher.update(func.name.as_bytes());
        hasher.update(b"\n");
        hasher.update(func.signature.as_bytes());
        hasher.update(b"\n");
    }
    format!("{:x}", hasher.finalize())
}

fn line_number_at(content: &str, pos: usize) -> usize {
    content[..pos].chars().filter(|&c| c == '\n').count() + 1
}

fn extract_line(content: &str, start: usize) -> String {
    let snippet = &content[start..];
    let end = snippet.find('\n').unwrap_or(snippet.len());
    snippet[..end].trim().to_string()
}

fn normalize_path(path: &str) -> String {
    Path::new(path)
        .strip_prefix("../../")
        .map(|p| p.to_string_lossy().to_string())
        .unwrap_or_else(|_| path.to_string())
}
