/* src/systems/TourTemplateScripts.res */

/* JavaScript templates for exported tours */

let renderScriptTemplate = `
    function renderGoldArrow(hotSpotDiv, args) {
      const currentSceneId = window.viewer.getScene();
      const currentSceneData = scenesData[currentSceneId];
      
      const isHome = currentSceneData && 
                     currentSceneData.hotSpots.length === 1 && 
                     persistentFrom && 
                     args.targetSceneId === persistentFrom;

      hotSpotDiv.style.width = "__BASE_SIZE__px";
      hotSpotDiv.style.height = "__BASE_SIZE__px";
      
      if (isHome) {
        hotSpotDiv.setAttribute('data-target-home', 'true');
        hotSpotDiv.innerHTML = \`
          <svg class="custom-arrow-svg" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid meet" style="overflow:visible;">
            <defs>
              <linearGradient id="homeGradExport_\${args.i}" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" style="stop-color:var(--gold-1);stop-opacity:1" />
                <stop offset="50%" style="stop-color:var(--gold-2);stop-opacity:1" />
                <stop offset="100%" style="stop-color:var(--gold-3);stop-opacity:1" />
              </linearGradient>
            </defs>
            <rect x="5" y="5" width="90" height="90" rx="8" fill="url(#homeGradExport_\${args.i})" />
            <text x="50" y="52" text-anchor="middle" dominant-baseline="middle" font-family="Outfit, sans-serif" font-weight="700" font-size="24" fill="var(--gold-text)" style="letter-spacing: 0px;">HOME</text>
          </svg>\`;
      } else {
        hotSpotDiv.innerHTML = \`
          <svg class="custom-arrow-svg" viewBox="0 0 100 100" style="overflow:visible;">
            <defs>
              <linearGradient id="arrowGradExport_\${args.i}" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" style="stop-color:var(--gold-1);stop-opacity:1" />
                <stop offset="50%" style="stop-color:var(--gold-2);stop-opacity:1" />
                <stop offset="100%" style="stop-color:var(--gold-3);stop-opacity:1" />
              </linearGradient>
            </defs>
            <path d="M10 43 L50 13 L90 43 L90 53 L50 23 L10 53 Z M10 73 L50 43 L90 73 L90 83 L50 53 L10 83 Z" fill="var(--gold-border)" />
            <path d="M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z" fill="url(#arrowGradExport_\${args.i})" />
            <path class="glow-unit glow-top" d="M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z" />
            <path class="glow-unit glow-bottom" d="M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z" />
            <path d="M10 40 L50 10 L90 40 L50 11 Z" fill="var(--arrow-white)" />
          </svg>\`;
      }
      
      hotSpotDiv.onclick = function() {
        // PRIORITY LOGIC:
        let navYaw = 90; // Fallback
        let navPitch = 0;

        if (args.isReturnLink && args.returnViewFrame) {
          navYaw = args.returnViewFrame.yaw !== undefined ? args.returnViewFrame.yaw : 90;
          navPitch = args.returnViewFrame.pitch !== undefined ? args.returnViewFrame.pitch : 0;
        } else {
          if (args.targetYaw !== undefined) {
             navYaw = args.targetYaw;
             navPitch = args.targetPitch !== undefined ? args.targetPitch : 0;
          } else if (args.viewFrame) {
             navYaw = args.viewFrame.yaw !== undefined ? args.viewFrame.yaw : 90;
             navPitch = args.viewFrame.pitch !== undefined ? args.viewFrame.pitch : 0;
          }
        }

        const v = window.viewer;
        const currentScene = v.getScene();
        transitionFrom = currentScene;
        persistentFrom = currentScene;

        setTimeout(() => { 
          const finalTarget = hotSpotDiv.getAttribute('data-target-home') === 'true' 
                              ? firstSceneId : args.targetSceneId;
          v.loadScene(finalTarget, navPitch, navYaw, 90);
        }, 450);
      };
    }
`

let loadEventScript = `
    window.viewer.on('load', function() {
      const currentSceneId = window.viewer.getScene();
      const currentSceneData = scenesData[currentSceneId];
      
      // AUTO-FORWARD
      if (currentSceneData && currentSceneData.isAutoForward && 
          currentSceneData.hotSpots && currentSceneData.hotSpots.length > 0) {
        const firstHotspot = currentSceneData.hotSpots[0];
        const targetSceneId = firstHotspot.target;
        
        setTimeout(() => {
          transitionFrom = currentSceneId;
          persistentFrom = currentSceneId;
          window.viewer.loadScene(targetSceneId, "same", "same", 90);
        }, 1000);
        return;
      }
      
      if (!transitionFrom && !isFirstLoad) return; 
      
      if (currentSceneData && currentSceneData.hotSpots && currentSceneData.hotSpots.length > 0) {
          window.viewer.setHfov(120);
      }
      
      persistentFrom = transitionFrom;
      lastVisitedSceneId = transitionFrom;
      transitionFrom = null;
      isFirstLoad = false;
    });
`

let generateRenderScript = baseSize => {
  renderScriptTemplate->String.replaceRegExp(/__BASE_SIZE__/g, Belt.Int.toString(baseSize))
}
