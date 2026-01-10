import { DownloadSystem } from "./DownloadSystem.js";
import { BACKEND_URL } from "../constants.js";
import { Debug } from "../utils/Debug.js";

/**
 * VideoEncoder System (Backend Connected)
 * 
 * Offloads video transcoding to the Rust backend.
 * Replaces the heavy FFmpeg.wasm implementation.
 */
export const VideoEncoder = {
    /**
     * Transcode a WebM blob to an MP4 file using the Backend.
     * 
     * @param {Blob} webmBlob - The source WebM video blob.
     * @param {string} baseName - The base filename (without extension).
     * @param {Function} progressCallback - (Deprecated/Fake) Progress reporting.
     * @returns {Promise<Blob>} - Resolves with the MP4 blob.
     */
    async transcodeWebMToMP4(webmBlob, baseName, progressCallback = null) {
        const log = (msg) => {
            const entry = `[${new Date().toLocaleTimeString()}] ${msg}`;
            console.log("[VideoEncoder] " + entry);
            if (window.appLog) window.appLog.push("[Native Encoder] " + entry);
        };

        log("Starting Backend Transcode...");

        try {
            if (progressCallback) progressCallback(10); // Fake start progress

            const formData = new FormData();
            // Backend expects a file field, name doesn't matter much but consistent is good
            formData.append("file", webmBlob, "input.webm");

            if (webmBlob.size < 1024) {
                const msg = `Video file is too small (${webmBlob.size} bytes). Recording likely failed.`;
                Debug.error("VideoEncoder", msg);
                throw new Error(msg);
            }

            log("Uploading to Rust Backend...");
            const response = await fetch(`${BACKEND_URL}/transcode-video`, {
                method: "POST",
                body: formData,
            });

            if (progressCallback) progressCallback(50); // Upload done, processing...

            if (!response.ok) {
                let errorDetails = "Unknown Backend Error";
                const responseText = await response.text();
                try {
                    const errorJson = JSON.parse(responseText);
                    errorDetails = `${errorJson.error}${errorJson.details ? ": " + errorJson.details : ""}`;
                } catch (e) {
                    errorDetails = responseText || `Status ${response.status}`;
                }

                Debug.error("VideoEncoder", `Backend Transcode Failed (${response.status})`, { details: errorDetails });
                throw new Error(errorDetails);
            }

            log("Downloading processed MP4...");
            const mp4Blob = await response.blob();

            if (progressCallback) progressCallback(100);

            const filename = `${baseName}.mp4`;
            log(`Success. Saving as ${filename} (${(mp4Blob.size / 1024 / 1024).toFixed(2)} MB)`);

            DownloadSystem.saveBlob(mp4Blob, filename);

            return mp4Blob;
        } catch (err) {
            console.error("[VideoEncoder] MP4 Conversion Failed", err);
            Debug.error("VideoEncoder", "MP4 Conversion Failed", { error: err.message });
            log("MP4 Conversion Failed: " + err.message);
            throw err;
        }
    }
};