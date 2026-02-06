use anyhow::Result;
use regex::Regex;
use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

#[derive(Debug, serde::Deserialize, Clone)]
pub struct ExclusionRules {
    pub folders: Vec<String>,
    pub files: Vec<String>,
    pub extensions: Vec<String>,
}

pub fn is_project_source(path: &Path, rules: &ExclusionRules) -> bool {
    let p_str = path.to_string_lossy().replace("\\", "/");
    let file_name = path.file_name().unwrap_or_default().to_string_lossy();
    let ext = path.extension().and_then(|s| s.to_str()).unwrap_or("");
    let valid_extensions = ["rs", "res", "css", "html", "js", "jsx"];
    if !valid_extensions.contains(&ext) {
        return false;
    }
    for folder in &rules.folders {
        if p_str.contains(folder) {
            return false;
        }
    }
    for file in &rules.files {
        if file_name == *file {
            return false;
        }
    }
    for suffix in &rules.extensions {
        if file_name.ends_with(suffix) {
            return false;
        }
    }
    true
}

pub struct GuardConfig {
    pub tasks_dir: String,
    pub map_file: String,
    pub data_flow_file: String,
}

impl Default for GuardConfig {
    fn default() -> Self {
        Self {
            tasks_dir: "../../tasks".to_string(),
            map_file: "../../MAP.md".to_string(),
            data_flow_file: "../../DATA_FLOW.md".to_string(),
        }
    }
}

pub fn get_next_id(config: &GuardConfig) -> usize {
    let mut max_id = 0;
    let scan_dirs = vec![
        format!("{}/pending", config.tasks_dir),
        format!("{}/active", config.tasks_dir),
        format!("{}/completed", config.tasks_dir),
        format!("{}/postponed", config.tasks_dir),
    ];

    for dir in scan_dirs {
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.filter_map(|e| e.ok()) {
                let name = entry.file_name().to_string_lossy().into_owned();
                if let Some(id_str) = name.split('_').next() {
                    if let Ok(id) = id_str.parse::<usize>() {
                        if id > max_id {
                            max_id = id;
                        }
                    }
                }
            }
        }
    }
    max_id + 1
}

pub fn get_next_dev_id(config: &GuardConfig) -> usize {
    let mut max_id = 0;
    let dev_tasks_dir = format!("{}/pending/dev_tasks", config.tasks_dir);

    if let Ok(entries) = fs::read_dir(&dev_tasks_dir) {
        for entry in entries.filter_map(|e| e.ok()) {
            let name = entry.file_name().to_string_lossy().into_owned();
            // Extract ID from D001_task_name format
            if name.starts_with('D') {
                if let Some(id_str) = name[1..].split('_').next() {
                    if let Ok(id) = id_str.parse::<usize>() {
                        if id > max_id {
                            max_id = id;
                        }
                    }
                }
            }
        }
    }
    max_id + 1
}

pub fn task_exists(config: &GuardConfig, pattern: &str) -> bool {
    let scan_dirs = vec![
        format!("{}/pending", config.tasks_dir),
        format!("{}/active", config.tasks_dir),
        format!("{}/postponed", config.tasks_dir),
    ];

    for dir in scan_dirs {
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.filter_map(|e| e.ok()) {
                let name = entry.file_name().to_string_lossy().into_owned();
                if name.contains(pattern) {
                    return true;
                }
            }
        }
    }
    false
}

pub fn create_task(config: &GuardConfig, filename: &str, content: &str) -> Result<bool> {
    let file_path = if filename.contains("/") {
        PathBuf::from(&config.tasks_dir)
            .join("pending")
            .join(filename)
    } else {
        PathBuf::from(&config.tasks_dir)
            .join("pending")
            .join(filename)
    };

    if let Some(parent) = file_path.parent() {
        if !parent.exists() {
            fs::create_dir_all(parent)?;
        }
    }

    if !file_path.exists() {
        fs::write(&file_path, content)?;
        println!("📝 Created Task: {}", file_path.display());
        Ok(true)
    } else {
        Ok(false)
    }
}

