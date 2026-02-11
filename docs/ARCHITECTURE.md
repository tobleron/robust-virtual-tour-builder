# Architecture & Standards

## 📌 Anchor-Based Positioning Standards
**Objective**: Ensure hotspots and UI overlays remain visually pinned to their panoramic coordinates regardless of the user's zoom level or viewport size.

### Core Principles
1.  **3D to 2D Projection**: All screen coordinates are derived from 3D (Yaw/Pitch) values using the `ProjectionMath.res` module.
2.  **Normalized Coordinates**: Hotspot positions are stored as normalized Yaw (-180 to 180) and Pitch (-90 to 90).
3.  **CSS Transforms**: Overlays use `transform: translate3d(...)` for high-performance rendering (GPU acceleration).

### Implementation Reference
-   **Projection Logic**: `src/utils/ProjectionMath.res`
-   **Rendering Component**: `src/components/HotspotLayer/HotspotLayer.res`

### Best Practices
-   **Avoid** direct `top/left` pixel manipulation for dynamic positioning.
-   **Use** `requestAnimationFrame` for smooth tracking during camera rotation.
-   **Debounce** depth calculations for occlusion culling to preserve FPS.

---

## 🏗️ System Architecture

```mermaid
graph TB
    %% --- Frontend Subgraph ---
    subgraph Frontend["Frontend (ReScript/React)"]
        direction TB

        subgraph FE_Core["Core (State Flow)"]
            Actions[Actions] --> Reducer[Reducer]
            Reducer --> State[State]
            State -.-> FE_Components
            Types[Types]
        end

        subgraph FE_Systems["Systems"]
            Navigation[Navigation]
            Upload[Upload]
            Simulation[Simulation]
            Teaser[Teaser]
            ProjectManager[ProjectManager]
        end

        subgraph FE_Components["Components"]
            Sidebar[Sidebar]
            ViewerUI[Viewer UI]
            SceneList[Scene List]
            HotspotLayer[Hotspot Layer]
            Pannellum[[Pannellum Viewer]]
        end

        subgraph FE_Infra["Infrastructure"]
            EventBus[EventBus]
            Logger[Logger]
            InteractionGuard[InteractionGuard]
            PersistenceLayer[PersistenceLayer]
        end
    end

    %% --- Browser Persistence ---
    subgraph Browser["Browser Context"]
        IDB[(IndexedDB)]
    end

    %% --- Backend Subgraph ---
    subgraph Backend["Backend (Rust/Actix-web)"]
        direction TB

        subgraph BE_API["API Layer"]
            ProjHandlers[Project]
            MediaHandlers[Media]
            PathfinderHandlers[Pathfinder]
        end

        subgraph BE_Services["Services"]
            UploadQuota[Upload Quota]
            Geocoding[Geocoding]
            ImageAnalysis[Image Analysis]
        end

        subgraph BE_Storage["Storage"]
            FS[(File System - Images)]
            ProjectData[(JSON - Project Data)]
        end
    end

    %% --- Major Interactions ---
    FE_Components <--> FE_Systems
    FE_Systems <--> FE_Core
    FE_Systems <--> FE_Infra
    PersistenceLayer <--> IDB

    FE_Systems <--> BE_API
    BE_API <--> BE_Services
    BE_Services <--> BE_Storage

    %% --- Data Flow Overlays ---
    %% Upload Pipeline: Files → Resizer → API → Backend Image Processing
    Upload -.-> |"Files → Resizer"| MediaHandlers
    MediaHandlers -.-> |"Image Processing"| ImageAnalysis

    %% Persistence: State → PersistenceLayer → IndexedDB
    State -.-> |"Persistence"| PersistenceLayer
    PersistenceLayer -.-> IDB

    %% Navigation: User Click → FSM → SceneLoader → ViewerPool → SceneTransition
    Navigation -.-> |"FSM → SceneLoader → ViewerPool → SceneTransition"| Pannellum
```
