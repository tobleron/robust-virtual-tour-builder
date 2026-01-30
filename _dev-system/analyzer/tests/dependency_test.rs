use std::collections::HashMap;
use efficiency_analyzer::resolver::Resolver;

#[test]
fn test_rescript_dotted_module_resolution() {
    let mut registry = HashMap::new();
    registry.insert("ComplexSystem".to_string(), vec!["src/systems/ComplexSystem.res".to_string()]);

    let resolver = Resolver::new(registry);

    // Test Case: `ComplexSystem.SubModule` usage should map to `ComplexSystem.res`
    let results = resolver.resolve("ComplexSystem.SubModule");
    assert!(results.contains(&"src/systems/ComplexSystem.res".to_string()), "Failed to resolve ComplexSystem.SubModule");
}

#[test]
fn test_rust_inline_module_resolution() {
    let mut registry = HashMap::new();
    registry.insert("feature".to_string(), vec!["backend/src/api/feature.rs".to_string()]);

    let resolver = Resolver::new(registry);

    // Test Case: `feature::Logic::process` usage should map to `feature.rs`
    let results = resolver.resolve("feature::Logic");
    assert!(results.contains(&"backend/src/api/feature.rs".to_string()), "Failed to resolve feature::Logic");
}

#[test]
fn test_standard_resolution() {
    let mut registry = HashMap::new();
    registry.insert("User".to_string(), vec!["src/core/User.res".to_string()]);

    let resolver = Resolver::new(registry);

    let results = resolver.resolve("User");
    assert!(results.contains(&"src/core/User.res".to_string()));
}
