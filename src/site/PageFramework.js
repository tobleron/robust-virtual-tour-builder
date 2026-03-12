// @efficiency-role: orchestrator
import {
  buildProjectAssetUrl,
  closeBuilderProjectPicker,
  handleBuilderLatestOpen,
  handleBuilderSnapshotOpen,
  installBuilderTourPickerBridge,
  normalizeLogoForBuilder,
  normalizeProjectDataForBuilder,
  openBuilderProjectPicker,
  toggleBuilderProjectHistory,
} from './PageFrameworkBuilder.js';
import {
  bindAuthForms,
  getAuthSession,
  redirectIfProtectedPageRequiresAuth,
  signOutAndRedirect,
  updateAuthSurfaces,
} from './PageFrameworkAuth.js';
import {
  handleDashboardProjectDelete,
  handleDashboardProjectDuplicate,
  handleDashboardSnapshotOpen,
  loadDashboardProjects,
  toggleDashboardProjectHistory,
} from './PageFrameworkDashboard.js';
import {
  contentFor,
  footer,
  nav,
  renderAuthActions,
  resolveAppSurface,
  titleFor,
} from './PageFrameworkShared.js';

function bindGlobalChromeHandlers() {
  if (document.body.getAttribute('data-auth-chrome-bound') === '1') return;
  document.body.setAttribute('data-auth-chrome-bound', '1');

  document.addEventListener('click', event => {
    const target = event.target;
    if (!(target instanceof Element)) return;

    const signOutButton = target.closest('[data-auth-signout="1"]');
    if (signOutButton) {
      event.preventDefault();
      signOutAndRedirect();
      return;
    }

    const openTourButton = target.closest('[data-builder-open-tour="1"]');
    if (openTourButton) {
      event.preventDefault();
      openBuilderProjectPicker();
      return;
    }

    const closeModalButton = target.closest('[data-builder-close-modal="1"]');
    if (closeModalButton) {
      event.preventDefault();
      closeBuilderProjectPicker();
      return;
    }

    const latestButton = target.closest('[data-builder-open-latest]');
    if (latestButton) {
      event.preventDefault();
      handleBuilderLatestOpen(
        latestButton.getAttribute('data-builder-open-latest') || '',
        latestButton.getAttribute('data-project-name') || 'saved tour'
      );
      return;
    }

    const historyButton = target.closest('[data-builder-history-toggle]');
    if (historyButton) {
      event.preventDefault();
      toggleBuilderProjectHistory(historyButton.getAttribute('data-builder-history-toggle') || '');
      return;
    }

    const openSnapshotButton = target.closest('[data-builder-open-snapshot]');
    if (openSnapshotButton) {
      event.preventDefault();
      handleBuilderSnapshotOpen(
        openSnapshotButton.getAttribute('data-builder-session-id') || '',
        openSnapshotButton.getAttribute('data-builder-open-snapshot') || '',
        openSnapshotButton.getAttribute('data-project-name') || 'saved tour'
      );
      return;
    }

    const dashboardHistoryToggle = target.closest('[data-dashboard-history-toggle]');
    if (dashboardHistoryToggle) {
      event.preventDefault();
      toggleDashboardProjectHistory(dashboardHistoryToggle.getAttribute('data-dashboard-history-toggle') || '');
      return;
    }

    const dashboardSnapshotOpen = target.closest('[data-dashboard-open-snapshot]');
    if (dashboardSnapshotOpen) {
      event.preventDefault();
      handleDashboardSnapshotOpen(
        dashboardSnapshotOpen.getAttribute('data-dashboard-session-id') || '',
        dashboardSnapshotOpen.getAttribute('data-dashboard-open-snapshot') || '',
        dashboardSnapshotOpen.getAttribute('data-project-name') || 'saved tour'
      );
      return;
    }

    const deleteButton = target.closest('[data-dashboard-delete]');
    if (deleteButton) {
      event.preventDefault();
      handleDashboardProjectDelete(
        deleteButton.getAttribute('data-dashboard-delete') || '',
        deleteButton.getAttribute('data-project-name') || 'saved tour'
      );
      return;
    }

    const duplicateButton = target.closest('[data-dashboard-duplicate]');
    if (duplicateButton) {
      event.preventDefault();
      handleDashboardProjectDuplicate(
        duplicateButton.getAttribute('data-dashboard-duplicate') || '',
        duplicateButton.getAttribute('data-project-name') || 'saved tour'
      );
    }
  });
}

export function renderPageFramework(rootElement, page) {
  if (!rootElement) return;
  bindGlobalChromeHandlers();
  document.body.classList.add('site-framework-mode');
  document.title = `Robust Virtual Tour Builder | ${titleFor(page)}`;

  rootElement.innerHTML = `
    <div class="site-shell" id="main-content">
      ${nav(page)}
      <main class="site-main">
        ${contentFor(page)}
      </main>
      ${footer()}
    </div>
  `;

  bindAuthForms(page);
  getAuthSession().then(session => {
    window.__VTB_AUTH_SESSION__ = session;
    updateAuthSurfaces(session);
    if (!redirectIfProtectedPageRequiresAuth(page, session)) return;
    if (page === 'dashboard') loadDashboardProjects();
  });
}

export function renderBuilderFramework(rootElement) {
  if (!rootElement) return;
  bindGlobalChromeHandlers();
  document.body.classList.add('builder-overlay-mode');
  document.title = 'Robust Virtual Tour Builder | Builder';

  if (!document.getElementById('builder-shell-overlay')) {
    const overlay = document.createElement('div');
    overlay.id = 'builder-shell-overlay';
    overlay.className = 'builder-overlay-bar';
    overlay.innerHTML = `
      <div class="builder-overlay-left">
        <a class="site-btn site-btn-ghost" href="/dashboard">Back to Dashboard</a>
      </div>
      <div class="builder-overlay-right" data-auth-surface="builder">
        ${renderAuthActions({ authenticated: false, user: null }, 'builder')}
      </div>
    `;
    document.body.appendChild(overlay);
  }

  if (!document.getElementById('builder-project-modal')) {
    const modal = document.createElement('div');
    modal.id = 'builder-project-modal';
    modal.className = 'builder-project-modal';
    modal.hidden = true;
    document.body.appendChild(modal);
  }

  installBuilderTourPickerBridge();

  getAuthSession().then(session => {
    window.__VTB_AUTH_SESSION__ = session;
    updateAuthSurfaces(session);
  });
}

export {
  buildProjectAssetUrl,
  normalizeLogoForBuilder,
  normalizeProjectDataForBuilder,
  resolveAppSurface,
};
