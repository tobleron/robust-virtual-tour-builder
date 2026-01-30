use super::{CommonMetrics, strip_code_modular};
use std::collections::HashMap;

#[derive(Debug, Clone)]
struct Scope {
    name: String,
    start_line: usize,
    depth: usize,
    complexity: f64,
    // density: f64, // Calculated at end
    // max_nesting: usize, // Calculated at end
    is_function: bool,
}

pub struct RescriptParser<'a> {
    content: &'a str,
    chars: Vec<char>,
    pos: usize,
    line: usize,
    metrics: CommonMetrics,
    scope_stack: Vec<Scope>,
    completed_scopes: Vec<Scope>,
    in_string: bool,
    string_char: char,
    pending_function_name: Option<String>,
}

impl<'a> RescriptParser<'a> {
    pub fn new(content: &'a str) -> Self {
        RescriptParser {
            content,
            chars: content.chars().collect(),
            pos: 0,
            line: 1,
            metrics: CommonMetrics {
                loc: 0,
                logic_count: 0,
                max_nesting: 0,
                complexity_penalty: 0.0,
                hotspot_lines: None,
                hotspot_reason: None,
                hotspot_symbol: None,
                external_calls: 0,
                internal_calls: 0,
                state_count: 0,
                dependencies: Vec::new(),
            },
            scope_stack: vec![Scope {
                name: "root".to_string(),
                start_line: 1,
                depth: 0,
                complexity: 0.0,
                is_function: false,
            }],
            completed_scopes: Vec::new(),
            in_string: false,
            string_char: '"',
            pending_function_name: None,
        }
    }

