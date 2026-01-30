
#[test]
fn test_rescript_include_stripping() {
    let content = r#"
        /* Comment block */
        include ApiLogic
        // Another comment
        open OtherModule
    "#;
    let stripped = efficiency_analyzer::drivers::strip_code(content);
    // Ensure newlines are preserved or at least spaces exist so tokens don't merge
    println!("Stripped: '{}'", stripped);

    // Minimal mock of the parsing logic in rescript.rs
    let mut includes = Vec::new();
    for line in stripped.lines() {
        let trim = line.trim();
        if trim.starts_with("include ") {
             if let Some(dep) = trim.split_whitespace().nth(1) {
                 includes.push(dep.replace(";", "").to_string());
             }
        }
    }

    assert!(includes.contains(&"ApiLogic".to_string()), "Failed to parse include from stripped code");
}
