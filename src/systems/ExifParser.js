import { BACKEND_URL } from "../constants.js";
import { Debug } from "../utils/Debug.js";

/**
 * Metadata & Quality System (Backend Connected)
 * 
 * Offloads EXIF parsing and heavy image quality analysis to the Rust backend.
 * Replaces the complex manual byte-parsing and slow canvas-based analysis.
 */

/**
 * Extract EXIF data and analyze image quality via Backend
 * @param {File} file - Image file to process
 * @returns {Promise<Object>} Combined metadata and quality analysis
 */
export async function extractExifData(file) {
    try {
        const formData = new FormData();
        formData.append("file", file);

        const response = await fetch(`${BACKEND_URL}/extract-metadata`, {
            method: "POST",
            body: formData,
        });

        if (!response.ok) {
            let errorDetails = "Unknown Metadata Error";
            try {
                const errorJson = await response.json();
                errorDetails = `${errorJson.error}${errorJson.details ? ": " + errorJson.details : ""}`;
            } catch (e) {
                errorDetails = await response.text();
            }
            
            Debug.error("ExifParser", `Backend Metadata Extraction Failed (${response.status})`, { details: errorDetails });
            return { error: errorDetails };
        }

        const data = await response.json();
        
        // Map Rust field names to JS expected names
        // Backend returns { exif: { ... }, quality: { ... } }
        
        const mappedQuality = {
            ...data.quality,
            isBlurry: data.quality.is_blurry,
            isSoft: data.quality.is_soft,
            isSeverelyDark: data.quality.is_severely_dark,
            isDim: data.quality.is_dim,
            hasBlackClipping: data.quality.has_black_clipping,
            hasWhiteClipping: data.quality.has_white_clipping,
            colorHist: data.quality.color_hist,
            stats: data.quality.stats ? {
                ...data.quality.stats,
                avgLuminance: data.quality.stats.avg_luminance,
                blackClipping: data.quality.stats.black_clipping,
                whiteClipping: data.quality.stats.white_clipping,
                sharpnessVariance: data.quality.stats.sharpness_variance
            } : {}
        };

        const result = {
            ...data.exif,
            dateTime: data.exif.date_time,
            quality: mappedQuality
        };

        return result;
    } catch (err) {
        Debug.error("ExifParser", "Metadata Processing Failed", { error: err.message });
        return { error: err.message };
    }
}

/**
 * Legacy wrapper for compatibility with existing code
 * @param {File} file 
 * @returns {Promise<Object>} quality analysis object
 */
export async function analyzeImageQuality(file) {
    const data = await extractExifData(file);
    if (data.error) return { score: 7.5, issues: 0, analysis: null, error: data.error };
    return data.quality;
}

/**
 * Calculate average GPS location, excluding outliers
 * @param {Array} gpsPoints - Array of {lat, lon} objects
 * @param {number} maxDistanceKm - Max distance from centroid before considered outlier
 * @returns {Object} {centroid, outliers, validCount}
 */
export function calculateAverageLocation(gpsPoints, maxDistanceKm = 0.5) {
    if (!gpsPoints || !gpsPoints.length) return null;

    // First pass: simple average
    let sumLat = 0, sumLon = 0;
    gpsPoints.forEach(p => { sumLat += p.lat; sumLon += p.lon; });
    const roughCentroid = { lat: sumLat / gpsPoints.length, lon: sumLon / gpsPoints.length };

    // Identify outliers
    const validPoints = [];
    const outliers = [];

    gpsPoints.forEach((p, i) => {
        const dist = haversineDistance(roughCentroid.lat, roughCentroid.lon, p.lat, p.lon);
        if (dist > maxDistanceKm) {
            outliers.push({ index: i, distance: dist, point: p });
        } else {
            validPoints.push(p);
        }
    });

    // Recalculate centroid without outliers
    if (validPoints.length === 0) {
        return { centroid: roughCentroid, outliers, validCount: 0 };
    }

    sumLat = 0; sumLon = 0;
    validPoints.forEach(p => { sumLat += p.lat; sumLon += p.lon; });

    return {
        centroid: { lat: sumLat / validPoints.length, lon: sumLon / validPoints.length },
        outliers,
        validCount: validPoints.length
    };
}

