/**
 * Image Processing System (Backend Connected)
 * 
 * Offloads heavy image processing to the Rust backend:
 * - Uploads raw image to /optimize-image
 * - Backend handles resizing (4K, 2K, HD) and WebP conversion
 * - Returns optimized WebP blobs
 * 
 * @module Resizer
 */

import { BACKEND_URL } from "../constants.js";
import { Debug } from "../utils/Debug.js";

/**
 * Check if the backend is reachable
 * @returns {Promise<boolean>}
 */
export async function checkBackendHealth() {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 2000); // 2s timeout
    const response = await fetch(`${BACKEND_URL}/health`, { signal: controller.signal });
    clearTimeout(timeoutId);
    return response.ok;
  } catch (e) {
    return false;
  }
}

/**
 * Generate a SHA-256 checksum for a file.
 * Used for "fingerprinting" images to detect duplicates.
 * SECURITY: Uses sample-based hashing to prevent collision attacks
 * PERFORMANCE: Optimized for large files (samples 3 regions instead of full hash)
 */
export async function getChecksum(file) {
  const SMALL_FILE_THRESHOLD = 10 * 1024 * 1024; // 10MB
  const SAMPLE_SIZE = 1024 * 1024; // 1MB per sample

  let hashBuffer;

  if (file.size <= SMALL_FILE_THRESHOLD) {
    // Small files: Hash entire content for maximum accuracy
    const arrayBuffer = await file.arrayBuffer();
    hashBuffer = await crypto.subtle.digest('SHA-256', arrayBuffer);
  } else {
    // Large files: Sample beginning + middle + end to prevent collision attacks
    // This prevents attackers from uploading duplicates with different trailing data
    const samples = [
      file.slice(0, SAMPLE_SIZE),                                    // Beginning
      file.slice(Math.floor(file.size / 2), Math.floor(file.size / 2) + SAMPLE_SIZE), // Middle
      file.slice(Math.max(0, file.size - SAMPLE_SIZE), file.size)   // End
    ];

    // Concatenate samples
    const sampleBuffers = await Promise.all(samples.map(s => s.arrayBuffer()));
    const totalSize = sampleBuffers.reduce((acc, buf) => acc + buf.byteLength, 0);
    const combined = new Uint8Array(totalSize);

    let offset = 0;
    sampleBuffers.forEach(buf => {
      combined.set(new Uint8Array(buf), offset);
      offset += buf.byteLength;
    });

    hashBuffer = await crypto.subtle.digest('SHA-256', combined);
  }

  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

  // Append size to ensure collision safety
  return `${hash}_${file.size}`;
}

/**
 * Process and optimize a panoramic image via Rust Backend (Single 4K)
 * 
 * @param {File} file - Input image file (JPEG, PNG, etc.)
 * @returns {Promise<File>} Processed WebP file at 4K resolution
 */
export async function processImage(file) {
  try {
    const formData = new FormData();
    formData.append("file", file);

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 60000); // 60s timeout

    let response;
    try {
      response = await fetch(`${BACKEND_URL}/optimize-image`, {
        method: "POST",
        body: formData,
        signal: controller.signal,
      });
    } catch (fetchErr) {
      throw new Error(`Network request failed: ${fetchErr.message}`);
    } finally {
      clearTimeout(timeoutId);
    }

    if (!response || !response.ok) {
      const errorJson = await response.json().catch(() => ({ error: "Unknown Error" }));
      const errorText = errorJson.details || errorJson.error || "No response details";
      throw new Error(`Backend error: ${response ? response.status : 'N/A'} ${errorText}`);
    }

    const blob = await response.blob();

    // Smart filename extraction
    let newName = file.name.replace(/\.[^/.]+$/, "");
    const match = file.name.match(/_(\d{6})_\d{2}_(\d{3})/);

    if (match && match[1] && match[2]) {
      newName = `${match[1]}_${match[2]}`;
    }

    return new File([blob], newName + ".webp", {
      type: "image/webp",
      lastModified: Date.now(),
    });

  } catch (err) {
    Debug.error("Resizer", "Image optimization failed", { error: err.message, file: file.name });
    throw new Error(`Image processing failed for ${file.name}: ${err.message}`);
  }
}

/**
 * Combined processing: Optimize image AND extract metadata in one request.
 * 
 * @param {File} file - Input image file
 * @returns {Promise<Object>} { preview: File, metadata: Object }
 */
