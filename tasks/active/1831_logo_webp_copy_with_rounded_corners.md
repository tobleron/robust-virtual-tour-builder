# 1831 Logo WebP Copy With Rounded Corners

## Objective
Create a rounded-corner copy of `public/images/robust_logo_new.png` in `public/images/` using a web-friendly format that preserves transparency if supported, and ensure builder/export logo optimization keeps that transparency during upload packaging.

## Scope
- Inspect the source logo asset dimensions/format.
- Create a copied asset with rounded corners.
- Prefer WebP if transparency is supported reliably.
- Inspect the builder/export logo optimization path for alpha flattening.
- Preserve transparency when logos are optimized to WebP for builder state and export packaging.
- Refine exported-tour watermark sizing so logo surface area scales more proportionally with the rendered stage.
- Refine the exported-tour 4K marketing banner so it appears slightly shorter within the builder preview stage.
- Add focused regression coverage for the logo transparency-preservation path.
- Verify the output file exists and inspect its alpha/channel data.
- Run the standard build verification.

## Constraints
- Do not alter the original source file.
- Keep the output in `public/images/`.
- Use local tooling only.
- Keep the transparency fix scoped to logo optimization rather than broad panorama-processing behavior.

## Verification
- inspect source/output metadata
- `npm run test:frontend`
- `npm run build`

## Progress
- [x] Created rounded transparent WebP copy in `public/images/`.
- [x] Preserved alpha during builder/export logo WebP optimization.
- [x] Refined exported-tour watermark sizing to use runtime stage-area and logo-aspect scaling.
- [x] Added focused unit-test coverage for the alpha-preservation path.
- [x] Verified with `npm run test:frontend`.
- [x] Verified with `npm run build`.
