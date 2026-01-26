# Fix React Src Warnings

## Context
Unit tests (and likely runtime logs) are flooding with React warnings:
`An empty string ("") was passed to the src attribute.`
This causes performance issues (browser network requests) and noise in logs.

## Objective
Locate and fix all instances where `src` attributes might receive an empty string.

## Plan
1.  **Locate**: Focus on `src/components/SceneList.res` (SceneItem thumbnail) and other image components.
2.  **Implement Guard**: Change `src={url}` to `src={url != "" ? url : "fallback.png"}` or handle nulls if the binding allows.
    - Note: ReBindings for `img.src` usually expect a string. We might need to render `React.null` or a placeholder `div` if the URL is empty, OR pass a transparent pixel data URI.
3.  **Verify**: Run `npm test` and check that the stderr warnings are gone.