#[allow(dead_code)]
pub fn append_to_unified_task(
    config: &GuardConfig,
    task_name: &str,
    description: &str,
) -> Result<bool> {
    let tests_dir = PathBuf::from(&config.tasks_dir).join("pending/tests");
    if !tests_dir.exists() {
        fs::create_dir_all(&tests_dir)?;
    }

    let mut unified_path = None;
    if let Ok(entries) = fs::read_dir(&tests_dir) {
        for entry in entries.filter_map(|e| e.ok()) {
            let name = entry.file_name().to_string_lossy().into_owned();
            if name.contains("Test_Generation_Unified.md") {
                unified_path = Some(entry.path());
                break;
            }
        }
    }

    let (mut content, path) = if let Some(path) = unified_path {
        (fs::read_to_string(&path)?, path)
    } else {
        let next_id = get_next_id(config);
        let path = tests_dir.join(format!("{:03}_Test_Generation_Unified.md", next_id));
        (format!("# Task {}: Test Generation Unified\n\n## Objective\nConsolidated tracking of all pending unit test tasks (New & Update) to reduce file fragmentation.\n\n## Tasks\n", next_id), path)
    };

    // Check for exact task name match to prevent duplication
    let pattern = format!(r"- \[ \] {}\s", regex::escape(task_name));
    let re = Regex::new(&pattern).unwrap();
    if re.is_match(&content) {
        return Ok(true);
    }

    if !content.ends_with('\n') {
        content.push('\n');
    }
    content.push_str(&format!("- [ ] {} ({})\n", task_name, description));
    fs::write(&path, content)?;
    println!(
        "➕ Appended to Unified Task: {} in {}",
        task_name,
        path.display()
    );
    Ok(true)
}

pub fn get_mapped_files(config: &GuardConfig) -> HashSet<String> {
    let mut mapped_paths = HashSet::new();
    if let Ok(map_content) = fs::read_to_string(&config.map_file) {
        let regex = Regex::new(r" \[.*?\]\((.*?)\)").unwrap();
        for cap in regex.captures_iter(&map_content) {
            let mut p = cap[1].to_string();
            if p.starts_with("file://") {
                if let Some(idx) = p.find("/robust-virtual-tour-builder/") {
                    p = p[idx + "/robust-virtual-tour-builder/".len()..].to_string();
                }
            }
            let clean_p = format!("../../{}", p.replace("\\", "/"));
            mapped_paths.insert(clean_p);
        }

        // Fallback for [src/Main.res] style
        let text_regex = Regex::new(r"\[(.*?)\]\(").unwrap();
        for cap in text_regex.captures_iter(&map_content) {
            let p = cap[1].to_string();
            if p.contains('.') && (p.starts_with("src/") || p.starts_with("backend/src/")) {
                let clean_p = format!("../../{}", p.replace("\\", "/"));
                mapped_paths.insert(clean_p);
            }
        }
    }
    mapped_paths
}

