use crate::api::utils::{PROCESSED_IMAGE_WIDTH, WEBP_QUALITY};
use serde_json::Value;
use std::collections::HashMap;

pub fn generate_project_summary(project_data: &Value) -> Result<String, String> {
    let tour_name = project_data["tourName"]
        .as_str()
        .unwrap_or("Untitled Tour")
        .to_string();
    let scenes = project_data["scenes"]
        .as_array()
        .ok_or("Missing 'scenes' array")?;
    let mut total_hotspots = 0;
    let mut total_score = 0.0;
    let mut total_luminance = 0;
    let mut group_counts: HashMap<String, u32> = HashMap::new();
    let mut score_count = 0;
    for scene in scenes {
        if let Some(hss) = scene["hotspots"].as_array() {
            total_hotspots += hss.len();
        }
        if let Some(group) = scene["colorGroup"].as_str() {
            *group_counts.entry(group.to_string()).or_insert(0) += 1;
        }
        if let Some(quality) = scene["quality"].as_object() {
            if let Some(score) = quality.get("score").and_then(|v| v.as_f64()) {
                total_score += score;
                score_count += 1;
            }
            if let Some(stats) = quality.get("stats").and_then(|v| v.as_object()) {
                if let Some(lum) = stats.get("avgLuminance").and_then(|v| v.as_u64()) {
                    total_luminance += lum;
                }
            }
        }
    }
    let mut group_summary = String::new();
    let mut group_ids: Vec<_> = group_counts.keys().collect();
    group_ids.sort_by(|a, b| {
        a.parse::<i32>()
            .unwrap_or(-1)
            .cmp(&b.parse::<i32>().unwrap_or(-1))
    });
    for id in group_ids {
        group_summary.push_str(&format!(
            "  - Visual Group {}: {} scene(s)\n",
            id, group_counts[id]
        ));
    }

    let avg_score = if score_count > 0 {
        total_score / score_count as f64
    } else {
        0.0
    };
    let avg_lum = if score_count > 0 {
        total_luminance / score_count as u64
    } else {
        0
    };

    Ok(format!(
        "====================================================\nVIRTUAL TOUR - PROJECT SUMMARY\n====================================================\n\n\
        Project Name:      {}\nGenerated On:      {}\nApplication:       Robust Virtual Tour Builder v4.4.7\n\n--- SCENE ANALYSIS ---\n\
        Total Scenes:      {}\nTotal Hotspots:    {}\nVisual Groups:     {} (Identified via similarity clustering)\n{}\n--- QUALITY METRICS ---\n\
        Avg Quality Score: {:.1}/10.0\nAvg Luminance:     {} (Balanced range: 100-180)\n\n\
        Technical Checks Performed:\n- Luminance Analysis: Ensuring balanced exposure\n- Sharpness Variance: Detecting blur or soft focus\n\
        - Clipping Detection: Checking for lost detail in highlights/shadows\n\n--- IMAGE SPECIFICATIONS ---\nStandard Format:   WebP (Lossy)\n\
        WebP Quality:      {:.1}%\nMax Resolution:    {}x{} px\n\n--- VALIDATION ---\nStatus:            COMPLETED\n\n\
        ====================================================\n",
        tour_name,
        chrono::Local::now().format("%Y-%m-%d %H:%M:%S"),
        scenes.len(),
        total_hotspots,
        group_counts.len(),
        group_summary,
        avg_score * 10.0,
        avg_lum,
        WEBP_QUALITY,
        PROCESSED_IMAGE_WIDTH,
        PROCESSED_IMAGE_WIDTH
    ))
}
