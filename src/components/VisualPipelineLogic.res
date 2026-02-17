/* src/components/VisualPipelineLogic.res - Logic for VisualPipeline */

module Logic = {
  let calculateReorder = (
    timeline: array<Types.timelineItem>,
    sourceId: string,
    dropIndex: int,
  ): option<(int, int)> => {
    let sourceIndex = timeline->Belt.Array.getIndexBy(t => t.id == sourceId)->Option.getOr(-1)

    if sourceIndex != -1 {
      let finalIndex = if dropIndex > sourceIndex {
        dropIndex - 1
      } else {
        dropIndex
      }
      if finalIndex != sourceIndex {
        Some((sourceIndex, finalIndex))
      } else {
        None
      }
    } else {
      None
    }
  }
}

module Styles = {
  let nodeSize = 14

  let styles = "
  /* --- Sizing & Scaling (T1430) --- */
  :root {
    --vp-pipe-height: 12px;
    --vp-node-base: 18px;
    --vp-marker-size: 10px;
    --vp-bottom-margin: 24px;
  }

  /* Compact Mode for smaller viewports */
  body.viewer-state-tablet,
  body.viewer-state-portrait,
  body.viewer-state-2k,
  body.viewer-force-fallback,
  body.stage-size-small {
    --vp-pipe-height: 10px;
    --vp-node-base: 14px;
    --vp-marker-size: 8px;
    --vp-bottom-margin: 12px;
  }