    pub fn analyze(mut self, dict: &HashMap<String, f64>) -> anyhow::Result<CommonMetrics> {
        // First pass: basic LOC
        self.metrics.loc = self.content.lines().filter(|l| !l.trim().is_empty() && !l.trim().starts_with("//")).count();
        self.metrics.complexity_penalty = super::apply_complexity_dictionary(self.content, dict);

        // Use the dedicated dependency extractor to avoid duplicating logic in the parser loop
        // (The parser loop focuses on Structure/Complexity/Scope, not imports which are top-level mostly)
        let stripped = strip_code_modular(self.content, false);
        self.extract_dependencies(&stripped);

        // Second pass: Semantic traversal
        while self.pos < self.chars.len() {
            let c = self.chars[self.pos];
            
            // Track line numbers
            if c == '\n' {
                self.line += 1;
            }

            // Handle Strings
            if self.in_string {
                if c == '\\' {
                    self.pos += 1; // Skip escaped
                } else if c == self.string_char {
                    self.in_string = false;
                }
                self.pos += 1;
                continue;
            }

            // Handle Comments
            if c == '/' {
                if self.peek(1) == '/' {
                    self.skip_line_comment();
                    continue;
                } else if self.peek(1) == '*' {
                    self.skip_block_comment();
                    continue;
                }
            }

            if c == '"' || c == '`' {
                self.in_string = true;
                self.string_char = c;
                self.pos += 1;
                continue;
            }

            // Logic & Nesting Analysis
            match c {
                '{' => self.push_scope(),
                '}' => self.pop_scope(),
                '=' => {
                    if self.peek(1) == '>' {
                        // Arrow function `=>`
                        self.metrics.logic_count += 1;
                        self.current_scope_mut().complexity += 1.0;

                        // If we see `=>`, the current "pending" name (if any) is definitely a function.
                        // If `=>` is followed by `{`, `push_scope` will use the name.
                        // If `=>` is followed by expression (implicit return), we are technically in a function scope too,
                        // but tracking single-expression scope complexity is less critical for "Surgical" refactoring.
                        // However, we should flag it.
                        // if let Some(name) = &self.pending_function_name {
                             // We found `let name = ... =>`
                             // We can try to attribute this complexity to `name`
                             // For now, we rely on the upcoming `{` or just logic accumulation.
                        // }
                    }
                },
                '-' => {
                    if self.peek(1) == '>' {
                        // Pipe `->`
                        self.metrics.logic_count += 1;
                        self.current_scope_mut().complexity += 0.5;
                    }
                },
                _ => {}
            }

            // Keyword detection (basic lookahead)
            if c.is_alphabetic() {
                let word = self.read_word();
                match word.as_str() {
                    "switch" => {
                        self.metrics.logic_count += 1;
                        self.current_scope_mut().complexity += 2.0;
                    },
                    "if" | "else" => {
                        self.metrics.logic_count += 1;
                        self.current_scope_mut().complexity += 1.0;
                    },
                    "for" | "while" => {
                        self.metrics.logic_count += 1;
                        self.current_scope_mut().complexity += 3.0;
                    },
                    "mutable" | "ref" | "useState" | "useReducer" => {
                        self.metrics.state_count += 1;
                        self.current_scope_mut().complexity += 5.0;
                    },
                    "let" => {
                        self.check_function_definition();
                    },
                    _ => {
                        // Clear pending function name if we encounter other words/tokens that break the `let x =` pattern
                        // (This is a simplified heuristic)
                        // self.pending_function_name = None;
                    }
                }
            } else {
                // Allow dot, brackets, angle brackets (generics/JSX) to avoid resetting pending name
                if !c.is_whitespace() && c != '=' && c != '(' && c != ')' && c != ':' && c != '.' && c != '[' && c != ']' && c != '<' && c != '>' {
                    // Reset pending name on unexpected chars (like `;` or `,`)
                    self.pending_function_name = None;
                }
                self.pos += 1;
            }
        }

        // Finalize
        // Pop any remaining scopes (should just be root)
        while let Some(scope) = self.scope_stack.pop() {
            self.completed_scopes.push(scope);
        }

        self.metrics.max_nesting = self.completed_scopes.iter().map(|s| s.depth).max().unwrap_or(0);

        // Find Hotspot (Function with highest complexity)
        let mut max_score = 0.0;

        // Add root complexity to the list for comparison? No, we want specific functions.

        for scope in &self.completed_scopes {
            if scope.is_function {
                // Heuristic: Scope complexity is high
                if scope.complexity > max_score {
                    max_score = scope.complexity;
                    self.metrics.hotspot_symbol = Some(format!("Function: `{}`", scope.name));
                    self.metrics.hotspot_lines = Some((scope.start_line, self.metrics.loc.min(scope.start_line + 20)));
                    self.metrics.hotspot_reason = Some(format!("High Local Complexity ({:.1}). Logic heavy.", scope.complexity));
                }
            }
        }

        // Fallback: If no functions detected (maybe it's a script), check if root is complex
        if self.metrics.hotspot_symbol.is_none() && self.metrics.complexity_penalty > 50.0 {
             self.metrics.hotspot_reason = Some("Global Scope Complexity".to_string());
        }

        Ok(self.metrics)
    }

    fn push_scope(&mut self) {
        let current_depth = self.scope_stack.len();
        self.metrics.max_nesting = self.metrics.max_nesting.max(current_depth);

        let mut is_func = false;
        let name = if let Some(n) = self.pending_function_name.take() {
            is_func = true;
            n
        } else {
            "block".to_string()
        };

        self.scope_stack.push(Scope {
            name,
            start_line: self.line,
            depth: current_depth,
            complexity: 0.0,
            is_function: is_func,
        });
        self.pos += 1;
    }

    fn pop_scope(&mut self) {
        if self.scope_stack.len() > 1 {
            if let Some(scope) = self.scope_stack.pop() {
                // Propagate complexity to parent (bubbling up)
                if let Some(parent) = self.scope_stack.last_mut() {
                    parent.complexity += scope.complexity * 0.5; // Child complexity contributes partial weight to parent
                }
                self.completed_scopes.push(scope);
            }
        }
        self.pos += 1;
    }
    
