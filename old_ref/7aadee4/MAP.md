# 🗺️ Robust Virtual Tour Builder - Codebase Map

This map provides a semantic overview of the project structure to optimize context acquisition and pinpoint intent through tagging.

---

## 🏗️ Core Architecture

### 🛡️ State Management & Logic
*   [src/core/State.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/State.res): Central application state definition. `#state` `#immutability`
*   [src/core/Reducer.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/Reducer.res): Root reducer orchestrating domain updates. `#reducer` `#action-dispatch`
*   [src/core/Actions.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/Actions.res): All supported user and system actions. `#actions` `#events`
*   [src/core/AppContext.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/core/AppContext.res): Typed React Context for state and dispatch accessibility. `#react-context` `#hooks`

### 🌐 System Layer (Business Logic)
*   [src/systems/UploadProcessor.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/UploadProcessor.res): Lightweight facade for the image processing pipeline. `#upload` `#facade`
*   [src/systems/UploadProcessorLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/UploadProcessorLogic.res): Core image validation, fingerprinting, and clustering logic. `#image-processing` `#logic`
*   [src/systems/HotspotLine.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/HotspotLine.res): Facade for visual hotspot connections and simulation arrows. `#hotspots` `#rendering` `#facade`
*   [src/systems/HotspotLineLogic.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/HotspotLineLogic.res): Coordinate projection math and SVG drawing primitives. `#math` `#rendering` `#logic`
*   [src/systems/SimulationDriver.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/SimulationDriver.res): Logic for Autopilot and route simulations. `#autopilot` `#simulation` `#navigation`
*   [src/systems/NavigationController.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/NavigationController.res): Manages movement between scenes. `#navigation` `#scene-switching`
*   [src/systems/ProjectManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/ProjectManager.res): Handles ZIP-based loading and periodic auto-saving. `#persistence` `#save-load` `#zip`
*   [src/systems/Exporter.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/systems/Exporter.res): Generates production-ready tour clusters. `#export` `#deployment`

### 🎨 Visual & UI Components
*   [src/components/ViewerUI.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/ViewerUI.res): The primary HUD and control interface layer. `#ui` `#hud` `#layers`
*   [src/components/Sidebar.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/Sidebar.res): Scene list, drag-and-drop organization, and project controls. `#sidebar` `#scene-management`
*   [src/components/HotspotManager.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/HotspotManager.res): Visual editor for placement and editing of nav links. `#hotspots` `#editor`
*   [src/components/AppErrorBoundary.res](file:///Users/r2/Desktop/robust-virtual-tour-builder/src/components/AppErrorBoundary.res): Top-level safety net for render failures. `#error-handling` `#stability`

### ⚙️ Backend API (Rust)
*   [backend/src/main.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/main.rs): Server entry point, middleware setup, and routing. `#rust` `#api` `#server`
*   [backend/src/api/project.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project.rs): Endpoints for project packaging, imports, and validation. `#backend-logic` `#project-api`
*   [backend/src/api/media/image.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/media/image.rs): High-performance image processing logic. `#rust` `#image-processing` `#performance`
*   [backend/src/pathfinder/algorithms.rs](file:///Users/r2/Desktop/robust-virtual-tour-builder/backend/src/pathfinder/algorithms.rs): Graph traversal logic for optimal routes. `#algorithms` `#graph-theory`

---

## 📁 Directory Semantic Index

| Directory | Primary Purpose | Key Tags |
| :--- | :--- | :--- |
| `src/core` | Data model, state, and foundational types. | `#state` `#types` `#json` |
| `src/systems` | Complex business logic and background services. | `#logic` `#processing` `#simulation` |
| `src/components` | UI building blocks and contextual modules. | `#ui` `#react` `#hud` |
| `backend/src` | High-performance Rust services and APIs. | `#rust` `#backend` `#concurrency` |
| `css` | Design system, tokens, and animations. | `#styling` `#tailwind` `#tokens` |
| `scripts` | Automation, setup, and maintenance tools. | `#automation` `#scripts` `#ci` |

---

## 🛠️ Infrastructure & Config
*   [GEMINI.md](file:///Users/r2/Desktop/robust-virtual-tour-builder/GEMINI.md): AI interaction protocols and strict behavioral rules. `#protocols`
*   [rescript.json](file:///Users/r2/Desktop/robust-virtual-tour-builder/rescript.json): Frontend compiler configuration. `#rescript` `#config`
*   [rsbuild.config.mjs](file:///Users/r2/Desktop/robust-virtual-tour-builder/rsbuild.config.mjs): Build pipeline and HTML template parameters. `#build` `#bundle`
*   [css/variables.css](file:///Users/r2/Desktop/robust-virtual-tour-builder/css/variables.css): The "source of truth" for design tokens. `#design-system` `#theme`
*   [docs/INITIALIZATION_STANDARDS.md](file:///Users/r2/Desktop/robust-virtual-tour-builder/docs/INITIALIZATION_STANDARDS.md): Guidelines for consistent app startup and project resets. `#standards` `#initialization`
