/**
 * Lightweight EXIF Parser for JPEG files
    * Extracts GPS coordinates, camera info, capture date, and performs quality analysis
        */

/**
 * Extract EXIF data from a File object
 * @param {File} file - JPEG file to parse
 * @returns {Promise<Object>} Extracted metadata
 */
export async function extractExifData(file) {
    try {
        const buffer = await file.slice(0, 128 * 1024).arrayBuffer(); // Read first 128KB (header)
        const view = new DataView(buffer);

        // Verify JPEG magic number
        if (view.getUint16(0) !== 0xFFD8) {
            return { error: "Not a valid JPEG" };
        }

        // Find EXIF marker (APP1 = 0xFFE1)
        let offset = 2;
        while (offset < view.byteLength - 4) {
            const marker = view.getUint16(offset);
            if (marker === 0xFFE1) {
                // Found APP1 (EXIF)
                const length = view.getUint16(offset + 2);
                const exifData = parseExifSegment(view, offset + 4, length - 2);
                return exifData;
            } else if ((marker & 0xFF00) === 0xFF00) {
                // Other marker - skip it
                const segmentLength = view.getUint16(offset + 2);
                offset += 2 + segmentLength;
            } else {
                break;
            }
        }

        return { error: "No EXIF data found" };
    } catch (err) {
        return { error: err.message };
    }
}

function parseExifSegment(view, start, length) {
    const result = {
        make: null,
        model: null,
        dateTime: null,
        gps: null,
        focalLength: null,
        iso: null,
        aperture: null,
        width: null,
        height: null
    };

    try {
        // Check for "Exif\0\0" header
        const exifHeader = String.fromCharCode(
            view.getUint8(start), view.getUint8(start + 1),
            view.getUint8(start + 2), view.getUint8(start + 3)
        );
        if (exifHeader !== "Exif") return result;

        const tiffStart = start + 6;
        const byteOrder = view.getUint16(tiffStart);
        const littleEndian = byteOrder === 0x4949; // "II" = Intel = Little Endian

        // Read IFD0 offset
        const ifd0Offset = view.getUint32(tiffStart + 4, littleEndian);

        // Parse IFD0
        const ifd0 = parseIFD(view, tiffStart + ifd0Offset, tiffStart, littleEndian);

        result.make = ifd0[0x010F]; // Make
        result.model = ifd0[0x0110]; // Model
        result.dateTime = ifd0[0x0132]; // DateTime
        result.width = ifd0[0xA002]; // PixelXDimension
        result.height = ifd0[0xA003]; // PixelYDimension

        // Parse EXIF SubIFD
        if (ifd0[0x8769]) {
            const exifIFD = parseIFD(view, tiffStart + ifd0[0x8769], tiffStart, littleEndian);
            result.focalLength = exifIFD[0x920A];
            result.iso = exifIFD[0x8827];
            result.aperture = exifIFD[0x829D];
            result.width = result.width || exifIFD[0xA002];
            result.height = result.height || exifIFD[0xA003];

            // SubIFD date tags (often more accurate than IFD0 date)
            if (!result.dateTime) {
                result.dateTime = exifIFD[0x9003] || exifIFD[0x9004]; // DateTimeOriginal or DateTimeDigitized
            }
        }

        // Parse GPS IFD
        if (ifd0[0x8825]) {
            const gpsIFD = parseIFD(view, tiffStart + ifd0[0x8825], tiffStart, littleEndian);
            const lat = parseGPSCoord(gpsIFD[0x0002], gpsIFD[0x0001]); // GPSLatitude, GPSLatitudeRef
            const lon = parseGPSCoord(gpsIFD[0x0004], gpsIFD[0x0003]); // GPSLongitude, GPSLongitudeRef
            if (lat !== null && lon !== null) {
                result.gps = { lat, lon };
            }
        }
    } catch (e) {
        // Partial parse is OK
    }

    return result;
}

/**
 * Analyze image quality with conservative, high-confidence metrics only
 * @param {File} file 
 * @returns {Promise<Object>} { score, stats, analysis }
 */
