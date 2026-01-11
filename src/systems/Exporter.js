import { notify } from "../utils/NotificationSystem.js";
import { DownloadSystem } from "./DownloadSystem.js";
import { generateTourHTML, generateEmbedCodes, generateExportIndex } from "./TourHTMLTemplate.js";
import { BACKEND_URL } from "../constants.js";
import { Debug } from "../utils/Debug.js";

/**
 * Fetch a library file from the libs folder
 * @param {string} filename - Library filename
 * @returns {Promise<Blob>} Library file blob
 */
async function fetchLib(filename) {
    const response = await fetch(`src/libs/${filename}`);
    if (!response.ok) throw new Error(`Missing Library: ${filename}`);
    return await response.blob();
}

/**
 * Upload and process via XHR to track progress
 * @param {FormData} formData 
 * @param {Function} onProgress 
 * @returns {Promise<Blob>}
 */
function uploadAndProcess(formData, onProgress) {
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open("POST", `${BACKEND_URL}/create-tour-package`);
        xhr.timeout = 300000; // 5 minutes

        // Upload Progress (0-50%)
        xhr.upload.onprogress = (e) => {
            if (e.lengthComputable) {
                const percent = Math.round((e.loaded / e.total) * 50);
                if (onProgress) onProgress(percent, 100, `Uploading: ${Math.round((e.loaded / 1024 / 1024))}MB sent`);
            }
        };

        xhr.onload = () => {
            if (xhr.status === 200) {
                if (onProgress) onProgress(100, 100, "Download Ready");
                resolve(xhr.response);
            } else {
                let errorMsg = "Backend Error";
                try {
                    // Try to parse JSON error
                    if (xhr.responseType === "blob") {
                        // If blob, we need to read it to text to see error
                        const reader = new FileReader();
                        reader.onload = () => {
                            try {
                                const json = JSON.parse(reader.result);
                                reject(new Error(json.details || json.error));
                            } catch (e) {
                                reject(new Error(`Backend returned status ${xhr.status}`));
                            }
                        };
                        reader.readAsText(xhr.response);
                    } else {
                        const json = JSON.parse(xhr.responseText);
                        reject(new Error(json.details || json.error));
                    }
                } catch (e) {
                    reject(new Error(`Backend returned status ${xhr.status}`));
                }
            }
        };

        xhr.onerror = () => reject(new Error("Network Error - Check Backend Connection"));
        xhr.ontimeout = () => reject(new Error("Request Timed Out (5m limit)"));

        // When upload is complete, we enter "Processing" state (50-90%)
        xhr.upload.onload = () => {
            if (onProgress) onProgress(50, 100, "Processing on Server (Please Wait)...");
        };

        xhr.responseType = "blob";
        xhr.send(formData);
    });
}

/**
 * Export the virtual tour as a ZIP file via Rust Backend
 * @param {Array} scenes - Array of scene objects
 * @param {Function} onProgress - Progress callback (done, total, message)
 */
export async function exportTour(scenes, onProgress) {
    const { store } = await import("../store.js");
    const { VERSION } = await import("../version.js");
    const tourName = store.state.tourName || "Virtual_Tour";
    const safeName = tourName.replace(/[^a-z0-9]/gi, "_").toLowerCase();

    if (onProgress) onProgress(0, 100, "Preparing assets...");

    try {
        const formData = new FormData();

        // 1. Generate HTML Templates
        const html4k = generateTourHTML(scenes, tourName, true, "4k", 120, 60, VERSION);
        const html2k = generateTourHTML(scenes, tourName, true, "2k", 90, 50, VERSION);
        const htmlHd = generateTourHTML(scenes, tourName, true, "hd", 60, 40, VERSION);
        const htmlIndex = generateExportIndex(tourName, VERSION);
        const embed = generateEmbedCodes(tourName, VERSION);

        formData.append("html_4k", html4k);
        formData.append("html_2k", html2k);
        formData.append("html_hd", htmlHd);
        formData.append("html_index", htmlIndex);
        formData.append("embed_codes", embed);

        // 2. Append Libraries
        try {
            const panJS = await fetchLib("pannellum.js");
            const panCSS = await fetchLib("pannellum.css");
            formData.append("pannellum.js", panJS, "pannellum.js");
            formData.append("pannellum.css", panCSS, "pannellum.css");
        } catch (e) {
            console.error("Failed to load libraries:", e);
        }

        // 3. Append Logo (if exists)
        try {
            const logoRes = await fetch("images/logo.png");
            if (logoRes.ok) {
                const logoBlob = await logoRes.blob();
                formData.append("logo.png", logoBlob, "logo.png");
            }
        } catch (e) {
            console.warn("Logo not found, skipping");
        }

        // 4. Append Scene Images (Raw)
        scenes.forEach((s, idx) => {
            const file = s.originalFile || s.file;
            formData.append(`scene_${idx}`, file, s.name);
        });

        // 5. Send via XHR
        const zipBlob = await uploadAndProcess(formData, onProgress);

        if (onProgress) onProgress(100, 100, "Saving...");
        DownloadSystem.saveBlob(zipBlob, `Export_RMX_${safeName}_v${VERSION}.zip`);

    } catch (err) {
        console.error("Export failed:", err);
        Debug.error("Exporter", "Tour Export Failed", { error: err.message });
        notify(`Export Failed: ${err.message}`, "error");

        if (onProgress) onProgress(0, 0, "Failed");
    }
}