/**
 * Haversine formula for distance between two GPS points
 */
function haversineDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) ** 2 +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Reverse geocode GPS coordinates to an address
 * Uses OpenStreetMap Nominatim (free, no API key)
 * @param {number} lat 
 * @param {number} lon 
 * @returns {Promise<string>} Address string or error message
 */
export async function reverseGeocode(lat, lon) {
    try {
        const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&zoom=18&addressdetails=1`;
        const response = await fetch(url, {
            headers: { "User-Agent": "VirtualTourBuilder/1.0" }
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();

        if (data.error) {
            return `[Geocoding Error: ${data.error}]`;
        }

        // Build a friendly address
        const addr = data.address || {};
        const parts = [];

        if (addr.road) parts.push(addr.road);
        if (addr.suburb || addr.neighbourhood) parts.push(addr.suburb || addr.neighbourhood);
        if (addr.city || addr.town || addr.village) parts.push(addr.city || addr.town || addr.village);
        if (addr.state || addr.province) parts.push(addr.state || addr.province);
        if (addr.country) parts.push(addr.country);

        return parts.length > 0 ? parts.join(", ") : data.display_name || "[Unknown Location]";
    } catch (err) {
        return `[Geocoding Unavailable: ${err.message}. Check internet connection.]`;
    }
}

/**
 * Generate a camera signature for grouping
 */
export function getCameraSignature(exif) {
    const make = exif.make || "Unknown";
    const model = exif.model || "Unknown";
    const dims = (exif.width && exif.height) ? `${exif.width}x${exif.height}` : "Unknown";
    return `${make} ${model} @ ${dims}`;
}

/**
 * Compare two image results for abstract color similarity (0-1 range)
 * Uses BINNED histogram intersection for structural abstraction.
 * This ignores minor exposure/detail differences and focused on overall "vibe".
 * 
 * Adapted to work with Backend response structure:
 * - result.histogram (array)
 * - result.colorHist (object {r, g, b}) (NOTE: Backend sends 'color_hist' snake_case, frontend wrapper in ExifParser.js maps it?) 
 *   Wait, ExifParser.js extractExifData returns data.quality. 
 *   Backend QualityAnalysis struct has `color_hist`. JSON will be `color_hist`.
 *   I should update this function to handle `color_hist` (snake_case) or update extractExifData to map it.
 */
export function calculateSimilarity(resultA, resultB) {
    if (!resultA || !resultB) return 0;

    // Handle potential casing differences (backend uses snake_case)
    const histA = resultA.histogram;
    const histB = resultB.histogram;
    const colorA = resultA.colorHist || resultA.color_hist;
    const colorB = resultB.colorHist || resultB.color_hist;

    // LUMINANCE ONLY FALLBACK
    if (!colorA || !colorB) {
        if (!histA || !histB) return 0;
        return intersectBinned(histA, histB, 8);
    }

    // Use pre-allocated Float32Arrays for intersection to avoid GC pressure
    const rSim = intersectBinned(colorA.r || [], colorB.r || [], 8);
    const gSim = intersectBinned(colorA.g || [], colorB.g || [], 8);
    const bSim = intersectBinned(colorA.b || [], colorB.b || [], 8);

    return (rSim + gSim + bSim) / 3;
}

/**
 * Intersect histograms after grouping them into 'n' bins
 */
function intersectBinned(histA, histB, numBins) {
    if (!histA || !histB) return 0;
    
    const binSize = 256 / numBins;
    const binnedA = new Float32Array(numBins);
    const binnedB = new Float32Array(numBins);

    // Group into bins
    for (let i = 0; i < 256; i++) {
        const binIdx = Math.floor(i / binSize);
        // Backend might return larger arrays if bit depth differs, but we assume 256 bins for 8-bit
        const valA = histA[i] || 0;
        const valB = histB[i] || 0;
        
        binnedA[binIdx] += valA;
        binnedB[binIdx] += valB;
    }

    let intersection = 0;
    let sumA = 0;
    for (let i = 0; i < numBins; i++) {
        intersection += Math.min(binnedA[i], binnedB[i]);
        sumA += binnedA[i];
    }
    return sumA > 0 ? intersection / sumA : 0;
}