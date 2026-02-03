# Task 1195: Create Tests for Teaser System

## Objective
Create unit tests for `src/systems/Teaser.res` to ensure `startAutoTeaser` and other logic works correctly.

## Context
`Teaser.res` currently lacks a dedicated test file `tests/unit/Teaser_v.test.res`.

## Requirements
- Create `tests/unit/Teaser_v.test.res`.
- Test `startAutoTeaser` (mocking dependencies like `GlobalStateBridge`, `Sidebar`, etc. if needed).
- Verify dispatch of correct actions.
