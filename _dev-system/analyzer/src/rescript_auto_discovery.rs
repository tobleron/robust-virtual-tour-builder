use std::collections::HashMap;
use std::path::Path;

/// Enhanced ReScript Auto-Discovery Module
/// Handles ReScript's implicit module resolution patterns that don't require explicit imports

pub struct ReScriptAutoDiscovery {
    // Map of directory -> modules in that directory
    directory_modules: HashMap<String, Vec<String>>,
    // Map of module name -> full file path
    module_registry: HashMap<String, String>,
}

impl ReScriptAutoDiscovery {
    pub fn new() -> Self {
        Self {
            directory_modules: HashMap::new(),
            module_registry: HashMap::new(),
        }
    }

    /// Build registry from all ReScript files in the project
    pub fn build_registry(&mut self, files: &[String]) -> Result<(), Box<dyn std::error::Error>> {
        for file_path in files {
            if file_path.ends_with(".res") {
                let path = Path::new(file_path);

                // Extract module name from filename
                if let Some(stem) = path.file_stem() {
                    let module_name = stem.to_string_lossy().to_string();

                    // Extract directory name
                    if let Some(parent) = path.parent() {
                        let dir_name = parent.to_string_lossy().to_string();

                        // Debug: Print registration
                        println!("📝 Registering: {} in directory {}", module_name, dir_name);

                        // Register module in directory
                        self.directory_modules
                            .entry(dir_name.clone())
                            .or_insert_with(Vec::new)
                            .push(module_name.clone());

                        // Register module path
                        self.module_registry.insert(module_name, file_path.clone());
                    }
                }
            }
        }
        Ok(())
    }

    /// Resolve JSX component usage to actual file dependencies
    /// In ReScript, <Component /> automatically discovers Component.res in same directory
    pub fn resolve_jsx_dependency(&self, using_file: &str, jsx_component: &str) -> Option<String> {
        let using_path = Path::new(using_file);

        // Get directory of the using file
        if let Some(parent_dir) = using_path.parent() {
            let dir_name = parent_dir.to_string_lossy().to_string();

            // Debug: Show directory lookup
            println!(
                "🔍 Looking for {} in directory: {}",
                jsx_component, dir_name
            );
            println!(
                "🗂️ All directories in registry: {:?}",
                self.directory_modules.keys().collect::<Vec<_>>()
            );

            // Look for component in same directory
            if let Some(modules_in_dir) = self.directory_modules.get(&dir_name) {
                println!("📁 Found modules in {}: {:?}", dir_name, modules_in_dir);
                for module in modules_in_dir {
                    if module == jsx_component {
                        let resolved = self.module_registry.get(module).cloned();
                        println!("✅ Found match: {} -> {:?}", module, resolved);
                        return resolved;
                    }
                }
                println!("❌ No match found for {}", jsx_component);
            } else {
                println!("❌ No modules found in directory: {}", dir_name);
            }
        } else {
            println!("❌ No parent directory found for: {}", using_file);
        }
        None
    }

    /// Check if a file uses any JSX components from same directory
    pub fn find_same_directory_jsx_deps(&self, content: &str, file_path: &str) -> Vec<String> {
        let mut deps = Vec::new();

        // Find JSX usage patterns: <ComponentName
        let jsx_regex = regex::Regex::new(r"<([A-Z][a-zA-Z0-9]*)\b").unwrap();

        // Debug: Check if content has JSX patterns
        if content.contains("<SceneList") || content.contains("<VisualPipeline") {
            println!("🚨 Found JSX patterns in: {}", file_path);
        }

        for captures in jsx_regex.captures_iter(content) {
            if let Some(component_match) = captures.get(1) {
                let component_name = component_match.as_str();

                // Debug: Print found component
                println!(
                    "🎯 Found JSX component: {} in {}",
                    component_name, file_path
                );

                // Resolve to actual file
                if let Some(file_dep) = self.resolve_jsx_dependency(file_path, component_name) {
                    println!("✅ Resolved to: {}", file_dep);
                    deps.push(file_dep);
                } else {
                    println!("❌ Failed to resolve: {}", component_name);
                }
            }
        }

        deps
    }

    /// Enhanced dependency resolution for ReScript-specific patterns
    pub fn resolve_rescript_dependency(&self, dep: &str, using_file: &str) -> Option<String> {
        // Strategy 1: Direct module name lookup
        if let Some(path) = self.module_registry.get(dep) {
            return Some(path.clone());
        }

        // Strategy 2: JSX component auto-discovery (same directory)
        if let Some(path) = self.resolve_jsx_dependency(using_file, dep) {
            return Some(path);
        }

        // Strategy 3: ReScript module alias resolution
        if dep.contains('.') {
            let parts: Vec<&str> = dep.split('.').collect();
            if let Some(base_module) = parts.first() {
                if let Some(path) = self.module_registry.get(*base_module) {
                    return Some(path.clone());
                }
            }
        }

        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_jsx_auto_discovery() {
        let mut discovery = ReScriptAutoDiscovery::new();
        let files = vec![
            "src/components/Sidebar.res".to_string(),
            "src/components/SceneList.res".to_string(),
            "src/components/VisualPipeline.res".to_string(),
        ];

        discovery.build_registry(&files).unwrap();

        // Test JSX resolution
        let sidebar_content = r#"
        <SceneList />
        <SomeOtherComponent />
        "#;

        let deps =
            discovery.find_same_directory_jsx_deps(sidebar_content, "src/components/Sidebar.res");

        assert!(deps.contains(&"src/components/SceneList.res".to_string()));
    }

    #[test]
    fn test_module_registry() {
        let mut discovery = ReScriptAutoDiscovery::new();
        let files = vec!["src/components/SceneList.res".to_string()];

        discovery.build_registry(&files).unwrap();

        assert_eq!(
            discovery.resolve_rescript_dependency("SceneList", "src/components/Sidebar.res"),
            Some("src/components/SceneList.res".to_string())
        );
    }
}
