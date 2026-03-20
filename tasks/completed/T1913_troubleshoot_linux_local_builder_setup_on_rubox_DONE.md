# T1913 Troubleshoot Linux Local Builder Setup On Rubox

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [ ] The shell wrapper fails on real Linux desktops because package-manager detection only handles `brew` and `apt`, while `rubox` is Arch and exposes Homebrew only through a non-interactive shell path.
  - [ ] The current setup path assumes prerequisites like `curl` and package-manager binaries are already on `PATH`, which is unreliable in SSH and first-run environments.
  - [ ] The public setup flow may also be too strict about repo/bootstrap assumptions, so the user-facing instructions need validation against a clean remote clone.

- [ ] **Activity Log**
  - [x] Verified direct SSH access to `rubox`.
  - [x] Inspected the remote environment, package-manager availability, and prerequisite binaries.
  - [x] Reproduced that Homebrew exists on the machine but is not visible on the default SSH `PATH`.
  - [x] Patched the local-builder setup scripts for broader Linux compatibility and better fallback behavior.
  - [x] Re-ran setup on `rubox` from a fresh clone/check-out until the public install path succeeded.
  - [x] Verified the resulting local builder runtime starts correctly.

- [ ] **Code Change Ledger**
  - [x] `scripts/setup-local-builder.sh` — broadened Linux package-manager detection to include standard Homebrew paths and `pacman`, and ensured `curl` is available for `rustup`. Revert by restoring the original wrapper if the new probing logic proves wrong.
  - [x] `scripts/local-builder-runtime.mjs` — added detached-HEAD recovery for `main` and port preflight/fallback so local setup does not falsely report readiness when `8080` is already occupied. Revert surgically if startup regressions appear.
  - [ ] `README.md` / `DEVELOPERS_README.md` — adjust setup docs only if the real remote install shows instruction drift.

- [ ] **Rollback Check**
  - [x] Confirmed CLEAN or REVERTED non-working changes.

- [ ] **Context Handoff**
  - [x] `rubox` is reachable over SSH from this session and is running Arch Linux.
  - [x] Homebrew exists at `/home/linuxbrew/.linuxbrew/bin/brew`, but the non-interactive SSH `PATH` does not expose it, so the wrapper now normalizes standard tool paths and supports `pacman`.
  - [x] The patched setup succeeded remotely: it built the frontend/backend, detected occupied `8080`, rewrote local runtime config to `8083`, and served healthy responses from the started builder.
