// @efficiency-role: ui-component
import {
  deleteDashboardProject,
  fetchDashboardProjects,
  fetchProjectSnapshots,
} from './PageFrameworkBuilder.js';
import { escapeHtml, formatShortTimestamp } from './PageFrameworkShared.js';

const dashboardHistoryState = {
  histories: {},
  loading: {},
  errors: {},
};

function renderDashboardHistoryRows(project) {
  const history = dashboardHistoryState.histories[project.sessionId];
  if (!history) return '';

  const loading = Boolean(dashboardHistoryState.loading[project.sessionId]);
  const error = dashboardHistoryState.errors[project.sessionId] || '';
  const colSpan = 5;

  return `
    <tr class="site-dashboard-history-row">
      <td colspan="${colSpan}">
        <div class="site-dashboard-history-panel">
          ${loading ? '<p class="site-muted">Loading snapshot history...</p>' : ''}
          ${error ? `<p class="builder-modal-error">${escapeHtml(error)}</p>` : ''}
          ${
            !loading && !error && history.length === 0
              ? '<p class="site-muted">No retained snapshots yet.</p>'
              : ''
          }
          ${
            history
              .map(
                item => `
                  <div class="site-dashboard-history-item">
                    <div>
                      <strong>${escapeHtml(item.tourName || 'Snapshot')}</strong>
                      <span>${escapeHtml(formatShortTimestamp(item.createdAt || '-'))} • ${escapeHtml((item.origin || 'auto').toUpperCase())} • ${item.sceneCount || 0} scenes • ${item.hotspotCount || 0} hotspots</span>
                    </div>
                    <button
                      class="site-link site-link-button"
                      type="button"
                      data-dashboard-open-snapshot="${escapeHtml(item.snapshotId || '')}"
                      data-dashboard-session-id="${escapeHtml(project.sessionId || '')}"
                      data-project-name="${escapeHtml(project.tourName || 'Untitled Tour')}"
                    >
                      Open in Builder
                    </button>
                  </div>
                `
              )
              .join('')
          }
        </div>
      </td>
    </tr>
  `;
}

export async function toggleDashboardProjectHistory(sessionId) {
  if (dashboardHistoryState.histories[sessionId]) {
    delete dashboardHistoryState.histories[sessionId];
    delete dashboardHistoryState.loading[sessionId];
    delete dashboardHistoryState.errors[sessionId];
    await loadDashboardProjects();
    return;
  }

  dashboardHistoryState.loading[sessionId] = true;
  dashboardHistoryState.errors[sessionId] = '';
  dashboardHistoryState.histories[sessionId] = [];
  await loadDashboardProjects();

  try {
    const snapshots = await fetchProjectSnapshots(sessionId);
    dashboardHistoryState.histories[sessionId] = Array.isArray(snapshots) ? snapshots : [];
  } catch (_error) {
    dashboardHistoryState.errors[sessionId] = 'Failed to load snapshot history.';
  } finally {
    dashboardHistoryState.loading[sessionId] = false;
    await loadDashboardProjects();
  }
}

export async function handleDashboardSnapshotOpen(sessionId, snapshotId, label) {
  const confirmed = window.confirm(`Open "${label}" snapshot in the builder?`);
  if (!confirmed) return;
  window.location.assign(
    `/builder?projectId=${encodeURIComponent(sessionId)}&snapshotId=${encodeURIComponent(snapshotId)}`
  );
}

export async function handleDashboardProjectDelete(sessionId, label) {
  const confirmed = window.confirm(`Delete "${label}"? This removes the project and its retained snapshots.`);
  if (!confirmed) return;
  try {
    await deleteDashboardProject(sessionId);
    delete dashboardHistoryState.histories[sessionId];
    delete dashboardHistoryState.loading[sessionId];
    delete dashboardHistoryState.errors[sessionId];
    await loadDashboardProjects();
  } catch (_error) {
    window.alert('Failed to delete the project.');
  }
}

export async function loadDashboardProjects() {
  const tbody = document.getElementById('site-dashboard-projects');
  if (!tbody) return;

  try {
    const projects = await fetchDashboardProjects();
    if (!Array.isArray(projects) || projects.length === 0) {
      tbody.innerHTML = `<tr><td colspan="5">No saved tours yet.</td></tr>`;
      return;
    }

    tbody.innerHTML = projects
      .map(project => {
        const sessionId = encodeURIComponent(project.sessionId || '');
        const projectName = project.tourName || 'Untitled Tour';
        const scenes = Number.isFinite(project.sceneCount) ? project.sceneCount : 0;
        const updated = formatShortTimestamp(project.updatedAt || '-');
        const isHistoryOpen = Boolean(dashboardHistoryState.histories[project.sessionId]);
        return `
          <tr>
            <td>${escapeHtml(projectName)}</td>
            <td>${scenes}</td>
            <td>${escapeHtml(updated)}</td>
            <td><span class="site-chip">Saved</span></td>
            <td>
              <div class="site-table-actions">
                <a class="site-link" href="/builder?projectId=${sessionId}">Open Builder</a>
                <button class="site-link site-link-button" type="button" data-dashboard-history-toggle="${sessionId}">
                  ${isHistoryOpen ? 'Hide History' : 'History'}
                </button>
                <button class="site-icon-button" type="button" aria-label="Delete project" title="Delete project" data-dashboard-delete="${sessionId}" data-project-name="${escapeHtml(projectName)}">🗑</button>
              </div>
            </td>
          </tr>${renderDashboardHistoryRows(project)}
        `;
      })
      .join('');
  } catch (_error) {
    tbody.innerHTML = `<tr><td colspan="5">Failed to load dashboard projects.</td></tr>`;
  }
}
