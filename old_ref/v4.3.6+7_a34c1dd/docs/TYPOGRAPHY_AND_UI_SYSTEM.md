# Typography & UI Design System

This document defines the typography and UI text handling systems used throughout the project for consistent, accessible, and visually appealing text rendering.

---

## 1. Strategic Dual-Font System

This project uses a **strategic dual-font approach** for optimal readability and visual hierarchy:

### Outfit (Display/Body Font)
- **Use for**: Headings, titles, body text, modal headings, branding elements, progress percentages, upload dialogs.
- **Characteristics**: Modern, geometric, great visual impact.
- **CSS Variable**: `var(--font-heading)` or `var(--font-body)`
- **Standard Implementation**: `font-family: var(--font-body);`

### Inter (UI/Functional Font)
- **Use for**: Form inputs, buttons, labels, data displays, technical text, version numbers, viewer modal components.
- **Characteristics**: Optimized for UI, excellent at small sizes, professional.
- **CSS Variable**: `var(--font-ui)`

---

## 2. Font Loading & Performance

To ensure optimal performance, we only load the fonts and weights actually used in the project.

### Google Fonts Implementation
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Outfit:wght@400;600;700&display=swap" rel="stylesheet">
```

### Performance Impact
- **Consolidation**: Reduced from 4 fonts to 2 (removed EB Garamond and Merriweather).
- **Optimization**: Uses `display=swap` for better UX.
- **Impact**: ~50% reduction in font loading bandwidth, saving ~40-60KB.

---

## 3. Font Size System (WCAG 2.1 AA Compliant)

This project uses a **standardized, accessible font size scale** based on a 16px base.

### Type Scale Variables

| Variable | Size | Use Case |
|----------|------|----------|
| `--text-xs` | 0.75rem (12px) | Fine print, captions, timestamps, version numbers |
| `--text-sm` | 0.875rem (14px) | UI labels, helper text, small buttons, scene names |
| `--text-base` | 1rem (16px) | Body text, inputs, default size, modal body |
| `--text-lg` | 1.125rem (18px) | Emphasized text, large buttons, modal headings |
| `--text-xl` | 1.25rem (20px) | Section headings, icons |
| `--text-2xl` | 1.5rem (24px) | Page headings, modal titles |
| `--text-3xl` | 1.875rem (30px) | Hero headings, large modals |

### Implementation Rules
1. **Always use CSS variables** instead of hardcoded px values.
2. **Minimum size**: `var(--text-xs)` (12px) is for fine print only.
3. **UI Text Minimum**: 14px for labels and controls to meet WCAG standards.
4. **Body Text Minimum**: 16px for readability.

---

## 4. Advanced Responsive Sizing

For specific UI elements like the **Project ID Input Field**, we use intelligent scaling techniques.

### A. Viewport-Based Scaling (CSS Clamp)
Used to smoothly transition font sizes between mobile and desktop resolutions without media queries.
```css
font-size: clamp(var(--text-sm), 3.5vw, var(--text-base));
```
- **Mobile**: 14px (minimum characters fit)
- **Scaling**: 3.5% of viewport width
- **Desktop**: 16px (maximum readability)

### B. Container-Based (Content-Aware) Scaling
Used in the Sidebar to ensure long filenames fit within the 320px fixed-width container.

| Text Length | Font Size | Reasoning |
|-------------|-----------|-----------|
| Short (0-32 chars) | 16px | Full size |
| Medium (33-37 chars) | 15px | Minor reduction |
| Long (38+ chars) | 14px | WCAG minimum |

---

## 5. Handling Long Text (Best Practices)

When text (like filenames) overflows its container, we use a multi-layered approach to preserve accessibility.

### Implementation: Ellipsis + Tooltip
1. **Visual**: `text-overflow: ellipsis` shows "..." for overflow.
2. **Interaction**: `title` attribute provides a native tooltip with the full text on hover.
3. **Accessibility**: Maintains 16px readable size instead of shrinking text to illegible levels.

### 🚫 Forbidden Practices
- **DO NOT** reduce font size below 12px.
- **DO NOT** use `overflow: hidden` without an ellipsis or tooltip.
- **DO NOT** sacrifice accessibility for aesthetics.

---

## 6. Audit & History

### Initial State (Pre-Standardization)
- 3 different font families (Outfit, Inter, Helvetica).
- 4 fonts loaded (2 unused).
- 15+ unique hardcoded font sizes (including inaccessible 10px and 11px).
- Inconsistent usage across components.

### Final Standardized State
- ✅ **Strategic Dual-Font System** implemented.
- ✅ **7 Standardized Size Variables** enforced via CSS.
- ✅ **WCAG 2.1 AA Compliance** reached (no text below 12px).
- ✅ **Performance Optimized** (unused fonts removed).
- ✅ **Single Source of Truth** (CSS variables in `style.css`).

---
*Last Updated: 2026-01-18*
