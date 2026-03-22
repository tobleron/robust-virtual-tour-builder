# 1937 — Reduce %raw JavaScript Escape Hatches

**Priority:** 🟡 P3  
**Effort:** 2–4 hours  
**Origin:** Codebase Analysis 2026-03-22

## Context

~80+ `%raw` JavaScript escape hatches exist across the ReScript codebase. Each `%raw` is a type-safety escape hatch that bypasses the compiler's guarantees. While many are justified (DOM APIs, browser feature detection, crypto APIs), several can be replaced with proper typed bindings.

## Scope

### Categories of %raw Usage

**Category 1 — Replace with proper bindings (high value):**
- `window.__VTB_INITIALIZED__` checks → Create `@val` binding in `BrowserBindings.res`
- `window.__RE_STATE__` debug assignment → Create binding
- `window.APP_VERSION` → Create binding
- `window.pannellum` presence check → Already has bindings, consolidate
- `typeof import.meta` env checks → Create `@val` binding

**Category 2 — Justified, document only:**
- `instanceof File/Blob` checks in `JsonParsersProjectDecoders.res`
- `crypto.subtle.digest` in `ExporterUpload.res`
- Canvas `roundRect` polyfill in `TeaserRecorderHud.res`
- `Response(formData).blob()` conversion workaround
- `ServiceWorker` lifecycle management

**Category 3 — Low priority refactoring:**
- Complex DOM manipulation in `ViewerAdapter.res`
- Event dispatch helpers
- Feature loaders

### Steps

1. Start with Category 1 — create proper bindings in `src/bindings/BrowserBindings.res`
2. Replace at least 10 `%raw` calls with typed bindings
3. Add `// JUSTIFIED: [reason]` comments to Category 2 usages
4. Run `npm run build` after each batch of replacements

### Iterative Approach

This can be done incrementally across multiple sessions. Each session should:
1. Pick 5–10 `%raw` calls to replace
2. Create or extend bindings
3. Verify build passes

## Acceptance Criteria

- [ ] Category 1 `%raw` calls replaced with proper bindings
- [ ] Category 2 `%raw` calls have justification comments
- [ ] `npm run build` passes
- [ ] Net reduction of at least 15 `%raw` escape hatches
