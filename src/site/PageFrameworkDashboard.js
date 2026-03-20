// @efficiency-role: ui-component
import {
  bulkDeleteDashboardProjects,
  deleteDashboardProject,
  duplicateDashboardProject,
  fetchDashboardProjects,
  fetchProjectSnapshots,
} from './PageFrameworkBuilder.js';
import { escapeHtml, formatShortTimestamp } from './PageFrameworkShared.js';

const DASHBOARD_PAGE_SIZE = 20;

const dashboardHistoryState = {
  histories: {},
  loading: {},
  errors: {},
};

const dashboardPageState = {
  currentPage: 1,
  pageSize: DASHBOARD_PAGE_SIZE,
  totalPages: 1,
  totalItems: 0,
  currentItems: [],
  selectedProjects: {},
  selectAllPending: false,
};

function selectedProjectEntries() {
  return Object.entries(dashboardPageState.selectedProjects);
}

function selectedProjectCount() {
  return selectedProjectEntries().length;
}

async function fetchAllDashboardProjects() {
  const firstPayload = normalizeDashboardResponse(
    await fetchDashboardProjects(1, dashboardPageState.pageSize)
  );
  let items = [...firstPayload.items];

  for (let page = 2; page <= firstPayload.totalPages; page += 1) {
    const payload = normalizeDashboardResponse(
      await fetchDashboardProjects(page, dashboardPageState.pageSize)
    );
    items = items.concat(payload.items);
  }

  return items;
}

function removeBulkDeleteDialog() {
  const existing = document.querySelector('[data-dashboard-bulk-dialog="1"]');
  if (existing) existing.remove();
}

