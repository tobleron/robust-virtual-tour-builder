# 1414: ARCH: Domain Slice Optimization for Global State

## Objective (Developer Decision Required)
Evaluate the feasibility of splitting `src/core/State.res` into smaller, domain-specific sub-states to prevent "God Object" growth.

## Context
The architectural audit noted that while state is currently manageable, `src/core/State.res` is becoming dense. As features like advanced clustering, AI analysis, and multi-user sync are added, a monolithic state might hinder AI agent context and developer comprehension.

## Proposed Strategy
- [ ] **Option A**: Keep current structure but enforce strict slice hooks (already started with `useSceneSlice`).
- [ ] **Option B**: Physically split `State.res` into `ProjectState.res`, `SessionState.res`, and `SystemState.res`, combined in a root state.
- [ ] **Option C**: Migrate to a more decentralized state model for non-UI data (e.g., moving cache to specialized services).

## Decision Points for Developer
- Does the current monolithic state cause noticeable "Context Fog" for AI agents?
- Would the overhead of managing multiple sub-reducers outweigh the benefits of isolation?
- Is the current `AppStateBridge` sufficient for cross-domain sync?

*This task is advisory. Move to `active/` only if a structural split is deemed necessary.*
