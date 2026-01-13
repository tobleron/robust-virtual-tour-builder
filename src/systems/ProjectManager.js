import { notify } from "../utils/NotificationSystem.js";
import { DownloadSystem } from "./DownloadSystem.js";
import { Debug } from "../utils/Debug.js";

import { BACKEND_URL } from "../constants.js";

/**
 * Save the current project as a ZIP file (using Backend)
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
                Debug.info('Project', "Project save cancelled by user.");
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

        })),
        timeline: state.timeline || []
    };

    try {
        // 2. Upload to Backend for Zipping
        if (onProgress) onProgress(10, 100, "Uploading to backend...");

        const formData = new FormData();
        formData.append('project_data', JSON.stringify(projectData));

        // Append each scene's file blob
        // Todo: Optimisation - if files are already on backend (session), maybe we don't need to re-upload?
        // But for now, we assume pure frontend state is the source of truth.
        state.scenes.forEach((scene, index) => {
            if (scene.file) {
                formData.append('files', scene.file, scene.name);
            } else {
                console.warn(`[ProjectManager] Scene ${scene.name} (index ${index}) is missing its file blob.`);
            }
        });

        const response = await fetch(`${BACKEND_URL}/save-project`, {
            method: "POST",
            body: formData,
        });

        if (!response.ok) {
            let errorDetails = "Unknown Backend Error";
            try {
                const errorJson = await response.json();
                errorDetails = errorJson.details || errorJson.error || errorDetails;
            } catch (e) {
                errorDetails = await response.text();
            }
            throw new Error(`Backend save failed: ${response.status} - ${errorDetails}`);
        }

        if (onProgress) onProgress(80, 100, "Downloading ZIP...");

        const zipBlob = await response.blob();

        if (onProgress) onProgress(100, 100, "Saving to disk...");

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
 * Load a project from a ZIP file (using Backend)
 */
export async function loadProject(zipFile, onProgress) {
    if (onProgress) onProgress(0, 100, "Uploading project...");

    try {
        const formData = new FormData();
        formData.append('file', zipFile);

        // 1. Send ZIP to Backend
        const response = await fetch(`${BACKEND_URL}/load-project`, {
            method: "POST",
            body: formData
        });

        if (!response.ok) {
            throw new Error(`Backend load failed: ${response.status} ${response.statusText}`);
        }

        const { session_id, project_data } = await response.json();

        if (onProgress) onProgress(20, 100, "Downloading scenes...");

        // 2. Reconstruct Scenes by fetching images from backend session
        const rawScenes = project_data.scenes || [];
        const totalScenes = rawScenes.length;
        let loadedCount = 0;

        // Fetch concurrently with limit? Or just Promise.all
        // Browsers limit concurrent connections (usually 6).
        // For large projects, Promise.all might timeout or error.
        // Let's do huge Promise.all for now, expecting backend to be fast.

        const scenes = await Promise.all(rawScenes.map(async (item) => {
            try {
                const imageUrl = (`${BACKEND_URL}/session/${session_id}/${encodeURIComponent(item.name)}`);
                const imgRes = await fetch(imageUrl);
                if (!imgRes.ok) throw new Error(`Failed to fetch image: ${item.name}`);

                const blob = await imgRes.blob();

                loadedCount++;
                if (onProgress) onProgress(20 + Math.round((loadedCount / totalScenes) * 70), 100, `Loading ${item.name}...`);

                // Reconstruct File object
                const file = new File([blob], item.name, { type: "image/webp" });

                return {
                    id: item.id || `legacy_${item.name}`,
                    name: item.name,
                    label: item.label || "",
                    category: item.category || "indoor",
                    floor: item.floor || "ground",
                    isAutoForward: item.isAutoForward || false,
                    quality: item.quality || null,
                    colorGroup: item.colorGroup || null,
                    file: file,
                    originalFile: file,
                    hotspots: (item.hotspots || []).map(h => ({
                        ...h,
                        startPitch: h.startPitch,
                        startYaw: h.startYaw,
                        startHfov: h.startHfov,
                        returnViewFrame: h.returnViewFrame || null,
                        isReturnLink: h.isReturnLink || false,
                        waypoints: h.waypoints || []
                    }))
                };
            } catch (e) {
                console.error(`Failed to load scene ${item.name}`, e);
                // Return null or partial?
                // Returning null and filtering might be safer.
                return null;
            }
        }));

        // Filter out failed loads
        const validScenes = scenes.filter(s => s !== null);

        // --- VALIDATION: Filter out links to non-existent scenes ---
        const validSceneNames = new Set(validScenes.map(s => s.name));
        let brokenLinksRemoved = 0;

        validScenes.forEach(scene => {
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
            tourName: project_data.projectName || "Imported Tour",
            scenes: validScenes,
            deletedSceneIds: project_data.deletedSceneIds || [],
            timeline: project_data.timeline || [],
            activeIndex: 0
        };

        if (onProgress) onProgress(100, 100, "Project Loaded!");
        return loadedProject;

    } catch (error) {
        console.error("Project load error:", error);
        if (onProgress) onProgress(0, 100, "Load Failed", false);
        throw error;
    }
}



