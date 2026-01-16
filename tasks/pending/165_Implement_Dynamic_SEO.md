---
title: Implement Dynamic SEO and HTML Config
status: pending
priority: medium
assignee: unassigned
---

# Implement Dynamic SEO and HTML Config

## Objective
Move hardcoded SEO metadata (Canonical URLs, Title, Description) from `index.html` to a configuration-driven approach during the build process.

## Context
`index.html` currently contains hardcoded values like `<link rel="canonical" href="https://your-domain.com/">`. Using the same template for dev, staging, and prod with different domains requires dynamic injection.

## Requirements
1.  **Rsbuild Config**: Modify `rsbuild.config.mjs` to define `html.templateParameters`.
2.  **Environment Variables**: sourcing values from `.env` files (e.g. `PUBLIC_URL`, `APP_TITLE`).
3.  **Template Update**: Update `index.html` to use EJS-style or Rsbuild-style placeholders (e.g. `<%= title %>`, `<%= canonicalUrl %>`).
4.  **Defaults**: Ensure valid defaults exist if env vars are missing.

## Implementation Details
-   **Rsbuild**: Use the `html.templateParameters` option.
-   **Meta Tags**: Focus on `og:url`, `canonical`, `title`, and `description`.

## Definition of Done
- [ ] Building with `PUBLIC_URL=https://production.com` results in the correct canonical tag in `dist/index.html`.
- [ ] Building locally (Dev) defaults to localhost or empty.