  #visual-pipeline-container {
    position: absolute; bottom: 0; left: 0; width: 100%; height: auto; z-index: 9000;
    display: flex; justify-content: center; align-items: flex-end; pointer-events: none;
    padding-bottom: env(safe-area-inset-bottom, 20px);
    /* Safe Zone: Explicitly avoid Floor Nav (Left) and Logo (Right) */
    padding-left: 70px;
    padding-right: 150px;
    box-sizing: border-box;
  }

  .visual-pipeline-wrapper {
    pointer-events: auto;
    margin-bottom: var(--vp-bottom-margin);
    display: flex; justify-content: center; align-items: center;
    width: 100%;
    max-width: 1200px; /* Cap expansion on ultra-wide */
    padding: 0;
    background: transparent;
    user-select: none;
    flex-wrap: wrap;
    row-gap: 18px; /* Vertical space for wrapping */
    column-gap: 0;
    transition: all 0.3s ease;
  }

  body.viewer-state-portrait #visual-pipeline-container {
    /* More aggressive padding for narrow portrait screens */
    padding-left: 60px;
    padding-right: 140px;
    padding-bottom: env(safe-area-inset-bottom, 10px);
  }

  body.viewer-state-portrait .visual-pipeline-wrapper {
    row-gap: 12px;
    transform: scale(0.85);
    transform-origin: bottom center;
  }

  .pipeline-track {
    display: flex; flex-wrap: wrap; justify-content: center; align-items: center;
    position: relative; width: 100%; gap: 0;
  }

  /* Connector (Pipe) */
  .drop-zone {
    width: 30px; height: 32px; display: flex; align-items: center; justify-content: center;
    position: relative; z-index: 10;
    transition: width 0.3s cubic-bezier(0.2, 1, 0.2, 1); will-change: width;
  }

  .drop-zone::before {
    content: ''; position: absolute; top: 50%; 
    left: -1px; width: calc(100% + 2px); /* Overlap to prevent gaps */
    height: var(--vp-pipe-height); transform: translateY(-50%);
    /* Synchronized Blue with Orange line in Golden Minor Ratio */
    background: linear-gradient(
      to bottom,
      var(--primary-ui-blue) 0%,
      var(--primary-ui-blue) 38.2%,
      var(--orange-brand) 38.2%,
      var(--orange-brand) 61.8%,
      var(--primary-ui-blue) 61.8%,
      var(--primary-ui-blue) 100%
    );
    opacity: 1; z-index: 10;
    border-radius: 0; pointer-events: none;
  }

  .drop-zone::after {
    content: ''; position: absolute; width: var(--vp-node-base);
    height: var(--vp-node-base); border-radius: 50%;
    background: rgba(255, 255, 255, 0.1); border: 2px dashed rgba(255, 255, 255, 0.5); opacity: 0;
    box-shadow: 0 0 12px rgba(255, 255, 255, 0.4); z-index: 15; pointer-events: none;
    transition: all 0.3s cubic-bezier(0.2, 1, 0.2, 1); transform: scale(0.7);
  }

  .drop-zone.drag-over::after { opacity: 1; transform: scale(1); border-color: white; }
  .drop-zone.drag-over { width: 48px; }
  .dragging-active .drop-zone { z-index: 100; cursor: copy; }

  /* Node (Circle) */
  .pipeline-node {
    width: calc(var(--vp-node-base) + 4px); 
    height: calc(var(--vp-node-base) + 4px);
    display: flex; align-items: center; justify-content: center; cursor: pointer;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
    position: relative; flex-shrink: 0;
    z-index: 20;
    border-radius: 50%;
    margin: 0 -0.5px;
    
    /* Solid Synchronized Blue Circle Base */
    background-color: var(--primary-ui-blue);
    
    /* Overlay Orange Stripe passing through */
    background-image: linear-gradient(
      to bottom,
      transparent 0%,
      transparent 38.2%,
      var(--orange-brand) 38.2%,
      var(--orange-brand) 61.8%,
      transparent 61.8%,
      transparent 100%
    );
    background-size: 100% var(--vp-pipe-height);
    background-position: center center;
    background-repeat: no-repeat;
  }

  .pipeline-node:hover { transform: none; box-shadow: 0 0 0 2px rgba(255, 255, 255, 0.3); }
  .pipeline-node:active { transform: scale(0.95); }

  .pipeline-node.is-dragging { opacity: 0.4; transform: scale(0.9); }

  /* Inner Selection Marker */
  .node-marker {
    width: var(--vp-marker-size); height: var(--vp-marker-size);
    background: var(--orange-brand);
    border-radius: 50%;
    position: absolute;
    opacity: 0;
    transform: scale(0);
    transition: all 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    z-index: 25;
    pointer-events: none;
  }

  .pipeline-node.active .node-marker {
    opacity: 1;
    transform: scale(1);
  }

  .pipeline-node:focus-visible {
    outline: none;
    box-shadow: 0 0 0 4px rgba(255, 255, 255, 0.5);
  }

  .node-tooltip {
    position: absolute; bottom: 100%; left: 50%; transform: translateX(-50%) translateY(10px);
    background: rgba(15, 23, 42, 0.95);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px; padding: 8px;
    opacity: 0; pointer-events: none; transition: all 0.2s cubic-bezier(0.2, 0.8, 0.2, 1);
    display: flex; flex-direction: column; align-items: center; width: 160px; z-index: 100;
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(4px);
    margin-bottom: 12px;
    pointer-events: none;
  }

  .pipeline-node:hover .node-tooltip { opacity: 1; transform: translateX(-50%) translateY(0); }

  .tooltip-thumb {
    width: 100%; height: 72px; object-fit: cover; border-radius: 4px;
    margin-bottom: 6px; background: var(--slate-900);
    border: 1px solid rgba(255,255,255,0.1);
  }

  .tooltip-text {
    font-size: 9px; color: white; font-weight: 500; text-align: center;
    width: 100%; 
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    line-height: 1.3;
    padding: 0 2px;
  }

  .tooltip-link-id {
    font-size: 9px; color: var(--slate-400); font-weight: 700;
    text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;
  }

  .auto-forward-indicator {
    position: absolute; top: -6px; right: -6px;
    background: var(--primary); color: white;
    width: 14px; height: 14px; border-radius: 50%;
    font-size: 9px; display: flex; align-items: center; justify-content: center;
    box-shadow: 0 2px 4px rgba(0,0,0,0.3);
    z-index: 30; pointer-events: none;
  }

  .drop-zone.is-endpoint { width: 4px; }
  .drop-zone.is-endpoint.drag-over { width: 36px; }
"
}
