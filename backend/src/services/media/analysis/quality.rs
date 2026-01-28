// @efficiency: domain-logic
use super::super::resizing::resize_fast_rgba;
use crate::models::*;
use rayon::prelude::*;

pub fn analyze_quality(src_rgba: &[u8], src_w: u32, src_h: u32) -> Result<QualityAnalysis, String> {
    let thumb_rgba = resize_fast_rgba(src_rgba, src_w, src_h, 400, 400)
        .map_err(|e| format!("Analysis resize failed: {}", e))?;

    let w = 400u32;
    let h = 400u32;
    let pixel_count = (w * h) as f32;

    let gray_pixels: Vec<u8> = thumb_rgba
        .par_chunks(4)
        .map(|chunk| {
            if chunk.len() >= 3 {
                ((chunk[0] as u32 * 54)
                    .saturating_add(chunk[1] as u32 * 183)
                    .saturating_add(chunk[2] as u32 * 19)
                    >> 8) as u8
            } else {
                0
            }
        })
        .collect();

    let (hist_r, hist_g, hist_b, hist_gray, total_lum) = thumb_rgba
        .par_chunks(4)
        .fold(
            || {
                (
                    vec![0u32; 256],
                    vec![0u32; 256],
                    vec![0u32; 256],
                    vec![0u32; 256],
                    0u64,
                )
            },
            |(mut hr, mut hg, mut hb, mut hgray, mut tlum), chunk| {
                if chunk.len() >= 3 {
                    let r = chunk[0] as usize;
                    let g = chunk[1] as usize;
                    let b = chunk[2] as usize;
                    hr[r] += 1;
                    hg[g] += 1;
                    hb[b] += 1;
                    let lum = ((chunk[0] as u32 * 54)
                        .saturating_add(chunk[1] as u32 * 183)
                        .saturating_add(chunk[2] as u32 * 19)
                        >> 8) as u8;
                    hgray[lum as usize] += 1;
                    tlum += lum as u64;
                }
                (hr, hg, hb, hgray, tlum)
            },
        )
        .reduce(
            || {
                (
                    vec![0u32; 256],
                    vec![0u32; 256],
                    vec![0u32; 256],
                    vec![0u32; 256],
                    0u64,
                )
            },
            |mut a, b| {
                for i in 0..256 {
                    a.0[i] += b.0[i];
                    a.1[i] += b.1[i];
                    a.2[i] += b.2[i];
                    a.3[i] += b.3[i];
                }
                a.4 += b.4;
                a
            },
        );

    let avg_lum = (total_lum as f32 / pixel_count) as u32;
    let black_clipping = (hist_gray[0] as f32 / pixel_count) * 100.0;
    let white_clipping = (hist_gray[255] as f32 / pixel_count) * 100.0;

    let y_start = (h as f32 * 0.2) as u32;
    let y_end = (h as f32 * 0.8) as u32;

    let (laplace_sum, laplace_sq_sum, sampled_count) = ((y_start + 1)..(y_end - 1))
        .into_par_iter()
        .map(|y| {
            let mut l_sum = 0.0;
            let mut l_sq_sum = 0.0;
            let mut count = 0;
            for x in 1..(w - 1) {
                let idx = (y * w + x) as usize;
                if idx >= gray_pixels.len() {
                    continue;
                }
                let center = gray_pixels[idx] as i32;
                let lap = gray_pixels[idx - w as usize] as i32
                    + gray_pixels[idx - 1] as i32
                    + gray_pixels[idx + 1] as i32
                    + gray_pixels[idx + w as usize] as i32
                    - 4 * center;
                let lap_val = lap as f64;
                l_sum += lap_val;
                l_sq_sum += lap_val * lap_val;
                count += 1;
            }
            (l_sum, l_sq_sum, count)
        })
        .reduce(
            || (0.0, 0.0, 0u64),
            |a, b| (a.0 + b.0, a.1 + b.1, a.2 + b.2),
        );

    let laplace_var = if sampled_count > 0 {
        let mean = laplace_sum / sampled_count as f64;
        (laplace_sq_sum / sampled_count as f64) - (mean * mean)
    } else {
        0.0
    };

    let is_blurry = laplace_var < 100.0;
    let is_soft = !is_blurry && laplace_var < 120.0;
    let is_severely_dark = avg_lum < 50;
    let is_severely_bright = avg_lum > 200;
    let is_dim = !is_severely_dark && avg_lum < 60;
    let has_black_clipping = black_clipping > 15.0;
    let has_white_clipping = white_clipping > 15.0;

    let mut score = 7.5f32;
    let mut issues = 0u32;
    let mut warnings = 0u32;

    if has_black_clipping {
        score -= 2.0;
        issues += 1;
    }
    if has_white_clipping {
        score -= 2.0;
        issues += 1;
    }
    if is_severely_dark {
        score -= 2.5;
        issues += 1;
    }
    if is_severely_bright {
        score -= 1.5;
        issues += 1;
    }
    if is_blurry {
        score -= 2.0;
        issues += 1;
    }
    if is_dim {
        score -= 1.0;
        warnings += 1;
    }
    if is_soft {
        score -= 1.0;
        warnings += 1;
    }
    if issues == 0 && warnings == 0 {
        score += 1.5;
    }
    score = score.clamp(1.0, 10.0);

    let mut messages = Vec::new();
    if is_severely_dark {
        messages.push("Very dark image.");
    }
    if is_severely_bright {
        messages.push("Very bright image.");
    }
    if has_black_clipping {
        messages.push("Lost shadow detail.");
    }
    if has_white_clipping {
        messages.push("Lost highlight detail.");
    }
    if is_blurry {
        messages.push("Possible blur detected.");
    }
    if is_dim {
        messages.push("Image appears dim; brighter exposure recommended.");
    }
    if is_soft {
        messages.push("Slight softness detected; check focus.");
    }

    Ok(QualityAnalysis {
        score,
        histogram: hist_gray,
        color_hist: ColorHist {
            r: hist_r,
            g: hist_g,
            b: hist_b,
        },
        stats: QualityStats {
            avg_luminance: avg_lum,
            black_clipping,
            white_clipping,
            sharpness_variance: laplace_var as u32,
        },
        is_blurry,
        is_soft,
        is_severely_dark,
        is_severely_bright,
        is_dim,
        has_black_clipping,
        has_white_clipping,
        issues,
        warnings,
        analysis: if messages.is_empty() {
            None
        } else {
            Some(messages.join(" "))
        },
    })
}
