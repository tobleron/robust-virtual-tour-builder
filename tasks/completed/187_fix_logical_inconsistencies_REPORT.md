# Fix Logical Inconsistencies & Quality Issues REPORT

## Objective
Fix three low-risk "Easy Wins" identified in the project code quality analysis to improve robustness without altering core logic.

## Implementation Details

### 1. Hardcoded Backend URL Fixed
- Modified `src/utils/Constants.res` to introduce `backendUrlEnv` binding to `import.meta.env.VITE_BACKEND_URL`.
- Logic now prefers the environment variable, falling back to `http://localhost:8080` if undefined.
- This allows seamless deployment/configuration changes without recompiling the default constant.

### 2. Type Safety in ViewerLoader Enforced
- Modified `src/components/ViewerLoader.res` to eliminate `asDynamic` (any) usage for Pannellum viewer custom properties.
- Defined `type customViewerProps` with `@as` decorators to safely map `_sceneId` and `_isLoaded` fields.
- Used `external asCustom: ReBindings.Viewer.t => customViewerProps = "%identity"` for zero-cost type coercion.

### 3. Watcher Detection Hardened
- Updated `scripts/ensure-watcher.sh` to use `pgrep -f "scripts/dev-mode.sh"`.
- This prevents false positives where the detector script itself might be matched by a loose grep pattern.

## Verification
- Code syntax verified (ReScript record labels corrected).
- Logic is sound and backwards compatible.