function renderDashboardHistoryRows(project) {
  const history = dashboardHistoryState.histories[project.sessionId];
  if (!history) return '';

  const loading = Boolean(dashboardHistoryState.loading[project.sessionId]);
  const error = dashboardHistoryState.errors[project.sessionId] || '';
  const colSpan = 6;

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

function renderPagination() {
  const container = document.getElementById('site-dashboard-pagination');
  if (!container) return;

  if (dashboardPageState.totalItems === 0) {
    container.innerHTML = '';
    return;
  }

  container.innerHTML = `
    <button
      class="site-btn site-btn-ghost"
      type="button"
      data-dashboard-page="${dashboardPageState.currentPage - 1}"
      ${dashboardPageState.currentPage <= 1 ? 'disabled' : ''}
    >
      Previous
    </button>
    <span class="site-dashboard-pagination-copy">
      Page ${dashboardPageState.currentPage} of ${dashboardPageState.totalPages}
    </span>
    <button
      class="site-btn site-btn-ghost"
      type="button"
      data-dashboard-page="${dashboardPageState.currentPage + 1}"
      ${dashboardPageState.currentPage >= dashboardPageState.totalPages ? 'disabled' : ''}
    >
      Next
    </button>
  `;
}

function updateDashboardToolbar() {
  const summary = document.getElementById('site-dashboard-summary');
  const bulkDelete = document.getElementById('site-dashboard-bulk-delete');
  const selectAll = document.getElementById('site-dashboard-select-all');
  if (summary) {
    if (dashboardPageState.totalItems === 0) {
      summary.textContent = 'No saved tours yet.';
    } else {
      const start = (dashboardPageState.currentPage - 1) * dashboardPageState.pageSize + 1;
      const end = start + dashboardPageState.currentItems.length - 1;
      const selected = selectedProjectCount();
      summary.textContent = dashboardPageState.selectAllPending
        ? 'Selecting all tours...'
        : `Showing ${start}-${end} of ${dashboardPageState.totalItems} tours` +
          (selected > 0 ? ` • ${selected} selected` : '');
    }
  }
  if (bulkDelete) {
    bulkDelete.disabled = selectedProjectCount() === 0 || dashboardPageState.selectAllPending;
  }
  if (selectAll) {
    const selected = selectedProjectCount();
    selectAll.checked = dashboardPageState.totalItems > 0 && selected === dashboardPageState.totalItems;
    selectAll.indeterminate = selected > 0 && selected < dashboardPageState.totalItems;
    selectAll.disabled = dashboardPageState.selectAllPending;
  }
}

function clearDeletedDashboardState(sessionIds) {
  for (const sessionId of sessionIds) {
    delete dashboardPageState.selectedProjects[sessionId];
    delete dashboardHistoryState.histories[sessionId];
    delete dashboardHistoryState.loading[sessionId];
    delete dashboardHistoryState.errors[sessionId];
  }
}

export function openDashboardBulkDeleteDialog() {
  const selected = selectedProjectEntries();
  if (selected.length === 0) return;

  removeBulkDeleteDialog();

  const backdrop = document.createElement('div');
  backdrop.className = 'site-dialog-backdrop';
  backdrop.setAttribute('data-dashboard-bulk-dialog', '1');

  const dialog = document.createElement('div');
  dialog.className = 'site-dialog';
  dialog.setAttribute('role', 'dialog');
  dialog.setAttribute('aria-modal', 'true');
  dialog.setAttribute('aria-labelledby', 'site-dashboard-bulk-title');

  const title = document.createElement('h2');
  title.id = 'site-dashboard-bulk-title';
  title.textContent = `Delete ${selected.length} tour${selected.length === 1 ? '' : 's'}?`;

  const body = document.createElement('p');
  body.textContent = 'This removes the selected projects and their retained snapshots. This cannot be undone.';

  const list = document.createElement('div');
  list.className = 'site-dashboard-bulk-list';
  const selectedLabels = Object.fromEntries(selected);
  selected.slice(0, 12).forEach(([, label]) => {
    const item = document.createElement('div');
    item.className = 'site-dashboard-bulk-list-item';
    item.textContent = label || 'Untitled Tour';
    list.appendChild(item);
  });

  if (selected.length > 12) {
    const extra = document.createElement('p');
    extra.className = 'site-muted';
    extra.textContent = `${selected.length - 12} more selected tour${selected.length - 12 === 1 ? '' : 's'} will also be deleted.`;
    list.appendChild(extra);
  }

  const error = document.createElement('p');
  error.className = 'builder-modal-error';
  error.hidden = true;

  const actions = document.createElement('div');
  actions.className = 'site-dialog-actions';

  const cancelButton = document.createElement('button');
  cancelButton.type = 'button';
  cancelButton.className = 'site-btn site-btn-ghost';
  cancelButton.textContent = 'Cancel';
  cancelButton.addEventListener('click', () => removeBulkDeleteDialog());

  const confirmButton = document.createElement('button');
  confirmButton.type = 'button';
  confirmButton.className = 'site-btn site-btn-primary';
  confirmButton.textContent = 'Delete Selected';
  confirmButton.addEventListener('click', async () => {
    confirmButton.disabled = true;
    cancelButton.disabled = true;
    confirmButton.textContent = 'Deleting...';
    error.hidden = true;

    try {
      const response = await bulkDeleteDashboardProjects(selected.map(([sessionId]) => sessionId));
      const deletedSessionIds = Array.isArray(response?.deletedSessionIds) ? response.deletedSessionIds : [];
      const failures = Array.isArray(response?.failures) ? response.failures : [];

      clearDeletedDashboardState(deletedSessionIds);
      await loadDashboardProjects(dashboardPageState.currentPage);

      if (failures.length === 0) {
        removeBulkDeleteDialog();
        return;
      }

      failures.forEach(item => {
        if (item?.sessionId) {
          dashboardPageState.selectedProjects[item.sessionId] =
            selectedLabels[item.sessionId] || item.sessionId || 'Untitled Tour';
        }
      });
      const failureText = failures
        .slice(0, 6)
        .map(item => {
          const label = selectedLabels[item?.sessionId] || item?.sessionId || 'Unknown tour';
          const details = item?.error || 'Delete failed';
          return `${label}: ${details}`;
        })
        .join(' | ');
      error.hidden = false;
      error.textContent =
        failures.length > 6
          ? `${failureText} | ${failures.length - 6} more failed.`
          : failureText;
      confirmButton.disabled = false;
      cancelButton.disabled = false;
      confirmButton.textContent = 'Delete Remaining';
      updateDashboardToolbar();
    } catch (_error) {
      error.hidden = false;
      error.textContent = 'Bulk delete request failed before the batch completed.';
      confirmButton.disabled = false;
      cancelButton.disabled = false;
      confirmButton.textContent = 'Delete Selected';
    }
  });

  actions.appendChild(cancelButton);
  actions.appendChild(confirmButton);
  dialog.appendChild(title);
  dialog.appendChild(body);
  dialog.appendChild(list);
  dialog.appendChild(error);
  dialog.appendChild(actions);
  backdrop.appendChild(dialog);
  document.body.appendChild(backdrop);
  confirmButton.focus();
}

export function toggleDashboardProjectSelection(sessionId, label, checked) {
  if (!sessionId) return;
  if (checked) {
    dashboardPageState.selectedProjects[sessionId] = label || 'Untitled Tour';
  } else {
    delete dashboardPageState.selectedProjects[sessionId];
  }
  updateDashboardToolbar();
}

export async function toggleDashboardSelectAll(checked) {
  if (!checked) {
    dashboardPageState.selectedProjects = {};
    updateDashboardToolbar();
    await loadDashboardProjects(dashboardPageState.currentPage);
    return;
  }

  dashboardPageState.selectAllPending = true;
  updateDashboardToolbar();

  try {
    const allProjects = await fetchAllDashboardProjects();
    dashboardPageState.selectedProjects = allProjects.reduce((acc, project) => {
      if (project?.sessionId) {
        acc[project.sessionId] = project.tourName || 'Untitled Tour';
      }
      return acc;
    }, {});
  } finally {
    dashboardPageState.selectAllPending = false;
    updateDashboardToolbar();
    await loadDashboardProjects(dashboardPageState.currentPage);
  }
}

export async function changeDashboardPage(page) {
  const nextPage = Number.parseInt(String(page), 10);
  if (!Number.isFinite(nextPage) || nextPage < 1 || nextPage === dashboardPageState.currentPage) return;
  await loadDashboardProjects(nextPage);
}

export async function toggleDashboardProjectHistory(sessionId) {
  if (dashboardHistoryState.histories[sessionId]) {
    delete dashboardHistoryState.histories[sessionId];
    delete dashboardHistoryState.loading[sessionId];
    delete dashboardHistoryState.errors[sessionId];
    await loadDashboardProjects(dashboardPageState.currentPage);
    return;
  }

  dashboardHistoryState.loading[sessionId] = true;
  dashboardHistoryState.errors[sessionId] = '';
  dashboardHistoryState.histories[sessionId] = [];
  await loadDashboardProjects(dashboardPageState.currentPage);

  try {
    const snapshots = await fetchProjectSnapshots(sessionId);
    dashboardHistoryState.histories[sessionId] = Array.isArray(snapshots) ? snapshots : [];
  } catch (_error) {
    dashboardHistoryState.errors[sessionId] = 'Failed to load snapshot history.';
  } finally {
    dashboardHistoryState.loading[sessionId] = false;
    await loadDashboardProjects(dashboardPageState.currentPage);
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
    delete dashboardPageState.selectedProjects[sessionId];
    delete dashboardHistoryState.histories[sessionId];
    delete dashboardHistoryState.loading[sessionId];
    delete dashboardHistoryState.errors[sessionId];
    await loadDashboardProjects(dashboardPageState.currentPage);
  } catch (_error) {
    window.alert('Failed to delete the project.');
  }
}

export async function handleDashboardProjectDuplicate(sessionId, label) {
  const confirmed = window.confirm(
    `Duplicate "${label}"? Only the latest restorable project state will be copied.`
  );
  if (!confirmed) return;

  try {
    await duplicateDashboardProject(sessionId);
    await loadDashboardProjects(dashboardPageState.currentPage);
  } catch (_error) {
    window.alert('Failed to duplicate the project.');
  }
}

function normalizeDashboardResponse(payload) {
  if (Array.isArray(payload)) {
    return {
      items: payload,
      page: 1,
      pageSize: DASHBOARD_PAGE_SIZE,
      totalItems: payload.length,
      totalPages: Math.max(1, Math.ceil(payload.length / DASHBOARD_PAGE_SIZE)),
    };
  }

  return {
    items: Array.isArray(payload?.items) ? payload.items : [],
    page: Number.isFinite(payload?.page) ? payload.page : 1,
    pageSize: Number.isFinite(payload?.pageSize) ? payload.pageSize : DASHBOARD_PAGE_SIZE,
    totalItems: Number.isFinite(payload?.totalItems) ? payload.totalItems : 0,
    totalPages: Number.isFinite(payload?.totalPages) ? payload.totalPages : 1,
  };
}

export async function loadDashboardProjects(page = dashboardPageState.currentPage) {
  const tbody = document.getElementById('site-dashboard-projects');
  if (!tbody) return;

  try {
    const payload = await fetchDashboardProjects(page, dashboardPageState.pageSize);
    const normalized = normalizeDashboardResponse(payload);
    dashboardPageState.currentItems = normalized.items;
    dashboardPageState.currentPage = normalized.page;
    dashboardPageState.pageSize = normalized.pageSize;
    dashboardPageState.totalItems = normalized.totalItems;
    dashboardPageState.totalPages = normalized.totalPages;

    if (!Array.isArray(normalized.items) || normalized.items.length === 0) {
      tbody.innerHTML = `<tr><td colspan="6">No saved tours yet.</td></tr>`;
      updateDashboardToolbar();
      renderPagination();
      return;
    }

    tbody.innerHTML = normalized.items
      .map(project => {
        const rawSessionId = project.sessionId || '';
        const sessionId = encodeURIComponent(rawSessionId);
        const projectName = project.tourName || 'Untitled Tour';
        const scenes = Number.isFinite(project.sceneCount) ? project.sceneCount : 0;
        const updated = formatShortTimestamp(project.updatedAt || '-');
        const isHistoryOpen = Boolean(dashboardHistoryState.histories[rawSessionId]);
        const isSelected = Boolean(dashboardPageState.selectedProjects[rawSessionId]);
        return `
          <tr>
            <td>
              <input
                type="checkbox"
                aria-label="Select ${escapeHtml(projectName)}"
                data-dashboard-select="${escapeHtml(rawSessionId)}"
                data-project-name="${escapeHtml(projectName)}"
                ${isSelected ? 'checked' : ''}
              />
            </td>
            <td>${escapeHtml(projectName)}</td>
            <td>${scenes}</td>
            <td>${escapeHtml(updated)}</td>
            <td><span class="site-chip">Saved</span></td>
            <td>
              <div class="site-table-actions">
                <a class="site-link" href="/builder?projectId=${sessionId}">Open Builder</a>
                <button class="site-link site-link-button" type="button" data-dashboard-duplicate="${escapeHtml(rawSessionId)}" data-project-name="${escapeHtml(projectName)}">
                  Duplicate
                </button>
                <button class="site-link site-link-button" type="button" data-dashboard-history-toggle="${escapeHtml(rawSessionId)}">
                  ${isHistoryOpen ? 'Hide History' : 'History'}
                </button>
                <button class="site-icon-button" type="button" aria-label="Delete project" title="Delete project" data-dashboard-delete="${escapeHtml(rawSessionId)}" data-project-name="${escapeHtml(projectName)}">🗑</button>
              </div>
            </td>
          </tr>${renderDashboardHistoryRows(project)}
        `;
      })
      .join('');

    updateDashboardToolbar();
    renderPagination();
  } catch (_error) {
    tbody.innerHTML = `<tr><td colspan="6">Failed to load dashboard projects.</td></tr>`;
    dashboardPageState.currentItems = [];
    dashboardPageState.totalItems = 0;
    dashboardPageState.totalPages = 1;
    updateDashboardToolbar();
    renderPagination();
  }
}
