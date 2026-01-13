/**
 * VisualPipelineComponent.js
 * 
 * Renders the compact visual timeline pipeline at the bottom of the screen.
 * Implements a stable HTML5 Click-and-Drag reordering mechanism.
 */

import { store } from "../store.js";
import { getGroupColor } from "../utils/ColorPalette.js";

const NODE_SIZE = 22;

export class VisualPipelineComponent {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;

    this.injectStyles();

    this.wrapper = document.createElement('div');
    this.wrapper.className = 'visual-pipeline-wrapper';
    this.wrapper.innerHTML = `<div class="pipeline-track"></div>`;
    this.container.appendChild(this.wrapper);

    this.dragSourceId = null;
    this.thumbCache = new Map();

    // Bindings
    this.render = this.render.bind(this);
    this.handleDragStart = this.handleDragStart.bind(this);
    this.handleDragEnd = this.handleDragEnd.bind(this);
    this.handleDragOver = this.handleDragOver.bind(this);
    this.handleDragLeave = this.handleDragLeave.bind(this);
    this.handleDrop = this.handleDrop.bind(this);

    store.subscribe(this.render);
    this.render(store.state);
  }

  injectStyles() {
    if (document.getElementById('visual-pipeline-styles')) return;

    const style = document.createElement('style');
    style.id = 'visual-pipeline-styles';
    style.textContent = `
      #visual-pipeline-container {
        position: absolute;
        bottom: 0; left: 0;
        width: 100%; height: 0;
        z-index: 1000;
        display: flex;
        justify-content: center;
        align-items: flex-end; 
        pointer-events: none;
        padding-left: 70px;
        padding-right: 160px;
        box-sizing: border-box;
      }

      .visual-pipeline-wrapper {
        pointer-events: auto;
        margin-bottom: 20px;
        display: flex;
        justify-content: center;
        align-items: center;
        width: 100%;
        min-width: 200px;
        max-width: 800px;
        padding: 6px 12px;
        background: transparent;
        user-select: none;
        flex-wrap: wrap;
      }
      
      .pipeline-track {
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        align-items: center;
        position: relative;
        width: 100%;
      }
      
      .drop-zone {
        width: 14px;
        height: 32px;
        display: flex;
        align-items: center;
        justify-content: center;
        position: relative;
        z-index: 10;
        margin: 0 -2px;
        transition: width 0.3s cubic-bezier(0.2, 1, 0.2, 1);
        will-change: width;
      }
      
      .drop-zone::before {
        content: '';
        position: absolute;
        top: 50%; left: 0;
        transform: translateY(-50%);
        width: 100%; height: 6px;
        background: var(--pipe-color, #1e293b);
        z-index: 10;
        pointer-events: none;
      }

      .drop-zone::after {
        content: '';
        position: absolute;
        width: ${NODE_SIZE}px;
        height: ${NODE_SIZE}px;
        border-radius: 50%;
        background: rgba(255, 255, 255, 0.1);
        border: 2px dashed white;
        opacity: 0;
        box-shadow: 0 0 12px rgba(255, 255, 255, 0.4);
        z-index: 15;
        pointer-events: none;
        transition: all 0.3s cubic-bezier(0.2, 1, 0.2, 1);
        transform: scale(0.7);
      }

      .drop-zone.drag-over::after {
        opacity: 1;
        transform: scale(1);
      }

      .drop-zone.drag-over {
        width: 32px;
      }
      
      /* Bring drop zones to front during drag to ensure they catch the drop */
      .dragging-active .drop-zone {
        z-index: 100;
        cursor: copy;
      }
      
      .pipeline-node {
        width: ${NODE_SIZE}px;
        height: ${NODE_SIZE}px;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: grab;
        transition: transform 0.2s, opacity 0.2s;
        position: relative;
        flex-shrink: 0;
        margin: 3px 0;
        z-index: 20;
      }

      .pipeline-node.is-dragging {
        opacity: 0.4;
      }
      
      .pipeline-node::after {
        content: '';
        position: absolute;
        inset: 0;
        background: var(--node-color, #0a7a56);
        border-radius: 50%;
        z-index: 20;
        transition: transform 0.2s, box-shadow 0.2s;
        box-shadow: 1px 1px 1px #000;
      }
      
      .pipeline-node:hover::after { 
        transform: scale(1.15); 
        box-shadow: 2px 2px 1px #000;
      }
      
      .pipeline-node.active::after { 
        transform: scale(1.2); 
        box-shadow: none;
      }
      
      .pipeline-node.active::before {
        content: '';
        position: absolute;
        inset: -3px;
        border: 3px solid white;
        border-radius: 50%;
        z-index: 5;
        transform: scale(1.2);
        box-shadow: none;
      }

      .node-tooltip {
        position: absolute;
        bottom: 50px; left: 50%;
        transform: translateX(-50%) translateY(10px);
        background: #1e293b;
        border: 1px solid #334155;
        border-radius: 8px;
        padding: 4px;
        opacity: 0;
        pointer-events: none;
        transition: all 0.2s ease;
        display: flex;
        flex-direction: column;
        align-items: center;
        width: 120px;
        z-index: 30;
        box-shadow: 0 8px 16px rgba(0,0,0,0.5);
      }
      
      .pipeline-node:hover .node-tooltip {
        opacity: 1;
        transform: translateX(-50%) translateY(0);
      }
      
      .tooltip-thumb {
        width: 112px; height: 63px;
        object-fit: cover;
        border-radius: 4px;
        margin-top: 4px; margin-bottom: 4px;
        background: #0f172a;
      }
      .tooltip-text {
        color: white; font-size: 10px; font-weight: 600;
        text-align: center; white-space: nowrap;
        overflow: hidden; text-overflow: ellipsis; max-width: 100%;
      }
      .tooltip-link-id {
        color: #94a3b8; font-size: 9px; font-weight: 700;
        margin-bottom: 2px;
      }
      .auto-forward-indicator {
        position: absolute;
        inset: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 25;
        color: white;
        font-size: 21px;
        font-weight: 900;
        line-height: 1;
        pointer-events: none;
        text-shadow: 0 1px 2px rgba(0,0,0,0.5);
        /* Slight optical adjustments for the » glyph */
        padding-bottom: 2px;
        padding-left: 1px;
      }
      .drop-zone.is-endpoint::before {
        display: none;
      }
    `;
    document.head.appendChild(style);
  }

  handleDragStart(e) {
    const node = e.target.closest('.pipeline-node');
    if (!node) return;

    this.dragSourceId = node.dataset.id;
    node.classList.add('is-dragging');
    this.wrapper.classList.add('dragging-active');

    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', this.dragSourceId);
  }

  handleDragEnd(e) {
    const node = e.target.closest('.pipeline-node');
    if (node) node.classList.remove('is-dragging');
    this.wrapper.classList.remove('dragging-active');
    this.wrapper.querySelectorAll('.drop-zone').forEach(el => el.classList.remove('drag-over'));
    this.dragSourceId = null;
  }

  handleDragOver(e) {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    const zone = e.target.closest('.drop-zone');

    if (zone) {
      zone.classList.add('drag-over');
    }

    return false;
  }

  handleDragEnter(e) {
    e.preventDefault();
    const zone = e.target.closest('.drop-zone');
    if (zone) {
      zone.classList.add('drag-over');
    }
  }

  handleDragLeave(e) {
    const zone = e.target.closest('.drop-zone');
    if (zone) {
      zone.classList.remove('drag-over');
    }
  }

  handleDrop(e) {
    e.preventDefault();
    const zone = e.target.closest('.drop-zone');
    if (zone && this.dragSourceId !== null) {
      const dropIndex = parseInt(zone.dataset.index);
      const sourceIndex = store.state.timeline.findIndex(t => t.id === this.dragSourceId);

      if (sourceIndex !== -1) {
        let finalIndex = dropIndex;
        if (dropIndex > sourceIndex) finalIndex = dropIndex - 1;
        if (finalIndex !== sourceIndex) {
          store.reorderTimeline(sourceIndex, finalIndex);
        }
      }
    }
    this.handleDragEnd(e);
  }

  render(state) {
    if (!state.timeline || state.timeline.length === 0) {
      this.wrapper.style.display = 'none';
      return;
    }
    this.wrapper.style.display = 'flex';

    const track = this.wrapper.querySelector('.pipeline-track');
    const fragment = document.createDocumentFragment();

    const firstZone = this.createDropZone(0);
    firstZone.classList.add('is-endpoint');
    fragment.appendChild(firstZone);

    state.timeline.forEach((item, index) => {
      const node = document.createElement('div');
      node.className = 'pipeline-node';
      node.dataset.id = item.id;
      node.draggable = true;

      const scene = state.scenes.find(s => s.id === item.sceneId);
      let color = '#0a7a56';
      if (scene) {
        color = getGroupColor(scene.colorGroup);
        node.style.setProperty('--node-color', color);
      }

      if (index === 0) {
        const firstZoneInTrack = fragment.querySelector('.drop-zone');
        if (firstZoneInTrack) firstZoneInTrack.style.setProperty('--pipe-color', color);
      }

      if (state.activeTimelineStepId === item.id) {
        node.classList.add('active');
      } else if (!state.activeTimelineStepId) {
        const currentScene = state.scenes[state.activeIndex];
        const isFirstMatch = state.timeline.findIndex(t => t.sceneId === (currentScene?.id)) === index;
        if (currentScene && item.sceneId === currentScene.id && isFirstMatch) {
          node.classList.add('active');
        }
      }

      // Interaction listeners
      node.addEventListener('click', () => {
        store.setActiveTimelineStep(item.id);
        const sceneIndex = state.scenes.findIndex(s => s.id === item.sceneId);
        if (sceneIndex !== -1) {
          const scene = state.scenes[sceneIndex];
          const hotspot = scene.hotspots.find(h => h.linkId === item.linkId);
          if (hotspot) {
            store.setActiveScene(sceneIndex, hotspot.yaw, hotspot.pitch);
          } else {
            store.setActiveScene(sceneIndex);
          }
        }
      });

      node.addEventListener('dragstart', this.handleDragStart);
      node.addEventListener('dragend', this.handleDragEnd);

      node.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        if (confirm('Remove this step from the timeline?')) {
          store.removeFromTimeline(item.id);
        }
      });

      // Thumbnail with Caching
      let thumbUrl = '';
      if (scene) {
        if (this.thumbCache.has(scene.id)) {
          thumbUrl = this.thumbCache.get(scene.id);
        } else {
          const file = scene.tinyFile || scene.file;
          if (file) {
            thumbUrl = URL.createObjectURL(file);
            this.thumbCache.set(scene.id, thumbUrl);
          }
        }
      }
      const thumbName = scene ? scene.name : 'Unknown Scene';

      // 6. CHECK FOR AUTO-FORWARD status (Target scene based)
      const targetScene = state.scenes.find(s => s.name === item.targetScene);
      const isAutoForward = targetScene && targetScene.isAutoForward;

      node.innerHTML = `
        <div class="node-tooltip">
           <span class="tooltip-link-id">Link: ${item.linkId || 'ID'}</span>
           ${thumbUrl ? `<img src="${thumbUrl}" class="tooltip-thumb" alt="preview">` : ''}
           <span class="tooltip-text">${thumbName}</span>
        </div>
        ${isAutoForward ? '<span class="auto-forward-indicator">»</span>' : ''}
      `;

      fragment.appendChild(node);

      const nextZone = this.createDropZone(index + 1);
      if (index === state.timeline.length - 1) {
        nextZone.classList.add('is-endpoint');
      }
      nextZone.style.setProperty('--pipe-color', color);
      fragment.appendChild(nextZone);
    });

    track.innerHTML = '';
    track.appendChild(fragment);
  }

  createDropZone(index) {
    const zone = document.createElement('div');
    zone.className = 'drop-zone';
    zone.dataset.index = index;
    zone.addEventListener('dragover', this.handleDragOver);
    zone.addEventListener('dragenter', this.handleDragEnter.bind(this));
    zone.addEventListener('dragleave', this.handleDragLeave);
    zone.addEventListener('drop', this.handleDrop);
    return zone;
  }
}
