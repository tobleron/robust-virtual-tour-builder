// @efficiency-role: orchestrator
/**
 * Application Entry Point
 * 
 * This file serves as the entry point for Rsbuild. It imports the CSS
 * (which includes Tailwind directives) and then imports the ReScript-compiled
 * Main.bs.js module.
 */

// Import Main Stylesheet (includes Tailwind and all modules)
import '../css/style.css';

import {
  normalizeProjectDataForBuilder,
  renderBuilderFramework,
  renderPageFramework,
  resolveAppSurface,
} from './site/PageFramework.js';
import { getAuthSession, getLocalSetupStatus } from './site/PageFrameworkAuth.js';

const appRoot = document.getElementById('app');
const routeTarget = resolveAppSurface(window.location.pathname, window.location.hostname);
const DEV_HOSTS = new Set(['localhost', '127.0.0.1', '0.0.0.0']);

function authHeaderValue() {
  const token = window.localStorage ? window.localStorage.getItem('auth_token') : null;
  if (token && token.trim() !== '') return `Bearer ${token}`;
  return null;
}

async function preloadDashboardProjectIfRequested() {
  const params = new URLSearchParams(window.location.search || '');
  const projectId = params.get('projectId');
  const snapshotId = params.get('snapshotId');
  if (!projectId) return;

  const auth = authHeaderValue();

  try {
    const headers = {};
    if (auth) headers.Authorization = auth;
    const endpoint = snapshotId
      ? `/api/project/dashboard/projects/${encodeURIComponent(projectId)}/snapshots/${encodeURIComponent(snapshotId)}`
      : `/api/project/dashboard/projects/${encodeURIComponent(projectId)}`;
    const response = await fetch(endpoint, {
      method: 'GET',
      headers,
      credentials: 'include',
    });
    if (!response.ok) return;

    const payload = await response.json();
    if (payload && payload.projectData) {
      const sessionId = payload.sessionId || projectId;
      window.__VTB_BOOT_PROJECT_DATA__ = normalizeProjectDataForBuilder(sessionId, payload.projectData);
      window.__VTB_BOOT_PROJECT_SESSION_ID__ = sessionId;
      window.__VTB_BOOT_PROJECT_LABEL__ =
        (payload.projectData && typeof payload.projectData.tourName === 'string' && payload.projectData.tourName.trim()) ||
        'saved tour';
    }
  } catch (_error) {
    // Keep boot resilient; builder still opens normally if preload fails.
  }
}

if (routeTarget === 'builder') {
  Promise.all([getAuthSession(), getLocalSetupStatus()]).then(([session, setupStatus]) => {
    if (setupStatus?.setupRequired) {
      window.location.assign('/setup');
      return;
    }
    if (!session?.authenticated) {
      window.location.assign('/signin');
      return;
    }

    renderBuilderFramework(appRoot);
    preloadDashboardProjectIfRequested().finally(() => {
      import('./Main.bs.js');
    });
  });
} else {
  renderPageFramework(appRoot, routeTarget);
}
