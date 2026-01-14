---
description: Move Teaser Pathfinding logic to Rust for performance
---

# Objective
Port the Breadth-First Search (BFS) / pathfinding logic from `src/systems/TeaserPathfinder.res` to the Rust backend for optimal performance on large graphs.

# Context
While ReScript is fast, pathfinding on very large graphs (500+ nodes) can block the main thread. Rust is better suited for this computational task.

# Requirements

1.  **Backend Implementation (`backend/src/pathfinder.rs`)**:
    *   Create a struct for the Graph (Scene Adjacency List).
    *   Implement `find_path(graph, start_id, end_id, skip_auto_forward)`.
    *   Expose an endpoint `POST /calculate-path` accepting `{ scenes: [...], start: string, targets: string[] }`.

2.  **Frontend Update (`TeaserPathfinder.res`)**:
    *   Replace client-side BFS with an async call to `BackendApi.calculateVideoPath(...)`.
    *   Handle the response (array of scene IDs/transitions).

3.  **Verification**:
    *   Run the "Teaser" generation on a complex tour.
    *   Ensure the calculated path is identical to the logic in the JS/ReScript version.
    *   Ideally, complex paths should calculate instantly.

# Note
This is an optimization. If Task 56 is implemented, memory is less of an issue, but CPU blocking is still avoided by this task.
