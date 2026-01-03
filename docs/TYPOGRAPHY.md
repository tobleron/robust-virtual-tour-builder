# Typography & Font Strategy

This document defines the typography system used throughout the project for consistent, accessible, and visually appealing text rendering.

## Strategic Dual-Font System

This project uses a **strategic dual-font approach** for optimal readability and visual hierarchy:

### Outfit (Display/Body Font)
- **Use for**: Headings, titles, body text, modal headings, branding elements
- **Characteristics**: Modern, geometric, great visual impact
- **CSS Variable**: `var(--font-heading)` or `var(--font-body)`

### Inter (UI/Functional Font)
- **Use for**: Form inputs, buttons, labels, data displays, technical text, version numbers
- **Characteristics**: Optimized for UI, excellent at small sizes, professional
- **CSS Variable**: `var(--font-ui)`

---

## Implementation Rules

1. **Always use CSS variables** instead of hardcoded `font-family` values
2. **Heading hierarchy**: All `<h1>`, `<h2>`, `<h3>` use Outfit
3. **Form elements**: All `<input>`, `<select>`, `<textarea>` use Inter
4. **Inline styles**: When necessary, use `font-family: 'Outfit', sans-serif` or `font-family: 'Inter', sans-serif`
5. **Never add new fonts** without explicit approval — keep the system lean

---

## Font Loading

- Only load fonts actually used in the project
- Use `display=swap` for better performance
- **Current fonts**: Inter (400, 500, 600, 700) and Outfit (400, 600, 700)

### HTML Include
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Outfit:wght@400;600;700&display=swap" rel="stylesheet">
```

---

## Font Size System

This project uses a **standardized, accessible font size scale** based on WCAG 2.1 guidelines:

### Type Scale (16px base)

| Variable | Size | Use Case |
|----------|------|----------|
| `--text-xs` | 0.75rem (12px) | Fine print, captions, timestamps |
| `--text-sm` | 0.875rem (14px) | UI labels, helper text, small buttons |
| `--text-base` | 1rem (16px) | Body text, inputs, default size |
| `--text-lg` | 1.125rem (18px) | Emphasized text, large buttons |
| `--text-xl` | 1.25rem (20px) | Section headings, icons |
| `--text-2xl` | 1.5rem (24px) | Page headings, modal titles |
| `--text-3xl` | 1.875rem (30px) | Hero headings, large modals |

### CSS Implementation
```css
:root {
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
}
```

---

## Usage Guidelines

- **Always use CSS variables** instead of hardcoded px values
- **Minimum size**: `var(--text-xs)` (12px) for fine print only
- **Body text**: `var(--text-base)` (16px) minimum for readability
- **UI elements**: `var(--text-sm)` (14px) for labels and controls
- **Headings**: `var(--text-xl)` and above for hierarchy
- ⚠️ **Never use sizes below 12px** — violates WCAG accessibility standards

---

## Accessibility Compliance

| Requirement | Status |
|-------------|--------|
| WCAG 2.1 AA compliant | ✅ Minimum 14px for UI, 16px for body |
| Readable on all screen sizes | ✅ Desktop, laptop, tablet, 4K |
| Scalable with browser zoom | ✅ Using rem units |
| Optimized for visual impairments | ✅ High contrast ratios |

---

*See also: [FONT_IMPLEMENTATION.md](./FONT_IMPLEMENTATION.md) for technical implementation details.*
