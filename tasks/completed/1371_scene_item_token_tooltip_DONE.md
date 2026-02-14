# 1371 Scene Item token label & tooltip cleanup

## Problem
1. When loading a saved project, the `SceneList` entries reuse the scene `file` URL that now includes `?token=…`. The badge inside each row still extracts the extension by splitting the raw URL, so the tooltip and extension label sometimes render `WEBP?TOKEN=dev-token` or similar.
2. The tooltip currently falls back to the `scene.originalFile` `File`, which is only present during the initial upload. After reloading a project the field is a `Url`, so the tooltip shows "filename unavailable" instead of the actual image name.

## Goal
- Strip query/fragments off the URL when computing the format badge so it only shows the extension (e.g. `WEBP`).
- When a saved project is loaded show the actual image filename in the tooltip by decoding it from the `/file/...` URL, while still using the uploaded file name when a `File` is available.
- Keep existing fallbacks so that we never show the raw query string or an empty tooltip label.
