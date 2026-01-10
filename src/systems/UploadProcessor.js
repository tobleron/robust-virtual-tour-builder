import { store } from "../store.js";
import { getChecksum, processAndAnalyzeImage, checkBackendHealth } from "./Resizer.js";
import { calculateSimilarity } from "./ExifParser.js";
import { generateExifReport } from "./ExifReportGenerator.js";
import { notify } from "../utils/NotificationSystem.js";

/**
 * UploadProcessor System
 * 
 * Orchestrates the multi-phase processing of uploaded 360 images:
 * 1. Fingerprinting (Duplicate detection)
 * 2. Combined Optimization & Analysis (Resizing + Quality Check)
 * 3. Sequential Clustering (Grouping similar scenes)
 */
export const UploadProcessor = {
    /**
     * Process a list of files and add them to the store as scenes.
     * 
     * @param {File[]} files - Array of image files to process.
     * @param {Function} progressCallback - Callback for progress updates (pct, message, isProcessing, phase).
     * @returns {Promise<Object>} - Quality results for reporting.
     */
    async processUploads(files, progressCallback = null) {
        const totalFiles = files.length;
        if (totalFiles === 0) return { qualityResults: [] };

        // SECURITY: Validate MIME types
        const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
        const validFiles = files.filter(f => {
            if (!ALLOWED_TYPES.includes(f.type)) {
                console.warn(`[UploadProcessor] Skipping non-image file: ${f.name} (${f.type})`);
                notify(`Skipped invalid file: ${f.name}`, "warning");
                return false;
            }
            return true;
        });

        if (validFiles.length === 0) {
            notify("No valid image files selected!", "error");
            return { qualityResults: [] };
        }

        const updateProgress = (pct, msg, isProc = true, phase = "") => {
            if (progressCallback) progressCallback(pct, msg, isProc, phase);
        };

        // --- Phase 0: Health Check ---
        updateProgress(0, "Checking backend...", true, "Health Check");
        const isBackendUp = await checkBackendHealth();
        if (!isBackendUp) {
            console.error("[UploadProcessor] Backend is offline.");
            updateProgress(100, "Error: Backend Offline", false);
            notify("Backend Server Not Connected! Please ensure the Rust backend is running on port 8080.", "error");
            return { qualityResults: [] };
        }

        const sceneDataList = [];
        const qualityResults = [];
        const startTime = Date.now();

        // Helper for concurrency
        const hardwareLimit = navigator.hardwareConcurrency || 4;
        const fingerprintConcurrency = Math.min(hardwareLimit, 8);
        const optimizationConcurrency = Math.max(1, Math.floor(hardwareLimit / 2));

        const runConcurrent = async (items, taskFn, concurrency = 4, onProgress) => {
            const results = [];
            const executing = [];
            let completed = 0;

            for (const item of items) {
                const p = Promise.resolve().then(() => taskFn(item));
                results.push(p);

                const e = p.then((res) => {
                    executing.splice(executing.indexOf(e), 1);
                    completed++;
                    if (onProgress) onProgress(completed, items.length);
                    return res;
                });
                executing.push(e);

                if (executing.length >= concurrency) {
                    await Promise.race(executing);
                }
            }
            return Promise.all(results);
        };

        // --- Phase 1: Fingerprinting (Checking duplicates) ---
        updateProgress(0, "Scanning files...", true, "Fingerprinting");

        const fingerprintResults = await runConcurrent(files, async (file) => {
            const id = await getChecksum(file);
            return { id, original: file };
        }, fingerprintConcurrency, (completed, total) => {
            const progress = Math.round((completed / total) * 20);
            updateProgress(progress, `Fingerprinting: ${completed}/${total}`);
        });

        // Filter duplicates while preserving order
        const seenIds = new Set(store.state.scenes.map(s => s.id));
        for (const res of fingerprintResults) {
            if (!seenIds.has(res.id)) {
                sceneDataList.push(res);
                seenIds.add(res.id);
            }
        }

        // --- Phase 2: Combined Optimization & Analysis ---
        updateProgress(20, "Processing images...", true, "Processing");
        const uniqueToProcess = sceneDataList.length;

        const processingResults = await runConcurrent(sceneDataList, async (item) => {
            try {
                const { preview, tiny, metadata } = await processAndAnalyzeImage(item.original);
                item.preview = preview;
                item.tiny = tiny; // Store the low-res progressive preview
                item.name = preview.name;
                item.originalName = item.original.name;
                item.quality = metadata.quality;
                item.metadata = metadata; // Keep full metadata (EXIF)

                return {
                    originalName: item.originalName,
                    newName: item.name,
                    quality: item.quality
                };
            } catch (err) {
                console.error(`[UploadProcessor] Processing failed for ${item.original.name}:`, err);
                item.error = err.message;
                item.skipped = true;
                return null;
            }
        }, optimizationConcurrency, (completed, total) => {
            const progress = 20 + Math.round((completed / total) * 75);
            updateProgress(progress, `Processing: ${completed}/${total}`);
        });

        // Filter out failed items and collect quality results
        let validItems = sceneDataList.filter(item => !item.skipped);
        qualityResults.push(...processingResults.filter(Boolean));

        if (validItems.length === 0 && uniqueToProcess > 0) {
            const lastError = sceneDataList[sceneDataList.length - 1].error || "Unknown Error";
            console.error("[UploadProcessor] All images failed to process:", lastError);
            updateProgress(100, "Processing Failed", false);
            notify(`Upload Failed! Reason: ${lastError}`, "error");
            return { qualityResults: [], duration: ((Date.now() - startTime) / 1000).toFixed(1) };
        }

        const duration = ((Date.now() - startTime) / 1000).toFixed(1);

        // --- Phase 3: Sequential Scene Grouping ---
        updateProgress(95, "Syncing scene blocks...", true, "Clustering");

        // Small yield to let UI update progress bar to 95%
        await new Promise(resolve => setTimeout(resolve, 50));

        // Sort new items by filename
        validItems.sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true, sensitivity: 'base' }));

        // 1. Get reference to existing scenes
        const existingScenes = store.state.scenes || [];
        const SCENE_SIMILARITY_THRESHOLD = 0.65;
        let lastKnownGroup = existingScenes.length > 0 ? existingScenes[existingScenes.length - 1].colorGroup : 0;

        console.log(`[UploadProcessor] Starting clustering for ${validItems.length} new items...`);

        // 2. Cluster only the NEW items to minimize work
        for (let i = 0; i < validItems.length; i++) {
            // Yield every 10 items to keep UI alive and responsive
            if (i > 0 && i % 10 === 0) {
                updateProgress(95, `Clustering: ${i}/${validItems.length}`, true);
                await new Promise(resolve => setTimeout(resolve, 10));
            }

            const current = validItems[i];
            let foundMatch = null;

            // Defensive check for quality data
            if (current && current.quality) {
                // Check against previous NEW items first
                for (let j = 1; j <= 3; j++) {
                    const prevIdx = i - j;
                    if (prevIdx >= 0) {
                        const prev = validItems[prevIdx];
                        if (prev && prev.quality && calculateSimilarity(current.quality, prev.quality) > SCENE_SIMILARITY_THRESHOLD) {
                            foundMatch = prev.colorGroup;
                            break;
                        }
                    } else if (existingScenes.length > 0) {
                        // Fallback to checking the very last existing scenes
                        const lastExistingIdx = existingScenes.length + prevIdx;
                        if (lastExistingIdx >= 0) {
                            const prev = existingScenes[lastExistingIdx];
                            if (prev && prev.quality && calculateSimilarity(current.quality, prev.quality) > SCENE_SIMILARITY_THRESHOLD) {
                                foundMatch = prev.colorGroup;
                                break;
                            }
                        }
                    }
                }
            }

            if (foundMatch) {
                current.colorGroup = foundMatch;
            } else {
                current.colorGroup = ++lastKnownGroup;
            }
        }

        // 3. Commit to store
        console.log("[UploadProcessor] Finalizing Store Update...");
        updateProgress(98, "Updating Sidebar...", true, "Finalizing");

        // Final yield to ensure progress text is visible
        await new Promise(resolve => setTimeout(resolve, 100));

        try {
            store.addScenes(validItems);
            console.log("[UploadProcessor] Store update successful.");
        } catch (err) {
            console.error("[UploadProcessor] CRITICAL: Store update failed:", err);
            notify("Store Update Error! Check console.", "error");
        }

        updateProgress(100, `Completed in ${duration}s`, false);


        // 4. Handle EXIF meta-processing (Async)
        this.processExifMetadata(validItems);

        return { qualityResults, duration };
    },

    /**
     * Process EXIF metadata to generate reports and suggest tour names.
     * 
     * @param {Object[]} sceneDataList 
     */
    async processExifMetadata(sceneDataList) {
        if (!sceneDataList || sceneDataList.length === 0) return;

        console.log(`🔍 [UploadProcessor] Starting EXIF metadata processing for ${sceneDataList.length} items...`);

        try {
            const result = await generateExifReport(sceneDataList);
            store.state.exifReport = result.report;

            console.log(`🔍 [UploadProcessor] Suggested Name: "${result.suggestedName}" | Current Tour Name: "${store.state.tourName}"`);

            if (result.suggestedName && !store.state.tourName) {
                console.log(`✅ [UploadProcessor] Setting Tour Name to: ${result.suggestedName}`);
                store.setTourName(result.suggestedName);
            } else {
                console.log(`⚠️ [UploadProcessor] Skipped setting name. (Suggested: ${!!result.suggestedName}, Current: ${!!store.state.tourName})`);
            }
            console.log(`clipboard EXIF Report generated and stored in memory`);
        } catch (err) {
            console.warn("EXIF Report generation failed:", err.message);
            console.error(err);
        }
    }
};