    fn current_scope_mut(&mut self) -> &mut Scope {
        self.scope_stack.last_mut().expect("Scope stack should never be empty (guarded root)")
    }

    fn peek(&self, offset: usize) -> char {
        if self.pos + offset < self.chars.len() {
            self.chars[self.pos + offset]
        } else {
            '\0'
        }
    }

    fn skip_line_comment(&mut self) {
        while self.pos < self.chars.len() && self.chars[self.pos] != '\n' {
            self.pos += 1;
        }
    }

    fn skip_block_comment(&mut self) {
        self.pos += 2; // skip /*
        while self.pos < self.chars.len() {
            if self.chars[self.pos] == '*' && self.peek(1) == '/' {
                self.pos += 2;
                return;
            }
            if self.chars[self.pos] == '\n' {
                self.line += 1;
            }
            self.pos += 1;
        }
    }

    fn read_word(&mut self) -> String {
        let start = self.pos;
        while self.pos < self.chars.len() && (self.chars[self.pos].is_alphanumeric() || self.chars[self.pos] == '_') {
            self.pos += 1;
        }
        self.chars[start..self.pos].iter().collect()
    }

    fn check_function_definition(&mut self) {
        // pattern: let name =
        self.skip_whitespace();
        let name = self.read_word();
        if !name.is_empty() {
             self.skip_whitespace();
             // We check for type annotations too: `let name: type =`
             if self.peek(0) == ':' {
                 self.pos += 1;
                 while self.pos < self.chars.len() && self.chars[self.pos] != '=' && self.chars[self.pos] != '{' {
                      self.pos += 1;
                 }
             }

             if self.peek(0) == '=' {
                 self.pending_function_name = Some(name);
                 self.pos += 1; // consume '='
             }
        }
    }

    fn skip_whitespace(&mut self) {
        while self.pos < self.chars.len() && self.chars[self.pos].is_whitespace() {
            if self.chars[self.pos] == '\n' { self.line += 1; }
            self.pos += 1;
        }
    }

    fn extract_dependencies(&mut self, content: &str) {
        for line in content.lines() {
            let trim = line.trim();
            if trim.starts_with("open ") || trim.starts_with("include ") {
                if let Some(dep) = trim.split_whitespace().nth(1) {
                    self.metrics.dependencies.push(dep.replace(";", "").to_string());
                    self.metrics.external_calls += 1;
                }
            } else if trim.starts_with("module ") && trim.contains("=") {
                 if let Some(parts) = trim.split('=').nth(1) {
                     let dep = parts.trim().replace(";", "");
                     self.metrics.dependencies.push(dep);
                     self.metrics.external_calls += 1;
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
                             if !self.metrics.dependencies.contains(&potential_module.to_string()) {
                                self.metrics.dependencies.push(potential_module.to_string());
                                self.metrics.external_calls += 1;
                             }
                         }
                     }
                 }
            }
        }

        // JSX
        let jsx_regex = regex::Regex::new(r"<([A-Z][a-zA-Z0-9\._]*)").unwrap();
        for captures in jsx_regex.captures_iter(content) {
            if let Some(match_obj) = captures.get(1) {
                let full_tag = match_obj.as_str();
                let component_name = full_tag.split('.').next().unwrap_or("");
                if !component_name.is_empty()
                   && component_name != "React" && component_name != "JSON"
                   && component_name != "Blob" && component_name != "File"
                   && component_name != "Dom" && component_name != "Nullable" {
                    if !self.metrics.dependencies.contains(&component_name.to_string()) {
                        self.metrics.dependencies.push(component_name.to_string());
                        self.metrics.external_calls += 1;
                    }
                }
            }
        }
    }
}

pub fn analyze_rescript(content: &str, dict: &HashMap<String, f64>) -> anyhow::Result<CommonMetrics> {
    let parser = RescriptParser::new(content);
    parser.analyze(dict)
}
