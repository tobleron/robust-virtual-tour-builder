pub mod rust;
pub mod rescript;
pub mod html;
pub mod css;
pub mod config;

#[derive(Default)]
pub struct CommonMetrics {
    pub loc: usize,
    pub logic_count: usize,
    pub max_nesting: usize,
    pub complexity_penalty: f64,
    pub hotspot_lines: Option<(usize, usize)>,
    pub hotspot_reason: Option<String>,
    pub external_calls: usize, // Imports/Opens
    pub internal_calls: usize, // Local function calls
}

pub enum EfficiencyOverride {
    None,
    Singleton,
    Ignore,
    Strict,
}

pub fn parse_header(content: &str) -> EfficiencyOverride {
    if content.contains("@efficiency: singleton") { return EfficiencyOverride::Singleton; }
    if content.contains("@efficiency: ignore") { return EfficiencyOverride::Ignore; }
    if content.contains("@efficiency: strict") { return EfficiencyOverride::Strict; }
    EfficiencyOverride::None
}

pub fn strip_code(content: &str) -> String {
    let mut result = String::with_capacity(content.len());
    let chars: Vec<char> = content.chars().collect();
    let mut i = 0;
    
    let mut in_line_comment = false;
    let mut in_block_comment = false;
    let mut in_string = false;
    let mut string_char = ' ';

    while i < chars.len() {
        let c = chars[i];
        let next = chars.get(i + 1).cloned();

        if in_line_comment {
            if c == '\n' { in_line_comment = false; result.push(c); }
        } else if in_block_comment {
            if c == '*' && next == Some('/') { in_block_comment = false; i += 1; }
        } else if in_string {
            if c == '\\' && i + 1 < chars.len() { i += 1; } // Skip escaped char
            else if c == string_char { in_string = false; }
        } else {
            if c == '/' && next == Some('/') { in_line_comment = true; i += 1; }
            else if c == '/' && next == Some('*') { in_block_comment = true; i += 1; }
            else if c == '"' || c == '\'' || c == '`' { in_string = true; string_char = c; }
            else { result.push(c); }
        }
        i += 1;
    }
    result
}