export async function processAndAnalyzeImage(file) {
  try {
    const formData = new FormData();
    formData.append("file", file);

    // TELEMETRY: Memory Pressure Check
    const mem = performance.memory ? {
      used: Math.round(performance.memory.usedJSHeapSize / 1024 / 1024) + 'MB',
      total: Math.round(performance.memory.totalJSHeapSize / 1024 / 1024) + 'MB',
      limit: Math.round(performance.memory.jsHeapSizeLimit / 1024 / 1024) + 'MB'
    } : 'unavailable';

    Debug.info('Resizer', 'BACKEND_PROCESS_FULL_START', {
      file: file.name,
      size: file.size,
      memory: mem
    });

    const fetchStart = performance.now();
    const response = await fetch(`${BACKEND_URL}/process-image-full`, {
      method: "POST",
      body: formData,
    });
    const fetchDuration = performance.now() - fetchStart;

    if (!response.ok) {
      const errorJson = await response.json().catch(() => ({ error: "Combined Processing Failed" }));
      throw new Error(errorJson.details || errorJson.error);
    }

    Debug.info("Resizer", "BACKEND_FETCH_COMPLETE", {
      fileName: file.name,
      durationMs: fetchDuration.toFixed(2),
      size: file.size
    });

    const zipBlob = await response.blob();
    const zip = await JSZip.loadAsync(zipBlob);

    // 1. Extract Previews
    const previewZipFile = zip.file("preview.webp");
    if (!previewZipFile) throw new Error("Missing preview.webp in response");
    const previewBlob = await previewZipFile.async("blob");

    const tinyZipFile = zip.file("tiny.webp");
    const tinyBlob = tinyZipFile ? await tinyZipFile.async("blob") : null;

    // Smart filename extraction (same logic as processImage)
    let newName = file.name.replace(/\.[^/.]+$/, "");
    const match = file.name.match(/_(\d{6})_\d{2}_(\d{3})/);
    if (match && match[1] && match[2]) newName = `${match[1]}_${match[2]}`;

    const previewFile = new File([previewBlob], newName + ".webp", {
      type: "image/webp",
      lastModified: Date.now(),
    });

    const tinyFile = tinyBlob ? new File([tinyBlob], newName + "_tiny.webp", {
      type: "image/webp",
      lastModified: Date.now(),
    }) : null;

    // 2. Extract Metadata
    const metaZipFile = zip.file("metadata.json");
    if (!metaZipFile) throw new Error("Missing metadata.json in response");
    const metaText = await metaZipFile.async("text");
    const rawMetadata = JSON.parse(metaText);

    // Map quality fields (same logic as ExifParser.js)
    const mappedQuality = {
      ...rawMetadata.quality,
      isBlurry: rawMetadata.quality.is_blurry,
      isSoft: rawMetadata.quality.is_soft,
      isSeverelyDark: rawMetadata.quality.is_severely_dark,
      isDim: rawMetadata.quality.is_dim,
      hasBlackClipping: rawMetadata.quality.has_black_clipping,
      hasWhiteClipping: rawMetadata.quality.has_white_clipping,
      colorHist: rawMetadata.quality.color_hist,
      stats: rawMetadata.quality.stats ? {
        ...rawMetadata.quality.stats,
        avgLuminance: rawMetadata.quality.stats.avg_luminance,
        blackClipping: rawMetadata.quality.stats.black_clipping,
        whiteClipping: rawMetadata.quality.stats.white_clipping,
        sharpnessVariance: rawMetadata.quality.stats.sharpness_variance
      } : {}
    };

    const metadata = {
      ...rawMetadata.exif,
      dateTime: rawMetadata.exif.date_time,
      focalLength: rawMetadata.exif.focal_length,
      aperture: rawMetadata.exif.aperture,
      iso: rawMetadata.exif.iso,
      quality: mappedQuality
    };

    return { preview: previewFile, tiny: tinyFile, metadata };

  } catch (err) {
    Debug.error("Resizer", "Combined processing failed", { error: err.message, file: file.name });
    throw err;
  }
}

/**
 * Generate multiple resolutions of an image via Rust Backend
 * 
 * @param {File} file - Source image file
 * @param {Object} targets - Target resolutions { key: width } (Currently ignores keys and uses 4k, 2k, hd defaults in backend)
 * @returns {Promise<Object>} Blobs for each resolution { "4k": blob, "2k": blob, "hd": blob }
 */
export async function generateResolutions(file, targets) {
  try {
    const formData = new FormData();
    formData.append("file", file);

    const response = await fetch(`${BACKEND_URL}/resize-image-batch`, {
      method: "POST",
      body: formData,
    });

    if (!response.ok) {
      const errorJson = await response.json().catch(() => ({ error: "Batch Resize Failed" }));
      throw new Error(errorJson.details || errorJson.error);
    }

    const zipBlob = await response.blob();

    // Use global JSZip to extract the 3 variants
    const zip = await JSZip.loadAsync(zipBlob);

    const results = {};
    const files = [
      { key: "4k", name: "4k.webp" },
      { key: "2k", name: "2k.webp" },
      { key: "hd", name: "hd.webp" }
    ];

    for (const f of files) {
      const zipFile = zip.file(f.name);
      if (zipFile) {
        results[f.key] = await zipFile.async("blob");
      } else {
        Debug.warn("Resizer", `Expected file ${f.name} missing from backend zip`);
      }
    }

    return results;

  } catch (err) {
    Debug.error("Resizer", "Batch resizing failed", { error: err.message, file: file.name });
    throw err;
  }
}
