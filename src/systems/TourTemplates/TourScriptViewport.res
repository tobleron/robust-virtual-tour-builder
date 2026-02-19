let script = `
    let exportViewportState = "";
    function resolveExportViewportState() {
      const portraitViewport = window.innerHeight > window.innerWidth || window.innerWidth <= 720;
      if (portraitViewport) return "portrait";
      // Allow desktop mode if viewport is at least 60px wider than the stage max width
      if (window.innerWidth >= (STAGE_MAX_WIDTH + 60)) return "desktop";
      return "tablet";
    }
    function updateExportStateClasses() {
      const nextState = resolveExportViewportState();
      exportViewportState = nextState;
      if (!document || !document.body) return nextState;
      document.body.classList.remove("export-state-desktop");
      document.body.classList.remove("export-state-tablet");
      document.body.classList.remove("export-state-portrait");
      document.body.classList.add("export-state-" + nextState);

      if (typeof IS_HD_EXPORT === 'boolean' && IS_HD_EXPORT) {
        document.body.classList.add("is-hd-export");
      }

      return nextState;
    }
    function getCurrentHfov() {
      const state = exportViewportState === "" ? updateExportStateClasses() : exportViewportState;
      return state === "portrait" ? MIN_HFOV : MAX_HFOV;
    }
    function applyCurrentHfov() {
      updateExportStateClasses();
      if (!window.viewer || typeof window.viewer.setHfov !== "function") return;
      if (typeof window.viewer.resize === "function") window.viewer.resize();
      window.viewer.setHfov(getCurrentHfov(), false);
      // Double trigger to catch late layout paint
      setTimeout(() => { if (window.viewer && window.viewer.resize) window.viewer.resize(); }, 50);
    }
`
