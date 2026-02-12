# [1353] State Boundary Migration Phase 1 (Runtime-Critical Paths)

## Objective
Reduce architectural coupling by migrating runtime-critical flows away from broad bridge reads/writes.

## Scope
1. Replace direct bridge access in high-risk flows with explicit injected state/dispatch APIs.
2. Focus first on navigation/upload/simulation integration boundaries.
3. Keep compatibility shims minimal and temporary.

## Target Files
- `src/core/AppContext.res`
- `src/core/AppStateBridge.res`
- `src/components/ViewerManager.res`
- `src/components/Sidebar/SidebarLogic.res`
- `src/systems/UploadProcessorLogic.res`

## Verification
- `npm run build`
- targeted integration tests for upload + navigation + simulation interactions.

## Acceptance Criteria
- Runtime-critical domains no longer depend on ad-hoc global reads.
- Behavior parity maintained for existing user workflows.
