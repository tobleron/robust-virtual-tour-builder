use crate::config::EfficiencyConfig;
use crate::task_generator::WorkUnit;
use anyhow::{Context, Result};
use std::collections::HashMap;
use std::fs::OpenOptions;
use std::io::Write;
use std::path::Path;

/// Flush work unit plans to markdown files
pub fn flush_plans(
    buffer: &HashMap<String, Vec<WorkUnit>>, 
    config: &EfficiencyConfig
) -> Result<()> {
    for (driver_name, units) in buffer {
        if units.is_empty() { continue; } 
        
        let plan_path = format!("../plans/{}_PLAN.md", driver_name.to_uppercase());
        let mut file = OpenOptions::new()
            .create(true)
            .truncate(true)
            .write(true)
            .open(&plan_path)
            .context("Failed to open plan file")?;
            
        file.write_all(format!("# {} MASTER PLAN\n", driver_name.to_uppercase()).as_bytes())?;
        file.write_all(config.templates.legend.as_bytes())?;

        let ambiguities: Vec<&WorkUnit> = units.iter()
            .filter(|u| matches!(u, WorkUnit::Ambiguity { .. }))
            .collect();
        if !ambiguities.is_empty() {
            file.write_all(format!("## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION ({})\n", ambiguities.len()).as_bytes())?;
            for unit in ambiguities {
                if let WorkUnit::Ambiguity { file: f_path, .. } = unit {
                    file.write_all(format!("- [ ] `{}`\n", f_path).as_bytes())?;
                }
            }
            file.write_all(b"\n---\n\n")?;
        }

        let surgicals: Vec<&WorkUnit> = units.iter()
            .filter(|u| matches!(u, WorkUnit::Surgical { .. }))
            .collect();
        if !surgicals.is_empty() {
            file.write_all(format!("## 🛠️ SURGICAL REFACTOR TASKS ({})\n", surgicals.len()).as_bytes())?;
            for unit in surgicals {
                if let WorkUnit::Surgical { file: f_path, reason, .. } = unit {
                    file.write_all(format!("- [ ] **{}**\n  - *Reason:* {}\n", f_path, reason).as_bytes())?;
                }
            }
            file.write_all(b"\n---\n\n")?;
        }

        let structural: Vec<&WorkUnit> = units.iter()
            .filter(|u| matches!(u, WorkUnit::Structural { .. }))
            .collect();
        if !structural.is_empty() {
            file.write_all(format!("## 🏗️ STRUCTURAL REFACTOR TASKS ({})\n", structural.len()).as_bytes())?;
            for unit in structural {
                if let WorkUnit::Structural { file: f, action, reason, .. } = unit {
                    file.write_all(format!("- [ ] **{}** (Action: {})\n  - *Reason:* {}\n", f, action, reason).as_bytes())?;
                }
            }
            file.write_all(b"\n---\n\n")?;
        }

        let merges: Vec<&WorkUnit> = units.iter()
            .filter(|u| matches!(u, WorkUnit::Merge { .. }))
            .collect();
        if !merges.is_empty() {
            file.write_all(format!("## 🧩 MERGE TASKS ({})\n", merges.len()).as_bytes())?;
            for unit in merges {
                if let WorkUnit::Merge { folder, files, reason, .. } = unit {
                    file.write_all(format!("### Merge Folder: `{}`\n- **Reason:** {}\n- **Files:**\n", folder, reason).as_bytes())?;
                    for f in files {
                         let full_path = Path::new(folder).join(f);
                        file.write_all(format!("  - `{}`\n", full_path.to_string_lossy()).as_bytes())?;
                    }
                }
            }
        }
    }
    Ok(())
}
