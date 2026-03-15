# Task D012: Surgical Refactor SYSTEMS EXPORTER FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 1.80 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/systems/Exporter/ExporterPackagingTemplates.res** (Metric: [Nesting: 3.00, Density: 0.22, Coupling: 0.05] | Drag: 4.24 | LOC: 291/300  ⚠️ Trigger: Drag above target (1.80) with file already at 291 LOC.  🎯 Target: Function: `generateWebIndex` (High Local Complexity (9.0). Logic heavy.)) → Refactor in-place (keep near ~300 LOC)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D012_Surgical_Refactor_SYSTEMS_EXPORTER_FRONTEND/verification.json` (files at `_dev-system/tmp/D012_Surgical_Refactor_SYSTEMS_EXPORTER_FRONTEND/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D012_Surgical_Refactor_SYSTEMS_EXPORTER_FRONTEND/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Exporter/ExporterPackagingTemplates.res`
- `src/systems/Exporter/ExporterPackagingTemplates.res` (16 functions, fingerprint 843da0fcf7f51379671988aa57b0dc8f50dd8c2f818d0e6ca86c5e8b34ab9902)
    - Grouped summary:
        - embed × 1 (lines: 253)
        - html2k × 1 (lines: 168)
        - html4k × 1 (lines: 154)
        - htmlDesktop2kBlob × 1 (lines: 196)
        - htmlDesktop2kLandscapeTouchBlob × 1 (lines: 224)
        - htmlDesktop4kLandscapeTouchBlob × 1 (lines: 238)
        - htmlDesktopHdLandscapeTouchBlob × 1 (lines: 210)
        - htmlHd × 1 (lines: 182)
        - htmlIndex × 1 (lines: 252)
        - marketingBanner × 1 (lines: 120)
        - marketingBody × 1 (lines: 150)
        - marketingPhone1 × 1 (lines: 151)
        - marketingPhone2 × 1 (lines: 152)
        - marketingShowRent × 1 (lines: 148)
        - marketingShowSale × 1 (lines: 149)
        - normalizeMarketingValue × 1 (lines: 12)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
