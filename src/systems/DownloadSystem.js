/**
 * DownloadSystem
 * 
 * Handles file downloads with proper browser compatibility and cleanup.
 * Uses the blob URL method with automatic resource management.
 * 
 * @module DownloadSystem
 */

import { BLOB_URL_CLEANUP_DELAY } from "../constants.js";

/**
 * Centralized download handler for all file types
 */
export class DownloadSystem {
    /**
     * Trigger a download for a Blob object
     * 
     * This method:
     * 1. Validates the blob has a proper MIME type
     * 2. Creates a temporary download link
     * 3. Programmatically clicks it
     * 4. Cleans up resources after download completes
     * 
     * @param {Blob} blob - The binary data to download
     * @param {string} filename - Desired filename (including extension)
     * 
     * @example
     * const jsonBlob = new Blob([JSON.stringify(data)], { type: 'application/json' });
     * DownloadSystem.saveBlob(jsonBlob, 'project.json');
     */
    static saveBlob(blob, filename) {
        console.log(`[DownloadSystem] Saving ${filename} (${blob.size} bytes, type: ${blob.type})`);

        // Ensure blob has a MIME type (required for Chrome to recognize file extension)
        if (!blob.type) {
            console.warn("[DownloadSystem] Blob missing type! Defaulting to application/octet-stream");
            blob = new Blob([blob], { type: "application/octet-stream" });
        }

        // Create temporary object URL for the blob
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");

        // Hide link to prevent visual flickering or layout shifts
        a.style.display = "none";
        a.style.pointerEvents = "none";
        a.href = url;
        a.download = filename;
        a.setAttribute("aria-hidden", "true"); // Accessibility: hide from screen readers

        document.body.appendChild(a);

        // Trigger download immediately
        a.click();

        // Cleanup: Remove link and revoke URL after sufficient delay
        // Delay ensures download completes even on slow connections
        setTimeout(() => {
            if (a.parentNode) document.body.removeChild(a);
            window.URL.revokeObjectURL(url); // Free memory
        }, BLOB_URL_CLEANUP_DELAY);
    }

    /**
     * Save a Blob with confirmation - detects if user cancels the file picker
     * 
     * Uses the modern File System Access API (showSaveFilePicker) which
     * properly returns a promise that rejects if user cancels.
     * Falls back to legacy saveBlob for unsupported browsers.
     * 
     * @param {Blob} blob - The binary data to download
     * @param {string} filename - Desired filename (including extension)
     * @returns {Promise<boolean>} - Resolves true if saved, rejects/false if cancelled
     */
    static async saveBlobWithConfirmation(blob, filename) {
        console.log(`[DownloadSystem] Saving with confirmation: ${filename}`);

        // Check if File System Access API is available
        if ('showSaveFilePicker' in window) {
            try {
                // Determine file type for the picker
                const extension = filename.split('.').pop().toLowerCase();
                const mimeType = blob.type || 'application/octet-stream';

                const options = {
                    suggestedName: filename,
                    types: [{
                        description: 'Project File',
                        accept: { [mimeType]: [`.${extension}`] }
                    }]
                };

                // This will THROW an AbortError if user cancels!
                const handle = await window.showSaveFilePicker(options);
                const writable = await handle.createWritable();
                await writable.write(blob);
                await writable.close();

                console.log(`[DownloadSystem] File saved successfully: ${filename}`);
                return true; // User saved the file
            } catch (err) {
                if (err.name === 'AbortError') {
                    console.log(`[DownloadSystem] User cancelled save dialog`);
                    throw new Error('USER_CANCELLED'); // Explicit cancellation
                }
                console.error(`[DownloadSystem] Save error:`, err);
                throw err; // Re-throw other errors
            }
        } else {
            // Fallback for browsers without File System Access API
            console.log(`[DownloadSystem] Fallback to legacy save (no cancellation detection)`);
            this.saveBlob(blob, filename);
            return true; // Assume success (can't detect cancellation)
        }
    }

    /**
     * Generate and download a ZIP file
     * 
     * Convenience method for JSZip library integration
     * 
     * @param {JSZip} zip - Configured JSZip instance
     * @param {string} filename - Output filename (should end with .zip)
     * 
     * @example
     * const zip = new JSZip();
     * zip.file("readme.txt", "Hello World");
     * DownloadSystem.downloadZip(zip, 'archive.zip');
     */
    static downloadZip(zip, filename) {
        if (!zip) {
            console.error("[DownloadSystem] No ZIP object provided");
            return;
        }

        zip.generateAsync({ type: "blob" }).then((content) => {
            this.saveBlob(content, filename);
        });
    }
}
