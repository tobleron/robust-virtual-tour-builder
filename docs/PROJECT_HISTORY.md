# Project Evolution & Release History

This document tracks the iterative growth, version milestones, and long-term roadmap for the Robust Virtual Tour Builder.

---

## 🚀 Current Project Status
- **Version**: v4.3.7 (Stable UI)
- **Status**: Commercial Ready (Post-Gap Analysis)
- **ReScript Logic Coverage**: ~95%
- **Test Pass Rate**: 100% (40/40 Unit Tests)

---

## 📦 Version History

### v4.3.7: "Stable UI No Ghost" (2026-01-21)
- **Focus**: Final resolution of "Ghost Arrow" artifacts.
- **Key Changes**: Implemented "Iron Dome" CSS protections and loop de-confliction.

### v4.3.0: Commercial Compliance (2026-01-15)
- **Focus**: Legal and SEO readiness.
- **Key Changes**: Addition of Privacy Policy, Terms of Service, and structured data headers.

### v4.0.0: ReScript Transition (Early 2026)
- **Focus**: Migration from JavaScript to a type-safe functional architecture.
- **Key Changes**: Complete rewrite of the logic layer; introduction of the Rust backend.

---

## 🛠️ Notable Bug Fixes

### Fix: Project Name "Unknown" Bug (v2)
- **Robust Filtering**: Implemented optional type checking and case-insensitive regex (`/Unknown/i`) in `UploadProcessor.res` to reject dummy names.
- **Architecture Shift**: Updated `ExifReportGenerator.res` to return `option<string>` instead of "Unknown_Location" strings.
- **Diagnostics**: Added specific logs (`PROJECT_NAME_GENERATED_FROM_EXIF`, `SKIPPING_UNKNOWN_PROJECT_NAME`) for traceability.
- **Verification**: Updated unit tests to verify `None` return behavior.

---

## 🗺️ Strategic Roadmap

### Tier 1: Core Consolidation (COMPLETED)
- ✅ Centralized Reducer Architecture (ReScript).
- ✅ Rust-Powered Image Processing Pipeline.
- ✅ Robust State management via `RootReducer`.

### Tier 2: Refinement & Polish (CURRENT)
- 🏃 Final elimination of `Obj.magic` (38 remaining).
- 🏃 Migration of `Viewer.js` helper functions to ReScript.

### Tier 3: Advanced Intelligence (FUTURE)
- 🔮 AI-assisted scene categorization.
- 🔮 Deep image similarity for hotspot suggestions.
- 🔮 Interactive floor plan generation.

---

## 📊 Historical Reports Summary

### AutoPilot Simulation Analysis (2026-01-20)
- **Issue**: Timeout errors during simulation.
- **Fixes**: Unified timeout constants, enabled progressive loading during simulation, and added retry logic.

### Application Analysis (2026-01-25)
- **Status**: 9/10 Design System compliance, 9.5/10 Testing Health.
- **Findings**: `Obj.magic` usage regression (62 vs target 38).
- **Action**: Ongoing refactoring to reduce unsafe casting.

### E2E Performance Analysis
- **Status**: Framework setup complete (Playwright).
- **Challenges**: Backend image format detection in headless environment requires tuning.

---
*Last Updated: 2026-01-25*
