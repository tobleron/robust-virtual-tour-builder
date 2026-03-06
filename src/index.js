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

if (routeTarget === 'builder') {
  import('./Main.bs.js');
} else {
  renderPageFramework(appRoot, routeTarget);
}
