# AI Guidelines & Project Philosophy

This document defines the high-level philosophy and architectural intent of the project. For procedural rules and coding standards, refer to [`.cursorrules`](/.cursorrules).

---

## 🎯 Core Philosophy
- **Stability First**: Robustness over speed. Type safety via ReScript is our shield.
- **Premium UX**: The app must feel expensive. Use smooth transitions, high-quality typography (Outfit/Inter), and refined color palettes.
- **Incrementalism**: Small, verified steps. Never attempt a "big bang" refactor without user approval.

---

## 🌳 Branching & Release
- **`develop`**: Where active work happens. Version suffix: `-beta`.
- **`main`**: Production-ready, stable releases only.
- **Pushing**: We commit often locally, but push to GitHub only on major updates (Y increment) or critical fixes.

---

## 🏗️ Architecture Source of Truth
- **ReScript v12**: The primary language for the frontend.
- **Functional Paradigm**: Favor immutability and pattern matching.
- **Centralized State**: `src/store.js` is the single source of truth for the app state.
- **Backend**: Rust-based, focused on high-performance image processing and safe file handling.

---

## 🎨 Design System
- **Typography**: 
  - Headings: `Outfit` (Modern, geometric)
  - UI/Body: `Inter` (Legible, functional)
- **Styling**: Vanilla CSS. Rely on CSS variables for a consistent theme.
- **Motion**: Every interactive element must have a subtle micro-interaction (hover, active, transition).

---

## 📚 Documentation Policy
- **Feature Docs**: Place in `/docs`.
- **Procedural Workflows**: Place in [`.agent/workflows/`](/.agent/workflows/).
- **Rules**: Keep the "vitals" in [`.cursorrules`](/.cursorrules).

---

## 💬 Communication
- **Be Explanatory**: When you change code, explain the *reasoning* and *impact*.
- **Be Proactive**: If you see a security flaw or a performance bottleneck, point it out.
- **Confirm Destructive Actions**: Always ask before deleting files or performing major refactors.
