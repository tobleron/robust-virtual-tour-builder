import { DownloadSystem } from "./DownloadSystem.js";
import { generateTourHTML, generateEmbedCodes } from "./TourHTMLTemplate.js";

/**
 * Generate multiple resolutions of an image
 * @param {File} file - Source image file
 * @param {Object} targets - Target resolutions { key: width }
 * @returns {Promise<Object>} Blobs for each resolution
 */
async function generateResolutions(file, targets) {
    return new Promise((resolve, reject) => {
        const img = new Image();
        const url = URL.createObjectURL(file);
        img.onload = async () => {
            const results = {};
            for (const [key, width] of Object.entries(targets)) {
                const canvas = document.createElement("canvas");
                const scale = width / img.width;
                canvas.width = width;
                canvas.height = img.height * scale;
                const ctx = canvas.getContext("2d");
                ctx.imageSmoothingEnabled = true;
                ctx.imageSmoothingQuality = "high";
                ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

                const blob = await new Promise(res => canvas.toBlob(res, "image/webp", 1.0));
                results[key] = blob;
            }
            URL.revokeObjectURL(url);
            resolve(results);
        };
        img.onerror = () => {
            URL.revokeObjectURL(url);
            reject(new Error("Failed to load image for resizing"));
        };
        img.src = url;
    });
}

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
 * Export the virtual tour as a ZIP file
 * @param {Array} scenes - Array of scene objects
 * @param {Function} onProgress - Progress callback (done, total, message)
 */
export async function exportTour(scenes, onProgress) {
    const { store } = await import("../store.js");
    const { VERSION } = await import("../version.js");
    const tourName = store.state.tourName || "Virtual_Tour";
    const safeName = tourName.replace(/[^a-z0-9]/gi, "_").toLowerCase();

    const zip = new JSZip();
    const f4k = zip.folder("tour_4k");
    const f2k = zip.folder("tour_2k");
    const fhd = zip.folder("tour_hd");

    const folders = [f4k, f2k, fhd];
    folders.forEach((f) => {
        f.folder("assets");
        f.folder("libs");
    });

    // Bundle Pannellum libraries
    try {
        const panJS = await fetchLib("pannellum.js");
        const panCSS = await fetchLib("pannellum.css");
        folders.forEach((f) => {
            f.folder("libs").file("pannellum.js", panJS);
            f.folder("libs").file("pannellum.css", panCSS);
        });
    } catch (e) {
        console.error("Error bundling libraries:", e);
        return;
    }

    // Bundle logo if available
    let hasLogo = false;
    try {
        const response = await fetch("images/logo.png");
        if (response.ok) {
            const logoBlob = await response.blob();
            folders.forEach((f) => {
                f.folder("assets").file("logo.png", logoBlob);
            });
            hasLogo = true;
        }
    } catch (e) {
        console.warn("Logo not found");
    }

    // Process scenes with progress updates
    const totalSteps = scenes.length;
    let completedSteps = 0;

    for (const s of scenes) {
        // UI UNBLOCK - Allow DOM repaint
        await new Promise(r => setTimeout(r, 0));

        // Always use originalFile (source JPG) for best quality
        const sourceFile = s.originalFile || s.file;

        if (onProgress) {
            onProgress(completedSteps, totalSteps, `Processing: ${s.name}`);
        }

        try {
            const blobs = await generateResolutions(sourceFile, {
                "4k": 4096,
                "2k": 2048,
                "hd": 1280
            });
            f4k.folder("assets").file(`images/${s.name}`, blobs["4k"]);
            f2k.folder("assets").file(`images/${s.name}`, blobs["2k"]);
            fhd.folder("assets").file(`images/${s.name}`, blobs["hd"]);
        } catch (err) {
            console.error(`Failed to resize ${s.name}, falling back to source`, err);
            folders.forEach(f => f.folder("assets").file(`images/${s.name}`, sourceFile));
        }
        completedSteps++;
    }

    if (onProgress) onProgress(totalSteps, totalSteps, "Bundling Zip...");
    await new Promise(r => setTimeout(r, 100));

    // Generate HTML files using template module
    f4k.file("index.html", generateTourHTML(scenes, tourName, hasLogo, "4k", 120, 60, VERSION));
    f2k.file("index.html", generateTourHTML(scenes, tourName, hasLogo, "2k", 90, 50, VERSION));
    fhd.file("index.html", generateTourHTML(scenes, tourName, hasLogo, "hd", 60, 40, VERSION));

    // Generate embed codes
    zip.file("embed_codes.txt", generateEmbedCodes(tourName, VERSION));

    // Generate and download ZIP
    const content = await zip.generateAsync({
        type: "blob",
        mimeType: "application/zip"
    });
    DownloadSystem.saveBlob(content, `Remax_${safeName}_v${VERSION}.zip`);
}
