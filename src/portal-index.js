// @efficiency-role: orchestrator
import '../css/style.css';
import React from 'react';
import { createRoot } from 'react-dom/client';
import * as PortalApp from './site/PortalApp.bs.js';

const root = document.getElementById('app');

if (root) {
  createRoot(root).render(React.createElement(PortalApp.make, {}));
}
