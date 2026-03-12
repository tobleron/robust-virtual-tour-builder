// @efficiency-role: ui-component
import { authJson, getAuthHeaderValue } from './PageFrameworkAuth.js';
import { escapeHtml, formatShortTimestamp } from './PageFrameworkShared.js';

const builderPickerState = {
  isOpen: false,
  loading: false,
  error: '',
  projects: [],
  histories: {},
  historyLoading: {},
  historyErrors: {},
};

function builderModalRoot() {
  return document.getElementById('builder-project-modal');
}

function builderStateSummary() {
  const state = window.__RE_STATE__;
  if (!state || typeof state !== 'object') return { hasContent: false, tourName: '' };
  const sceneOrder = Array.isArray(state.sceneOrder) ? state.sceneOrder : [];
  const tourName = typeof state.tourName === 'string' ? state.tourName.trim() : '';
  return {
    hasContent: sceneOrder.length > 0 || (tourName !== '' && tourName !== 'Tour Name'),
    tourName,
  };
}

function confirmBuilderProjectReplace(label) {
  const summary = builderStateSummary();
  if (!summary.hasContent) return true;
  return window.confirm(`Open "${label}"? Current in-editor state will be replaced.`);
}

function builderCanLoadSavedProject() {
  return typeof window.__VTB_LOAD_SAVED_PROJECT__ === 'function';
}

export function buildProjectAssetUrl(sessionId, filename) {
  if (!sessionId || !filename) return '';
  return `/api/project/${encodeURIComponent(sessionId)}/file/${encodeURIComponent(filename)}`;
}

function normalizeSceneFileForBuilder(sessionId, fileRef) {
  if (typeof fileRef !== 'string') return fileRef;
  if (fileRef === '') return fileRef;
  if (fileRef.startsWith('/api/project/') || fileRef.startsWith('http') || fileRef.startsWith('blob:')) {
    const fileMarker = '/file/';
    const markerIndex = fileRef.indexOf(fileMarker);
    if (markerIndex >= 0) {
      const filename = fileRef.slice(markerIndex + fileMarker.length).split('?')[0].split('#')[0];
      return buildProjectAssetUrl(sessionId, filename);
    }
    return fileRef;
  }
  return buildProjectAssetUrl(sessionId, fileRef.split('/').pop() || fileRef);
}

function normalizeInventoryForBuilder(sessionId, inventory) {
  if (!Array.isArray(inventory)) return inventory;
  return inventory.map(item => {
    const scene = item?.entry?.scene;
    if (!scene || typeof scene !== 'object') return item;
    return {
      ...item,
      entry: {
        ...item.entry,
        scene: {
          ...scene,
          file: normalizeSceneFileForBuilder(sessionId, scene.file),
          originalFile: normalizeSceneFileForBuilder(sessionId, scene.originalFile),
          tinyFile: normalizeSceneFileForBuilder(sessionId, scene.tinyFile),
        },
      },
    };
  });
}

export function normalizeLogoForBuilder(sessionId, logo) {
  if (!logo) return logo;
  if (typeof logo !== 'string') return logo;
  if (logo === 'logo_upload') return buildProjectAssetUrl(sessionId, 'logo_upload');
  if (logo.startsWith('/api/project/') || logo.startsWith('http')) {
    const fileMarker = '/file/';
    const markerIndex = logo.indexOf(fileMarker);
    if (markerIndex >= 0) {
      const filename = logo.slice(markerIndex + fileMarker.length).split('?')[0].split('#')[0];
      return buildProjectAssetUrl(sessionId, filename);
    }
    return logo;
  }
  if (logo.trim() !== '') return buildProjectAssetUrl(sessionId, logo.split('/').pop() || logo);
  return logo;
}

export function normalizeProjectDataForBuilder(sessionId, projectData) {
  if (!projectData || typeof projectData !== 'object') return projectData;
  const normalized = { ...projectData };
  normalized.sessionId = sessionId;
  if (Object.prototype.hasOwnProperty.call(normalized, 'inventory')) {
    normalized.inventory = normalizeInventoryForBuilder(sessionId, normalized.inventory);
  }
  if (Array.isArray(normalized.scenes)) {
    normalized.scenes = normalized.scenes.map(scene => ({
      ...scene,
      file: normalizeSceneFileForBuilder(sessionId, scene.file),
      originalFile: normalizeSceneFileForBuilder(sessionId, scene.originalFile),
      tinyFile: normalizeSceneFileForBuilder(sessionId, scene.tinyFile),
    }));
  }
  if (Object.prototype.hasOwnProperty.call(normalized, 'logo')) {
    normalized.logo = normalizeLogoForBuilder(sessionId, normalized.logo);
  }
  return normalized;
}

