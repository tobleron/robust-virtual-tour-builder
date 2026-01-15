# Task 118: Run Accessibility Audit and Fix Critical Issues

## Priority: MEDIUM

## Context
Current accessibility implementation is ~70% WCAG 2.1 AA compliant based on analysis:
- ✅ ARIA labels on modals
- ✅ Keyboard navigation
- ✅ Focus indicators
- 🟡 Some images missing alt text
- 🟡 Some color contrast issues
- 🟡 No skip navigation link

## Objective
Run a comprehensive accessibility audit and fix all critical/serious findings.

## Acceptance Criteria
- [ ] Run axe DevTools audit on main application views
- [ ] Run Lighthouse accessibility audit
- [ ] Fix all "critical" severity issues
- [ ] Fix all "serious" severity issues
- [ ] Document remaining "moderate" issues for future
- [ ] Achieve 90+ Lighthouse accessibility score

## Audit Process

### Step 1: Install axe DevTools
1. Install Chrome extension: https://chrome.google.com/webstore/detail/axe-devtools-web-accessib/lhdoppojpmngadmnindnejefpokejbdd
2. Or use npm: `npm install -D @axe-core/cli`

### Step 2: Run Audit on Key Views
Test these critical user flows:
1. **Main editor view** (sidebar + viewer)
2. **LinkModal dialog** (hotspot linking)
3. **Upload flow** (drag-drop + progress)
4. **Scene list** with multiple items
5. **Settings/export modals**

### Step 3: Run Lighthouse Audit
1. Open Chrome DevTools → Lighthouse tab
2. Select "Accessibility" only
3. Run audit on desktop and mobile viewports
4. Export report as JSON

## Common Issues to Check

### Images
```html
<!-- BAD -->
<img src="logo.png">

<!-- GOOD -->
<img src="logo.png" alt="Remax Virtual Tour Builder logo">
```

### Color Contrast
```css
/* BAD: 3.5:1 ratio */
color: #94a3b8; /* slate-400 on dark background */

/* GOOD: 4.5:1 ratio (meets AA) */
color: #cbd5e1; /* slate-300 on dark background */
```

### Skip Navigation
```html
<!-- Add at top of body -->
<a href="#main-content" class="sr-only focus:not-sr-only">
  Skip to main content
</a>

<!-- Add to main content area -->
<main id="main-content">
  ...
</main>
```

### Button Labels
```html
<!-- BAD -->
<button><span class="material-icons">delete</span></button>

<!-- GOOD -->
<button aria-label="Delete scene">
  <span class="material-icons" aria-hidden="true">delete</span>
</button>
```

## Expected Findings

Based on project analysis, likely issues:
1. **Pannellum viewer** - Third-party, limited a11y (can't fully fix)
2. **Icon-only buttons** - Need aria-labels
3. **Timeline/Visual Pipeline** - May need ARIA live regions
4. **Toast notifications** - Need `role="alert"`

## Deliverables
1. Audit report saved to `docs/ACCESSIBILITY_AUDIT_RESULTS.md`
2. Critical issues fixed in code
3. Lighthouse score documented

## Verification
1. Re-run axe DevTools - 0 critical/serious issues
2. Re-run Lighthouse - 90+ accessibility score
3. Manual keyboard navigation test passes
4. Screen reader (VoiceOver/NVDA) basic flow works

## Tools Reference
- axe DevTools: https://www.deque.com/axe/devtools/
- WAVE: https://wave.webaim.org/
- Lighthouse: Built into Chrome DevTools
- Contrast Checker: https://webaim.org/resources/contrastchecker/

## Estimated Effort
4-6 hours
