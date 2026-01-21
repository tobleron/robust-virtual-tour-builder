# CSS Architecture & Best Practices

## Core Philosophy: Separation of Concerns
This project strictly enforces a **Separation of Concerns (SoC)** between the Frontend Logic (ReScript) and the Visual Presentation (CSS).

### ✅ The Golden Rule
**Frontend Logic (`.res`) handles STATE and BEHAVIOR.**
**CSS Files (`.css`) handle LOOK and FEEL.**

### ❌ Forbidden Patterns
- **Do NOT** use inline styles in ReScript (e.g., `style={makeStyle({"color": "red"})}`).
- **Do NOT** define color palettes or font sizes in ReScript constants.
- **Do NOT** mix layout logic with business logic.

---

## 1. Implementation Guidelines

### A. Use Semantic Classes
Instead of describing *what* the style is (e.g., `text-red-500`), describe *what* the component is or its state.

**BAD (Utility Overload / Inline):**
```rescript
// ❌ Inline Style
<div style={makeStyle({"backgroundColor": "#ff0000"})}> Error </div>

// ❌ Ad-hoc Utilities (Hard to maintain consistency)
<div className="bg-red-500 text-white font-bold p-4"> Error </div>
```

**GOOD (Semantic):**
```css
/* css/components/notifications.css */
.notification-error {
    background-color: var(--danger);
    color: white;
    font-weight: 700;
    padding: 1rem;
}
```
```rescript
// ✅ ReScript
<div className="notification-error"> {React.string("Error")} </div>
```

### B. Dynamic Styling via State Classes
When a component changes appearance based on state (e.g., active, disabled, loading), do **not** swap values in ReScript. Instead, toggle specific state classes.

**BAD (Logic-Heavy Styling):**
```rescript
// ❌ ReScript calculating colors
let bgColor = if isActive { "#00ff00" } else { "#cccccc" }
<div style={makeStyle({"backgroundColor": bgColor})} />
```

**GOOD (Class Toggling):**
```css
/* active state defined in CSS */
.my-component.state-active {
    background-color: var(--success);
}
```
```rescript
// ✅ ReScript only handles class logic
<div className={`my-component ${if isActive { "state-active" } else { "" }}`} />
```

---

## 2. Directory Structure

Place CSS files in `css/` according to their scope:

- **`css/base.css`**: Global resets and root variables.
- **`css/variables.css`**: Design tokens (colors, spacing, fonts).
- **`css/layout.css`**: High-level grid/container structures.
- **`css/components/`**: Component-specific styles.
    - `viewer.css` (ViewerUI, HUD)
    - `ui.css` (General UI, Sidebars)
    - `buttons.css` (Button variants)
    - `modals.css` (Dialogs/Overlays)
    - `floor-nav.css` (Floor navigation controls)
    - `upload-report.css` (Upload summary report)

---

## 3. Exceptions to the Rule
Inline styles are permitted **ONLY** when the value is:
1.  **Truly Dynamic/Continuous**: Values that change every frame or depend on arbitrary user input (e.g., coordinates, progress bar percentage, highly granular drag positions).
2.  **External Image URLs**: Background images sourced from API data.

*Example of Valid Inline Style:*
```rescript
// Valid because 'progress' is a continuous float 0-100
<div style={makeStyle({"width": Float.toString(progress) ++ "%"})} />
```

---

## 4. Design Tokens
Always use the CSS Variables defined in `css/variables.css`.

- `var(--primary)`, `var(--secondary)`, `var(--danger)`
- `var(--font-heading)`, `var(--font-ui)`
- `var(--shadow-md)`, `var(--radius-lg)`

**Never hardcode hex values** (e.g., `#003da5`) in new CSS. Use the variables to ensure consistent theming.
