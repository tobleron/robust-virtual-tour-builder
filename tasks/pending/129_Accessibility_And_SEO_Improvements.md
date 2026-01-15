# Task: Professional Accessibility & SEO Enhancement

## Status
- **Priority:** MEDIUM-HIGH
- **Estimate:** 3 hours
- **Category:** UX / Compliance

## Description
The application lacks critical accessibility features required for WCAG 2.1 AA compliance and professional SEO signals.

## Requirements
### Accessibility
1.  **Skip Navigation:** Add a "Skip to Content" link at the top of `index.html` (visible only on focus) that targets the main viewer container.
2.  **Color Contrast Audit:** Review the `premium-glass` and `bg-primary` styles to ensure text contrast ratios meet 4.5:1.
3.  **Keyboard Focus:** Ensure all interactive elements in `ViewerUI.res` and `Sidebar.res` have clearly visible `:focus-visible` rings.

### SEO & Social Sharing
1.  **Meta Tags:** Add `<meta name="description">` to `index.html`.
2.  **Open Graph (OG):** Implement `og:title`, `og:description`, `og:image`, and `og:type` tags.
3.  **Twitter Cards:** Implement `twitter:card`, `twitter:title`, and `twitter:image` tags.

## Expected Outcome
- Improved screen reader navigation.
- Better visibility and professional link previews when sharing tours on social media.
- WCAG 2.1 AA compliant color contrast.
