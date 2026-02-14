use crate::discovery;
use regex::Regex;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::path::Path;
use tree_sitter::{Parser, Query, QueryCursor, StreamingIterator, Node};

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
        "res" | "rescript" => parse_rescript_functions_ast(content),
        "rs" => parse_rust_functions(content),
        _ => Vec::new(),
    }
}

fn parse_rescript_functions_ast(content: &str) -> Vec<FunctionDetail> {
    let mut parser = Parser::new();
    let language: tree_sitter::Language = tree_sitter_rescript::LANGUAGE.into();
    if parser.set_language(&language).is_err() {
        return Vec::new();
    }
    let tree = if let Some(t) = parser.parse(content, None) {
        t
    } else {
        return Vec::new();
    };
    
    let query_str = "(let_binding) @binding";
    let query = if let Ok(q) = Query::new(&language, query_str) {
        q
    } else {
        return Vec::new();
    };
    
    let mut cursor = QueryCursor::new();
    let mut matches = cursor.matches(&query, tree.root_node(), content.as_bytes());
    
    let mut functions = Vec::new();
    while let Some(m) = matches.next() {
        let binding_node: Node = m.nodes_for_capture_index(0).next().unwrap();
        
        let mut name = "unknown".to_string();
        let mut cursor = binding_node.walk();
        for child in binding_node.children(&mut cursor) {
            if child.kind() == "value_identifier" {
                name = child.utf8_text(content.as_bytes()).unwrap().to_string();
                break;
            }
        }
        
        if name.chars().next().map(|c: char| c.is_uppercase()).unwrap_or(false) {
            continue;
        }
        if matches!(name.as_str(), "module" | "type" | "open" | "unknown") {
            continue;
        }

        let start_byte = binding_node.start_byte();
        let line = line_number_at(content, start_byte);
        let signature = extract_line(content, start_byte);
        
        functions.push(FunctionDetail {
            name,
            signature,
            line,
        });
    }
    
    functions.sort_by_key(|f| f.line);
    functions.dedup_by(|a, b| a.name == b.name && a.line == b.line);
    functions
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
