# Color Palette Reference Guide

This document provides a comprehensive reference for all colors used in the Robust Virtual Tour Builder project.

---

## Current Color System

### 🎨 Brand Colors (Remax Identity)

| Variable | Hex | Usage | Visual |
|----------|-----|-------|--------|
| `--primary` | `#003da5` | Main brand color, primary buttons, links | 🔵 Remax Blue |
| `--primary-light` | `#2563eb` | Hover states, lighter accents | 🔵 Blue 500 |
| `--primary-dark` | `#001a38` | Dark backgrounds, headers | 🔵 Navy |
| `--primary-navy` | `#002147` | Alternative dark variant | 🔵 Deep Navy |
| `--primary-cobalt` | `#0047AB` | Vibrant interactive elements | 🔵 Cobalt |
| `--primary-gradient-mid` | `#002a70` | Gradient transitions | 🔵 Mid Blue |
| `--accent` | `#ffcc00` | Gold accents, highlights, CTAs | 🟡 Remax Gold |
| `--accent-light` | `#fdb931` | Lighter gold for hover states | 🟡 Light Gold |
| `--accent-soft` | `rgba(255, 204, 0, 0.1)` | Subtle gold backgrounds | 🟡 Gold Tint |
| `--danger` | `#dc3545` | Error states, delete buttons | 🔴 Remax Red |
| `--danger-light` | `#ef4444` | Hover states for danger actions | 🔴 Red 500 |
| `--danger-dark` | `#9b1c2e` | Dark red variant | 🔴 Dark Red |
| `--delete-hover` | `#bb2d3b` | Darker hover for delete actions | 🔴 Deep Red |
| `--orange-brand` | `#f97316` | Attention grabbers, 3rd chevron | 🟠 Brand Orange |

### ✅ Semantic Colors (Functional States)

| Variable | Hex | Usage | Visual |
|----------|-----|-------|--------|
| `--success` | `#10b981` | Success messages, confirmations | 🟢 Emerald 500 |
| `--success-light` | `#34d399` | Hover states, lighter success | 🟢 Emerald 400 |
| `--success-dark` | `#065f46` | Dark success variant | 🟢 Emerald 800 |
| `--warning` | `#f59e0b` | Warning messages, caution states | 🟠 Amber 500 |
| `--warning-light` | `#fbbf24` | Lighter warning states | 🟠 Amber 400 |
| `--warning-dark` | `#c2410c` | Dark warning variant | 🟠 Orange 700 |

### ⚪ Neutral Palette (Slate Scale)

| Variable | Hex | Usage | Visual |
|----------|-----|-------|--------|
| `--slate-50` | `#f8fafc` | Lightest backgrounds | ⚪ Almost White |
| `--slate-100` | `#f1f5f9` | Light backgrounds | ⚪ Very Light Gray |
| `--slate-200` | `#e2e8f0` | Borders, dividers | ⚪ Light Gray |
| `--slate-300` | `#cbd5e1` | Disabled states | ⚪ Gray |
| `--slate-400` | `#94a3b8` | Placeholder text | ⚫ Medium Gray |
| `--slate-500` | `#64748b` | Secondary text | ⚫ Gray |
| `--slate-600` | `#475569` | Body text | ⚫ Dark Gray |
| `--slate-700` | `#334155` | Headings | ⚫ Darker Gray |
| `--slate-800` | `#1e293b` | Dark backgrounds | ⚫ Very Dark Gray |
| `--slate-900` | `#0f172a` | Darkest backgrounds | ⚫ Almost Black |
| `--slate-950` | `#020617` | Pure dark mode | ⚫ Near Black |

### 🎯 Component-Specific Colors

