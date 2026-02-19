/* src/components/VisualPipelineLogic.res - Logic & Styles for VisualPipeline V2 (Thumbnail Chain) */

module Styles = {
  let styles = "
  /* --- Visual Pipeline V2: Thumbnail Chain --- */

  /* Container */
  #visual-pipeline-container {
    position: absolute; bottom: 0; left: 0; width: 100%; height: auto; z-index: 9000;
    display: flex; justify-content: center; align-items: flex-end; pointer-events: none;
    padding-bottom: env(safe-area-inset-bottom, 16px);
    padding-left: 70px;
    padding-right: 150px;
    box-sizing: border-box;
  }

  .visual-pipeline-wrapper {
    pointer-events: auto;
    margin-bottom: 16px;
    display: flex; justify-content: center; align-items: center;
    width: 100%;
    max-width: 1200px;
    padding: 0;
    background: transparent;
    user-select: none;
    flex-wrap: wrap;
    row-gap: 8px;
    column-gap: 0;
  }

  body.viewer-state-portrait #visual-pipeline-container {
    padding-left: 60px;
    padding-right: 140px;
    padding-bottom: env(safe-area-inset-bottom, 8px);
  }

  body.viewer-state-portrait .visual-pipeline-wrapper {
    row-gap: 6px;
    transform: scale(0.85);
    transform-origin: bottom center;
  }

  /* Pipeline Track */
  .pipeline-track {
    display: flex; flex-wrap: wrap; justify-content: center; align-items: center;
    position: relative; width: 100%; gap: 6px;
  }

  /* --- Thumbnail Node --- */
  .pipeline-node {
    width: 44px; height: 30px;
    position: relative;
    flex-shrink: 0;
    cursor: pointer;
    border-radius: 3px;
    overflow: visible;
    border: 3px solid var(--node-color, var(--primary-ui-blue));
    transition: border-color 0.3s ease,
                transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1),
                box-shadow 0.3s ease,
                opacity 0.2s ease;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.4);
    z-index: 20;
  }

  .pipeline-node:hover {
    transform: scale(1.12);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5),
                0 0 0 1px rgba(255, 255, 255, 0.2);
    z-index: 30;
  }

  .pipeline-node:active {
    transform: scale(0.97);
  }

  /* Active node glow — 1px orange ring with no gap */
  .pipeline-node.active {
    box-shadow: 0 0 0 1px var(--orange-brand, #f97316),
                0 4px 12px rgba(0, 0, 0, 0.4);
    transform: scale(1.08);
    z-index: 25;
  }

  .pipeline-node:focus-visible {
    outline: none;
    box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.6);
  }

  /* Thumbnail image */
  .pipeline-thumb {
    width: 100%; height: 100%;
    object-fit: cover;
    display: block;
    border-radius: inherit;
    background: var(--slate-900, #0f172a);
  }

  /* Scene number badge */
  .pipeline-badge {
    position: absolute;
    bottom: 1px; left: 1px;
    background: rgba(0, 0, 0, 0.7);
    backdrop-filter: blur(4px);
    color: white;
    font-size: 7px;
    font-weight: 700;
    padding: 1px 3px;
    border-radius: 2px;
    line-height: 1;
    pointer-events: none;
    z-index: 5;
  }







  /* --- Tooltip --- */
  .node-tooltip {
    position: absolute; bottom: 100%; left: 50%; transform: translateX(-50%) translateY(10px);
    background: rgba(15, 23, 42, 0.95);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px; padding: 8px;
    opacity: 0; pointer-events: none; transition: all 0.2s cubic-bezier(0.2, 0.8, 0.2, 1);
    display: flex; flex-direction: column; align-items: center; width: 160px; z-index: 100;
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(4px);
    margin-bottom: 8px;
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

  /* --- Compact Mode --- */
  body.viewer-state-tablet .pipeline-node,
  body.viewer-state-portrait .pipeline-node,
  body.viewer-state-2k .pipeline-node,
  body.viewer-force-fallback .pipeline-node,
  body.stage-size-small .pipeline-node {
    width: 34px; height: 24px;
    border-width: 2px;
  }





  body.viewer-state-tablet .pipeline-badge,
  body.viewer-state-portrait .pipeline-badge,
  body.viewer-state-2k .pipeline-badge,
  body.viewer-force-fallback .pipeline-badge,
  body.stage-size-small .pipeline-badge {
    font-size: 6px;
    padding: 0px 2px;
  }


"
}
