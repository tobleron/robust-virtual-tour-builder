/* src/components/VisualPipelineLogic.res - Logic & Styles for VisualPipeline V2 (Thumbnail Chain) */

module Styles = {
  let styles = "
  /* --- Visual Pipeline V3: Scalable Floor-Grouped Squares --- */

  /* Container */
  #visual-pipeline-container {
    position: absolute; bottom: 16px; left: 0; width: 100%; height: auto; z-index: 200;
    display: flex; justify-content: center; align-items: flex-end; pointer-events: none;
    /* User Spacing Proposal: 120px Left, 220px Right, ~80px Baseline elevation */
    padding-bottom: 65px;
    padding-left: 110px;
    padding-right: 220px;
    box-sizing: border-box;
    min-height: 170px;
  }

  #visual-pipeline-container.pipeline-locked {
    opacity: 0.78;
    filter: grayscale(0.28);
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
    /* Removed white border, added thin black angled shadow stroke */
    border: none;
    box-shadow: 0.5px 0.5px 0px 0px rgba(0, 0, 0, 0.8),
                0 1px 3px rgba(0, 0, 0, 0.4);
    transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1),
                box-shadow 0.3s ease,
                filter 0.3s ease;
    z-index: 20;
    pointer-events: auto;
  }

  .pipeline-node:hover {
    transform: scale(1.4);
    box-shadow: 0.5px 0.5px 0px 0px rgba(0, 0, 0, 0.9);
    z-index: 1001;
    filter: brightness(1.2);
  }

  .pipeline-node:active {
    transform: scale(0.9);
  }

  /* Active node glow - Synchronized with Brand Accent Yellow */
  .pipeline-node.active {
    box-shadow: 0 0 0 2px var(--accent, #ffcc00),
                0 4px 12px rgba(0, 0, 0, 0.4);
    transform: scale(1.2);
    z-index: 25;
  }

  .pipeline-node.active:hover {
    transform: scale(1.4);
    z-index: 1001;
  }

  .pipeline-node:focus-visible {
    outline: none;
    box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.6);
  }

  .pipeline-node.disabled {
    pointer-events: none;
    cursor: not-allowed;
    transform: none !important;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.25);
    filter: saturate(0.45) brightness(0.9);
  }

  /* --- Right-anchored Tooltip (above logo) --- */
  .pipeline-global-tooltip {
    position: absolute; right: 24px; bottom: 104px; transform: translateY(10px);
    background: #0e2d52; /* Navy blue bar color */
    border: 1.5px solid var(--orange-brand, #f97316); /* Thin orange border */
    border-radius: 6px; 
    padding: 0;
    opacity: 0; pointer-events: none;
    transition: opacity 0.2s cubic-bezier(0.2, 0.8, 0.2, 1), transform 0.2s cubic-bezier(0.2, 0.8, 0.2, 1);
    display: flex; flex-direction: column; align-items: center; width: 146px; z-index: 6008;
    box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.6);
    overflow: hidden;
  }

  .pipeline-global-tooltip.visible {
    opacity: 1;
    transform: translateY(0);
  }

  .tooltip-thumb {
    width: 100%; height: 84px; object-fit: cover;
    display: block;
    background: var(--slate-900);
  }

  /* --- Local Node Tooltip (LinkID) --- */
  .pipeline-node-tooltip {
    position: absolute;
    bottom: calc(100% + 10px);
    left: 50%;
    transform: translateX(-50%);
    background: #0e2d52;
    border: 1px solid var(--orange-brand, #f97316);
    border-radius: 4px;
    padding: 4px 8px;
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 6px;
    white-space: nowrap;
    z-index: 1000;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
    animation: localTooltipIn 0.2s ease-out forwards;
    pointer-events: none;
  }

  .pipeline-node-tooltip::after {
    content: '';
    position: absolute;
    top: 100%;
    left: 50%;
    transform: translateX(-50%);
    border-width: 5px;
    border-style: solid;
    border-color: var(--orange-brand, #f97316) transparent transparent transparent;
  }

  .tooltip-label {
    font-size: 8px;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    opacity: 0.6;
    color: white;
  }

  .tooltip-value {
    font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
    font-weight: 700;
    font-size: 11px;
    color: var(--orange-brand, #f97316);
  }

  @keyframes localTooltipIn {
    from { opacity: 0; transform: translate(-50%, 4px); }
    to { opacity: 1; transform: translate(-50%, 0); }
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
