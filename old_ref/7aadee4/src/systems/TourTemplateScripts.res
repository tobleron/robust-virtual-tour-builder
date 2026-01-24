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
      
      const ns = "http://www.w3.org/2000/svg";
      const svg = document.createElementNS(ns, "svg");
      svg.setAttribute("class", "custom-arrow-svg");
      svg.setAttribute("viewBox", "0 0 100 100");
      svg.style.overflow = "visible";
      
      if (isHome) {
        hotSpotDiv.setAttribute('data-target-home', 'true');
        svg.setAttribute("preserveAspectRatio", "xMidYMid meet");
        
        const defs = document.createElementNS(ns, "defs");
        const grad = document.createElementNS(ns, "linearGradient");
        grad.setAttribute("id", "homeGradExport_" + args.i);
        grad.setAttribute("x1", "0%"); grad.setAttribute("y1", "0%");
        grad.setAttribute("x2", "0%"); grad.setAttribute("y2", "100%");
        
        const s1 = document.createElementNS(ns, "stop");
        s1.setAttribute("offset", "0%"); s1.style.stopColor = "var(--gold-1)"; s1.style.stopOpacity = "1";
        const s2 = document.createElementNS(ns, "stop");
        s2.setAttribute("offset", "50%"); s2.style.stopColor = "var(--gold-2)"; s2.style.stopOpacity = "1";
        const s3 = document.createElementNS(ns, "stop");
        s3.setAttribute("offset", "100%"); s3.style.stopColor = "var(--gold-3)"; s3.style.stopOpacity = "1";
        
        grad.appendChild(s1); grad.appendChild(s2); grad.appendChild(s3);
        defs.appendChild(grad);
        svg.appendChild(defs);
        
        const rect = document.createElementNS(ns, "rect");
        rect.setAttribute("x", "5"); rect.setAttribute("y", "5");
        rect.setAttribute("width", "90"); rect.setAttribute("height", "90");
        rect.setAttribute("rx", "8"); rect.setAttribute("fill", "url(#homeGradExport_" + args.i + ")");
        svg.appendChild(rect);
        
        const text = document.createElementNS(ns, "text");
        text.setAttribute("x", "50"); text.setAttribute("y", "52");
        text.setAttribute("text-anchor", "middle"); text.setAttribute("dominant-baseline", "middle");
        text.style.fontFamily = "Outfit, sans-serif"; text.style.fontWeight = "700"; text.style.fontSize = "24px";
        text.setAttribute("fill", "var(--gold-text)"); text.style.letterSpacing = "0px";
        text.textContent = "HOME";
        svg.appendChild(text);
      } else {
        const defs = document.createElementNS(ns, "defs");
        const grad = document.createElementNS(ns, "linearGradient");
        grad.setAttribute("id", "arrowGradExport_" + args.i);
        grad.setAttribute("x1", "0%"); grad.setAttribute("y1", "0%");
        grad.setAttribute("x2", "0%"); grad.setAttribute("y2", "100%");
        
        const s1 = document.createElementNS(ns, "stop");
        s1.setAttribute("offset", "0%"); s1.style.stopColor = "var(--gold-1)"; s1.style.stopOpacity = "1";
        const s2 = document.createElementNS(ns, "stop");
        s2.setAttribute("offset", "50%"); s2.style.stopColor = "var(--gold-2)"; s2.style.stopOpacity = "1";
        const s3 = document.createElementNS(ns, "stop");
        s3.setAttribute("offset", "100%"); s3.style.stopColor = "var(--gold-3)"; s3.style.stopOpacity = "1";
        
        grad.appendChild(s1); grad.appendChild(s2); grad.appendChild(s3);
        defs.appendChild(grad);
        svg.appendChild(defs);
        
        const p1 = document.createElementNS(ns, "path");
        p1.setAttribute("d", "M10 43 L50 13 L90 43 L90 53 L50 23 L10 53 Z M10 73 L50 43 L90 73 L90 83 L50 53 L10 83 Z");
        p1.setAttribute("fill", "var(--gold-border)");
        svg.appendChild(p1);
        
        const p2 = document.createElementNS(ns, "path");
        p2.setAttribute("d", "M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z");
        p2.setAttribute("fill", "url(#arrowGradExport_" + args.i + ")");
        svg.appendChild(p2);
        
        const glow1 = document.createElementNS(ns, "path");
        glow1.setAttribute("class", "glow-unit glow-top");
        glow1.setAttribute("d", "M10 40 L50 10 L90 40 L90 60 L50 30 L10 60 Z");
        svg.appendChild(glow1);
        
        const glow2 = document.createElementNS(ns, "path");
        glow2.setAttribute("class", "glow-unit glow-bottom");
        glow2.setAttribute("d", "M10 70 L50 40 L90 70 L90 90 L50 60 L10 90 Z");
        svg.appendChild(glow2);
        
        const p3 = document.createElementNS(ns, "path");
        p3.setAttribute("d", "M10 40 L50 10 L90 40 L50 11 Z");
        p3.setAttribute("fill", "var(--arrow-white)");
        svg.appendChild(p3);
      }
      
      while (hotSpotDiv.firstChild) hotSpotDiv.removeChild(hotSpotDiv.firstChild);
      hotSpotDiv.appendChild(svg);
      
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