async function applySavedProjectToBuilder(sessionId, projectData, label) {
  if (!builderCanLoadSavedProject()) {
    throw new Error('Builder is still starting. Try again in a moment.');
  }
  await window.__VTB_LOAD_SAVED_PROJECT__(
    sessionId,
    normalizeProjectDataForBuilder(sessionId, projectData),
    label
  );
  window.history.replaceState({}, '', `/builder?projectId=${encodeURIComponent(sessionId)}`);
}

export async function fetchDashboardProjects() {
  const auth = getAuthHeaderValue();
  const headers = {};
  if (auth) headers.Authorization = auth;
  const response = await fetch('/api/project/dashboard/projects', {
    method: 'GET',
    headers,
    credentials: 'include',
  });
  if (!response.ok) throw new Error(`HTTP_${response.status}`);
  return response.json();
}

export async function fetchProjectSnapshots(sessionId) {
  const auth = getAuthHeaderValue();
  const headers = {};
  if (auth) headers.Authorization = auth;
  const response = await fetch(`/api/project/dashboard/projects/${encodeURIComponent(sessionId)}/snapshots`, {
    method: 'GET',
    headers,
    credentials: 'include',
  });
  if (!response.ok) throw new Error(`HTTP_${response.status}`);
  return response.json();
}

async function fetchLatestProject(sessionId) {
  const auth = getAuthHeaderValue();
  const headers = {};
  if (auth) headers.Authorization = auth;
  const response = await fetch(`/api/project/dashboard/projects/${encodeURIComponent(sessionId)}`, {
    method: 'GET',
    headers,
    credentials: 'include',
  });
  if (!response.ok) throw new Error(`HTTP_${response.status}`);
  return response.json();
}

async function fetchSnapshotProject(sessionId, snapshotId) {
  const auth = getAuthHeaderValue();
  const headers = {};
  if (auth) headers.Authorization = auth;
  const response = await fetch(
    `/api/project/dashboard/projects/${encodeURIComponent(sessionId)}/snapshots/${encodeURIComponent(snapshotId)}`,
    {
      method: 'GET',
      headers,
      credentials: 'include',
    }
  );
  if (!response.ok) throw new Error(`HTTP_${response.status}`);
  return response.json();
}

export async function deleteDashboardProject(sessionId) {
  return authJson(`/api/project/dashboard/projects/${encodeURIComponent(sessionId)}`, null, 'DELETE');
}

export async function duplicateDashboardProject(sessionId) {
  return authJson(`/api/project/dashboard/projects/${encodeURIComponent(sessionId)}/duplicate`, null, 'POST');
}

function builderProjectRow(project) {
  const sessionId = escapeHtml(project.sessionId || '');
  const projectName = escapeHtml(project.tourName || 'Untitled Tour');
  const updated = escapeHtml(project.updatedAt || '-');
  const scenes = Number.isFinite(project.sceneCount) ? project.sceneCount : 0;
  const history = builderPickerState.histories[project.sessionId];
  const historyError = builderPickerState.historyErrors[project.sessionId] || '';
  const historyLoading = Boolean(builderPickerState.historyLoading[project.sessionId]);

  return `
    <article class="builder-project-row">
      <div class="builder-project-main">
        <div>
          <h3>${projectName}</h3>
          <p>${scenes} scene${scenes === 1 ? '' : 's'} • Updated ${updated}</p>
        </div>
        <div class="builder-project-actions">
          <button class="site-btn site-btn-primary" type="button" data-builder-open-latest="${sessionId}" data-project-name="${projectName}">
            Open Latest
          </button>
          <button class="site-btn site-btn-ghost" type="button" data-builder-history-toggle="${sessionId}">
            ${history ? 'Hide History' : 'Show History'}
          </button>
        </div>
      </div>
      ${
        history
          ? `
            <div class="builder-history-list">
              ${historyLoading ? '<p class="site-muted">Loading snapshot history…</p>' : ''}
              ${historyError ? `<p class="builder-modal-error">${escapeHtml(historyError)}</p>` : ''}
              ${
                history.length === 0
                  ? '<p class="site-muted">No retained snapshots yet.</p>'
                  : history
                      .map(
                        item => `
                          <div class="builder-history-row">
                            <div>
                              <strong>${escapeHtml(item.tourName || 'Snapshot')}</strong>
                              <span>${escapeHtml(formatShortTimestamp(item.createdAt || '-'))} • ${escapeHtml((item.origin || 'auto').toUpperCase())} • ${item.sceneCount || 0} scenes • ${item.hotspotCount || 0} hotspots</span>
                            </div>
                            <button
                              class="site-btn site-btn-ghost"
                              type="button"
                              data-builder-open-snapshot="${escapeHtml(item.snapshotId || '')}"
                              data-builder-session-id="${sessionId}"
                              data-project-name="${projectName}"
                            >
                              Open Snapshot
                            </button>
                          </div>
                        `
                      )
                      .join('')
              }
            </div>
          `
          : ''
      }
    </article>
  `;
}

