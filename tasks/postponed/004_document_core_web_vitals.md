# Task 305: Document Core Web Vitals Metrics

**Priority**: Low  
**Effort**: Low (2 hours)  
**Impact**: Low  
**Category**: Performance / Documentation

## Objective

Document Core Web Vitals (LCP, FID, CLS) scores and add them to the performance documentation to provide complete performance metrics coverage.

## Current Status

**Performance Documentation**: Excellent  
**What's Documented**:
- ✅ Bundle size (~280KB gzipped)
- ✅ Project load time (~4s for 50 scenes)
- ✅ Image processing time (~500ms)
- ✅ Viewer transition time (~350ms)
- ✅ UI responsiveness (60 FPS)

**What's Missing**:
- ⚠️ Core Web Vitals (LCP, FID, CLS) not explicitly documented

## Core Web Vitals Overview

### 1. Largest Contentful Paint (LCP)
- **What**: Time until largest content element is visible
- **Target**: < 2.5 seconds (Good)
- **Measures**: Loading performance

### 2. First Input Delay (FID) / Interaction to Next Paint (INP)
- **What**: Time from first user interaction to browser response
- **Target**: < 100ms (Good) for FID, < 200ms for INP
- **Measures**: Interactivity

### 3. Cumulative Layout Shift (CLS)
- **What**: Visual stability (unexpected layout shifts)
- **Target**: < 0.1 (Good)
- **Measures**: Visual stability

## Implementation Steps

### Phase 1: Measure Core Web Vitals (1 hour)

1. **Use Lighthouse in Chrome DevTools**:
   ```bash
   # Start dev server
   npm run dev
   
   # Open Chrome DevTools
   # Navigate to Lighthouse tab
   # Run audit for Performance
   ```

2. **Use web-vitals library** (optional, for real user monitoring):
   ```bash
   npm install web-vitals
   ```

   Add to `src/Main.res` or early-boot.js:
   ```javascript
   import {getCLS, getFID, getFCP, getLCP, getTTFB} from 'web-vitals';
   
   getCLS(console.log);
   getFID(console.log);
   getFCP(console.log);
   getLCP(console.log);
   getTTFB(console.log);
   ```

3. **Test in production build**:
   ```bash
   npm run build
   # Serve dist folder
   # Measure with Lighthouse
   ```

### Phase 2: Document Results (30 minutes)

Add section to `docs/PERFORMANCE_AND_METRICS.md`:

```markdown
## Core Web Vitals

Measured using Google Lighthouse (Production Build):

| Metric | Score | Target | Status |
|--------|-------|--------|--------|
| **Largest Contentful Paint (LCP)** | X.Xs | < 2.5s | 🟢/🟡/🔴 |
| **First Input Delay (FID)** | XXms | < 100ms | 🟢/🟡/🔴 |
| **Cumulative Layout Shift (CLS)** | 0.XX | < 0.1 | 🟢/🟡/🔴 |
| **First Contentful Paint (FCP)** | X.Xs | < 1.8s | 🟢/🟡/🔴 |
| **Time to Interactive (TTI)** | X.Xs | < 3.8s | 🟢/🟡/🔴 |
| **Total Blocking Time (TBT)** | XXms | < 200ms | 🟢/🟡/🔴 |

### Methodology
- **Tool**: Google Lighthouse v11+
- **Environment**: Production build, served locally
- **Device**: Desktop (simulated)
- **Network**: Fast 3G throttling
- **Last Measured**: 2026-01-21

### Optimization Notes
- LCP optimized via progressive texture loading
- FID optimized via code splitting and lazy loading
- CLS prevented by reserving space for dynamic content
```

### Phase 3: Add to Audit Report (30 minutes)

Update `docs/PROJECT_STANDARDS_ADHERENCE_AUDIT.md`:

```markdown
### Performance Metrics (Detailed)

**Core Web Vitals** (Google Lighthouse):
- LCP: X.Xs (Target: <2.5s) ✅
- FID: XXms (Target: <100ms) ✅
- CLS: 0.XX (Target: <0.1) ✅
```

## Verification

1. Run Lighthouse audit
2. Verify all Core Web Vitals in "Good" range (green)
3. Document actual scores
4. Compare against targets
5. Identify any areas for improvement

## Success Criteria

- [ ] Core Web Vitals measured with Lighthouse
- [ ] Scores documented in PERFORMANCE_AND_METRICS.md
- [ ] Scores added to audit report
- [ ] All metrics in "Good" range (or improvement plan documented)
- [ ] Methodology documented
- [ ] "Last Measured" date included

## Expected Results

Based on current performance metrics, expected scores:
- **LCP**: ~1.5-2.0s (Good) - Progressive loading helps
- **FID**: <50ms (Good) - ReScript compiled to efficient JS
- **CLS**: <0.05 (Good) - Fixed layouts, no dynamic injections

## Benefits

- ✅ Complete performance documentation
- ✅ Alignment with Google's performance standards
- ✅ Baseline for future optimizations
- ✅ SEO benefits (Core Web Vitals are ranking factors)
- ✅ Professional performance reporting

## Resources

- Core Web Vitals: https://web.dev/vitals/
- Lighthouse: https://developers.google.com/web/tools/lighthouse
- web-vitals library: https://github.com/GoogleChrome/web-vitals
