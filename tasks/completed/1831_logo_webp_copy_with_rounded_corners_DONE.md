# 1831 Logo WebP Copy With Rounded Corners

## Objective
Create a rounded-corner copy of `public/images/robust_logo_new.png` in `public/images/` using a web-friendly format that preserves transparency if supported.

## Scope
- Inspect the source logo asset dimensions/format.
- Create a copied asset with rounded corners.
- Prefer WebP if transparency is supported reliably.
- Verify the output file exists and inspect its alpha/channel data.
- Run the standard build verification.

## Constraints
- Do not alter the original source file.
- Keep the output in `public/images/`.
- Use local tooling only.

## Verification
- inspect source/output metadata
- `npm run build`
