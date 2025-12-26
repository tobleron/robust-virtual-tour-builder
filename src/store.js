export const store = {
  state: {
    tourName: "New Virtual Tour",
    scenes: [],
    activeIndex: -1,
    activeYaw: 0,
    isLinking: false,
  },

  listeners: [],

  setTourName(name) {
    this.state.tourName = name;
    this.notify();
  },

  addScenes(sceneDataList) {
    // sceneDataList is now an array of objects: { original, preview, name }
    const newScenes = sceneDataList.map((data) => ({
      name: data.name,
      file: data.preview, // Used by Viewer/Sidebar (Fast)
      originalFile: data.original, // Used by Exporter (Master Quality) - SAVED!
      hotspots: [],
    }));

    this.state.scenes = [...this.state.scenes, ...newScenes].sort((a, b) =>
      a.name.localeCompare(b.name),
    );

    if (this.state.activeIndex === -1 && this.state.scenes.length > 0) {
      this.state.activeIndex = 0;
      this.state.activeYaw = 0;
    }
    this.notify();
  },

  setActiveScene(index, startYaw = 0) {
    this.state.activeIndex = index;
    this.state.activeYaw = startYaw;
    this.notify();
  },

  addHotspot(sceneIndex, hotspotData) {
    this.state.scenes[sceneIndex].hotspots.push(hotspotData);
    this.notify();
  },

  removeHotspot(sceneIndex, hotspotIndex) {
    if (this.state.scenes[sceneIndex]) {
      this.state.scenes[sceneIndex].hotspots.splice(hotspotIndex, 1);
      this.notify();
    }
  },
  // Inside src/store.js

  reorderScenes(fromIndex, toIndex) {
    if (fromIndex === toIndex) return;

    const scenes = this.state.scenes;
    const [movedItem] = scenes.splice(fromIndex, 1);
    scenes.splice(toIndex, 0, movedItem);

    // INTELLIGENT TRACKING: Keep the active scene highlighted correctly
    // regardless of where it moves.
    if (this.state.activeIndex === fromIndex) {
      this.state.activeIndex = toIndex;
    } else if (
      this.state.activeIndex > fromIndex &&
      this.state.activeIndex <= toIndex
    ) {
      this.state.activeIndex--;
    } else if (
      this.state.activeIndex < fromIndex &&
      this.state.activeIndex >= toIndex
    ) {
      this.state.activeIndex++;
    }

    this.notify();
  },

  // NEW: Function to clear links from a scene
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
    this.notify();
  },

  subscribe(callback) {
    this.listeners.push(callback);
  },

  notify() {
    this.listeners.forEach((cb) => cb(this.state));
  },
};
