import { DownloadSystem } from "./DownloadSystem.js";
// src/systems/ProjectManager.js
// Handles saving and loading virtual tour projects as ZIP files

/**
 * Save the current project as a ZIP file
 * @param {Object} state - The current store state
 * @param {Function} onProgress - Progress callback (done, total, message)
 */
export async function saveProject(state, onProgress) {
    const { VERSION } = await import("../version.js");

    // Validate we have scenes to save
    if (!state.scenes || state.scenes.length === 0) {
        console.error("No scenes to save.");
        return;
    }

    const tourName = state.tourName || "Virtual_Tour";
    const safeName = tourName.replace(/[^a-z0-9]/gi, "_").toLowerCase();
    const timestamp = new Date().toISOString();

    if (onProgress) onProgress(0, 100, "Initializing Save...");

    // Create ZIP structure
    const zip = new JSZip();
    const imagesFolder = zip.folder("images");

    // Build project metadata (without file blobs)
    const projectData = {
        version: VERSION,
        projectName: state.tourName,
        savedAt: timestamp,
        activeIndex: state.activeIndex,
        scenes: state.scenes.map(scene => ({
            id: scene.id, // THE STABLE ID
            name: scene.name,
            label: scene.label,
            category: scene.category,
            floor: scene.floor,
            hotspots: scene.hotspots.map(h => ({
                pitch: h.pitch,
                yaw: h.yaw,
                target: h.target,
                displayPitch: h.displayPitch,
                truePitch: h.truePitch,
                viewFrame: h.viewFrame || null
            }))
        }))
    };

    // Add metadata file
    zip.file("project.json", JSON.stringify(projectData, null, 2));

    // Add EXIF report if available
    if (state.exifReport) {
        const logsFolder = zip.folder("logs");
        const timestamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
        logsFolder.file(`EXIF_METADATA_${timestamp}.txt`, state.exifReport);
    }

    // Add all image files
    const totalSteps = state.scenes.length + 1; // +1 for final zip generation
    let completedSteps = 0;

    for (const scene of state.scenes) {
        if (onProgress) {
            const pct = Math.round((completedSteps / totalSteps) * 100);
            onProgress(pct, 100, `Saving: ${scene.name}`);
        }

        // Use the optimized WebP file (preview)
        const imageFile = scene.file;
        imagesFolder.file(scene.name, imageFile);

        completedSteps++;

        // Allow UI to breathe
        await new Promise(r => setTimeout(r, 10));
    }

    // Generate ZIP
    if (onProgress) onProgress(95, 100, "Creating ZIP archive...");

    const zipBlob = await zip.generateAsync({
        type: "blob",
        mimeType: "application/zip",
        compression: "DEFLATE",
        compressionOptions: { level: 6 }
    });

    // Download file with timestamp
    const dateStr = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    const filename = `${safeName}_${dateStr}.vt.zip`;

    if (onProgress) onProgress(100, 100, "Saving...");

    // Trigger download with cancellation detection
    // This will THROW if user cancels the file picker
    const saved = await DownloadSystem.saveBlobWithConfirmation(zipBlob, filename);

    if (saved) {
        if (onProgress) onProgress(100, 100, "Download Complete!");
    }

    return saved; // true = saved, error thrown = cancelled
}

/**
 * Load a project from a ZIP file
 * @param {File} zipFile - The uploaded .zip file
 * @param {Function} onProgress - Progress callback (done, total, message)
 * @returns {Object} - The loaded project data ready for store
 */
export async function loadProject(zipFile, onProgress) {
    if (onProgress) onProgress(0, 100, "Reading ZIP file...");

    try {
        // Load and parse ZIP
        const zip = await JSZip.loadAsync(zipFile);

        // Read project.json
        const projectJsonFile = zip.file("project.json");
        if (!projectJsonFile) {
            throw new Error("Invalid project file: project.json not found");
        }

        const projectJsonText = await projectJsonFile.async("text");
        const projectData = JSON.parse(projectJsonText);

        // Validate structure
        if (!projectData.scenes || !Array.isArray(projectData.scenes)) {
            throw new Error("Invalid project structure: scenes array missing");
        }

        if (onProgress) onProgress(10, 100, "Loading project metadata...");

        // Extract images folder
        const imagesFolder = zip.folder("images");
        if (!imagesFolder) {
            throw new Error("Invalid project file: images folder not found");
        }

        const imageFiles = [];
        const totalImages = projectData.scenes.length;
        let loadedImages = 0;

        // Load all images and reconstruct scene data
        const sceneDataList = [];

        for (const sceneMetadata of projectData.scenes) {
            const pct = 10 + Math.round((loadedImages / totalImages) * 80);
            if (onProgress) onProgress(pct, 100, `Loading: ${sceneMetadata.name}`);

            // Get image file from ZIP
            const imageFile = zip.file(`images/${sceneMetadata.name}`);
            if (!imageFile) {
                console.warn(`Warning: Image not found: ${sceneMetadata.name}`);
                continue;
            }

            // Convert to Blob, then to File
            const imageBlob = await imageFile.async("blob");
            const file = new File([imageBlob], sceneMetadata.name, { type: "image/webp" });

            // Reconstruct scene data structure
            sceneDataList.push({
                id: sceneMetadata.id || `legacy_${sceneMetadata.name}`,
                name: sceneMetadata.name,
                label: sceneMetadata.label || "",
                category: sceneMetadata.category || "indoor",
                floor: sceneMetadata.floor || "ground",
                file: file,
                originalFile: file,
                hotspots: sceneMetadata.hotspots || []
            });

            loadedImages++;

            // Allow UI to breathe
            await new Promise(r => setTimeout(r, 10));
        }

        if (onProgress) onProgress(95, 100, "Finalizing...");

        // Return structured data ready for store
        const loadedProject = {
            tourName: projectData.projectName || "Imported Tour",
            scenes: sceneDataList,
            activeIndex: projectData.activeIndex >= 0 && projectData.activeIndex < sceneDataList.length
                ? projectData.activeIndex
                : 0
        };

        if (onProgress) onProgress(100, 100, "Project Loaded!");

        return loadedProject;

    } catch (error) {
        console.error("Project load error:", error);
        if (onProgress) onProgress(0, 100, "", false);
        throw error; // Re-throw to be caught by caller
    }
}
