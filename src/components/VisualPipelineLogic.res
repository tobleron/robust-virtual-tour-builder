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
  let nodeSize = 22

  let styles =
    "
  #visual-pipeline-container {
    position: absolute; bottom: 0; left: 0; width: 100%; height: auto; z-index: 9000;
    display: flex; justify-content: center; align-items: flex-end; pointer-events: none;
    padding-bottom: env(safe-area-inset-bottom, 20px);
    box-sizing: border-box;
  }

  /* Responsive padding */
  @media (min-width: 768px) {
    #visual-pipeline-container {
      padding-left: 80px;
      padding-right: 80px;
    }
  }

  .visual-pipeline-wrapper {
    pointer-events: auto;
    margin-bottom: 24px;
    display: flex; justify-content: center; align-items: center;
    width: auto; max-width: 90%;
    padding: 12px 24px;
    background: rgba(15, 23, 42, 0.7); /* Slate-900 with opacity */
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 16px;
    box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.5);
    user-select: none;
    flex-wrap: wrap;
    gap: 12px;
    transition: all 0.3s ease;
  }

  .pipeline-track {
    display: flex; flex-wrap: wrap; justify-content: center; align-items: center;
    position: relative; width: 100%; gap: 4px;
  }

  .drop-zone {
    width: 14px; height: 32px; display: flex; align-items: center; justify-content: center;
    position: relative; z-index: 10;
    transition: width 0.3s cubic-bezier(0.2, 1, 0.2, 1); will-change: width;
  }

  .drop-zone::before {
    content: ''; position: absolute; top: 50%; left: 0; transform: translateY(-50%);
    width: 100%; height: 4px; background: rgba(255, 255, 255, 0.2); z-index: 10;
    border-radius: 2px; pointer-events: none;
  }

  .drop-zone::after {
    content: ''; position: absolute; width: " ++
    Int.toString(nodeSize) ++
    "px;
    height: " ++
    Int.toString(nodeSize) ++
    "px; border-radius: 50%;
    background: rgba(255, 255, 255, 0.1); border: 2px dashed rgba(255, 255, 255, 0.5); opacity: 0;
    box-shadow: 0 0 12px rgba(255, 255, 255, 0.4); z-index: 15; pointer-events: none;
    transition: all 0.3s cubic-bezier(0.2, 1, 0.2, 1); transform: scale(0.7);
  }

  .drop-zone.drag-over::after { opacity: 1; transform: scale(1); border-color: white; }
  .drop-zone.drag-over { width: 36px; }
  .dragging-active .drop-zone { z-index: 100; cursor: copy; }

  .pipeline-node {
    width: " ++
    Int.toString(nodeSize + 4) ++
    "px; height: " ++
    Int.toString(nodeSize + 4) ++ "px;
    display: flex; align-items: center; justify-content: center; cursor: pointer;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
    position: relative; flex-shrink: 0;
    z-index: 20;
  }

  .pipeline-node:hover { transform: translateY(-2px); }
  .pipeline-node:active { transform: translateY(0) scale(0.95); }

  .pipeline-node.is-dragging { opacity: 0.4; transform: scale(0.9); }

  .pipeline-node::after {
    content: ''; position: absolute; inset: 2px;
    background: var(--node-color, var(--success-dark));
    border-radius: 50%; z-index: 20;
    box-shadow: 0 2px 4px rgba(0,0,0,0.3);
    border: 2px solid rgba(255,255,255,0.1);
    transition: all 0.3s ease;
  }

  .pipeline-node:hover::after {
    box-shadow: 0 0 0 2px rgba(255,255,255,0.2), 0 4px 8px rgba(0,0,0,0.4);
    border-color: rgba(255,255,255,0.8);
  }

  .pipeline-node.active::after {
    box-shadow: 0 0 0 2px white, 0 0 12px var(--node-color);
    border-color: white;
  }

  .pipeline-node:focus-visible {
    outline: none;
  }
  .pipeline-node:focus-visible::after {
    box-shadow: 0 0 0 4px rgba(255, 255, 255, 0.5);
  }

  .node-tooltip {
    position: absolute; bottom: 100%; left: 50%; transform: translateX(-50%) translateY(10px);
    background: rgba(15, 23, 42, 0.95);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px; padding: 6px;
    opacity: 0; pointer-events: none; transition: all 0.2s cubic-bezier(0.2, 0.8, 0.2, 1);
    display: flex; flex-direction: column; align-items: center; width: 140px; z-index: 100;
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
    font-size: 11px; color: white; font-weight: 600; text-align: center;
    width: 100%; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
    line-height: 1.4;
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