function renderBuilderProjectPicker() {
  const modal = builderModalRoot();
  if (!modal) return;
  modal.hidden = !builderPickerState.isOpen;
  if (!builderPickerState.isOpen) {
    modal.innerHTML = '';
    return;
  }

  const session = window.__VTB_AUTH_SESSION__ || { authenticated: false, user: null };
  let body = '';

  if (!session.authenticated) {
    body = `
      <div class="builder-modal-state">
        <p class="site-muted">Sign in to open saved tours and restore retained snapshots.</p>
        <div class="site-hero-actions">
          <a class="site-btn site-btn-primary" href="/signin">Sign In</a>
          <a class="site-btn site-btn-ghost" href="/signup">Create Account</a>
        </div>
      </div>
    `;
  } else if (builderPickerState.loading) {
    body = `<div class="builder-modal-state"><p class="site-muted">Loading your saved tours…</p></div>`;
  } else if (builderPickerState.error) {
    body = `<div class="builder-modal-state"><p class="builder-modal-error">${escapeHtml(builderPickerState.error)}</p></div>`;
  } else if (!builderPickerState.projects.length) {
    body = `<div class="builder-modal-state"><p class="site-muted">No saved tours yet. Start editing and the backend snapshot history will begin automatically.</p></div>`;
  } else {
    body = builderPickerState.projects.map(builderProjectRow).join('');
  }

  modal.innerHTML = `
    <div class="builder-modal-backdrop" data-builder-close-modal="1"></div>
    <div class="builder-modal-card" role="dialog" aria-modal="true" aria-label="Open saved tour">
      <div class="builder-modal-head">
        <div>
          <h2>Open Saved Tour</h2>
          <p class="site-muted">Load the latest project state or open one of the retained backend snapshots.</p>
        </div>
        <button class="site-btn site-btn-ghost" type="button" data-builder-close-modal="1">Close</button>
      </div>
      <div class="builder-modal-body">${body}</div>
    </div>
  `;
}

export async function openBuilderProjectPicker() {
  builderPickerState.isOpen = true;
  builderPickerState.loading = true;
  builderPickerState.error = '';
  renderBuilderProjectPicker();

  try {
    const projects = await fetchDashboardProjects();
    builderPickerState.projects = Array.isArray(projects) ? projects : [];
    builderPickerState.loading = false;
    renderBuilderProjectPicker();
  } catch (_error) {
    builderPickerState.loading = false;
    builderPickerState.error = 'Failed to load saved tours.';
    renderBuilderProjectPicker();
  }
}

export function installBuilderTourPickerBridge() {
  window.__VTB_OPEN_TOUR_PICKER__ = () => {
    openBuilderProjectPicker();
  };
}

export function closeBuilderProjectPicker() {
  builderPickerState.isOpen = false;
  renderBuilderProjectPicker();
}

export async function toggleBuilderProjectHistory(sessionId) {
  if (builderPickerState.histories[sessionId]) {
    delete builderPickerState.histories[sessionId];
    delete builderPickerState.historyErrors[sessionId];
    delete builderPickerState.historyLoading[sessionId];
    renderBuilderProjectPicker();
    return;
  }

  builderPickerState.historyLoading[sessionId] = true;
  builderPickerState.historyErrors[sessionId] = '';
  builderPickerState.histories[sessionId] = [];
  renderBuilderProjectPicker();

  try {
    const snapshots = await fetchProjectSnapshots(sessionId);
    builderPickerState.histories[sessionId] = Array.isArray(snapshots) ? snapshots : [];
  } catch (_error) {
    builderPickerState.historyErrors[sessionId] = 'Failed to load snapshot history.';
  } finally {
    builderPickerState.historyLoading[sessionId] = false;
    renderBuilderProjectPicker();
  }
}

export async function handleBuilderLatestOpen(sessionId, label) {
  if (!confirmBuilderProjectReplace(label)) return;
  try {
    const payload = await fetchLatestProject(sessionId);
    await applySavedProjectToBuilder(payload.sessionId || sessionId, payload.projectData, label);
    closeBuilderProjectPicker();
  } catch (error) {
    builderPickerState.error = error?.message || 'Failed to open saved tour.';
    renderBuilderProjectPicker();
  }
}

export async function handleBuilderSnapshotOpen(sessionId, snapshotId, label) {
  if (!confirmBuilderProjectReplace(`${label} snapshot`)) return;
  try {
    const payload = await fetchSnapshotProject(sessionId, snapshotId);
    await applySavedProjectToBuilder(
      payload.sessionId || sessionId,
      payload.projectData,
      `${label} snapshot`
    );
    closeBuilderProjectPicker();
  } catch (error) {
    builderPickerState.error = error?.message || 'Failed to open snapshot.';
    renderBuilderProjectPicker();
  }
}
