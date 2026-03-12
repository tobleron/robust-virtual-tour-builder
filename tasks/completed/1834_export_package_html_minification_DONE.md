# 1834 Export Package HTML Minification

## Objective
Add production-safe minification for generated exported-tour HTML payloads during package assembly so shipped exports have smaller HTML/inline JS/CSS without changing runtime behavior or pulling minifier code into the browser bundle.

## Scope
- Backend export package assembly only.
- Minify generated `web_only` and `desktop` HTML outputs immediately before ZIP write.
- Preserve existing export paths, runtime behavior, and packaging structure.

## Verification
- `cargo check`
- relevant frontend/build verification if export contracts are touched
- `npm run build`

## Progress
- [x] Confirmed export HTML is generated on the frontend but assembled into the final ZIP on the backend, making backend-side minification the correct integration point.
- [x] Added Rust-side HTML minification for packaged `web_only` and `desktop` HTML outputs using `minify-html` so inline JS/CSS are reduced without shipping a minifier in the browser bundle.
- [x] Added a narrow backend unit test for the HTML minifier helper.
- [x] Ran `npm run build`.
- [x] `cargo check` passed after the later unrelated backend compile issue was fixed elsewhere in the codebase.
