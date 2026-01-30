// @efficiency-role: ui-component

open ReBindings

let nodeSize = 22

let styles =
  "
  #visual-pipeline-container {
    position: absolute; bottom: 0; left: 0; width: 100%; height: 0; z-index: 1000;
    display: flex; justify-content: center; align-items: flex-end; pointer-events: none;
    padding-left: 70px; padding-right: 160px; box-sizing: border-box;
  }
  .visual-pipeline-wrapper {
    pointer-events: auto; margin-bottom: 20px; display: flex; justify-content: center;
    align-items: center; width: 100%; min-width: 200px; max-width: 800px;
    padding: 6px 12px; background: transparent; user-select: none; flex-wrap: wrap;
  }
  .pipeline-track {
    display: flex; flex-wrap: wrap; justify-content: center; align-items: center;
    position: relative; width: 100%;
  }
  .drop-zone {
    width: 14px; height: 32px; display: flex; align-items: center; justify-content: center;
    position: relative; z-index: 10; margin: 0 -2px;
    transition: width 0.3s cubic-bezier(0.2, 1, 0.2, 1); will-change: width;
  }
  .drop-zone::before {
    content: ''; position: absolute; top: 50%; left: 0; transform: translateY(-50%);
    width: 100%; height: 6px; background: var(--pipe-color, var(--slate-700)); z-index: 10;
    pointer-events: none;
  }
  .drop-zone::after {
    content: ''; position: absolute; width: " ++
  Int.toString(nodeSize) ++
  "px;
    height: " ++
  Int.toString(nodeSize) ++
  "px; border-radius: 50%;
    background: rgba(255, 255, 255, 0.1); border: 2px dashed white; opacity: 0;
    box-shadow: 0 0 12px rgba(255, 255, 255, 0.4); z-index: 15; pointer-events: none;
    transition: all 0.3s cubic-bezier(0.2, 1, 0.2, 1); transform: scale(0.7);
  }
  .drop-zone.drag-over::after { opacity: 1; transform: scale(1); }
  .drop-zone.drag-over { width: 32px; }
  .dragging-active .drop-zone { z-index: 100; cursor: copy; }
  .pipeline-node {
    width: " ++
  Int.toString(nodeSize) ++
  "px; height: " ++
  Int.toString(nodeSize) ++ "px;
    display: flex; align-items: center; justify-content: center; cursor: grab;
    transition: transform 0.2s, opacity 0.2s; position: relative; flex-shrink: 0;
    margin: 3px 0; z-index: 20;
  }
  .pipeline-node.is-dragging { opacity: 0.4; }
  .pipeline-node::after {
    content: ''; position: absolute; inset: 0; background: var(--node-color, var(--success-dark));
    border-radius: 50%; z-index: 20; transition: transform 0.2s, box-shadow 0.2s;
    box-shadow: 1px 1px 1px #000;
  }
  .pipeline-node:hover::after { transform: scale(1.15); box-shadow: 2px 2px 1px #000; }
  .pipeline-node.active::after { transform: scale(1.2); box-shadow: none; }
  .pipeline-node.active::before {
    content: ''; position: absolute; inset: -3px; border: 3px solid white;
    border-radius: 50%; z-index: 5; transform: scale(1.2); box-shadow: none;
  }
  .pipeline-node:focus-visible {
    outline: 2px solid white; outline-offset: 4px; z-index: 100;
  }
  .node-tooltip {
    position: absolute; bottom: 50px; left: 50%; transform: translateX(-50%) translateY(10px);
    background: var(--slate-800); border: 1px solid var(--slate-700); border-radius: 8px; padding: 4px;
    opacity: 0; pointer-events: none; transition: all 0.2s ease; display: flex;
    flex-direction: column; align-items: center; width: 120px; z-index: 30;
    box-shadow: 0 8px 16px rgba(0,0,0,0.5);
  }
  .pipeline-node:hover .node-tooltip { opacity: 1; transform: translateX(-50%) translateY(0); }
  .tooltip-thumb {
    width: 112px; height: 63px; object-fit: cover; border-radius: 4px;
    margin-top: 4px; margin-bottom: 4px; background: var(--slate-900);
  }
  .tooltip-text { font-size: 10px; color: white; font-weight: 600; text-align: center; width: 100%; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; padding: 0 4px; }
  .tooltip-link-id { font-size: 8px; color: var(--slate-400); font-weight: bold; margin-bottom: 2px; }
  .auto-forward-indicator { position: absolute; top: -8px; right: -8px; color: white; font-size: 12px; font-weight: bold; text-shadow: 1px 1px 2px black; pointer-events: none; }
  .drop-zone.is-endpoint { width: 4px; }
  .drop-zone.is-endpoint.drag-over { width: 32px; }
"

let injectStyles = () => {
  let existing = Dom.getElementById("visual-pipeline-styles")
  switch Nullable.toOption(existing) {
  | Some(_) => ()
  | None =>
    Logger.info(~module_="VisualPipelineStyles", ~message="INJECT_STYLES", ())
    let style = Dom.createElement("style")
    Dom.setId(style, "visual-pipeline-styles")
    Dom.setTextContent(style, styles)
    Dom.appendChild(Dom.head, style)
  }
}
