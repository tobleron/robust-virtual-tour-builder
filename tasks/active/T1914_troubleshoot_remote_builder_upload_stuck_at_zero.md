# T1914 Troubleshoot Remote Builder Upload Stuck At Zero

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [x] The upload stack still uses a localhost-targeted backend URL or health probe, so LAN clients can sign in but upload requests never leave the browser correctly.
  - [ ] Worker-based validation/fingerprinting stalls before the first backend upload request is issued, leaving the UI at `0%`.
  - [ ] A worker crash or unhandled worker error strands pending promises because the pool never invalidates or resolves waiters.
  - [ ] A later worker-backed metadata stage such as EXIF extraction hangs without timeout and blocks upload completion.

- [ ] **Activity Log**
  - [x] Confirmed the LAN-served builder is reachable and healthy on `rubox`.
  - [x] Inspected frontend upload API/client code for hardcoded localhost or same-machine assumptions.
  - [x] Inspected remote backend logs and live requests while reproducing the stuck upload state.
  - [x] Confirmed no upload API requests were reaching the backend during the stuck `0%` state.
  - [x] Added worker timeouts and fallback logging for upload validation and fingerprinting.
  - [x] Added worker-pool invalidation so worker crashes resolve pending requests instead of hanging indefinitely.
  - [x] Added timeout-backed fallback for worker EXIF extraction.
  - [x] Rebuilt locally and redeployed the patched build to `rubox` for retest.
  - [ ] Re-verify upload progress remotely from the Mac against the rebuilt `rubox` instance.

- [ ] **Code Change Ledger**
  - [x] `src/systems/ImageValidator.res` — add worker timeout and explicit validation fallback logging. Revert if the stall is proven backend-side instead.
  - [x] `src/systems/FingerprintService.res` — add worker timeout and checksum fallback logging. Revert if fingerprinting is not on the stuck path.
  - [x] `src/systems/ExifParser.res` — add timeout-backed EXIF worker fallback for later upload stages. Revert if worker EXIF is proven safe.
  - [x] `src/utils/WorkerPool.res` — add timeout plumbing to worker request helpers. Revert surgically if request signatures destabilize call sites.
  - [x] `src/utils/WorkerPoolCore.res` — invalidate crashed worker pools and resolve pending waiters instead of hanging. Revert only if it causes false-positive pool resets.
  - [x] `src/utils/Constants.res` — add upload/EXIF/tiny worker timeout constants. Revert only if timeout tuning proves too aggressive.

- [ ] **Rollback Check**
  - [ ] Confirmed CLEAN or REVERTED non-working changes.

- [ ] **Context Handoff**
  - [x] `rubox` is serving the rebuilt builder on `http://192.168.1.186:8083/`, and sign-in from the Mac already works.
  - [x] Backend diagnostics previously showed no upload API requests at all during the stuck `0%` state, so the failure is client-side before transfer.
  - [x] The remaining step is to retry upload from the Mac and inspect whether the new worker fallbacks allow upload to proceed or emit new fallback diagnostics instead of hanging.