| Variable | Value | Usage | Component |
|----------|-------|-------|-----------|
| `--viewer-bg` | `#1a202c` | Main viewer background | Panellum Viewer |
| `--sidebar-bg` | `#ffffff` | Sidebar background | Scene List |
| `--floor-default` | `var(--primary-navy)` | Unselected floor button | Floor Nav |
| `--floor-bg-hover` | `var(--primary-dark)` | Floor button background hover | Floor Nav |
| `--floor-hover` | `var(--accent)` | Floor button border hover | Floor Nav |
| `--floor-active` | `var(--primary)` | Selected floor | Floor Nav |
| `--floor-active-bg` | `var(--primary-cobalt)` | Selected floor background | Floor Nav |
| `--floor-border-active` | `var(--accent)` | Active floor border | Floor Nav |

### 🎨 Design Tokens

#### Shadows
```css
--shadow-sm:      0 1px 2px 0 rgb(0 0 0 / 0.05)
--shadow-md:      0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)
--shadow-lg:      0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)
--shadow-xl:      0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)
--shadow-premium: 0 25px 50px -12px rgba(0, 0, 0, 0.5)
```

#### Border Radius
```css
--radius-sm:   0.5rem   (8px)
--radius-md:   0.75rem  (12px)
--radius-lg:   1rem     (16px)
--radius-full: 9999px   (Fully rounded)
```

#### Glassmorphism
```css
--glass-bg:     rgba(15, 23, 42, 0.7)
--glass-border: rgba(255, 255, 255, 0.1)
--glass-blur:   12px
```

#### Typography
```css
--font-heading: "Outfit", system-ui, -apple-system, sans-serif
--font-body:    "Outfit", system-ui, -apple-system, sans-serif
--font-ui:      "Inter", system-ui, -apple-system, sans-serif
--font-mono:    ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace
```

#### Transitions
```css
--transition-fast:   0.15s
--transition-normal: 0.3s
```

---

## Color Usage Guidelines

### ✅ DO

1. **Always use CSS variables** for colors
   ```css
   /* ✅ GOOD */
   background-color: var(--primary);
   color: var(--slate-700);
   ```

2. **Use semantic variables** for functional states
   ```css
   /* ✅ GOOD */
   .error-message { color: var(--danger); }
   .success-badge { background: var(--success); }
   ```

3. **Use brand colors** for primary UI elements
   ```css
   /* ✅ GOOD */
   .btn-primary { background: var(--primary); }
   .accent-highlight { color: var(--accent); }
   ```

### ❌ DON'T

1. **Never hardcode hex values** in CSS
   ```css
   /* ❌ BAD */
   background-color: #003da5;
   ```

2. **Don't use inline styles** for colors in ReScript
   ```rescript
   /* ❌ BAD */
   <div style={makeStyle({"backgroundColor": "#ff0000"})} />
   ```

3. **Don't create ad-hoc color variations**
   ```css
   /* ❌ BAD */
   background: #0047AB; /* Random blue variant */
   ```

---

## Proposed Simplified Palette

### Option 1: Remax-Centric (Recommended)

**Core Palette** (6 colors + neutrals):
```css
/* PRIMARY (Blue Family) */
--primary:       #003da5  /* Remax Blue */
--primary-light: #2563eb  /* Interactive */
--primary-dark:  #001a38  /* Backgrounds */

/* ACCENT (Gold Family) */
--accent:        #ffcc00  /* Remax Gold */
--accent-light:  #fdb931  /* Hover */
--accent-dark:   #b8860b  /* Borders */

/* SEMANTIC (Simplified) */
--success:       #10b981  /* Emerald */
--danger:        #dc3545  /* Red */
--warning:       #f59e0b  /* Amber */

/* NEUTRALS (Slate 50-950) */
[Keep existing slate scale]
```

**Benefits**:
- Strong Remax brand identity
- Reduced color count (from 20+ to 12)
- Easier to maintain
- More cohesive visual appearance

**Migration Map**:
```
OLD COLOR           → NEW VARIABLE
#ea580c (orange)    → var(--accent)
#f97316 (orange)    → var(--accent-light)
#0047AB (blue)      → var(--primary-light)
#001a4d (navy)      → var(--primary-dark)
#00235d (navy)      → var(--primary-dark)
#163a63 (blue)      → var(--primary-dark)
```

