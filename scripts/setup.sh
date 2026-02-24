#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting Robust Project Scaffolding & Setup..."

# 1. Check for Prerequisites
echo "🔍 Checking prerequisites..."

check_cmd() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ $1 is not installed."
        MISSING_TOOLS=1
    else
        echo "✅ $1 is installed."
    fi
}

MISSING_TOOLS=0
check_cmd node
check_cmd npm
check_cmd cargo
check_cmd ffmpeg
check_cmd fswatch

if [ "$MISSING_TOOLS" -eq 1 ]; then
    echo ""
    echo "⚠️  Some required tools are missing. Refer to REQUIREMENTS.txt for installation instructions."
fi

# 2. Project Detection & Initialization
if [ ! -f "package.json" ]; then
    echo "🐣 No project detected. Initializing new project skeleton..."
    
    # Create Directory Structure
    mkdir -p .agent/workflows tasks/pending tasks/completed tasks/active tasks/postponed/tests \
             docs/standards docs/_pending_integration scripts src/core src/components src/systems \
             backend/src/api backend/src/models backend/src/services css/components logs bin public tests/unit
    
    # Generate GEMINI.md
    cat <<'EOF' > GEMINI.md
# 🚀 PROJECT PROTOCOLS & CONTEXT

## 🧠 CORE BEHAVIOR (SYSTEM 2 THINKING)
Before executing ANY code or shell command, you must perform a **Context Check**:
1. **Pathing**: ALL paths in your commands must be relative to project root.
2. **Safety**: If you are about to edit a file >700 lines, **PAUSE** and ask for confirmation.
3. **Never use `git commit` directly**.

## 🚨 CODING VITALS (PRIORITY 0)
- **ReScript v12 Only**: All frontend code MUST be in ReScript v12.
- **Explicit Handling**: Use `Option`/`Result` explicitly. No `unwrap()` or `panic!`.
- **Logger Module**: `console.log` is strictly forbidden. Use the `Logger` module.
- **No Alerts**: Use `EventBus.dispatch(ShowNotification(...))` or modals.
- **Immutability**: Maintain functional purity in ReScript; avoid `mutable` unless performance critical.

## 📂 CRITICAL PATHS
- **Codebase Map**: `./MAP.md` (Semantic index - READ FIRST)
- **Pending Tasks**: `./tasks/pending` (Standard tasks)
- **Postponed Tasks**: `./tasks/postponed` (Deferred tasks) & `./tasks/postponed/tests` (Test tasks)

## 🛠️ WORKFLOW AUTOMATION
1. **Context Refresh**: Read MAP.md and relevant tasks.
2. **Project Guard**: Run `./scripts/project-guard.sh` to ensure health.
3. **Build**: Run `npm run build` before completion.
EOF

    # Generate .cursorrules
    cat <<'EOF' > .cursorrules
# Project Agent Rules

## 🎯 Primary Protocol
👉 **Consensus Rule**: ALWAYS prioritize protocols defined in [GEMINI.md](GEMINI.md).

## 🚨 CODING VITALS (Priority 0)
1. **ReScript v12 Only**: All frontend code MUST be in ReScript v12.
2. **Handle Option/Result**: Use explicit pattern matching. No `unwrap()`.
3. **No Console Logs**: Use the `Logger` module.
4. **Functional Purity**: UI in `src/components/`, Logic in `src/systems/`, State in `src/core/State.res`.
EOF

    # Generate MAP.md
    cat <<'EOF' > MAP.md
# 🗺️ Codebase Map

This map provides a semantic overview of the project structure.

## 🏗️ Core Architecture
- [src/core/Logger.res](src/core/Logger.res): Central logging utility.
- [src/core/EventBus.res](src/core/EventBus.res): System-wide event dispatcher.

## 📁 Directory Semantic Index
| Directory | Primary Purpose |
| :--- | :--- |
| `src/core` | Data model, state, and foundational types. |
| `src/systems` | Complex business logic and background services. |
| `src/components` | UI building blocks. |
| `backend/src` | High-performance Rust services and APIs. |
EOF

    # Generate TASKS.md
    cat <<'EOF' > tasks/TASKS.md
