/**
 * EXIF Metadata Report Generator
 * Creates a detailed log file grouping images by camera/specs
 */

import { extractExifData, analyzeImageQuality, calculateAverageLocation, reverseGeocode, getCameraSignature } from "./ExifParser.js";

/**
 * Generate EXIF metadata report from uploaded files
 * @param {Object[]} sceneDataList - Array of processed scene items containing { original, quality }
 * @returns {Promise<{report: string, suggestedName: string}>} Report content and suggested project name
 */
export async function generateExifReport(sceneDataList) {
    const lines = [];
    let resolvedAddress = null;
    let captureDateTime = null;

    lines.push("╔══════════════════════════════════════════════════════════════════════════════╗");
    lines.push("║                          EXIF METADATA ANALYSIS REPORT                       ║");
    lines.push("╠══════════════════════════════════════════════════════════════════════════════╣");
    lines.push(`║  Generated: ${new Date().toLocaleString().padEnd(63)}║`);
    lines.push(`║  Total Files Analyzed: ${sceneDataList.length.toString().padEnd(52)}║`);
    lines.push("╚══════════════════════════════════════════════════════════════════════════════╝");
    lines.push("");

    // Extract EXIF from all files
    const exifResults = [];
    const gpsPoints = [];

    for (const item of sceneDataList) {
        const file = item.original;

        // Optimization: Use pre-existing metadata if available from UploadProcessor
        const exif = item.metadata || await extractExifData(file);
        const quality = item.quality || item.metadata?.quality || await analyzeImageQuality(file);

        exifResults.push({ filename: file.name, exif, quality });

        if (exif.gps) {
            gpsPoints.push({ ...exif.gps, filename: file.name });
        }

        // Capture the first valid dateTime for project naming
        if (!captureDateTime && exif.dateTime) {
            captureDateTime = exif.dateTime;
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // SECTION 1: LOCATION ANALYSIS
    // ─────────────────────────────────────────────────────────────────
    lines.push("┌──────────────────────────────────────────────────────────────────────────────┐");
    lines.push("│  📍 LOCATION ANALYSIS                                                        │");
    lines.push("└──────────────────────────────────────────────────────────────────────────────┘");
    lines.push("");

    if (gpsPoints.length === 0) {
        lines.push("  ⚠️  No GPS data found in any uploaded images.");
        lines.push("      Images may have been taken with location services disabled,");
        lines.push("      or GPS metadata was stripped during processing.");
        lines.push("");
    } else {
        const locationAnalysis = calculateAverageLocation(gpsPoints, 0.5);

        lines.push(`  GPS Data Found: ${gpsPoints.length} of ${sceneDataList.length} images`);
        lines.push("");

        if (locationAnalysis.outliers.length > 0) {
            lines.push("  ⚠️  OUTLIERS DETECTED (excluded from average calculation):");
            locationAnalysis.outliers.forEach(o => {
                lines.push(`      • ${o.point.filename} - ${(o.distance * 1000).toFixed(0)}m from cluster center`);
            });
            lines.push("");
        }

        if (locationAnalysis.centroid) {
            const { lat, lon } = locationAnalysis.centroid;
            lines.push(`  📍 Estimated Property Location:`);
            lines.push(`     Latitude:  ${lat.toFixed(6)}`);
            lines.push(`     Longitude: ${lon.toFixed(6)}`);
            lines.push(`     Google Maps: https://maps.google.com/?q=${lat},${lon}`);
            lines.push("");

            // Reverse geocode
            lines.push("  🔍 Address Lookup:");
            const address = await reverseGeocode(lat, lon);
            if (address.startsWith("[")) {
                lines.push(`     ${address}`);
                lines.push("     (This does not affect your virtual tour - geocoding is informational only)");
            } else {
                lines.push(`     ${address}`);
                resolvedAddress = address;
            }
            lines.push("");
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // SECTION 2: CAMERA/DEVICE GROUPING
    // ─────────────────────────────────────────────────────────────────
    lines.push("┌──────────────────────────────────────────────────────────────────────────────┐");
    lines.push("│  📷 CAMERA & DEVICE ANALYSIS                                                 │");
    lines.push("└──────────────────────────────────────────────────────────────────────────────┘");
    lines.push("");

    // Group by camera signature
    const groups = {};
    exifResults.forEach(r => {
        const sig = getCameraSignature(r.exif);
        if (!groups[sig]) {
            groups[sig] = { exif: r.exif, files: [] };
        }
        groups[sig].files.push(r.filename);
    });

    Object.entries(groups).forEach(([signature, data]) => {
        lines.push(`  ┌─ ${signature} ─${"─".repeat(Math.max(0, 60 - signature.length))}`);
        lines.push(`  │  Images: ${data.files.length}`);

        if (data.exif.focalLength) {
            lines.push(`  │  Focal Length: ${data.exif.focalLength.toFixed(1)}mm`);
        }
        if (data.exif.aperture) {
            lines.push(`  │  Aperture: f/${data.exif.aperture.toFixed(1)}`);
        }
        if (data.exif.iso) {
            lines.push(`  │  ISO: ${data.exif.iso}`);
        }
        if (data.exif.dateTime) {
            lines.push(`  │  Capture Period: ${data.exif.dateTime}`);
        }

        lines.push(`  │`);
        lines.push(`  │  Files:`);
        data.files.forEach(f => {
            lines.push(`  │    • ${f}`);
        });
        lines.push(`  └${"─".repeat(76)}`);
        lines.push("");
    });

    // ─────────────────────────────────────────────────────────────────
    // SECTION 3: DETAILED FILE LIST (for reference)
    // ─────────────────────────────────────────────────────────────────
    lines.push("┌──────────────────────────────────────────────────────────────────────────────┐");
    lines.push("│  📋 INDIVIDUAL FILE METADATA                                                 │");
    lines.push("└──────────────────────────────────────────────────────────────────────────────┘");
    lines.push("");

    exifResults.forEach(r => {
        const hasGPS = r.exif.gps ? "✓ GPS" : "✗ No GPS";
        const hasCamera = r.exif.model ? `${r.exif.make || ""} ${r.exif.model}`.trim() : "Unknown Device";
        const qScore = r.quality?.score ? `| Quality: ${r.quality.score}/10` : "";
        lines.push(`  ${r.filename}`);
        lines.push(`    └─ ${hasCamera} | ${hasGPS} ${qScore}`);
        if (r.quality?.analysis) {
            lines.push(`       Note: ${r.quality.analysis}`);
        }
    });

    lines.push("");
    lines.push("═".repeat(80));
    lines.push("END OF REPORT");
    lines.push("═".repeat(80));

    // Generate suggested project name
    const suggestedName = generateProjectName(resolvedAddress, captureDateTime);

    return {
        report: lines.join("\n"),
        suggestedName
    };
}

/**
 * Generate a smart project identification name
 * Format: Word1_Word2_Word3_DDMMYYHH_SSSSS
 * @param {string|null} address - Resolved address string
 * @param {string|null} dateTime - EXIF capture datetime
 * @returns {string} Suggested project name
 */
function generateProjectName(address, dateTime) {
    // 1. Extract first 3 words in full from address
    let locationPart = "Unknown_Location";
    if (address) {
        // Split by comma or space and take first 3 complete words
        const words = address.split(/[\s,]+/).filter(w => w.length > 0);
        const selectedWords = words.slice(0, 3).map(w => {
            // Remove non-alphanumeric for safety and use Title Case
            const clean = w.replace(/[^a-zA-Z0-9]/g, '');
            if (clean.length === 0) return "";
            return clean.charAt(0).toUpperCase() + clean.slice(1).toLowerCase();
        }).filter(w => w.length > 0);

        if (selectedWords.length > 0) {
            locationPart = selectedWords.join("_");
        }
    }

    // 2. Generate compact timestamp DDMMYYHH
    let timestampPart;
    if (dateTime) {
        // EXIF format is typically "YYYY:MM:DD HH:MM:SS"
        const match = dateTime.match(/(\d{4}):(\d{2}):(\d{2})\s+(\d{2})/);
        if (match) {
            const [, year, month, day, hour] = match;
            const shortYear = year.slice(2);
            timestampPart = `${day}${month}${shortYear}${hour}`;
        }
    }
    if (!timestampPart) {
        // Fallback to current time
        const now = new Date();
        const day = now.getDate().toString().padStart(2, '0');
        const month = (now.getMonth() + 1).toString().padStart(2, '0');
        const year = now.getFullYear().toString().slice(2);
        const hour = now.getHours().toString().padStart(2, '0');
        timestampPart = `${day}${month}${year}${hour}`;
    }

    // 3. Generate random serial (5 digits)
    const serialPart = Math.floor(10000 + Math.random() * 90000).toString();

    return `${locationPart}_${timestampPart}_${serialPart}`;
}

/**
 * Save the EXIF report to the logs folder (browser download)
 * @param {string} content - Report content
 */
export function downloadExifReport(content) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
    const filename = `EXIF_METADATA_${timestamp}.txt`;

    const blob = new Blob([content], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);

    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);

    setTimeout(() => URL.revokeObjectURL(url), 10000);

    return filename;
}
