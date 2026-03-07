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

import { renderPageFramework, resolveAppSurface } from './site/PageFramework.js';

const appRoot = document.getElementById('app');
const routeTarget = resolveAppSurface(window.location.pathname, window.location.hostname);
const DEV_HOSTS = new Set(['localhost', '127.0.0.1', '0.0.0.0']);

function authHeaderValue() {
  const token = window.localStorage ? window.localStorage.getItem('auth_token') : null;
  if (token && token.trim() !== '') return `Bearer ${token}`;
  if (DEV_HOSTS.has((window.location.hostname || '').toLowerCase())) return 'Bearer dev-token';
  return null;
}

async function preloadDashboardProjectIfRequested() {
  const params = new URLSearchParams(window.location.search || '');
  const projectId = params.get('projectId');
  if (!projectId) return;

  const auth = authHeaderValue();

  try {
    const headers = {};
    if (auth) headers.Authorization = auth;
    const response = await fetch(`/api/project/dashboard/projects/${encodeURIComponent(projectId)}`, {
      method: 'GET',
      headers,
      credentials: 'include',
    });
    if (!response.ok) return;

    const payload = await response.json();
    if (payload && payload.projectData) {
      window.__VTB_BOOT_PROJECT_DATA__ = payload.projectData;
      window.__VTB_BOOT_PROJECT_SESSION_ID__ = payload.sessionId || projectId;
    }
  } catch (_error) {
    // Keep boot resilient; builder still opens normally if preload fails.
  }
}

if (routeTarget === 'builder') {
  preloadDashboardProjectIfRequested().finally(() => {
    import('./Main.bs.js');
  });
} else {
  renderPageFramework(appRoot, routeTarget);
}