pub fn check_map(config: &GuardConfig, rules: &ExclusionRules) -> Result<()> {
    if !Path::new(&config.map_file).exists() {
        return Ok(());
    }

    let map_content = fs::read_to_string(&config.map_file)?;
    let regex = Regex::new(r" \[.*?\]\((.*?)\)").unwrap();
    let mut mapped_paths = std::collections::HashSet::new();

    for cap in regex.captures_iter(&map_content) {
        let mut p = cap[1].to_string();
        if p.starts_with("file://") {
            if let Some(idx) = p.find("/robust-virtual-tour-builder/") {
                p = p[idx + "/robust-virtual-tour-builder/".len()..].to_string();
            }
        }
        mapped_paths.insert(p.replace("\\", "/"));
    }

    // Fallback for [src/Main.res] style
    let text_regex = Regex::new(r"\[(.*?)\]\(").unwrap();
    for cap in text_regex.captures_iter(&map_content) {
        let p = cap[1].to_string();
        if p.contains('.') && (p.starts_with("src/") || p.starts_with("backend/src/")) {
            mapped_paths.insert(p.replace("\\", "/"));
        }
    }

    let mut unmapped_files = Vec::new();
    let src_dirs = vec!["../../src", "../../backend/src"];

    for dir in src_dirs {
        for entry in WalkDir::new(dir).into_iter().filter_map(|e| e.ok()) {
            let path = entry.path();
            if path.is_file() {
                let p_str = path.to_string_lossy().to_string().replace("\\", "/");
                // Remove "../../" prefix
                let clean_p = if p_str.starts_with("../../") {
                    &p_str[6..]
                } else {
                    &p_str
                };

                if is_project_source(path, rules) && !mapped_paths.contains(clean_p) {
                    if path.exists() {
                         // Check for ignore tag in content
                         let is_ignored = if let Ok(content) = fs::read_to_string(path) {
                             content.contains("@efficiency-role: ignored") || content.contains("@efficiency-role ignored")
                         } else {
                             false
                         };

                         if !is_ignored {
                             unmapped_files.push(clean_p.to_string());
                         }
                    }
                }
            }
        }
    }

    let mut lines: Vec<String> = map_content.lines().map(|s| s.to_string()).collect();
    let mut changed = false;

    // --- MAP.md Zombie Elimination (Global) ---
    // If ANY entry in MAP.md points to a non-existent file, remove it.
    let mut new_lines = Vec::new();
    let link_regex = Regex::new(r"\[.*?\]\((.*?)\)").unwrap();

    for line in lines.into_iter() {
        let mut is_zombie = false;
        
        // Only check lines that look like structural map entries (bullet points with links)
        if line.trim_start().starts_with("* [") || line.trim_start().starts_with("- [") {
            // Find the FIRST link in the line (usually the file path)
            if let Some(cap) = link_regex.captures(&line) {
                let raw_path = cap[1].to_string();
                // Handle anchors (e.g., src/Main.res#anchor)
                let p_no_anchor = raw_path.split('#').next().unwrap_or(&raw_path);
                
                let mut p = p_no_anchor.to_string();

                // Clean path (remove file:// prefix if present)
                if p.starts_with("file://") {
                    if let Some(idx) = p.find("/robust-virtual-tour-builder/") {
                        p = p[idx + "/robust-virtual-tour-builder/".len()..].to_string();
                    }
                }
                
                // Ignore external links or empty paths
                if !p.starts_with("http") && !p.is_empty() {
                     let full_path = Path::new("../../").join(&p);
                     // If file does not exist, mark for deletion
                     if !full_path.exists() {
                         println!("🧹 Removing zombie entry: {}", p);
                         is_zombie = true;
                         changed = true;
                     }
                }
            }
        }
        
        if !is_zombie {
            new_lines.push(line);
        }
    }
    lines = new_lines;

    if !unmapped_files.is_empty() {
        println!("🗺️ Found {} unmapped files.", unmapped_files.len());

        // Find or create header
        let header_idx = lines
            .iter()
            .position(|l| l.contains("## 🆕 Unmapped Modules"));
        let idx = if let Some(i) = header_idx {
            i + 1
        } else {
            lines.push("".to_string());
            lines.push("## 🆕 Unmapped Modules".to_string());
            changed = true;
            lines.len()
        };

        for f in unmapped_files {
            let entry = format!(
                "* [{}]({}): New module detected. Please classify. #new",
                f, f
            );
            if !lines.iter().any(|l| l.contains(&format!("[{}]", f))) {
                lines.insert(idx, entry);
                changed = true;
            }
        }
    }

    // --- MAP.md Writing ---
    if changed {
        let mut final_content = lines.join("\n");
        if !final_content.ends_with('\n') {
            final_content.push('\n');
        }
        fs::write(&config.map_file, final_content)?;
        println!("🗺️ Updated MAP.md.");
    }

    // --- Task Synchronizer (Classify_Map_Entries) ---
    let unmapped_header = "## 🆕 Unmapped Modules";
    let mut unmapped_items = Vec::new();
    let mut header_pos = None;

    for (i, line) in lines.iter().enumerate() {
        if line.contains(unmapped_header) {
            header_pos = Some(i);
            continue;
        }
        if header_pos.is_some() && i > header_pos.unwrap() {
            if line.starts_with("## ") {
                break;
            }
            if line.starts_with("* [") {
                // Extract the entry text
                unmapped_items.push(line.trim_start_matches("* ").to_string());
            }
        }
    }

    let has_unmapped_items = !unmapped_items.is_empty();
    let task_pattern = "Classify_Map_Entries";

    if has_unmapped_items {
        let mut existing_task_path = None;
        let dev_tasks_dir = format!("{}/pending/dev_tasks", config.tasks_dir);

        // Ensure dev_tasks directory exists
        if !Path::new(&dev_tasks_dir).exists() {
            let _ = fs::create_dir_all(&dev_tasks_dir);
        }

        if let Ok(entries) = fs::read_dir(&dev_tasks_dir) {
            for entry in entries.filter_map(|e| e.ok()) {
                if entry.file_name().to_string_lossy().contains(task_pattern) {
                    existing_task_path = Some(entry.path());
                    break;
                }
            }
        }

        let (id, path) = if let Some(p) = existing_task_path {
            let id = p.file_name().unwrap().to_string_lossy().split('_').next().unwrap_or("D0").to_string();
            (id, p)
        } else {
            let next_id = get_next_dev_id(config);
            let id_str = format!("D{:03}", next_id);
            (id_str.clone(), PathBuf::from(&dev_tasks_dir).join(format!("{}_{}.md", id_str, task_pattern)))
        };

        let mut task_content = format!(
            "# Task {}: Classify New Map Entries\n\n## 🚨 Trigger\nNew modules were detected and added to the 'Unmapped Modules' section of `MAP.md`.\n\n## Objective\nMove the entries from 'Unmapped Modules' to their appropriate semantic sections in `MAP.md`.\n\n## Tasks\n",
            id
        );
        for item in unmapped_items {
            task_content.push_str(&format!("- [ ] {}\n", item));
        }

        fs::write(&path, task_content)?;
    } else {
        // Check if unmapped section is now empty and remove the task if it was resolved
        let dev_tasks_dir = format!("{}/pending/dev_tasks", config.tasks_dir);
        if let Ok(entries) = fs::read_dir(dev_tasks_dir) {
            for entry in entries.filter_map(|e| e.ok()) {
                let name = entry.file_name().to_string_lossy().into_owned();
                if name.contains(task_pattern) {
                    println!("🧹 Deleting resolved task: {:?}", entry.path());
                    let _ = fs::remove_file(entry.path());
                }
            }
        }
    }

    Ok(())
}

