# Rate-Limit Policy Rationale (v1.0)

## Overview
This document outlines the rationale for the specific rate-limit and backpressure configurations chosen for the Robust Virtual Tour Builder. These values were selected to balance server stability with a fluid user experience, specifically addressing "Project Load" edge cases and typical real estate brokerage workflows.

## Profile: Balanced / Burst-Friendly

### 1. Scope-Based Budgets
We categorize traffic into four scopes to ensure that critical operations (like loading) are not penalized by background noise.

| Scope | Burst Capacity | Refill Rate | Rationale |
| :--- | :--- | :--- | :--- |
| **`Read` (Load)** | 50 reqs | 5/sec | **Primary Fix:** Large projects (40-100 scenes) generate many metadata requests on load. A 50-req burst allows the initial load to complete without triggering the countdown timer. |
| **`Write` (Upload)** | 20 reqs | 2/sec | Supports the frontend's 5x5 batching strategy. Allows for 4 concurrent batches plus overhead for metadata updates. |
| **`Admin` (Save/Exp)** | 10 reqs | 1/sec | These are infrequent but critical "heavy" operations. The lower rate prevents abuse while the burst allows for immediate action when the user clicks 'Save'. |
| **`Health`** | 100 reqs | 10/sec | Essential for the "Online/Offline" detection. This must practically never throttle to avoid false "Browser Offline" states. |

### 2. User Experience Philosophy
*   **Transparency over Blocking:** We prefer "Option A" (Informative Pause). If the user hits a limit, the UI indicates a "Cooldown" rather than just failing or blocking the entire app.
*   **Progress Integrity:** The progress bar remains active during throttled windows to prevent "hope loss." The status text explicitly mentions the server is "cooling down" to manage user expectations.
*   **Adaptive Backgrounding:** During heavy `Write` (upload) bursts, low-priority background telemetry is automatically paused to reserve the network and rate-limit budget for the user's primary task.

### 3. Workload Assumptions
*   **Broker Workflow:** Typical upload is 20-40 images.
*   **Max Capacity:** Support for up to 100 images and 300 hotspots per tour.
*   **Compression:** High frontend compression reduces the payload size per request, making request *frequency* the primary bottleneck rather than bandwidth.

## Rollout and Safety
*   **Canary Deployment:** release to 10% of users first.
*   **Observation:** Monitor `Read` path 429 errors. If >2% of loads hit a 429, the burst capacity should be increased further.
