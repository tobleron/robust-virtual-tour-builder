# Network Resilience & Stability Architecture

This document details the architectural hardening implemented under **Masterplan Task 1448**. The system is designed to handle flaky internet connectivity, complete service outages, and unexpected application terminations without data loss or UI degradation.

## 1. Core Primitives

### 1.1 NetworkStatus Module (`src/utils/NetworkStatus.res`)
The central authority for connectivity state.
- **Hardware Integration**: Monitors `navigator.onLine`.
- **Event-Driven**: Dispatches `NetworkStatusChanged(bool)` via `EventBus`.
- **Subscription Model**: Allows components to react instantly to connectivity changes.

### 1.2 RequestQueue (`src/utils/RequestQueue.res`)
Manages backpressure and concurrency.
- **Auto-Pause**: Automatically suspends processing when the `NetworkStatus` indicates the browser is offline.
- **Resume logic**: Flushes the pending queue immediately upon reconnection.
- **Draining**: Provides a safe way to reject all pending tasks during critical system failures.

### 1.3 Circuit Breaker (`src/utils/CircuitBreaker.res`)
Prevents "cascading failures" by stopping requests to a failing backend.
- **Graduated Recovery**: The `HalfOpen` state now requires multiple consecutive successes to transition back to `Closed`.
- **Failure Tolerance**: Probing in `HalfOpen` mode is now more resilient to single-request blips.

---

## 2. API Resilience Stack

### 2.1 AuthenticatedClient (`src/systems/Api/AuthenticatedClient.res`)
The primary gateway for all backend communication.
- **Pre-flight Check**: Every request validates `NetworkStatus.isOnline()` before execution.
- **Fast-Fail**: Requests made while offline return a `NetworkOffline` error immediately, skipping retries and avoiding circuit breaker trips.
- **Signal Management**: Strict cleanup of `AbortSignal` listeners prevents memory leaks during timed-out or aborted requests.

### 2.2 Exporter Resilience (`src/systems/Exporter.res`)
Handles large project binary uploads (multi-MB ZIPs).
- **XHR Monitoring**: Uses `XMLHttpRequest` with custom progress tracking and network-aware error handling.
- **Smart Retries**: Implements a 3-attempt retry strategy with exponential backoff for non-terminal network errors.
- **Circuit Breaker Integration**: Manually records successes and failures to the global API circuit breaker.

---

## 3. Data Integrity & Recovery

### 3.1 Operation Journal (`src/utils/OperationJournal.res`)
Tracks long-running asynchronous operations (Uploads, Exports, Saves).
- **Emergency Flush**: On window `beforeunload` or `unload`, all `InProgress` and `Pending` operations are serialized to LocalStorage.
- **Multi-Entry Tracking**: Supports multiple simultaneous operations in the emergency queue.
- **Context Merging**: Incrementally updates metadata (e.g., "10 of 50 files processed") so recovery can pick up exactly where it left off.

### 3.2 State Snapshots (`src/core/StateSnapshot.res`)
Immutable history for rollback and persistence.
- **UUID Stability**: Uses cryptographic `Crypto.randomUUID()` for snapshot identifiers, ensuring zero collisions during local persistence recovery.

---

## 4. UI/UX Feedback Loop

### 4.1 Offline Banner (`src/components/ui/OfflineBanner.res`)
- A global, high-z-index warning displayed automatically when connectivity is lost.
- Alerts the user that "Some features may be unavailable," preventing confusion during failed actions.

### 4.2 Recovery Modal (`src/systems/Upload/UploadRecovery.res`)
- **Granular Feedback**: Informs the user exactly how much work was completed before a crash.
- **Resume Path**: Provides a direct "Select Files" button to re-trigger the `TriggerUpload` event with context awareness.

---

## 5. Technical Specifications

| Feature | Logic | Timeout / Limit |
| :--- | :--- | :--- |
| **SW Assets** | Cache-First | 15s Timeout |
| **SW Navigation** | Network-First (Fallback to index.html) | 10s Timeout |
| **API Requests** | Circuit Breaker + Pre-check | 30s Timeout |
| **Telemetry** | Batching + Offline Suspend | 5s Batch / 50 logs |
| **Concurrency** | RequestQueue | 6 Concurrent / 256 Queued |

---

## 6. Verification & Testing
Hardening is verified via the following suites:
- **Unit Tests**: `tests/unit/utils/NetworkStatus_v.test.res`, `tests/unit/RequestQueue_v.test.res`, `tests/unit/CircuitBreaker_v.test.res`.
- **Integration Tests**: `tests/unit/AuthenticatedClient_v.test.res`, `tests/unit/OperationJournal_Context_v.test.res`.
- **E2E Tests**: `tests/e2e/error-recovery.spec.ts` (simulates offline/online toggles).
