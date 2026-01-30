
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

    // Minimal mock of the parsing logic in rescript.rs (this is testing strip_code mainly)
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

#[test]
fn test_rescript_dot_dependency_extraction() {
    // This integration test requires the actual parser logic.
    // However, the test file is outside the crate structure usually unless configured.
    // But since `efficiency_analyzer` is a lib, we can use it.

    let content = r#"
        let x = Logger.info("test")
        let y = Constants.MAX_WIDTH
    "#;

    let dict = std::collections::HashMap::new();
    let metrics = efficiency_analyzer::drivers::rescript::analyze_rescript(content, &dict).unwrap();

    assert!(metrics.dependencies.contains(&"Logger".to_string()), "Failed to extract Logger dependency");
    assert!(metrics.dependencies.contains(&"Constants".to_string()), "Failed to extract Constants dependency");
}
