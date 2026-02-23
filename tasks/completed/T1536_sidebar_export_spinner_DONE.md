Assignee: Codex
Capacity Class: A
Objective: Diagnose and fix the stray circular animation that appears near the sidebar during exports (duplicate of the progress indicator already shown elsewhere). Ensure the extra spinner disappears without regressing export feedback.
Boundary: `src/components/Sidebar`, `src/components/Sidebar/SidebarProcessing`, `src/components/Sidebar/SidebarActions`, `src/components/Sidebar/SidebarProjectInfo`, `src/systems/OperationLifecycle`, `src/components/VisualPipeline`, and any shared spinner indicators referenced by the sidebar.
Owned Interfaces: Processing banner, export button spinner, sidebar busy indicator, related state selectors.
No-Touch Zones: Viewer system, backend, `_dev-system` plan files, unrelated tasks.
Independent Verification: Manual reproduction (trigger export) and `npm run test:frontend` to confirm no test regression.
Depends On: 1536_sidebar_version_build_label

# Hypothesis (Ordered Expected Solutions)
- [x] The extra spinner is rendered by the sidebar processing banner, which subscribes to the same export operation and shows another animation; we can hide it when `operations.active` already shows the spinner elsewhere or when `SidebarProcessing` is used in the sidebar during exports.
- [ ] Sidebar actions render a generic `BusyIndicator` that unnecessarily renders during export; we can gate it to only show for certain operations while the export button already covers the visual cue.
- [ ] A separate component (e.g., `SidebarProjectInfo` or `SidebarActions`) is mounting the spinner due to an `isProcessing` flag; we can adjust the selector so only non-export operations trigger it.

# Activity Log
- [x] Inspect sidebar components for spinner render logic while export is running.
- [x] Trace operation state to determine why the spinner is active during exports.
- [x] Verify there are no duplicate spinner components triggered by `OperationLifecycle` subscriptions.
- [x] Implement targeted fix and rerun `npm run test:frontend`.

# Code Change Ledger
- [x] `src/components/Sidebar/SidebarProcessing.res` – removed the redundant `spinner` element inside the processing card so export runs no longer show the stray circular animation (revert: add the spinner `div` back).

# Rollback Check
- [x] Confirm non-working changes are reverted or not introduced.

# Context Handoff
- [x] Provide 3-sentence summary covering reproducing steps, narrowed root cause, and next action if session ends prematurely.
  * Reproduced by running an export while the sidebar processing card is visible—its spinner is the blue circle near the right edge.
  * Root cause: `SidebarProcessing` renders an extra `spinner` element whenever a critical operation is active, duplicating the visual cue already on the export button and the progress bar.
  * Next step if interrupted: no further code changes are needed, just re-run `npm run test:frontend` to verify after editing the processing card.
