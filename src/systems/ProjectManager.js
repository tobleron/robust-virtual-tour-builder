import { DownloadSystem } from "./DownloadSystem.js";
import { Debug } from "../utils/Debug.js";

/**
 * Helper to run worker tasks
 */
async function runZipTask(type, payload, onProgress) {
    // PRE-CHECK: If payload is large or needs raw binary access, handle it here
    let transfer = [];
    if (type === 'LOAD_PROJECT' && (payload instanceof File || payload instanceof Blob)) {
        if (payload.size === 0) {
            throw new Error("Cannot load empty file (0 bytes).");
        }
        // Read file as ArrayBuffer for reliable worker transmission
        const buffer = await payload.arrayBuffer();
        payload = buffer;
        transfer = [buffer];
    }

    return new Promise((resolve, reject) => {
        // Vite-compatible worker instantiation - using classic type to support importScripts
        const worker = new Worker(new URL('../workers/ZipWorker.js', import.meta.url), { type: 'classic' });

        worker.onmessage = (e) => {
            const { type: resType, payload: resPayload } = e.data;
            if (resType === 'PROGRESS' && onProgress) {
                onProgress(resPayload.pct, 100, resPayload.message);
            } else if (resType === 'SAVE_COMPLETE' || resType === 'LOAD_COMPLETE') {
                worker.terminate();
                resolve(resPayload);
            } else if (resType === 'ERROR') {
                worker.terminate();
                reject(new Error(resPayload));
            }
        };

        worker.onerror = (err) => {
            worker.terminate();
            reject(err);
        };

        worker.postMessage({ type, payload }, transfer);
    });
}

/**
 * Save the current project as a ZIP file
 */
export async function saveProject(state, onProgress) {
    const { VERSION } = await import("../version.js");

    if (!state.scenes || state.scenes.length === 0) {
        console.error("No scenes to save.");
        return;
    }

    const tourName = state.tourName || "Virtual_Tour";
    const safeName = tourName.replace(/[^a-z0-9]/gi, "_").toLowerCase();
    const dateStr = new Date().toISOString().split('T')[0];
    const filename = `Saved_RMX_${safeName}_v${VERSION}_${dateStr}.vt.zip`;

    // 1. Acquire File Handle EARLY (while user gesture is still active)
    let fileHandle = null;
    let useFileHandle = 'showSaveFilePicker' in window;

    if (useFileHandle) {
        try {
            // Request handle for ZIP file
            fileHandle = await DownloadSystem.getFileHandle(filename, 'application/zip');
        } catch (err) {
            if (err.name === 'AbortError') {
                console.log("Project save cancelled by user.");
                if (onProgress) onProgress(0, 0, "Cancelled");
                throw new Error('USER_CANCELLED');
            }
            console.warn("[ProjectManager] File picker failed, falling back to legacy download:", err);
            useFileHandle = false;
        }
    }

    if (onProgress) onProgress(0, 100, "Preparing metadata...");

    const projectData = {
        version: VERSION,
        projectName: state.tourName,
        savedAt: new Date().toISOString(),
        activeIndex: state.activeIndex,
        deletedSceneIds: state.deletedSceneIds || [],
        scenes: state.scenes.map(scene => ({
            id: scene.id,
            name: scene.name,
            label: scene.label,
            category: scene.category,
            floor: scene.floor,
            isAutoForward: scene.isAutoForward || false,
            quality: scene.quality || null,
            colorGroup: scene.colorGroup || null,
            hotspots: scene.hotspots.map(h => ({
                pitch: h.pitch,
                yaw: h.yaw,
                target: h.target,
                displayPitch: h.displayPitch,
                truePitch: h.truePitch,
                // PERSISTENCE FIX: Save start position (Point A) for simulation/visuals
                startPitch: h.startPitch,
                startYaw: h.startYaw,
                startHfov: h.startHfov,
                viewFrame: h.viewFrame || null,
                returnViewFrame: h.returnViewFrame || null,
                isReturnLink: h.isReturnLink || false,
                targetYaw: h.targetYaw,
                targetPitch: h.targetPitch,
                // MULTI-POINT LINKS: Save ALL intermediate waypoints
                waypoints: h.waypoints || []
            }))

        }))
    };

    // Prepare files for worker (must be plain objects/blobs)
    const files = state.scenes.map(s => ({
        name: s.name,
        blob: s.file // Blobs are transferable
    }));

    try {
        // 2. Heavy Lifting (Zip Generation) - takes time
        const zipBlob = await runZipTask('SAVE_PROJECT', {
            projectData,
            files,
            exifReport: state.exifReport
        }, onProgress);

        if (onProgress) onProgress(100, 100, "Saving...");

        // 3. Write to File (using handle acquired in step 1, or legacy fallback)
        if (useFileHandle && fileHandle) {
            await DownloadSystem.writeFileToHandle(fileHandle, zipBlob);
            if (onProgress) onProgress(100, 100, "Saved!");
        } else {
            // Legacy download (anchor click)
            DownloadSystem.saveBlob(zipBlob, filename);
            if (onProgress) onProgress(100, 100, "Download Started!");
        }
        return true;
    } catch (err) {
        console.error("Project save failed:", err);
        if (onProgress) onProgress(0, 0, "Failed");
        throw err;
    }
}

