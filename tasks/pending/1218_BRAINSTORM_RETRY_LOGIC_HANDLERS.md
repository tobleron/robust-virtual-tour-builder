---
title: Brainstorm Retry Logic Implementation for OperationJournal
status: pending
priority: high
tags: [persistence, reliability, brainstorming]
---

# Task: Brainstorm Retry Logic Implementation

## Context
Task 1205 implemented the `OperationJournal` and `RecoveryPrompt`, but the actual "Retry" execution logic in `Main.res` is currently a placeholder (logs `RETRY_OPERATIONS`). We need a concrete plan for how different system orchestrators will handle recovery.

## Objectives
- [ ] Analyze `UploadProcessor.res` to determine how to restart a batch upload from journal context.
- [ ] Analyze `ProjectManager.res` to determine if ZIP generation can be resumed or must be restarted.
- [ ] Define the interface for "Retry Handlers" that systems must register.
- [ ] Determine if `OperationJournal` needs to store more granular state (e.g., "files processed so far").

## Proposed Strategy
1. **System Registration**: Systems (Upload, Export) should register themselves with a `RecoveryManager`.
2. **Context Passing**: When "Retry" is clicked, look up the operation type and dispatch to the registered handler with the stored `JSON.t` context.
3. **Idempotency**: Ensure that retrying an upload doesn't create duplicate scenes (leverage `FingerprintService`).
