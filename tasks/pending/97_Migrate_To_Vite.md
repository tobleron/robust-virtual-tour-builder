# Task: Migrate Build System to Vite
**Priority:** High (Modernization/DX)
**Status:** Pending

## Objective
Replace the current ad-hoc build scripts (`live-server`, `rescript build`, manual `tailwindcss`) with **Vite**.

## Context
The current `start_dev.sh` and `package.json` scripts are functional but lack the features of a modern commercial-grade frontend toolchain:
- **HMR (Hot Module Replacement)**: Currently using full page reloads.
- **Optimization**: Vite provides automatic code splitting, tree-shaking, and asset hashing.
- **Speed**: Instant server start.

## Requirements
1. **Install** Vite and necessary plugins:
   - `npm install -D vite @vitejs/plugin-react`
   - (Optional) `vite-plugin-rescript` if available/stable, or just configure generic watcher.
2. **Create** `vite.config.js`.
   - Configure proxy to forward `/api` requests to `http://localhost:8080`.
3. **Update** `index.html`.
   - Move `index.html` to root (if not already) or configure Vite root.
   - Update script tags to use ESM `<script type="module" src="/src/Main.bs.js"></script>`.
4. **Update** `package.json` scripts:
   - `"dev": "vite"`
   - `"build": "rescript build && vite build"`
   - `"preview": "vite preview"`
5. **Verify** Tailwind integration with Vite (usually standard PostCSS config).

## Verification
- `npm run dev` starts the dev server.
- Changes to `.res` files (which compile to `.bs.js`) trigger fast HMR updates in browser.
- Backend API calls work via proxy.
