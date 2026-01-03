export const store = {
  state: {
    tourName: "",
    scenes: [],
    activeIndex: -1,
    activeYaw: 0,
    activePitch: 0,
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
    exifReport: null
  },

  listeners: [],

  setTourName(name) {
    if (this.state.tourName !== name) {
      console.log(`📦 [Store] setTourName changed from "${this.state.tourName}" to "${name}"`);
      this.state.tourName = name;
      this.notify();
    }
  },

  addScenes(sceneDataList) {
    const success = [];
    const skipped = [];

    sceneDataList.forEach((data) => {
      // Check for duplicate checksums
      const isDuplicate = this.state.scenes.some(s => s.id === data.id);
      if (isDuplicate) {
        skipped.push(data.originalName);
        return;
      }

      const newScene = {
        id: data.id, // THE STABLE ID (Checksum)
        name: data.name, // The display/filename (User-editable via label)
        file: data.preview,
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
      success.push(data.originalName);
    });

    // Sort by name
    this.state.scenes.sort((a, b) => a.name.localeCompare(b.name));

    if (this.state.activeIndex === -1 && this.state.scenes.length > 0) {
      this.state.activeIndex = 0;
      this.state.activeYaw = 0;
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
    this.state.activeIndex = index;
    this.state.activeYaw = startYaw;
    this.state.activePitch = startPitch;
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
    this.state.scenes.splice(index, 1);
    if (this.state.scenes.length === 0) {
      this.state.activeIndex = -1;
    } else if (index === this.state.activeIndex) {
      this.state.activeIndex = 0;
    } else if (index < this.state.activeIndex) {
      this.state.activeIndex--;
    }
    // Update all prefixes to maintain correct sequence after deletion
    this.syncSceneNames();
    this.notify();
  },

  /**
   * Helper to ensure all filenames (with labels) match their current index.
   * This preserves the sequence (01, 02, 03...) regardless of moves or deletes.
   */
  syncSceneNames() {
    this.state.scenes.forEach((scene, index) => {
      if (scene.label) {
        this.applyLazyRename(index, scene.label);
      }
    });
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

    if (cleanLabel) {
      // 1. Calculate 2-digit index prefix (1-indexed)
      const prefix = (sceneIndex + 1).toString().padStart(2, '0');

      // 2. Generate clean slug (e.g. "Living Room" -> "living_room")
      let baseSlug = cleanLabel.replace(/[\s-]+/g, "_").replace(/[^a-z0-9_]/gi, "").toLowerCase();

      // 3. Combine to final name
      const newName = `${prefix}_${baseSlug}.webp`;

      if (newName !== oldName) {
        scene.name = newName;

        // 4. CASCADE UPDATE: Update all hotspots pointing to the old name
        this.state.scenes.forEach(s => {
          s.hotspots.forEach(h => {
            if (h.target === oldName) h.target = newName;
          });
        });
      }
    }
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

  updateHotspotTargetYaw(sceneIndex, hotspotIndex, yaw) {
    if (this.state.scenes[sceneIndex] && this.state.scenes[sceneIndex].hotspots[hotspotIndex]) {
      this.state.scenes[sceneIndex].hotspots[hotspotIndex].targetYaw = yaw;
      // Do NOT notify to prevent viewer reload. Silent update.
    }
  },

  /**
   * Update the return view yaw for a return link hotspot
   * Used for bidirectional view saving when navigating via return links
   */
  updateHotspotReturnYaw(sceneIndex, hotspotIndex, yaw) {
    const hotspot = this.state.scenes[sceneIndex]?.hotspots[hotspotIndex];
    if (hotspot && hotspot.returnViewFrame) {
      hotspot.returnViewFrame.yaw = yaw;
      // Do NOT notify to prevent viewer reload. Silent update.
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
    this.state.activeIndex = projectData.activeIndex >= 0 && projectData.activeIndex < this.state.scenes.length
      ? projectData.activeIndex
      : (this.state.scenes.length > 0 ? 0 : -1);
    this.state.activeYaw = 0;
    this.state.isLinking = false;
    this.state.transition = { type: null, targetHotspotIndex: -1, fromSceneName: null };
    this.notify();
  },
};