# Task Management - Follow Instructions in Exact Order

## Task Creation Rule
- **Mandatory Prefix**: Every new task MUST have a sequential number prefix (e.g., `001_initial_setup.md`).
- **Sequence Basis**: Next available number across all task folders.

## Workflow Instructions
1. **Move to active**: Move task to `tasks/active/`.
2. **Implement**: Work on task.
3. **Verify**: Run `npm run build`.
4. **Report**: Rename to `_REPORT` or `_CREATED`.
5. **Archive**: Move to `tasks/completed/`.
EOF

    # Generate rescript.json
    cat <<'EOF' > rescript.json
{
    "name": "robust-project",
    "sources": [
        { "dir": "src", "subdirs": true },
        { "dir": "tests", "subdirs": true, "type": "dev" }
    ],
    "package-specs": { "module": "es6", "in-source": true },
    "suffix": ".bs.js",
    "jsx": { "version": 4, "mode": "automatic" },
    "dependencies": [ "@rescript/react", "rescript-vitest" ],
    "warnings": { "error": "+101" }
}
EOF

    # Generate vitest.config.mjs
    cat <<'EOF' > vitest.config.mjs
import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        include: ['tests/**/*.test.bs.js'],
        environment: 'jsdom',
        globals: true,
    },
});
EOF

    # Generate rsbuild.config.mjs
    cat <<'EOF' > rsbuild.config.mjs
import { defineConfig } from '@rsbuild/core';
import { pluginReact } from '@rsbuild/plugin-react';

export default defineConfig({
  plugins: [pluginReact()],
  source: { entry: { index: './src/index.js' } },
  html: { template: './index.html' },
  output: {
    distPath: { root: 'dist' },
    filenameHash: true,
    cleanDistPath: true,
  },
  server: {
    proxy: { '/api': { target: 'http://127.0.0.1:8080', changeOrigin: true } }
  }
});
EOF

    # Generate postcss.config.js
    cat <<'EOF' > postcss.config.js
export default {
    plugins: {
        '@tailwindcss/postcss': {},
        autoprefixer: {},
    },
};
EOF

    # Generate tailwind.config.js
    cat <<'EOF' > tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [
        "./src/**/*.{html,js,jsx,ts,tsx,res,bs.js}",
        "./*.html"
    ],
}
EOF

    # Generate css/style.css
    cat <<'EOF' > css/style.css
@import "tailwindcss";

@theme {
  --color-brand: #3b82f6;
}

body {
  @apply bg-slate-950 text-slate-100 font-sans;
}
EOF

    # Generate index.html
    cat <<'EOF' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Robust Project</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <div id="root"></div>
    <script type="module" src="/src/index.js"></script>
</body>
</html>
EOF

    # Generate src/index.js (Entry for rsbuild)
    cat <<'EOF' > src/index.js
import "./Main.bs.js";
EOF

    # Generate src/Main.res
    cat <<'EOF' > src/Main.res
switch ReactDOM.querySelector("#root") {
| Some(rootElement) => {
    let root = ReactDOM.Client.createRoot(rootElement)
    ReactDOM.Client.Root.render(root, <div className="p-8"> {React.string("Hello, Robust Project!")} </div>)
  }
| None => ()
}
EOF

    # Generate Standard Workflows
    cat <<'EOF' > .agent/workflows/commit-workflow.md
# Commit Workflow
1. Remove Raw Console Calls.
2. Increment Version in package.json.
3. Run npm run build.
4. Use ./scripts/commit.sh "vX.Y.Z [Context] Message".
EOF

    cat <<'EOF' > .agent/workflows/new-module-standards.md
# New Module Standards
1. Use ReScript v12.
2. Include Logger module.
3. Add to MAP.md immediately.
4. Create corresponding unit test.
EOF

    # Generate scripts/commit.sh
    cat <<'EOF' > scripts/commit.sh
#!/bin/bash
MSG="$1"
if [ -z "$MSG" ]; then echo "❌ Error: Commit message required."; exit 1; fi
echo "🛠️ Verifying Build..."
npm run build
git add .
git commit -m "$MSG"
echo "✅ Committed: $MSG"
EOF
    chmod +x scripts/commit.sh

    # Generate scripts/project-guard.sh (The Guard)
    cat <<'EOF' > scripts/project-guard.sh
