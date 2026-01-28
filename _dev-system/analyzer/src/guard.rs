use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;
use anyhow::Result;
use regex::Regex;

pub struct GuardConfig {
    pub tasks_dir: String,
    pub map_file: String,
}

impl Default for GuardConfig {
    fn default() -> Self {
        Self {
            tasks_dir: "../../tasks".to_string(),
            map_file: "../../MAP.md".to_string(),
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
        PathBuf::from(&config.tasks_dir).join("pending").join(filename)
    } else {
        PathBuf::from(&config.tasks_dir).join("pending").join(filename)
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

pub fn append_to_unified_task(config: &GuardConfig, task_name: &str, description: &str) -> Result<bool> {
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

    if content.contains(task_name) {
        return Ok(true);
    }

    if !content.ends_with('\n') {
        content.push('\n');
    }
    content.push_str(&format!("- [ ] {} ({})\n", task_name, description));
    fs::write(&path, content)?;
    println!("➕ Appended to Unified Task: {} in {}", task_name, path.display());
    Ok(true)
}

pub fn check_map(config: &GuardConfig) -> Result<()> {
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
                let clean_path = if p_str.starts_with("../../") {
                    &p_str[6..]
                } else {
                    &p_str
                };

                let extension = path.extension().and_then(|s| s.to_str()).unwrap_or("");
                if (extension == "res" || extension == "rs") && !mapped_paths.contains(clean_path) {
                    unmapped_files.push(clean_path.to_string());
                }
            }
        }
    }

    if !unmapped_files.is_empty() {
        println!("🗺️ Found {} unmapped files.", unmapped_files.len());
        let mut new_content = map_content.clone();
        
        if !new_content.contains("## 🆕 Unmapped Modules") {
            new_content.push_str("\n\n## 🆕 Unmapped Modules\n");
        }

        let mut added_count = 0;
        for f in unmapped_files {
            if !new_content.contains(&format!("[{}]", f)) {
                let abs_path = fs::canonicalize(format!("../../{}", f))?;
                let link = format!("file://{}", abs_path.to_string_lossy());
                new_content.push_str(&format!("* [{}]({}): New module detected. Please classify. #new\n", f, link));
                added_count += 1;
            }
        }

        if added_count > 0 {
            fs::write(&config.map_file, new_content)?;
            println!("🗺️ Added {} files to MAP.md.", added_count);

            if !task_exists(config, "Classify_Map_Entries") {
                let next_id = get_next_id(config);
                let task_filename = format!("{:03}_Classify_Map_Entries.md", next_id);
                let task_content = format!(
                    "# Task {}: Classify New Map Entries\n\n## 🚨 Trigger\nNew modules were detected and added to the 'Unmapped Modules' section of `MAP.md`.\n\n## Objective\nMove the entries from 'Unmapped Modules' to their appropriate semantic sections in `MAP.md`.\n",
                    next_id
                );
                create_task(config, &task_filename, &task_content)?;
            }
        }
    }

    Ok(())
}

pub fn get_hints(content: &str) -> String {
    let mut hints = String::new();
    if content.contains("Pannellum") {
        hints.push_str("\n- **Mock Pannellum**: This module interacts with Pannellum. Mock the global `window.pannellum` object in `tests/node-setup.js` or locally.");
    }
    if content.contains("FFmpeg") {
        hints.push_str("\n- **Mock FFmpeg**: This module uses FFmpeg. Ensure the FFmpeg core is mocked or its promises are resolved instantly.");
    }
    if content.contains("EventBus") {
        hints.push_str("\n- **EventBus Integration**: Use `EventBus.dispatch` spies to verify that actions are triggered correctly.");
    }
    if content.contains("Fetch") || content.contains("BackendApi") {
        hints.push_str("\n- **API Mocks**: Mock `fetch` and `RequestQueue.schedule`. Jules should verify that the correct endpoints are called with the expected payloads.");
    }
    if content.contains("Window") || content.contains("Dom") {
        hints.push_str("\n- **DOM/Window Bindings**: Use `ReBindings` to mock browser-specific properties like `localStorage`, `location`, or `window.innerWidth`.");
    }

    if !hints.is_empty() {
        format!("\n## 💡 Implementation Hints for Cloud Agents (Jules)\n{}", hints)
    } else {
        String::new()
    }
}

pub fn check_tests(config: &GuardConfig, file_path: &Path) -> Result<()> {
    let p_str = file_path.to_string_lossy();
    if p_str.contains(".bs.js") || p_str.contains("/libs/") || !p_str.ends_with(".res") {
        return Ok(());
    }

    let file_name = file_path.file_name().unwrap().to_string_lossy();
    let file_base = file_path.file_stem().unwrap().to_string_lossy();
    
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

    let content = fs::read_to_string(file_path)?;

    if existing_test.is_none() {
        let task_name = format!("Test_{}_New", file_base);
        append_to_unified_task(config, &task_name, "New")?;
    } else {
        let src_stats = fs::metadata(file_path)?;
        let test_stats = fs::metadata(existing_test.as_ref().unwrap())?;

        if src_stats.modified()? > test_stats.modified()? {
            let src_mtime = src_stats.modified()?;
            let test_mtime = test_stats.modified()?;

            if src_mtime > test_mtime {
                let task_name = format!("Test_{}_Update", file_base);
                append_to_unified_task(config, &task_name, "Update")?;
            }
        }
    }

    Ok(())
}

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