export async function analyzeImageQuality(file) {
    try {
        // Create a small bitmap for analysis (fast)
        const bitmap = await createImageBitmap(file, {
            resizeWidth: 400,
            resizeQuality: 'low'
        });

        const canvas = document.createElement('canvas');
        canvas.width = bitmap.width;
        canvas.height = bitmap.height;
        const ctx = canvas.getContext('2d', { willReadFrequently: true });
        ctx.drawImage(bitmap, 0, 0);

        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        const data = imageData.data;
        const gray = new Uint8ClampedArray(canvas.width * canvas.height);

        const histogram = new Uint32Array(256).fill(0);
        const histR = new Uint32Array(256).fill(0);
        const histG = new Uint32Array(256).fill(0);
        const histB = new Uint32Array(256).fill(0);
        let totalLuminance = 0;

        // Build grayscale and RGB histograms
        for (let i = 0; i < data.length; i += 4) {
            const r = data[i], g = data[i + 1], b = data[i + 2];
            const L = Math.round(0.2126 * r + 0.7152 * g + 0.0722 * b);
            histogram[L]++;
            histR[r]++;
            histG[g]++;
            histB[b]++;
            totalLuminance += L;
            gray[i / 4] = L;
        }

        const pixelCount = canvas.width * canvas.height;
        const avgLuminance = totalLuminance / pixelCount;

        // --- Clipping Detection (High-Confidence) ---
        // Only flag if >15% of pixels are pure black or pure white
        const blackClipping = (histogram[0] / pixelCount) * 100;
        const whiteClipping = (histogram[255] / pixelCount) * 100;

        const hasBlackClipping = blackClipping > 15;
        const hasWhiteClipping = whiteClipping > 15;

        // --- Exposure Check (Conservative) ---
        // Only flag severely underexposed (<50) or overexposed (>200)
        const isSeverelyDark = avgLuminance < 50;
        const isSeverelyBright = avgLuminance > 200;

        // --- Sharpness Detection (Laplacian Variance) ---
        // Sample center band only (middle 60% of height) to avoid equirectangular distortion
        let laplaceSum = 0;
        let laplaceSqSum = 0;
        let sampledPixels = 0;
        const w = canvas.width;
        const h = canvas.height;
        const yStart = Math.floor(h * 0.2);
        const yEnd = Math.floor(h * 0.8);

        for (let y = yStart + 1; y < yEnd - 1; y++) {
            for (let x = 1; x < w - 1; x++) {
                const idx = y * w + x;
                const lap = gray[idx - w] + gray[idx - 1] + gray[idx + 1] + gray[idx + w] - 4 * gray[idx];
                laplaceSum += lap;
                laplaceSqSum += lap * lap;
                sampledPixels++;
            }
        }

        const laplaceVar = sampledPixels > 0
            ? (laplaceSqSum / sampledPixels) - Math.pow(laplaceSum / sampledPixels, 2)
            : 0;

        // Blur detection: Severe (<100) and Warning tier (<120, 20% more conservative)
        const isBlurry = laplaceVar < 100;
        const isSoft = !isBlurry && laplaceVar < 120; // Intermediate "soft focus" warning

        // Dim detection: 20% more conservative than severe threshold (50 * 1.2 = 60)
        const isDim = !isSeverelyDark && avgLuminance < 60;

        // --- Balanced Scoring ---
        // Start at 7.5 (neutral) and adjust based on issues
        let score = 7.5;
        let issueCount = 0;
        let warningCount = 0;

        // Severe issues (heavy penalty)
        if (hasBlackClipping) { score -= 2.0; issueCount++; }
        if (hasWhiteClipping) { score -= 2.0; issueCount++; }
        if (isSeverelyDark) { score -= 2.5; issueCount++; }
        if (isSeverelyBright) { score -= 1.5; issueCount++; }
        if (isBlurry) { score -= 2.0; issueCount++; }

        // Warning tier (lighter penalty for balanced feedback)
        if (isDim) { score -= 1.0; warningCount++; }
        if (isSoft) { score -= 1.0; warningCount++; }

        // Bonus for clean images with no issues or warnings
        if (issueCount === 0 && warningCount === 0) score += 1.5;

        score = Math.max(1, Math.min(10, score));

        // --- Balanced Feedback ---
        const analysis = [];

        // Severe issues
        if (isSeverelyDark) analysis.push("Very dark image.");
        if (isSeverelyBright) analysis.push("Very bright image.");
        if (hasBlackClipping) analysis.push("Lost shadow detail.");
        if (hasWhiteClipping) analysis.push("Lost highlight detail.");
        if (isBlurry) analysis.push("Possible blur detected.");

        // Warning tier feedback (gentler language)
        if (isDim) analysis.push("Image appears dim; brighter exposure recommended.");
        if (isSoft) analysis.push("Slight softness detected; check focus.");

        return {
            score: parseFloat(score.toFixed(1)),
            histogram: Array.from(histogram),
            colorHist: {
                r: Array.from(histR),
                g: Array.from(histG),
                b: Array.from(histB)
            },
            stats: {
                avgLuminance: Math.round(avgLuminance),
                blackClipping: parseFloat(blackClipping.toFixed(1)),
                whiteClipping: parseFloat(whiteClipping.toFixed(1)),
                sharpnessVariance: Math.round(laplaceVar)
            },
            isBlurry,
            isSoft,
            isSeverelyDark,
            isDim,
            hasBlackClipping,
            hasWhiteClipping,
            issues: issueCount,
            warnings: warningCount,
            analysis: analysis.length > 0 ? analysis.join(" ") : null
        };

    } catch (err) {
        console.error("Quality analysis failed:", err);
        return { score: 7.5, issues: 0, analysis: null, error: err.message };
    }
}


