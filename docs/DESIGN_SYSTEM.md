# Design System & Styling Architecture

This document defines the visual standards, accessibility requirements, and CSS architecture for the Robust Virtual Tour Builder.

---

## 1. Core Philosophy: Separation of Concerns

This project strictly enforces a **Separation of Concerns (SoC)** between Frontend Logic (ReScript) and Visual Presentation (CSS).

### ✅ The Golden Rule
**Frontend Logic (`.res`) handles STATE and BEHAVIOR.**
**CSS Files (`.css`) handle LOOK and FEEL.**

### ❌ Forbidden Patterns
- **Do NOT** use inline styles in ReScript (e.g., `style={makeStyle({"color": "red"})}`).
- **Do NOT** define color palettes or font sizes in ReScript constants.
- **Do NOT** mix layout logic with business logic.

---

## 2. Strategic Dual-Font System

For optimal readability and visual hierarchy, we use a two-font approach:

### Outfit (Display/Body Font)
- **Use for**: Headings, titles, body text, branding, progress indicators.
- **Characteristics**: Modern, geometric, high visual impact.
- **CSS Variable**: `var(--font-heading)` or `var(--font-body)`

### Inter (UI/Functional Font)
- **Use for**: Form inputs, buttons, labels, technical text, version numbers.
- **Characteristics**: Optimized for UI, excellent legibility at small sizes.
- **CSS Variable**: `var(--font-ui)`

### Performance Metrics
- **Optimization**: Reduced from 4 fonts to 2 (removed EB Garamond and Merriweather).
- **Impact**: ~50% reduction in font loading bandwidth (~40-60KB saved).

---

## 3. Standardized Typography & Sizing

### Accessible Font Scale (WCAG 2.1 AA)
Based on a 16px base, using CSS variables to ensure consistency.

| Variable | Size | Use Case |
|----------|------|----------|
| `--text-xs` | 12px | Fine print, captions, timestamps |
| `--text-sm` | 14px | UI labels, helper text, small buttons |
| `--text-base`| 16px | Body text, inputs, default size |
| `--text-lg` | 18px | Emphasized text, large buttons |
| `--text-xl` | 20px | Section headings |
| `--text-2xl`| 24px | Page headings, modal titles |
| `--text-3xl`| 30px | Hero headings |

### Responsive Sizing Techniques
- **Viewport Scaling**: `font-size: clamp(var(--text-sm), 3.5vw, var(--text-base));`
- **Content-Aware Scaling**: Sidebar filenames shrink from 16px to 14px as length increases to preserve layout integrity.

---

## 4. Color Palette & Design Tokens

Always use the variables defined in `css/variables.css`. **Never hardcode hex values.**

### Semantic Colors
- `var(--primary)`: Main brand color.
- `var(--secondary)`: Accent and supporting elements.
- `var(--danger)`: Error states and destructive actions.
- `var(--success)`: Positive feedback and completion states.

---

## 5. CSS Implementation Guidelines

### A. Semantic Classes
Describe *what* a component is, not just its appearance.
- **BAD**: `bg-red-500 text-white`
- **GOOD**: `.notification-error`

### B. State-Based Styling
Toggle CSS classes in ReScript instead of manipulating styles directly.
- **Example**: `.my-component.state-active { ... }`

### C. Exceptions for Inline Styles
Permitted **ONLY** for:
1. **Dynamic/Continuous Values**: Coordinate math (hotspots), progress bar percentages.
2. **External Assets**: User-uploaded background images.

---

## 6. Accessibility (ARIA & UX)

### Standards Compliance
- **WCAG 2.1 AA**: Minimum font size 12px; high contrast ratios.
- **Keyboard Navigation**: Full Tab/Enter support; `Escape` key closes all modals.
- **Screen Readers**: Descriptive ARIA labels (e.g., `aria-label="Save navigation link"`).
- **Focus Management**: Visible focus rings and auto-focusing primary inputs in modals.

### Handling Long Text
- **Visual**: `text-overflow: ellipsis` for containers.
- **Interaction**: Native tooltips (`title` attribute) provide the full text on hover.

---
*Last Updated: 2026-01-21*
