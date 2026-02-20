# T1484: Enterprise Chunked Uploads & Hardened Rate Limits

## Context
Initial testing with the `x700.zip` (100MB+) revealed that single-POST uploads are brittle and require dangerously high rate-limit thresholds. To achieve true enterprise-grade stability and security, we are moving to a **Chunked Resumable Upload** system. This allows the backend to enforce strict, "hardened" limits while the frontend paces its uploads.

## Status
- [ ] **Phase 1: Backend Chunking API**
  - [ ] Implement `POST /api/project/import/init` (returns `uploadId`, `chunkSize`).
  - [ ] Implement `POST /api/project/import/chunk` (receives `uploadId`, `index`, `data`).
  - [ ] Implement `POST /api/project/import/complete` (triggers reassembly and existing `import_project` logic).
  - [ ] Logic for chunk cleanup on timeout/failure.

- [ ] **Phase 2: Frontend "Slicer" Implementation**
  - [ ] Create `src/utils/FileSlicer.res` to split `zipFile` into chunks (e.g., 5MB each).
  - [ ] Update `ProjectSystem.res` to use the new chunked flow.
  - [ ] Implement retry logic for failed chunks (exponential backoff).

- [ ] **Phase 3: Harden Rate Limits (THE GOAL)**
  - [ ] Revert `Write` class to 2 RPS / 10 Burst (Safe for chunks, stops DOS).
  - [ ] Revert `Media` class to 1 RPS / 5 Burst (Strongest protection).
  - [ ] Lower `MAX_PAYLOAD_SIZE` to 10MB (more than enough for a 5MB chunk).
  - [ ] Verify `x700.zip` still works via chunked flow under these strict limits.

## Verification Criteria
- [ ] `x700.zip` (101MB) uploads as ~21 small requests, completing without 429 errors.
- [ ] Aborting halfway through an upload and resuming only sends the remaining chunks.
- [ ] Server successfully reassembles chunks and extracts the project.
- [ ] Attempting to send a single 100MB file (legacy POST) is rejected with 413 (Payload Too Large).
