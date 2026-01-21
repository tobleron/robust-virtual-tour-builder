# Project Evolution & Release History

This document tracks the iterative growth, version milestones, and long-term roadmap for the Robust Virtual Tour Builder.

---

## 🚀 Current Project Status
- **Version**: v4.3.7 (Stable UI)
- **Status**: Commercial Ready (Post-Gap Analysis)
- **ReScript Logic Coverage**: ~95%
- **Test Pass Rate**: 100% (40/40 Unit Tests)

---

## 🗺️ Strategic Roadmap

### Tier 1: Core Consolidation (COMPLETED)
- ✅ Centralized Reducer Architecture (ReScript).
- ✅ Rust-Powered Image Processing Pipeline.
- ✅ Robust State management via `RootReducer`.

### Tier 2: Refinement & Polish (CURRENT)
- 🏃 Final elimination of `Obj.magic` (38 remaining).
- 🏃 Migration of `Viewer.js` helper functions to ReScript.
- 🏃 Implementation of PWA offline support (Optional/Postponed).

### Tier 3: Advanced Intelligence (FUTURE)
- 🔮 AI-assisted scene categorization (Outdoor/Indoor automatic detection).
- 🔮 Deep image similarity for automatic hotspot placement suggestions.
- 🔮 Interactive floor plan generation from panorama metadata.

---

## 📦 Version History (Major Milestones)

### v4.3.7: "Stable UI No Ghost"
- **Date**: 2026-01-21
- **Focus**: Final resolution of "Ghost Arrow" artifacts.
- **Key Changes**: Implemented "Iron Dome" CSS protections and loop de-confliction.

### v4.3.0: Commercial Compliance
- **Date**: 2026-01-15
- **Focus**: Legal and SEO readiness.
- **Key Changes**: Addition of Privacy Policy, Terms of Service, and structured data headers.

### v4.0.0: ReScript Transition
- **Date**: Early 2026
- **Focus**: Migration from JavaScript to a type-safe functional architecture.
- **Key Changes**: Complete rewrite of the logic layer; introduction of the Rust backend.

---

## ✨ Notable Improvements (Retrospective)

### Performance Breakthroughs
- **FFmpeg Caching**: Reduced warm-start video generation time from 30s to near-instant.
- **Single-ZIP loading**: Improved initial load times for 50+ scene projects by 70%.

### Accessibility Wins
- **Full ARIA support**: Implemented descriptive labels for all interactive elements.
- **Keyboard-only Navigation**: Enabled full tour building experience without a mouse.
- **WCAG 2.1 AA Compliance**: Guaranteed high contrast and accessible font sizes (min 12px).

---
*Last Updated: 2026-01-21*
