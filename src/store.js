import { Debug } from "./utils/Debug.js";

/**
 * Sanitize scene/tour names to prevent filesystem issues and ensure cross-platform compatibility
 * @param {string} name - Raw name input
 * @param {number} maxLength - Maximum allowed length (default: 255)
 * @returns {string} Sanitized name
 */
function sanitizeName(name, maxLength = 255) {
  if (!name || typeof name !== 'string') {
    return 'Untitled';
  }

  return name
    .trim()
    // Remove control characters and invalid filesystem characters
    .replace(/[\x00-\x1F\x7F<>:"\/\\|?*]/g, '_')
    // Replace multiple spaces/underscores with single underscore
    .replace(/[_\s]+/g, '_')
    // Remove leading/trailing underscores
    .replace(/^_+|_+$/g, '')
    // Limit length
    .substring(0, maxLength)
    // Fallback if empty after sanitization
    || 'Untitled';
}

export const store = {
  state: {
    tourName: "",
    scenes: [],
    activeIndex: -1,
    activeYaw: 0,
    activePitch: 0,
    // Note: HFOV is fixed at GLOBAL_HFOV (90°) - see Viewer.js
    isLinking: false,
    transition: {
      type: null,
      targetHotspotIndex: -1,
      fromSceneName: null
    },
    // Track stats for the last upload batch
    lastUploadReport: {
      success: [],
      skipped: []
    },
    // EXIF metadata report (stored until project save)
    exifReport: null,
    // Track the first phase of 2-click linking
    linkDraft: null, // { pitch, yaw, camPitch, camYaw, camHfov }
    preloadingSceneIndex: -1, // Anticipatory loading for smooth transitions
    isTeasing: false, // High-quality rendering mode for teaser recording
    // PERSISTENCE FIX: Track IDs of scenes removed by the user to prevent accidental re-adding
    deletedSceneIds: []
  },

  listeners: [],

  setPreloadingScene(index) {
    if (this.state.preloadingSceneIndex !== index) {
      this.state.preloadingSceneIndex = index;
      // Do NOT notify() for pre-loading to avoid unnecessary full-UI re-renders.
      // The Viewer will observe this via the existing subscribe loop.
      // Actually, we NEED notify to trigger the subscription callback in Viewer.js.
      this.notify();
    }
  },

  setLinkDraft(draft) {
    this.state.linkDraft = draft;
    this.notify();
  },

  setIsTeasing(val) {
    if (this.state.isTeasing !== val) {
      this.state.isTeasing = val;
      // No notify needed if we're just setting a flag for the next reload
    }
  },

  setTourName(name) {
    // Sanitize tour name for filesystem safety
    const sanitized = sanitizeName(name, 100);

    if (this.state.tourName !== sanitized) {
      console.log(`📦 [Store] setTourName changed from "${this.state.tourName}" to "${sanitized}"`);
      this.state.tourName = sanitized;
      this.notify();
    }
  },

  addScenes(sceneDataList) {
    if (!sceneDataList) return;
    const success = [];
    const skipped = [];

    sceneDataList.forEach((data) => {
      // Check for duplicate checksums
      const isDuplicate = this.state.scenes.some(s => s.id === data.id);
      if (isDuplicate) {
        skipped.push(data.originalName || data.name);
        return;
      }

      const newScene = {
        id: data.id, // THE STABLE ID (Checksum)
        name: data.name, // The display/filename (User-editable via label)
        file: data.preview,
        tinyFile: data.tiny, // Store the 512px progressive preview
        originalFile: data.original,
        hotspots: [],
        category: "indoor",
        floor: "ground",
        label: "",
        quality: data.quality || null,
        colorGroup: data.colorGroup || null,
        _metadataSource: "default", // legacy support
        categorySet: false,
        labelSet: false
      };

      this.state.scenes.push(newScene);
      success.push(data.originalName || data.name);
    });

    // Sort by name
    this.state.scenes.sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true, sensitivity: 'base' }));

    // CRITICAL: Ensure an active scene is selected if we just added the first ones
    if ((this.state.activeIndex === -1 || !this.state.scenes[this.state.activeIndex]) && this.state.scenes.length > 0) {
      console.log("📦 [Store] Initializing activeIndex to 0");
      this.state.activeIndex = 0;
      this.state.activeYaw = 0;
      this.state.activePitch = 0;
    }

    this.state.lastUploadReport = { success, skipped };
    // Update all prefixes to maintain correct sequence after new additions/sorting
    this.syncSceneNames();
    this.notify();
  },

  setActiveScene(index, startYaw = 0, startPitch = 0, transition = null) {
    // GUARD: Validate index is a valid integer within bounds
    if (!Number.isInteger(index) || index < 0 || index >= this.state.scenes.length) {
      console.warn(`[Store] setActiveScene: Invalid index ${index} (scenes: ${this.state.scenes.length})`);
      return;
    }

    // GUARD: Validate yaw and pitch are numbers within valid ranges
    if (typeof startYaw !== 'number' || !isFinite(startYaw)) {
      console.warn(`[Store] setActiveScene: Invalid startYaw ${startYaw}, defaulting to 0`);
      startYaw = 0;
    }
    if (typeof startPitch !== 'number' || !isFinite(startPitch)) {
      console.warn(`[Store] setActiveScene: Invalid startPitch ${startPitch}, defaulting to 0`);
      startPitch = 0;
    }

    // Normalize yaw to [0, 360) range
    startYaw = ((startYaw % 360) + 360) % 360;

    // Clamp pitch to [-90, 90] range
    startPitch = Math.max(-90, Math.min(90, startPitch));

    const targetScene = this.state.scenes[index];
    let finalYaw = startYaw;
    let finalPitch = startPitch;
    // Note: HFOV is fixed at 90° in Viewer.js - no longer stored in state

    // OPTIONAL: AUTO-ORIENTATION
    // If no specific orientation is provided (yaw/pitch are 0 and no transition type)
    if (!transition && startYaw === 0 && startPitch === 0 && targetScene.hotspots && targetScene.hotspots.length > 0) {
      const firstLink = targetScene.hotspots.find(h => h.target);
      if (firstLink) {
        if (index === 0) {
          // VERY FIRST SCENE: Look at the actual arrow on the floor to guide the user.
          finalYaw = firstLink.yaw;
          finalPitch = firstLink.pitch;
          Debug.info('Store', `Auto-Orientation (Entry): Looking at Link Arrow @ ${finalYaw.toFixed(1)}°`);
        } else {
          // ALL OTHER SCENES: Follow the "Director's Start View" (Point A) captured at link creation.
          finalYaw = firstLink.startYaw !== undefined ? firstLink.startYaw : firstLink.yaw;
          finalPitch = firstLink.startPitch !== undefined ? firstLink.startPitch : firstLink.pitch;
          Debug.info('Store', `Auto-Orientation (Scene ${index}): Following Director's Start View @ ${finalYaw.toFixed(1)}°`);
        }
      }
    }

    this.state.activeIndex = index;
    this.state.activeYaw = finalYaw;
    this.state.activePitch = finalPitch;
    this.state.transition = transition || { type: null, targetHotspotIndex: -1 };
    this.notify();
  },

  addHotspot(sceneIndex, hotspotData, skipNotify = false) {
    if (this.state.scenes[sceneIndex]) {
      this.state.scenes[sceneIndex].hotspots.push(hotspotData);
      if (!skipNotify) this.notify();
    }
  },

  removeHotspot(sceneIndex, hotspotIndex) {
    if (this.state.scenes[sceneIndex]) {
      this.state.scenes[sceneIndex].hotspots.splice(hotspotIndex, 1);
      this.notify();
    }
  },

  reorderScenes(fromIndex, toIndex) {
    if (fromIndex === toIndex) return;
    const scenes = this.state.scenes;
    const [movedItem] = scenes.splice(fromIndex, 1);
    scenes.splice(toIndex, 0, movedItem);

    if (this.state.activeIndex === fromIndex) {
      this.state.activeIndex = toIndex;
    } else if (this.state.activeIndex > fromIndex && this.state.activeIndex <= toIndex) {
      this.state.activeIndex--;
    } else if (this.state.activeIndex < fromIndex && this.state.activeIndex >= toIndex) {
      this.state.activeIndex++;
    }
    // Re-index all labeled scenes to reflect new order
    this.syncSceneNames();
    this.notify();
  },

  clearHotspots(sceneIndex) {
    if (this.state.scenes[sceneIndex]) {
      this.state.scenes[sceneIndex].hotspots = [];
      this.notify();
    }
  },

  deleteScene(index) {
    const sceneToDelete = this.state.scenes[index];
    if (!sceneToDelete) return;

    const targetName = sceneToDelete.name;
    console.log(`📦 [Store] Deleting scene "${targetName}" (Index: ${index})`);

    // 1. Clean up "orphan" links in other scenes that point to this scene
    this.state.scenes.forEach((scene) => {
      // Filter out hotspots that target the scene we are about to delete
      // We check existing targets against the name of the scene being deleted
      const originalLength = scene.hotspots.length;
      scene.hotspots = scene.hotspots.filter(h => h.target !== targetName);

      if (scene.hotspots.length !== originalLength) {
        console.log(`📦 [Store] Removed ${originalLength - scene.hotspots.length} orphan links from scene "${scene.name}"`);
      }
    });

    // 1.5. Record deletion in fingerprint history to prevent accidental re-adding
    if (sceneToDelete.id) {
      if (!this.state.deletedSceneIds) this.state.deletedSceneIds = [];
      if (!this.state.deletedSceneIds.includes(sceneToDelete.id)) {
        this.state.deletedSceneIds.push(sceneToDelete.id);
      }
    }

    // 2. Perform the deletion
    this.state.scenes.splice(index, 1);

    // 3. Adjust active index
    if (this.state.scenes.length === 0) {
      this.state.activeIndex = -1;
    } else if (index === this.state.activeIndex) {
      // Stay at the same index (which is now the next scene), 
      // or move to the new last item if we just deleted the former end.
      const nextIndex = Math.min(index, this.state.scenes.length - 1);
      // Use setActiveScene to trigger orientation logic and notification
      this.setActiveScene(nextIndex, 0, 0);
    } else if (index < this.state.activeIndex) {
      this.state.activeIndex--;
    }

    // 4. Update all prefixes to maintain correct sequence after deletion
    this.syncSceneNames();
    this.notify();
  },

  /**
   * Helper to ensure all filenames (with labels) match their current index.
   * This preserves the sequence (01, 02, 03...) regardless of moves or deletes.
   */
  syncSceneNames() {
    const renameMap = new Map();

    // 1. Identify all needed renames first
    this.state.scenes.forEach((scene, index) => {
      if (scene.label) {
        const oldName = scene.name;
        const prefix = (index + 1).toString().padStart(2, '0');

        // Sanitize label before creating filename
        const sanitizedLabel = sanitizeName(scene.label, 200);
        let baseSlug = sanitizedLabel.replace(/[\s-]+/g, "_").replace(/[^a-z0-9_]/gi, "").toLowerCase();
        const newName = `${prefix}_${baseSlug}.webp`;

        if (newName !== oldName) {
          renameMap.set(oldName, newName);
          scene.name = newName;
        }
      }
    });

    // 2. Perform ONE cascade update for all hotspots if renames occurred
    if (renameMap.size > 0) {
      console.log(`📦 [Store] Batch updating links for ${renameMap.size} renamed scenes...`);
      this.state.scenes.forEach(s => {
        s.hotspots.forEach(h => {
          if (renameMap.has(h.target)) {
            h.target = renameMap.get(h.target);
          }
        });
      });
    }
  },

  /**
   * Internal logic for lazy renaming with index prefixing
   */
  applyLazyRename(sceneIndex, newLabel) {
    const scene = this.state.scenes[sceneIndex];
    if (!scene) return;

    const oldName = scene.name;
    const cleanLabel = newLabel.trim();
    scene.label = cleanLabel;
    if (cleanLabel) scene.labelSet = true;

    // Trigger a full sync to ensure sequence is maintained
    this.syncSceneNames();
  },

  /**
   * Update metadata for a specific scene
   */
  updateSceneMetadata(sceneIndex, metadata) {
    const scene = this.state.scenes[sceneIndex];
    if (!scene) return;

    if (metadata.category !== undefined) {
      scene.category = metadata.category;
      scene.categorySet = true;
    }
    if (metadata.floor !== undefined) {
      scene.floor = metadata.floor;
      scene._metadataSource = "user";
    }

    if (metadata.label !== undefined) {
      this.applyLazyRename(sceneIndex, metadata.label);
    }

    if (metadata.isAutoForward !== undefined) {
      scene.isAutoForward = metadata.isAutoForward;
      // Note: isAutoForward is often set by the system/LinkModal, 
      // so we don't mark as "user" geoconfiguration here to allow inheritance.
    }

    this.notify();
  },

  /**
   * Update the arrival view for a normal link hotspot.
   * yaw and pitch are saved live as the user pans in the destination scene.
   */
  updateHotspotTargetView(sceneIndex, hotspotIndex, yaw, pitch, hfov, silent = true) {
    const hotspot = this.state.scenes[sceneIndex]?.hotspots[hotspotIndex];
    if (hotspot) {
      hotspot.targetYaw = yaw;
      hotspot.targetPitch = pitch;
      hotspot.targetHfov = hfov;
      if (!silent) this.notify();
    }
  },

  /**
   * Update the arrival view for a return link hotspot.
   */
  updateHotspotReturnView(sceneIndex, hotspotIndex, yaw, pitch, hfov, silent = true) {
    const hotspot = this.state.scenes[sceneIndex]?.hotspots[hotspotIndex];
    if (hotspot && hotspot.returnViewFrame) {
      hotspot.returnViewFrame.yaw = yaw;
      hotspot.returnViewFrame.pitch = pitch;
      hotspot.returnViewFrame.hfov = hfov;
      if (!silent) this.notify();
    }
  },

  getScenesByFloor() {
    const grouped = {};
    this.state.scenes.forEach((scene, index) => {
      const floor = scene.floor || "ground";
      if (!grouped[floor]) grouped[floor] = [];
      grouped[floor].push({ ...scene, index });
    });
    return grouped;
  },

  subscribe(callback) {
    this.listeners.push(callback);
  },

  notify() {
    this.listeners.forEach((cb) => cb(this.state));
  },

  loadProject(projectData) {
    this.state.tourName = projectData.tourName || "Imported Tour";
    this.state.scenes = (projectData.scenes || []).map(scene => ({
      ...scene,
      category: scene.category || "indoor",
      floor: scene.floor || "ground",
      label: scene.label || "",
      // If old project has no ID, we generate one from name to avoid crashes
      id: scene.id || `legacy_${scene.name}`,
      categorySet: scene.categorySet || !!scene.category,
      labelSet: scene.labelSet || !!scene.label,
      _metadataSource: scene._metadataSource || "user"
    }));

    // TELEMETRY: Project Integrity Check
    const sceneNames = new Set(this.state.scenes.map(s => s.name));
    let totalHotspots = 0;
    let orphanedLinks = 0;

    this.state.scenes.forEach(scene => {
      scene.hotspots.forEach(hs => {
        totalHotspots++;
        if (!sceneNames.has(hs.target)) {
          orphanedLinks++;
          Debug.warn('Store', `Orphaned link found in scene "${scene.name}": target "${hs.target}" does not exist.`);
        }
      });
    });

    Debug.info('Store', 'LOAD_PROJECT', {
      tourName: this.state.tourName,
      sceneCount: this.state.scenes.length,
      totalHotspots,
      orphanedLinks,
      version: projectData.version || 'unknown'
    });

    // Restore deletion history
    this.state.deletedSceneIds = projectData.deletedSceneIds || [];

    const targetIdx = projectData.activeIndex >= 0 && projectData.activeIndex < this.state.scenes.length
      ? projectData.activeIndex
      : (this.state.scenes.length > 0 ? 0 : -1);

    this.setActiveScene(targetIdx, 0, 0);
  },
};
