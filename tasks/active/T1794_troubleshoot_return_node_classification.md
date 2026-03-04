# T1794 Troubleshoot Return Node Classification

- [x] **Hypothesis (Ordered Expected Solutions)**
  - [x] Expand traversal-derived return detection from single-parent mapping to multi-inbound-source mapping per scene.
  - [x] Restrict inbound-source accumulation to non-return arrivals so forward discovery links keep sequence status.
  - [x] Add/adjust unit coverage around traversal return labeling to prevent sequenced numbering on true back-links.

- [x] **Activity Log**
  - [x] Inspected `HotspotSequence.deriveTraversalBadgeByLinkId` and confirmed single-parent finalization was the source of missed return labels in multi-forward-inbound flows.
  - [x] Implemented inbound-source tracking + non-return gating in `src/systems/HotspotSequence.res`.
  - [x] Added regression coverage in `tests/unit/HotspotSequence_v.test.res` for scenes reached from multiple forward sources.
  - [x] Added unvisited auto-forward inbound regression: if a scene is only reachable through an auto-forward link, its backlink is still classified as `Return`.
  - [x] Added export regression assertion to preserve auto-forward execution behavior even when hotspot is return-classified.
  - [x] Verified with `npx vitest tests/unit/HotspotSequence_v.test.bs.js --run` and `npx vitest tests/unit/TourTemplates_v.test.bs.js --run`.
  - [x] `npm run build` currently blocked if ReScript watch process is already active in another terminal (expected local environment constraint).
  - [x] Reproduced `edge.zip` misclassification (`A07` and `A08` marked `Return`, while `A09` and `A10` were sequenced) using direct `HotspotSequence.deriveBadgeByLinkId` inspection.
  - [x] Isolated root cause to post-traversal inferred-inbound override that force-marked returns for unvisited auto-forward targets.
  - [x] Replaced return inference with deterministic parent-path classification (first-entry parent only), independent from greedy simulation completion.
  - [x] Re-ran unit validations and full build: `npm run res:build`, `npx vitest tests/unit/HotspotSequence_v.test.bs.js --run`, `npx vitest tests/unit/TourTemplates_v.test.bs.js --run`, `npm run build`.
  - [x] Verified target edge links now classify correctly (`A07` sequence, `A08` sequence, `A09` return, `A10` return).

- [x] **Code Change Ledger**
  - [x] `src/systems/HotspotSequence.res`
    - Added `isBackToInboundSource` helper and replaced single-parent map with inbound-source map.
    - Updated traversal classification to keep first forward sequence assignments while classifying back-links as `Return`.
    - Added non-return arrival gating before recording inbound sources.
    - Updated post-traversal finalization to force `Return` on links to observed forward inbound sources.
  - [x] `tests/unit/HotspotSequence_v.test.res`
    - Added multi-forward-inbound return regression scenario and assertions.
    - Preserved existing baseline sequence/return expectations.
    - Added auto-forward-unvisited target regression to ensure back-link still becomes `Return`.
  - [x] `tests/unit/TourTemplates_v.test.res`
    - Added regression check to ensure return classification does not disable auto-forward execution path in export script generation.
  - [x] `src/systems/HotspotSequence.res`
    - Removed unsafe unvisited auto-forward inbound post-pass that could flip forward links to `Return`.
    - Added deterministic parent-scene map derivation with explicit hotspot traversal priority (non-auto-forward before auto-forward).
    - Applied `Return` classification only for links that target the source scene’s first-entry parent.
  - [x] `tests/unit/HotspotSequence_v.test.res`
    - Updated multi-inbound expectation to parent-only return behavior.
    - Added regression covering hub -> master -> balcony pattern to ensure forward links remain sequenced and only backlinks are `Return`.

- [x] **Rollback Check**
  - [x] Confirmed CLEAN for this troubleshooting scope (no temporary debug edits left).

- [x] **Context Handoff**
  - [x] Return-link classification now records forward inbound sources and marks corresponding back-links as `R`.
  - [x] Return arrivals do not add new inbound sources, preventing over-classification of primary forward links.
  - [x] Unit regression added to guard multi-forward-inbound behavior.
  - [x] Return classification now relies on deterministic first-entry parent mapping, not inferred inbound overrides from unvisited auto-forward targets.
  - [x] This fixes `edge.zip` false positives where `L1 hub -> master bedroom` and `master bedroom -> balcony` were incorrectly labeled `R`.
  - [x] Keep this task active until user verifies the fix visually in stage builder and confirms no new return-label regressions.
