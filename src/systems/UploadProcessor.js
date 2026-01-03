import { store } from "../store.js";
import { getChecksum, processImage } from "./Resizer.js";
import { analyzeImageQuality, calculateSimilarity } from "./ExifParser.js";
import { generateExifReport } from "./ExifReportGenerator.js";

/**
 * UploadProcessor System
 * 
 * Orchestrates the multi-phase processing of uploaded 360 images:
 * 1. Fingerprinting (Duplicate detection)
 * 2. Optimization (Resizing/Compression)
 * 3. Quality Analysis (Clarity, exposure, etc.)
 * 4. Sequential Clustering (Grouping similar scenes)
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

        const sceneDataList = [];
        const qualityResults = [];
        const startTime = Date.now();

        const updateProgress = (pct, msg, isProc = true, phase = "") => {
            if (progressCallback) progressCallback(pct, msg, isProc, phase);
        };

        // --- Phase 1: Fingerprinting (Checking duplicates) ---
        updateProgress(0, "Scanning files...", true, "Fingerprinting");
        for (let i = 0; i < totalFiles; i++) {
            const file = files[i];
            const id = await getChecksum(file);
            if (sceneDataList.some(s => s.id === id)) continue;

            sceneDataList.push({ id, original: file });
            const progress = Math.round(((i + 1) / totalFiles) * 33);
            updateProgress(progress, `Fingerprinting: ${i + 1}/${totalFiles}`);
        }

        // --- Phase 2: Optimization (Processing images) ---
        updateProgress(33, "Optimizing images...", true, "Optimization");
        const uniqueToProcess = sceneDataList.length;
        for (let i = 0; i < uniqueToProcess; i++) {
            const item = sceneDataList[i];
            const previewFile = await processImage(item.original);
            item.preview = previewFile;
            item.name = previewFile.name;
            item.originalName = item.original.name;

            const progress = 33 + Math.round(((i + 1) / uniqueToProcess) * 33);
            updateProgress(progress, `Optimizing: ${i + 1}/${uniqueToProcess}`);
        }

        // --- Phase 3: Analysis (Technical Quality) ---
        updateProgress(66, "Analyzing quality...", true, "Analysis");
        for (let i = 0; i < uniqueToProcess; i++) {
            const item = sceneDataList[i];
            const qualityData = await analyzeImageQuality(item.original);
            item.quality = qualityData;
            qualityResults.push({
                originalName: item.originalName,
                newName: item.name,
                quality: qualityData
            });

            const progress = 66 + Math.round(((i + 1) / uniqueToProcess) * 34);
            updateProgress(progress, `Analyzing: ${i + 1}/${uniqueToProcess}`);
        }

        const duration = ((Date.now() - startTime) / 1000).toFixed(1);

        // --- Phase 4: Sequential Scene Grouping ---
        updateProgress(95, "Syncing scene blocks...", true, "Clustering");

        // 1. Get all scenes (existing + new) and sort them by name (sequence)
        const allScenes = [
            ...store.state.scenes,
            ...sceneDataList
        ].sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true, sensitivity: 'base' }));

        // 2. Sequential Window-Based Clustering
        const SCENE_SIMILARITY_THRESHOLD = 0.65;
        let groupCounter = 0;

        for (let i = 0; i < allScenes.length; i++) {
            const current = allScenes[i];
            let foundMatch = null;

            for (let j = 1; j <= 3; j++) {
                const prevIdx = i - j;
                if (prevIdx < 0) break;

                const prev = allScenes[prevIdx];
                if (calculateSimilarity(current.quality, prev.quality) > SCENE_SIMILARITY_THRESHOLD) {
                    foundMatch = prev.colorGroup;
                    break;
                }
            }

            if (foundMatch) {
                current.colorGroup = foundMatch;
            } else {
                current.colorGroup = ++groupCounter;
            }
        }

        // 3. Commit to store
        store.addScenes(sceneDataList);
        updateProgress(100, `Completed in ${duration}s`, false);

        // 4. Handle EXIF meta-processing (Async)
        this.processExifMetadata(sceneDataList);

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