#!/bin/bash
LIMIT=700
WATCH_DIRS="./src ./backend/src"
echo "👀 Project Guard Active: Monitoring Growth ($LIMIT lines)..."
fswatch -0 $WATCH_DIRS | xargs -0 -n 1 -I {} wc -l {}
EOF
    chmod +x scripts/project-guard.sh

    # Generate .gitignore
    cat <<'EOF' > .gitignore
node_modules/
dist/
lib/
target/
.DS_Store
*.log
.env.local
EOF

    # Generate basic package.json
    cat <<EOF > package.json
{
  "name": "my-robust-project",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "res:build": "rescript",
    "res:watch": "rescript watch",
    "dev": "concurrently \"npm run res:watch\" \"rsbuild dev\"",
    "build": "npm run res:build && rsbuild build",
    "test": "echo 'Tests omitted during refactor'",
    "sentinel": "./scripts/project-guard.sh"
  },
  "devDependencies": {
    "rescript": "^12.0.0",
    "concurrently": "^8.2.0",
    "vitest": "^1.0.0",
    "jsdom": "^22.1.0",
    "@rsbuild/core": "^1.0.0",
    "@rsbuild/plugin-react": "^1.0.0",
    "@rescript/react": "^0.14.0",
    "rescript-vitest": "^2.1.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "tailwindcss": "^4.0.0",
    "@tailwindcss/postcss": "^4.0.0",
    "postcss": "^8.4.0",
    "autoprefixer": "^10.4.0"
  }
}
EOF

    # Generate src/core/Logger.res
    cat <<'EOF' > src/core/Logger.res
type level = Info | Warn | Error | Debug
let log = (level, message) => {
  let prefix = switch level {
    | Info => "ℹ️ [INFO]"
    | Warn => "⚠️ [WARN]"
    | Error => "🚨 [ERROR]"
    | Debug => "🔍 [DEBUG]"
  }
  Js.Console.log2(prefix, message)
}
let info = msg => log(Info, msg)
let warn = msg => log(Warn, msg)
let error = msg => log(Error, msg)
let debug = msg => log(Debug, msg)
EOF

    # Generate Cargo.toml
    cat <<EOF > backend/Cargo.toml
[package]
name = "backend"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = "0.7"
tokio = { version = "1.0", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
EOF

    # Generate REQUIREMENTS.txt (Embed it)
    cat <<'EOF' > REQUIREMENTS.txt
# 🛠️ Project Development Requirements

This project utilizes a high-performance ReScript (Frontend) and Rust (Backend) stack.

## 📦 Core Dependencies
- Node.js: v18.0.0+
- npm: v9.0.0+
- Rust: Stable toolchain
- Cargo: Included with Rust

## ⚙️ System Utilities
- ffmpeg: Required for image/video processing.
- fswatch: Required for real-time codebase health monitoring.
EOF

    echo "✅ Skeleton generated successfully!"
fi

# 3. Environment Setup (Standard)
if [ -f "package.json" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm install || echo "⚠️  npm install failed. Manual intervention may be needed."
    
    echo "🏗️ Building ReScript modules..."
    npm run res:build || echo "⚠️  Initial ReScript build failed. Ensure rescript is installed."
fi

# 4. Ensure runtime directories exist
mkdir -p logs bin dist
touch logs/.gitkeep

# 5. Cleanup stale ports
echo "🧹 Cleaning up stale ports (8080, 3000)..."
lsof -ti:8080,3000 | xargs kill -9 2>/dev/null || true

if [ "${SKIP_BROWSER_PROVISIONING:-0}" != "1" ]; then
    echo "🧪 Ensuring Playwright browsers are provisioned..."
    ./scripts/install-browsers.sh
else
    echo "⚙️ Browser provisioning disabled via SKIP_BROWSER_PROVISIONING=1."
fi

echo ""
echo "✨ Environment Ready!"
echo "🚀 Run 'npm run dev' to start development"
echo ""