pub fn check_data_flow(config: &GuardConfig, rules: &ExclusionRules) -> Result<()> {
    if !Path::new(&config.data_flow_file).exists() {
        println!("⚠️  DATA_FLOW.md not found. Skipping data flow check.");
        return Ok(());
    }

    let flow_content = fs::read_to_string(&config.data_flow_file)?;
    let regex = Regex::new(r"\[([^\]]+\.(?:res|rs|js|jsx|ts|tsx))\]").unwrap();
    
    // --- Split and Reconcile ---
    let header_marker = "## 🆕 Unmapped Modules";
    let (top_content, _) = match flow_content.find(header_marker) {
        Some(idx) => (&flow_content[..idx], &flow_content[idx..]),
        None => (flow_content.as_str(), ""),
    };

    // Extract REAL references ONLY from the flows (top section)
    let mut real_references = std::collections::HashSet::new();
    for cap in regex.captures_iter(top_content) {
        real_references.insert(cap[1].to_string().replace("\\", "/"));
    }

    // --- Physical Scan for Truly Unmapped ---
    let src_dirs = vec!["../../src", "../../backend/src"];
    let mut truly_missing = Vec::new();

    for dir in src_dirs {
        for entry in WalkDir::new(dir).into_iter().filter_map(|e| e.ok()) {
            let path = entry.path();
            if path.is_file() {
                let p_str = path.to_string_lossy().to_string().replace("\\", "/");
                let clean_p = if p_str.starts_with("../../") { &p_str[6..] } else { &p_str };

                if is_project_source(path, rules) && !real_references.contains(clean_p) {
                    let is_ignored = if let Ok(content) = fs::read_to_string(path) {
                        content.contains("@efficiency-role: ignored") || content.contains("@efficiency-role ignored")
                    } else {
                        false
                    };

                    if !is_ignored {
                        truly_missing.push(clean_p.to_string());
                    }
                }
            }
        }
    }

    truly_missing.sort();

    // --- Group by Directory for Token Efficiency ---
    let mut grouped: std::collections::BTreeMap<String, Vec<String>> = std::collections::BTreeMap::new();
    for path in truly_missing {
        let parent = Path::new(&path)
            .parent()
            .map(|p| p.to_string_lossy().to_string())
            .unwrap_or_else(|| "root".to_string());
        grouped.entry(parent).or_default().push(path);
    }

    // --- Reconstruct lines ---
    let mut final_lines: Vec<String> = top_content.lines().map(|s| s.to_string()).collect();
    
    // Ensure spacing
    if !final_lines.is_empty() && !final_lines.last().unwrap().is_empty() {
        final_lines.push("".to_string());
    }

    final_lines.push(header_marker.to_string());
    final_lines.push("(This section auto-populated by _dev-system analyzer)".to_string());

    if !grouped.is_empty() {
        println!("🌊 Reconciling: {} modules remain unmapped across {} directories.", 
            grouped.values().map(|v| v.len()).sum::<usize>(),
            grouped.len()
        );
        
        for (dir, files) in grouped {
            final_lines.push("".to_string());
            final_lines.push(format!("### 📂 {}", dir));
            for f in files {
                final_lines.push(format!("- `[{}]`", f));
            }
        }
    } else {
        println!("🌊 Success: All project modules are represented in data flows!");
    }

    final_lines.push("".to_string());
    final_lines.push("---".to_string());
    final_lines.push("(Utilities and Infrastructure modules are excluded from flow documentation by design)".to_string());

    let mut changed = false;
    let new_content = final_lines.join("\n");
    if new_content.trim() != flow_content.trim() {
        changed = true;
    }

    // --- Write if changed ---
    if changed {
        let mut final_content = final_lines.join("\n");
        if !final_content.ends_with('\n') {
            final_content.push('\n');
        }
        fs::write(&config.data_flow_file, final_content)?;
        println!("🌊 Updated DATA_FLOW.md");
    }

    let lines = final_lines;

    // --- Task Generation ---
    let unmapped_header = "## 🆕 Unmapped Modules";
    let mut unmapped_items = Vec::new();
    let mut in_unmapped_section = false;

    for line in &lines {
        if line.contains(unmapped_header) {
            in_unmapped_section = true;
            continue;
        }
        if in_unmapped_section {
            if line.starts_with("## ") && !line.contains(unmapped_header) {
                break;
            }
            // Use same regex to find all bracketed files in this section
            for cap in regex.captures_iter(line) {
                unmapped_items.push(format!("[{}]", &cap[1]));
            }
        }
    }

    let has_unmapped = !unmapped_items.is_empty();
    let task_pattern = "Integrate_DataFlow_Modules";

    if has_unmapped {
        let mut existing_task_path = None;
        let dev_tasks_dir = format!("{}/pending/dev_tasks", config.tasks_dir);

        // Ensure dev_tasks directory exists
        if !Path::new(&dev_tasks_dir).exists() {
            let _ = fs::create_dir_all(&dev_tasks_dir);
        }

        if let Ok(entries) = fs::read_dir(&dev_tasks_dir) {
            for entry in entries.filter_map(|e| e.ok()) {
                if entry.file_name().to_string_lossy().contains(task_pattern) {
                    existing_task_path = Some(entry.path());
                    break;
                }
            }
        }

        let (id, path) = if let Some(p) = existing_task_path {
            let id = p.file_name().unwrap().to_string_lossy()
                .split('_').next().unwrap_or("D0").to_string();
            (id, p)
        } else {
            let next_id = get_next_dev_id(config);
            let id_str = format!("D{:03}", next_id);
            (id_str.clone(), PathBuf::from(&dev_tasks_dir)
                .join(format!("{}_{}.md", id_str, task_pattern)))
        };

        let mut task_content = format!(
            "# Task {}: Integrate Modules into Data Flows\n\n\
            ## 🚨 Trigger\n\
            New modules were detected that are not represented in `DATA_FLOW.md`.\n\n\
            ## Objective\n\
            Review the unmapped modules in the 'Unmapped Modules' section of `DATA_FLOW.md` and either:\n\n\
            1. Add them to existing data flows if they're part of a documented flow\n\
            2. Create new flow documentation if they represent a new critical path\n\
            3. Leave them unmapped if they're utilities/helpers that don't fit flow documentation\n\n\
            ## Unmapped Modules\n",
            id
        );

        for item in unmapped_items {
            task_content.push_str(&format!("- [ ] {}\n", item));
        }

        fs::write(&path, task_content)?;
        println!("📝 Created/Updated Task: {}", path.display());
    } else {
        // Remove task if no unmapped modules
        let dev_tasks_dir = format!("{}/pending/dev_tasks", config.tasks_dir);
        if let Ok(entries) = fs::read_dir(&dev_tasks_dir) {
            for entry in entries.filter_map(|e| e.ok()) {
                if entry.file_name().to_string_lossy().contains(task_pattern) {
                    let _ = fs::remove_file(entry.path());
                    println!("🗑️  Removed task (all modules integrated)");
                }
            }
        }
    }

    Ok(())
}

