---
description: High-level quality standards for committing code. Technical verification is handled by scripts/commit.sh.
---

# Commit Workflow (Standards & Quality)

All technical verifications (Linting, Formatting, Build, Tests, Versioning, and Doc-Sync) are automated. **You must use the commit script for all commits.**

## 1. The Golden Rule
## 1. The Golden Rule
**Command (Standard)**: `./scripts/commit.sh "prefix: Description" [target-branch] [bump-level]`
- **Impact**: Build verification only (Tests skipped during Refactor).
- **Bump Level**: `major` | `minor` | `patch` | `none` (default).

**Command (Fast)**: `./scripts/fast-commit.sh "prefix: Description" [bump-level]`
- **Impact**: Skips build/tests. Useful for quick snapshots or non-critical progress saves.
- **Prefixes**: `feat:`, `fix:`, `perf:`, `refactor:`, `chore:`, `docs:`, `style:`, `security:`

---

## 2. Intelligent Versioning Strategy
You must explicitly decide the Semantic Versioning update level (`x.y.z`) based on the nature of your changes:

| Bump Level | Criteria | Example |
| :--- | :--- | :--- |
| **major** (x) | Breaking changes, major refactors, or new architectural eras. | `v4.0.0` -> `v5.0.0` |
| **minor** (y) | New features, significant improvements (backward compatible). | `v4.8.0` -> `v4.9.0` |
| **patch** (z) | Bug fixes, small tweaks, non-breaking refactors. | `v4.8.0` -> `v4.8.1` |
| **none** | Documentation, formatting, WIP snapshots, or invisible changes. | No change (Build # increments) |

**Decision Protocol**:
1. Analyze your changes: Are they breaking? New features? Or just fixes?
2. Choose the level.
3. Append it to the commit command.

*Example*:
- Strong refactoring? -> `./scripts/commit.sh "refactor: Core logic" development minor`
- Breaking API change? -> `./scripts/commit.sh "feat: New API" development major`
- Simple fix? -> `./scripts/commit.sh "fix: Typo" development patch`

---

## 3. Manual Quality Checklist (System 2 Thinking)
Before running the commit script, perform these checks that automation cannot catch:

### Architectural Integrity
- [ ] **ReScript v12 Core**: Ensure no legacy `Belt` or `Js` modules are used where `Core` alternatives exist.
- [ ] **Explicit Handling**: Verify `Option` and `Result` are handled explicitly; no `Obj.magic` or unsafe type-casting.
- [ ] **Module Boundaries**: Ensure new modules are correctly mapped in `MAP.md` (if not, the script will warn you, but you must add the tags).

### Visual & UX Verification
- [ ] **Ghost Artifacts**: In the browser, verify no SVG or CSS artifacts remain during scene transitions.
- [ ] **Responsive Check**: Ensure new UI elements don't break the layout on smaller viewports.
- [ ] **Interaction Feedback**: Verify animations (flickers, sweeps) feel tactical and responsive.

### Logging & Telemetry
- [ ] **Meaningful Logs**: Verify `Logger` output is descriptive and helpful for debugging, not just "Operation started/ended."
- [ ] **No Trace Leaks**: Ensure `Logger.trace` is disabled for production-bound code.

---

## 4. Automation Safeguards
The `./scripts/commit.sh` will block your commit if:
1. **Forbidden Patterns**: It detects `console.log`, `var`, `debugger`, or `alert(`.
2. **Build Warnings**: ReScript compiler emits *any* warnings (Strict Mode).
3. **Tests**: (Bypassed during Refactor phase).
If the script blocks you, resolve the issue and run it again. Do not bypass the script.