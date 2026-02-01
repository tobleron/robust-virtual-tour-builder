---
description: Functional Programming Standards (Router) - Guide for ReScript & Rust
---

# Functional Programming Standards (The Router)

## 🌍 Universal Principles (Always Apply)

No matter the language, adhering to these core principles reduces bugs:

1.  **Immutability First**: Default to `const`/`let`-bindings. Create new values rather than modifying existing ones.
2.  **Pure Functions**: Same Input → Same Output. Isolate side-effects (I/O, DB) to the edges of your architecture.
3.  **Type Safety**: Handle all edge cases. No "null" surprises. Use `Result` or `Option` types. Mandate `rescript-json-combinators` (ReScript) or `serde` (Rust) for all I/O boundary validation.

---

## 🔀 Workflow Router

Check the file extension you are working on and **READ** the corresponding standard:

### 1. 🚀 ReScript / Frontend (`.res`, `.resi`)
> **Action**: Read `.agent/workflows/rescript-standards.md`
> **Focus**: State management, extensive type safety, JS interop rules (`Obj.magic`), bindings.

### 2. 🦀 Rust / Backend (`.rs`)
> **Action**: Read `.agent/workflows/rust-standards.md`
> **Focus**: Error handling (`Result`), ownership, borrowing, concurrency (`Rayon`).

### 3. 📒 JavaScript / Glue (`.js`, `.mjs`)
> **Action**: Follow ReScript principles where possible (Immutability). Use `const`.

---

## Summary Checklist (Universal)

- [ ] Am I mutating state where I could return a new value?
- [ ] Are my side effects (I/O, Logging) isolated via the unified `Logger` system?
- [ ] Have I handled failure cases as values types (Result/Option)?