pub fn check_tests(_config: &GuardConfig, _file_path: &Path) -> Result<()> {
    // SUSPENDED: Automated test generation is disabled during heavy refactoring.
    Ok(())
}
/*
pub fn check_tests(config: &GuardConfig, file_path: &Path) -> Result<()> {
    let p_str = file_path.to_string_lossy().replace("\\", "/");

    // GUARD: Do not generate tests for files in the tests directory or library directories
    if p_str.contains("/tests/") || p_str.contains("/libs/") || !p_str.ends_with(".res") {
        return Ok(());
    }

    let file_base = match file_path.file_stem() {
        Some(stem) => stem.to_string_lossy(),
        None => return Ok(()),
    };

    if file_base == "Version" {
        return Ok(());
    }

    let test_dir = "../../tests/unit";
    let possible_tests = vec![
        format!("{}/{}_v.test.res", test_dir, file_base),
        format!("{}/{}.test.res", test_dir, file_base),
        format!("{}/{}Test.res", test_dir, file_base),
    ];

    let mut existing_test = None;
    for t in possible_tests {
        if Path::new(&t).exists() {
            existing_test = Some(t);
            break;
        }
    }

    if existing_test.is_none() {
        let task_name = format!("Test_{}", file_base);
        append_to_unified_task(config, &task_name, "New")?;
    } else {
        let src_stats = fs::metadata(file_path)?;
        let test_stats = fs::metadata(existing_test.as_ref().unwrap())?;

        if src_stats.modified()? > test_stats.modified()? {
            let src_mtime = src_stats.modified()?;
            let test_mtime = test_stats.modified()?;

            if src_mtime > test_mtime {
                let task_name = format!("Test_{}", file_base);
                append_to_unified_task(config, &task_name, "Update")?;
            }
        }
    }

    Ok(())
}
*/