### Option 2: Modern Dark Theme

**Core Palette** (Dark-first approach):
```css
/* BASE (Dark Slate) */
--bg-primary:   #0f172a  /* Main background */
--bg-secondary: #1e293b  /* Cards/panels */
--bg-tertiary:  #334155  /* Elevated elements */

/* ACCENT (Vibrant) */
--accent-blue:    #3b82f6  /* Primary actions */
--accent-emerald: #10b981  /* Success/positive */
--accent-amber:   #f59e0b  /* Warnings/highlights */

/* TEXT (High Contrast) */
--text-primary:   #f8fafc  /* Headings */
--text-secondary: #cbd5e1  /* Body text */
--text-tertiary:  #94a3b8  /* Muted text */
```

**Benefits**:
- Modern, premium aesthetic
- Better for viewer (dark environment)
- Reduced eye strain
- Aligns with industry trends

---

## Color Accessibility

### Contrast Ratios (WCAG 2.1 AA)

| Background | Foreground | Ratio | Status (Text) | Status (UI) |
|------------|------------|-------|---------------|-------------|
| White      | `--primary` | 9.6:1 | ✅ AAA | ✅ AAA |
| White      | `--slate-700` | 10.4:1 | ✅ AAA | ✅ AAA |
| White      | `--slate-600` | 7.5:1 | ✅ AAA | ✅ AAA |
| `--primary-dark` | `--accent` | 11.6:1 | ✅ AAA | ✅ AAA |
| White      | `--danger` | 4.6:1 | ✅ AA | ✅ AA |
| White      | `--success` | 3.0:1 | ❌ FAIL | ✅ AA (Large/UI) |
| `--primary` | White | 9.6:1 | ✅ AAA | ✅ AAA |
| `--danger` | White | 4.6:1 | ✅ AA | ✅ AA |
| `--success` | White | 3.0:1 | ❌ FAIL | ✅ AA (Large/UI) |

**Audit Findings (Jan 2026)**:
- **`--success` (#10b981)** has low contrast (3.0:1) against white. It is acceptable for graphical objects (buttons, icons) but **fails** for normal text.
- **Action**: Use `--success-text` or `--success-dark` for text content.
- **Action**: darken base `--success` variable to improve legibility on buttons.

**Recommendations**:
- Use `--success-dark` (#065f46) for any text on light backgrounds (Ratio 13.6:1).
- Use `--danger-light` for better contrast on dark backgrounds.
- Always test color combinations with a contrast checker.

---

## Theming Guide

### How to Change the Theme

1. **Update Primary Color**:
   ```css
   /* In css/variables.css */
   --primary: #1e40af; /* Change to new brand color */
   ```

2. **Update Accent Color**:
   ```css
   --accent: #f59e0b; /* Change to new accent */
   ```

3. **Test Propagation**:
   - Check all buttons
   - Verify floor navigation
   - Test modal dialogs
   - Review hover states

### Creating a Dark Mode Toggle

```css
/* Add to variables.css */
:root {
  --bg-main: #ffffff;
  --text-main: #0f172a;
}

[data-theme="dark"] {
  --bg-main: #0f172a;
  --text-main: #f8fafc;
}
```

---

## Quick Reference

### Most Common Colors

**Buttons**:
- Primary: `var(--primary)`
- Secondary: `var(--slate-600)`
- Danger: `var(--danger)`
- Success: `var(--success)`

**Text**:
- Headings: `var(--slate-900)`
- Body: `var(--slate-700)`
- Muted: `var(--slate-500)`

**Backgrounds**:
- Main: `#ffffff`
- Viewer: `var(--viewer-bg)`
- Sidebar: `var(--sidebar-bg)`

**States**:
- Hover: Add `-light` variant
- Active: Use base color
- Disabled: `var(--slate-300)`

---

*Last Updated: 2026-01-20*  
*Maintained by: Design System Team*
