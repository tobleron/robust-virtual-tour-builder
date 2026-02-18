# T1468 - Troubleshoot export NetworkOffline false negative during upload

## Objective
Diagnose and fix export failures that surface as `NetworkOffline` even when the app is online and the failure occurs after `UPLOAD_START`.

## Scope
- Frontend export network path in `src/systems/Exporter.res`.
- Error classification and retry logic for upload transport failures.
- No backend API changes.

## Hypothesis (Ordered Expected Solutions)
- [x] H1: `navigator.onLine` checks in XHR upload path are causing false `NetworkOffline` classification and skipping valid retries.
- [x] H2: Upload failure handling is treating `NetworkOffline` as terminal before checking backend reachability.
- [x] H3: Backend reachability precheck passes but transient transport errors are misclassified as offline due browser heuristics.
- [x] H4: Endpoint-level network errors require endpoint-specific diagnostics in messages to avoid ambiguity.

## Activity Log
- [x] Collect current exporter network/error path evidence.
- [x] Apply surgical fix to remove fragile offline classification and align retry/error mapping.
- [x] Verify with `npm run build`.
- [x] Archive troubleshooting task.

## Code Change Ledger
- [x] `src/systems/Exporter.res` - Removed `navigator.onLine` hard-gates from XHR upload path; reclassified legacy `NetworkOffline` as transport error, added backend reachability arbitration, and allowed retries for transport failures unless abort/unauthorized. Revert note: revert this file if regression appears in successful export path.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
This issue reproduces after `UPLOAD_START`, so the failure is inside upload transport handling rather than project-load/setup paths. Existing exporter logic includes `navigator.onLine` gates that can be wrong for local-backend workflows and likely produce false `NetworkOffline` outcomes. Continue from `uploadAndProcessRaw` and `uploadWithRetry` in `src/systems/Exporter.res` and validate message mapping with backend reachability probes.