pub fn check_tasks_count(config: &GuardConfig) -> Result<()> {
    let completed_dir = format!("{}/completed", config.tasks_dir);
    if !Path::new(&completed_dir).exists() {
        return Ok(());
    }

    let entries = fs::read_dir(completed_dir)?;
    let mut count = 0;
    for entry in entries {
        if let Ok(entry) = entry {
            if entry.file_name().to_string_lossy().ends_with(".md") {
                count += 1;
            }
        }
    }

    if count > 90 {
        if !task_exists(config, "Aggregate_Completed_Tasks") {
            let next_id = get_next_id(config);
            let task_filename = format!("{:03}_Aggregate_Completed_Tasks.md", next_id);
            let task_content = format!(
                "# Task {}: Aggregate Completed Tasks\n\n## 🚨 Trigger\nCompleted tasks count exceeds 90 (Current: {}).\n\n## Objective\nAggregate the oldest 50 completed tasks into `tasks/completed/_CONCISE_SUMMARY.md` and cleanup.\n\n## AI Prompt\n\"Please perform the following maintenance on the task system:\n1. Identify the oldest 50 task files in `tasks/completed/` (based on their numerical prefix).\n2. Read these 50 files and the existing `tasks/completed/_CONCISE_SUMMARY.md`.\n3. Integrate the core accomplishments from these 50 tasks into `tasks/completed/_CONCISE_SUMMARY.md`, following its established style (categorized, bullet points, extremely concise).\n4. After successful integration and verification, delete the 50 original task files from `tasks/completed/`.\n5. Ensure the `_CONCISE_SUMMARY.md` remains the definitive high-level history of the project.\"\n",
                next_id, count
            );
            create_task(config, &task_filename, &task_content)?;
            println!("🧹 Created Maintenance Task: {}", task_filename);
        }
    }

    Ok(())
}
