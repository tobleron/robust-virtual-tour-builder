# 1935 — Audit sonner Dependency vs Custom Notification System

**Priority:** 🟡 P2  
**Effort:** 15 minutes  
**Origin:** Codebase Analysis 2026-03-22

## Context

The project includes `sonner@^2.0.7` as a production dependency (a toast notification library), but also has a fully custom notification system:
- `NotificationManager.res` — queue management
- `NotificationQueue.res` — pure functional queue
- `NotificationTypes.res` — type definitions
- `NotificationCenter.res` — rendering

If the custom system is the canonical notification mechanism, `sonner` adds unnecessary bundle size. If both are used, the split creates inconsistent UX.

## Scope

### Steps

1. Search for actual `sonner` usage:
   ```bash
   grep -r "sonner\|Toaster\|toast(" src/ --include="*.res" --include="*.js" --include="*.jsx"
   ```
2. If `sonner` is not imported anywhere in `src/`:
   - Remove from `dependencies` in `package.json`
   - Run `npm install` to update lockfile
3. If `sonner` IS used alongside the custom system:
   - Document where each is used and why
   - Consider consolidating to a single notification mechanism
4. Run `npm run build`

## Acceptance Criteria

- [ ] `sonner` is either actively used (documented) or removed from `package.json`
- [ ] `npm run build` passes
- [ ] No duplicate/competing notification systems exist without clear justification
