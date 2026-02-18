# Task 1448: Network Stability Masterplan

**Type**: Masterplan  
**Created**: 2026-02-17  
**Status**: Pending

---

## Objective
Harden the application's resilience during internet connectivity loss. Ensure that user actions are never silently lost, the UI remains responsive, data integrity is maintained, and recovery is seamless when connectivity returns.

## Architecture Overview

```
┌─────────────────────────────────────┐
│  Service Worker (Asset Caching)     │  ← Offline UI shell
├─────────────────────────────────────┤
│  RecoveryCheck + RecoveryPrompt     │  ← Startup recovery UI
├─────────────────────────────────────┤
│  RecoveryManager (handler registry) │  ← Recovery orchestration
├─────────────────────────────────────┤
│  OperationJournal + JournalLogic    │  ← Operation tracking & emergency queue
├─────────────────────────────────────┤
│  OptimisticAction + StateSnapshot   │  ← Optimistic UI with rollback
├─────────────────────────────────────┤
│  AuthenticatedClient                │  ← Retry + CircuitBreaker integration
├─────────────────────────────────────┤
│  RequestQueue (concurrency limiter) │  ← Backpressure control
├─────────────────────────────────────┤
│  CircuitBreaker / Retry             │  ← Core resilience primitives
├─────────────────────────────────────┤
│  PersistenceLayer (IndexedDB)       │  ← Auto-save state to IDB
├─────────────────────────────────────┤
│  LoggerTelemetry (batch sender)     │  ← Telemetry with suspend logic
└─────────────────────────────────────┘
```

---

## Task Breakdown

### Phase 1: Critical Foundation
| Task | Title | Severity | Depends On |
|------|-------|----------|------------|
| **1449** | Create NetworkStatus Module | 🔴 Critical | None |
| **1450** | Fix CircuitBreaker HalfOpen Recovery | 🟡 Medium | None |
| **1451** | Add RequestQueue Pause/Resume/Drain | 🟡 Medium | 1449 |

### Phase 2: API Layer
| Task | Title | Severity | Depends On |
|------|-------|----------|------------|
| **1452** | AuthenticatedClient Offline Pre-Check | 🟡 Medium | 1449 |
| **1453** | Fix prepareRequestSignal Listener Leak | 🟡 Medium | None |
| **1454** | Exporter XHR Network Resilience | 🟡 Medium | 1449 |

### Phase 3: Persistence & Recovery
| Task | Title | Severity | Depends On |
|------|-------|----------|------------|
| **1455** | PersistenceLayer Multi-Entry Emergency Flush | 🟡 Medium | None |
| **1456** | UploadRecovery UX Improvements | 🟢 Low | None |
| **1457** | StateSnapshot UUID Fix | 🟢 Low | None |

### Phase 4: Polish
| Task | Title | Severity | Depends On |
|------|-------|----------|------------|
| **1458** | LoggerTelemetry Offline-Aware Flush | 🟢 Low | 1449 |
| **1459** | Service Worker Fetch Timeout | 🟢 Low | None |
| **1460** | AsyncQueue Error Propagation | 🟢 Low | None |
| **1461** | UploadProcessor Error Classification | 🟢 Low | 1449 |

---

## Dependency Graph

```
1449 (NetworkStatus) ──┬──► 1451 (RequestQueue Pause)
                       ├──► 1452 (AuthClient Offline)
                       ├──► 1454 (Exporter XHR)
                       ├──► 1458 (Telemetry Flush)
                       └──► 1461 (UploadProcessor Classify)

1450 (CB HalfOpen)          ← Independent
1453 (Signal Listener)      ← Independent
1455 (Emergency Flush)      ← Independent
1456 (Upload Recovery UX)   ← Independent
1457 (UUID Fix)             ← Independent
1459 (SW Fetch Timeout)     ← Independent
1460 (AsyncQueue Errors)    ← Independent
```

**Recommended execution order**: 1449 → 1450 → 1453 → 1457 → 1451 → 1452 → 1454 → 1455 → 1456 → 1458 → 1459 → 1460 → 1461

---

## Modules Audited

| Module | File(s) | Issues Found |
|--------|---------|--------------|
| CircuitBreaker | `src/utils/CircuitBreaker.res` | HalfOpen fragility (1450) |
| Retry | `src/utils/Retry.res` | ✅ Strong — no issues |
| RequestQueue | `src/utils/RequestQueue.res` | No pause/drain (1451) |
| AuthenticatedClient | `src/systems/Api/AuthenticatedClient.res` | No offline check (1452), listener leak (1453) |
| Exporter | `src/systems/Exporter.res` | Bypasses resilience stack (1454) |
| OperationJournal | `src/utils/OperationJournal.res`, `JournalLogic.res` | Single-entry emergency queue (1455) |
| UploadRecovery | `src/systems/Upload/UploadRecovery.res` | Vague UX (1456) |
| StateSnapshot | `src/core/StateSnapshot.res` | Math.random IDs (1457) |
| LoggerTelemetry | `src/utils/LoggerTelemetry.res` | Flushes when offline (1458) |
| ServiceWorkerMain | `src/ServiceWorkerMain.res` | No fetch timeout (1459) |
| AsyncQueue | `src/utils/AsyncQueue.res` | Swallows errors (1460) |
| UploadProcessor | `src/systems/UploadProcessor.res` | Misleading errors (1461) |
| PersistenceLayer | `src/utils/PersistenceLayer.res` | Missing journal flush (1455) |
| RecoveryCheck | `src/components/RecoveryCheck.res` | ✅ Good — no issues |
| RecoveryPrompt | `src/components/RecoveryPrompt.res` | ✅ Good — no issues |
| RecoveryManager | `src/utils/RecoveryManager.res` | ✅ Good — no issues |
| ProjectManager | `src/systems/ProjectManager.res` | ✅ Good — excellent journaling |
| OptimisticAction | `src/core/OptimisticAction.res` | ✅ Good — proper rollback |
| MediaApi / ProjectApi | `src/systems/Api/` | ✅ Good — proper error handling |

## Acceptance Criteria (Masterplan-Level)

- [ ] All 13 sub-tasks completed
- [ ] `NetworkStatus` module provides centralized online/offline awareness
- [ ] Offline banner visible when browser is offline
- [ ] API calls fast-fail when offline (no wasted retries)
- [ ] RequestQueue pauses when offline
- [ ] CircuitBreaker recovery is graduated
- [ ] All in-flight operations survive tab close
- [ ] All existing E2E tests pass (`tests/e2e/error-recovery.spec.ts`)
- [ ] Zero compiler warnings across all modified files