/**
 * Compare two image results for abstract color similarity (0-1 range)
 * Uses BINNED histogram intersection for structural abstraction.
 * This ignores minor exposure/detail differences and focused on overall "vibe".
 */
export function calculateSimilarity(resultA, resultB) {
    if (!resultA.colorHist || !resultB.colorHist) {
        if (!resultA.histogram || !resultB.histogram) return 0;
        return intersectBinned(resultA.histogram, resultB.histogram, 8); // 8 bins for luminance
    }

    // Use 8 bins (down from 256) to be much more forgiving/abstract
    const rSim = intersectBinned(resultA.colorHist.r, resultB.colorHist.r, 8);
    const gSim = intersectBinned(resultA.colorHist.g, resultB.colorHist.g, 8);
    const bSim = intersectBinned(resultA.colorHist.b, resultB.colorHist.b, 8);

    return (rSim + gSim + bSim) / 3;
}

/**
 * Intersect histograms after grouping them into 'n' bins
 */
function intersectBinned(histA, histB, numBins) {
    const binSize = 256 / numBins;
    const binnedA = new Float32Array(numBins);
    const binnedB = new Float32Array(numBins);

    // Group into bins
    for (let i = 0; i < 256; i++) {
        const binIdx = Math.floor(i / binSize);
        binnedA[binIdx] += histA[i];
        binnedB[binIdx] += histB[i];
    }

    let intersection = 0;
    let sumA = 0;
    for (let i = 0; i < numBins; i++) {
        intersection += Math.min(binnedA[i], binnedB[i]);
        sumA += binnedA[i];
    }
    return sumA > 0 ? intersection / sumA : 0;
}

function parseIFD(view, offset, tiffStart, littleEndian) {
    const entries = {};
    try {
        const count = view.getUint16(offset, littleEndian);
        for (let i = 0; i < count; i++) {
            const entryOffset = offset + 2 + i * 12;
            const tag = view.getUint16(entryOffset, littleEndian);
            const type = view.getUint16(entryOffset + 2, littleEndian);
            const numValues = view.getUint32(entryOffset + 4, littleEndian);
            const valueOffset = entryOffset + 8;

            entries[tag] = readTagValue(view, type, numValues, valueOffset, tiffStart, littleEndian);
        }
    } catch (e) { }
    return entries;
}

function readTagValue(view, type, count, valueOffset, tiffStart, littleEndian) {
    const typeSize = [0, 1, 1, 2, 4, 8, 1, 1, 2, 4, 8, 4, 8][type] || 1;
    const totalSize = typeSize * count;

    let dataOffset = valueOffset;
    if (totalSize > 4) {
        dataOffset = tiffStart + view.getUint32(valueOffset, littleEndian);
    }

    try {
        switch (type) {
            case 2: // ASCII
                let str = "";
                for (let i = 0; i < count - 1; i++) {
                    str += String.fromCharCode(view.getUint8(dataOffset + i));
                }
                return str;
            case 3: // SHORT
                return count === 1 ? view.getUint16(dataOffset, littleEndian) :
                    Array.from({ length: count }, (_, i) => view.getUint16(dataOffset + i * 2, littleEndian));
            case 4: // LONG
                return count === 1 ? view.getUint32(dataOffset, littleEndian) :
                    Array.from({ length: count }, (_, i) => view.getUint32(dataOffset + i * 4, littleEndian));
            case 5: // RATIONAL (unsigned)
                if (count === 1) {
                    const num = view.getUint32(dataOffset, littleEndian);
                    const den = view.getUint32(dataOffset + 4, littleEndian);
                    return den ? num / den : 0;
                }
                return Array.from({ length: count }, (_, i) => {
                    const num = view.getUint32(dataOffset + i * 8, littleEndian);
                    const den = view.getUint32(dataOffset + i * 8 + 4, littleEndian);
                    return den ? num / den : 0;
                });
            default:
                return view.getUint32(valueOffset, littleEndian);
        }
    } catch (e) {
        return null;
    }
}

function parseGPSCoord(dmsArray, ref) {
    if (!dmsArray || !Array.isArray(dmsArray) || dmsArray.length < 3) return null;

    const degrees = dmsArray[0];
    const minutes = dmsArray[1];
    const seconds = dmsArray[2];

    let decimal = degrees + minutes / 60 + seconds / 3600;

    if (ref === "S" || ref === "W") {
        decimal = -decimal;
    }

    return decimal;
}

/**
 * Calculate average GPS location, excluding outliers
 * @param {Array} gpsPoints - Array of {lat, lon} objects
 * @param {number} maxDistanceKm - Max distance from centroid before considered outlier
 * @returns {Object} {centroid, outliers, validCount}
 */
export function calculateAverageLocation(gpsPoints, maxDistanceKm = 0.5) {
    if (!gpsPoints.length) return null;

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
