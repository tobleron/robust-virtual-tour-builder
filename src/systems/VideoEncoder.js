import { CacheSystem } from "./CacheSystem.js";
import { DownloadSystem } from "./DownloadSystem.js";
import {
    FFMPEG_CRF_QUALITY,
    FFMPEG_PRESET,
    FFMPEG_CORE_VERSION,
} from "../constants.js";

/**
 * VideoEncoder System
 * 
 * Handles high-quality video transcoding (e.g., WebM to MP4) using FFmpeg.wasm.
 * Includes intelligent caching for FFmpeg core files to avoid repeated downloads.
 */
export const VideoEncoder = {
    /**
     * Transcode a WebM blob to an MP4 file using FFmpeg.
     * 
     * @param {Blob} webmBlob - The source WebM video blob.
     * @param {string} baseName - The base filename (without extension).
     * @param {Function} progressCallback - Optional callback for progress reporting (0-100).
     * @returns {Promise<Blob>} - Resolves with the MP4 blob.
     */
    async transcodeWebMToMP4(webmBlob, baseName, progressCallback = null) {
        const logBuffer = [];
        const log = (msg) => {
            const entry = `[${new Date().toLocaleTimeString()}] ${msg}`;
            console.log("[VideoEncoder] " + entry);
            if (window.appLog) window.appLog.push("[AI Encoder] " + entry);
            logBuffer.push(entry);
            if (logBuffer.length > 50) logBuffer.shift();
        };

        log("Starting FFmpeg Sequence...");

        try {
            // 1. DYNAMIC ESM IMPORT
            log("Importing FFmpeg from ESM...");
            let FFmpegModule, UtilModule;

            try {
                FFmpegModule = await import("../libs/esm-ffmpeg/index.js");
            } catch (err) { throw new Error("Failed to import @ffmpeg/ffmpeg: " + String(err)); }

            try {
                UtilModule = await import("../libs/esm-util/index.js");
            } catch (err) { throw new Error("Failed to import @ffmpeg/util: " + String(err)); }

            const { FFmpeg } = FFmpegModule;
            const { fetchFile } = UtilModule;

            log("Instantiating FFmpeg...");
            const ffmpeg = new FFmpeg();

            ffmpeg.on("log", ({ message }) => log(`[FFmpeg Internal] ${message}`));

            ffmpeg.on("progress", ({ progress }) => {
                const pct = Math.round(progress * 100);
                if (progressCallback) progressCallback(pct);
            });

            // 2. INTELLIGENT CACHING
            log("Checking cache for FFmpeg core files...");
            const cacheKey = `ffmpeg-core-${FFMPEG_CORE_VERSION}`;
            const cachedCore = await CacheSystem.get(cacheKey);

            if (cachedCore) {
                log("✓ FFmpeg core found in cache (instant load)");
                try {
                    const coreURL = URL.createObjectURL(cachedCore.data.core);
                    const wasmURL = URL.createObjectURL(cachedCore.data.wasm);

                    await ffmpeg.load({ coreURL, wasmURL });

                    URL.revokeObjectURL(coreURL);
                    URL.revokeObjectURL(wasmURL);
                    log("✓ FFmpeg loaded from cache successfully");
                } catch (err) {
                    log("Cache load failed, falling back to CDN download");
                    console.error("Cache load error:", err);
                    await ffmpeg.load();
                }
            } else {
                log("FFmpeg core not cached. Downloading from CDN...");
                log("This is a one-time download (~31 MB). Future sessions will load instantly.");

                await ffmpeg.load();
                log("✓ FFmpeg downloaded successfully");

                // Cache the core files for next time
                try {
                    log("Caching FFmpeg core files for future use...");
                    const coreURL = `https://unpkg.com/@ffmpeg/core@${FFMPEG_CORE_VERSION}/dist/umd/ffmpeg-core.js`;
                    const wasmURL = `https://unpkg.com/@ffmpeg/core@${FFMPEG_CORE_VERSION}/dist/umd/ffmpeg-core.wasm`;

                    const [coreBlob, wasmBlob] = await Promise.all([
                        fetch(coreURL).then(r => r.blob()),
                        fetch(wasmURL).then(r => r.blob()),
                    ]);

                    await CacheSystem.set(cacheKey, { core: coreBlob, wasm: wasmBlob }, {
                        version: FFMPEG_CORE_VERSION,
                        cachedAt: Date.now(),
                    });
                    log("✓ FFmpeg core cached for future sessions");
                } catch (cacheErr) {
                    log("Warning: Failed to cache FFmpeg core (non-fatal)");
                    console.warn("Cache save error:", cacheErr);
                }
            }

            // 3. RUN TRANSCODE
            log("FFmpeg Loaded. Writing File...");
            const data = await fetchFile(webmBlob);
            await ffmpeg.writeFile('input.webm', data);

            log("Running Conversion (Highest Quality)...");
            await ffmpeg.exec([
                '-i', 'input.webm',
                '-c:v', 'libx264',
                '-preset', FFMPEG_PRESET,
                '-crf', String(FFMPEG_CRF_QUALITY),
                'output.mp4'
            ]);

            log("Reading Output...");
            const outputData = await ffmpeg.readFile('output.mp4');
            const mp4Blob = new Blob([outputData.buffer], { type: 'video/mp4' });

            log("Clean up...");
            ffmpeg.terminate();

            const filename = `${baseName}.mp4`;
            log(`MP4 Conversion Success. Saving as ${filename}`);
            DownloadSystem.saveBlob(mp4Blob, filename);

            return mp4Blob;
        } catch (err) {
            console.error("[VideoEncoder] MP4 Conversion Failed", err);
            log("MP4 Conversion Failed: " + err.message);
            throw err;
        }
    }
};
