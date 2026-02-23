Assignee: Codex
Capacity Class: A
Objective: Display the semantic version plus build number in the sidebar version label regardless of branch (main/stable or development).
Boundary: `src/components/Sidebar`, `src/utils/Version`, `scripts/update-version`, version metadata files.
Owned Interfaces: Sidebar version label rendering, `buildInfo`/version accessors.
No-Touch Zones: Backend Rust sources, unrelated UI modules (viewer, upload, simulation) to avoid collateral effects.
Independent Verification: `npm run test:unit` ensuring ReScript build still passes.
Depends On: 1535

# Background
The sidebar currently shows version information but omits the build number for scenario-specific labels, causing ambiguity between main/stable and development builds. The user wants a concise format (`v4.5.4 • [Development Build 2]`).

# Success Criteria
- Sidebar version label renders as `v<major>.<minor>.<patch> • [<channel> Build <buildNumber>]` and respects channel metadata.
- `buildInfo` accessor exposes the build number wherever the sidebar text is composed.
- The version-build number combination updates without requiring branch-specific logic changes.
- Manual verification of the sidebar in the dev build shows the desired format.
- Tests: `npm run test:unit`.