/**
 * Load a project from a ZIP file
 */
export async function loadProject(zipFile, onProgress) {
    if (onProgress) onProgress(0, 100, "Initializing Worker...");

    try {
        const { projectData, sceneDataList } = await runZipTask('LOAD_PROJECT', zipFile, onProgress);

        if (onProgress) onProgress(90, 100, "Reconstructing scenes...");

        const scenes = sceneDataList.map(item => ({
            id: item.metadata.id || `legacy_${item.name}`,
            name: item.name,
            label: item.metadata.label || "",
            category: item.metadata.category || "indoor",
            floor: item.metadata.floor || "ground",
            isAutoForward: item.metadata.isAutoForward || false,
            quality: item.metadata.quality || null,
            colorGroup: item.metadata.colorGroup || null,
            file: new File([item.blob], item.name, { type: "image/webp" }),
            originalFile: new File([item.blob], item.name, { type: "image/webp" }),
            hotspots: (item.metadata.hotspots || []).map(h => ({
                ...h,
                // ENSURE START COORDS ARE RESTORED
                startPitch: h.startPitch,
                startYaw: h.startYaw,
                startHfov: h.startHfov,
                returnViewFrame: h.returnViewFrame || null,
                isReturnLink: h.isReturnLink || false,
                // MULTI-POINT LINKS: Restore ALL intermediate waypoints
                waypoints: h.waypoints || []
            }))
        }));

        // --- VALIDATION: Filter out links to non-existent scenes ---
        const validSceneNames = new Set(scenes.map(s => s.name));
        let brokenLinksRemoved = 0;

        scenes.forEach(scene => {
            const originalCount = scene.hotspots.length;
            scene.hotspots = scene.hotspots.filter(h => {
                const isValid = validSceneNames.has(h.target);
                if (!isValid) {
                    console.warn(`[ProjectManager] Removing broken link in scene "${scene.name}" pointing to missing target: "${h.target}"`);
                }
                return isValid;
            });
            brokenLinksRemoved += (originalCount - scene.hotspots.length);
        });

        if (brokenLinksRemoved > 0) {
            console.info(`[ProjectManager] Cleanup complete. Removed ${brokenLinksRemoved} broken links.`);
        }

        const loadedProject = {
            tourName: projectData.projectName || "Imported Tour",
            scenes: scenes,
            deletedSceneIds: projectData.deletedSceneIds || [],
            activeIndex: 0
        };

        if (onProgress) onProgress(100, 100, "Project Loaded!");
        return loadedProject;

    } catch (error) {
        console.error("Project load error:", error);
        if (onProgress) onProgress(0, 100, "", false);
        throw error;
    }
}

