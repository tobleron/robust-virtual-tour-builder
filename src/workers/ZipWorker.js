// src/workers/ZipWorker.js
importScripts('../libs/jszip.min.js');

self.onmessage = async (e) => {
    const { type, payload } = e.data;

    try {
        if (type === 'SAVE_PROJECT') {
            const { projectData, files, exifReport } = payload;
            const zip = new JSZip();

            // 1. Add metadata
            zip.file("project.json", JSON.stringify(projectData, null, 2));

            // 2. Add EXIF report
            if (exifReport) {
                const logsFolder = zip.folder("logs");
                const timestamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
                logsFolder.file(`EXIF_METADATA_${timestamp}.txt`, exifReport);
            }

            // 3. Add Images
            const imagesFolder = zip.folder("images");
            for (const file of files) {
                imagesFolder.file(file.name, file.blob);
            }

            // 4. Generate ZIP
            const zipBlob = await zip.generateAsync({
                type: "blob",
                mimeType: "application/zip",
                compression: "DEFLATE",
                compressionOptions: { level: 6 }
            }, (metadata) => {
                self.postMessage({ type: 'PROGRESS', payload: { pct: metadata.percent, message: "Compressing..." } });
            });

            if (!zipBlob || zipBlob.size === 0) {
                throw new Error("Failed to generate ZIP: Output blob is empty.");
            }

            self.postMessage({ type: 'SAVE_COMPLETE', payload: zipBlob });
        }

        else if (type === 'LOAD_PROJECT') {
            const zipFile = payload;

            if (!zipFile) throw new Error("Load failed: No file data received in worker.");

            const size = (zipFile instanceof ArrayBuffer) ? zipFile.byteLength : (zipFile.size || 0);
            if (size === 0) {
                throw new Error(`Load failed: Received empty file data (0 bytes). Received type: ${zipFile.constructor.name}`);
            }

            const zip = await JSZip.loadAsync(zipFile);

            // 1. Read project.json
            const projectJsonFile = zip.file("project.json");
            if (!projectJsonFile) throw new Error("project.json not found");
            const projectData = JSON.parse(await projectJsonFile.async("text"));

            // 2. Extract Images
            const sceneDataList = [];
            const scenes = projectData.scenes;

            for (let i = 0; i < scenes.length; i++) {
                const sceneMetadata = scenes[i];
                const imageFile = zip.file(`images/${sceneMetadata.name}`);

                if (imageFile) {
                    const blob = await imageFile.async("blob");
                    sceneDataList.push({
                        metadata: sceneMetadata,
                        blob: blob,
                        name: sceneMetadata.name
                    });
                }

                self.postMessage({
                    type: 'PROGRESS',
                    payload: {
                        pct: Math.round(((i + 1) / scenes.length) * 100),
                        message: `Extracting: ${sceneMetadata.name}`
                    }
                });
            }

            self.postMessage({
                type: 'LOAD_COMPLETE',
                payload: { projectData, sceneDataList }
            });
        }
    } catch (err) {
        self.postMessage({ type: 'ERROR', payload: err.message });
    }
};