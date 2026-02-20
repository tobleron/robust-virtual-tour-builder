/* src/components/VisualPipelineLogic.res - Logic & Styles for VisualPipeline V2 (Thumbnail Chain) */

module Styles = {
  let styles = "
  /* --- Visual Pipeline V3: Scalable Floor-Grouped Squares --- */

  /* Container */
  #visual-pipeline-container {
    position: absolute; bottom: 0; left: 0; width: 100%; height: auto; z-index: 200;
    display: flex; justify-content: center; align-items: flex-end; pointer-events: none;
    /* User Spacing Proposal: 120px Left, 220px Right, ~80px Baseline elevation */
    padding-bottom: 80px; 
    padding-left: 110px;
    padding-right: 150px;
    box-sizing: border-box;
    min-height: 200px;
  }

  .visual-pipeline-wrapper {
    pointer-events: none;
    display: flex; flex-direction: column-reverse; justify-content: flex-start; align-items: flex-start;
    width: 100%;
    max-width: 1400px;
    padding: 0;
    background: transparent;
    user-select: none;
    row-gap: 12px;
    position: relative;
    z-index: 20;
  }

  /* Floor Track */
  .pipeline-track {
    display: flex; flex-wrap: wrap; justify-content: flex-start; align-items: center;
    position: relative; width: 100%; gap: 6px;
    min-height: 12px;
    pointer-events: none;
  }

  /* --- Square Node --- */
  .pipeline-node {
    width: 12px; height: 12px;
    position: relative;
    flex-shrink: 0;
    cursor: pointer;
    border-radius: 3px;
    overflow: visible;
    background: var(--node-color, var(--primary-ui-blue));
    border: 1px solid rgba(255, 255, 255, 0.2);
    transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1),
                box-shadow 0.3s ease,
                filter 0.3s ease;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.4);
    z-index: 20;
    pointer-events: auto;
  }

  .pipeline-node:hover {
    transform: scale(1.4);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5),
                0 0 0 1px rgba(255, 255, 255, 0.4);
    z-index: 1001;
    filter: brightness(1.2);
  }

  .pipeline-node:active {
    transform: scale(0.9);
  }

  /* Active node glow */
  .pipeline-node.active {
    box-shadow: 0 0 0 2px var(--orange-brand, #f97316),
                0 4px 12px rgba(0, 0, 0, 0.4);
    transform: scale(1.2);
    z-index: 25;
  }

  .pipeline-node:focus-visible {
    outline: none;
    box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.6);
  }

  /* --- Tooltip --- */
  .node-tooltip {
    position: absolute; bottom: 100%; left: 50%; transform: translateX(-50%) translateY(10px);
    background: #0e2d52; /* Navy blue bar color */
    border: 1.5px solid var(--orange-brand, #f97316); /* Thin orange border */
    border-radius: 6px; 
    padding: 0;
    opacity: 0; pointer-events: none;
    transition: opacity 0.2s cubic-bezier(0.2, 0.8, 0.2, 1), transform 0.2s cubic-bezier(0.2, 0.8, 0.2, 1);
    transition-delay: 0ms;
    display: flex; flex-direction: column; align-items: center; width: 120px; z-index: 6008;
    box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.6);
    overflow: hidden;
    margin-bottom: 12px;
  }

  .pipeline-node:hover .node-tooltip {
    opacity: 1;
    transform: translateX(-50%) translateY(0);
    pointer-events: auto;
    transition-delay: 600ms;
  }

  .tooltip-thumb {
    width: 100%; height: 68px; object-fit: cover; 
    display: block;
    background: var(--slate-900);
  }

  .tooltip-footer {
    width: 100%;
    background: #0e2d52; /* Explicitly navy */
    padding: 4px 6px;
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 18px;
  }

  .tooltip-text {
    font-size: 7.5px; color: rgba(255, 255, 255, 0.9); font-weight: 500; text-align: center;
    width: 100%;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    line-height: 1;
  }

  /* --- Electronic Board Lines --- */
  .pipeline-svg-overlay {
    position: absolute;
    top: 0; left: 0; width: 100%; height: 100%;
    pointer-events: none;
    z-index: 5; /* Behind tracks */
    overflow: visible;
  }

  .pipeline-floor-line {
    fill: none;
    stroke: #f97316; /* Force brand orange for visibility */
    stroke-width: 1.8;
    opacity: 0.8;
    stroke-linecap: round;
    stroke-linejoin: round;
    filter: drop-shadow(0 0 2px rgba(249, 115, 22, 0.4));
    transition: opacity 0.3s ease;
  }
"
}
