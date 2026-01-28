
fn flush_plans(buffer: &HashMap<String, Vec<WorkUnit>>) -> Result<()> {
    for (driver_name, units) in buffer {
        if units.is_empty() { continue; } 
        
        let plan_path = format!("../plans/{}_PLAN.md", driver_name.to_uppercase());
        let mut file = OpenOptions::new().create(true).truncate(true).write(true).open(plan_path).context("Open fail")?;

        file.write_all(format!("# {} MASTER PLAN\n", driver_name.to_uppercase()).as_bytes())?;
        file.write_all(get_legend().as_bytes())?;

        // 1. AMBIGUITIES (Aggregated)
        let ambiguities: Vec<&WorkUnit> = units.iter().filter(|u| matches!(u, WorkUnit::Ambiguity { .. })).collect();
        if !ambiguities.is_empty() {
            file.write_all(format!("## ⚠️ PRECURSOR: AMBIGUITY RESOLUTION ({})\n", ambiguities.len()).as_bytes())?;
            file.write_all(b"**Action:** The AI Agent must analyze these files and update `_dev-system/config/efficiency.json` or add `@efficiency` headers.\n\n")?;
            for unit in ambiguities {
                if let WorkUnit::Ambiguity { file: f_path } = unit {
                    file.write_all(format!(