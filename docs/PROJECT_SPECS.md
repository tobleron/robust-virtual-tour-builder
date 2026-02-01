# Project Architecture & Specifications

This document outlines the high-level architecture, design system, and technical specifications of the Robust Virtual Tour Builder.

---

# Part 1: System Architecture & Technical Specifications

This section outlines the high-level architecture, performance strategies, security controls, and observability systems of the Robust Virtual Tour Builder.

## 1. High-Level Architecture

The project follows a **System 2 Thinking** architecture, partitioned between a logic-heavy ReScript frontend and a performance-critical Rust backend.

### Component Breakdown
- **Frontend (ReScript)**: Handles UI state management, user interactions, and orchestration of complex workflows (Simulation, Teaser Generation).
- **Backend (Rust)**: Executes CPU-intensive tasks including image processing (WebP encoding), parallel quality analysis, and project packaging (ZIP).
- **Data Validation Layer**: Uses `rescript-schema` to enforce strict runtime validation at the IO boundary, ensuring 100% type safety for API responses and preventing runtime crashes.
- **Security Logic**: Memory-safe Rust eliminates common vulnerabilities like buffer overflows.

## 2. Performance Engineering

### Optimization Highlights
- **Single-ZIP Project Loading**: Consolidates metadata and images into one request, improving load times by **70%**.
- **Parallel processing (Rayon)**: Backend batch operations (Batch Geocoding, Similarity Checks) are up to **5x faster** than sequential JS.
- **Resource-Aware Resizing**: Balancing speed and quality using `fast_image_resize` (Lanczos3 for 4K).
- **Progressive Texture Loading**: 512px blurred previews load instantly, followed by a hot-swap to full 4K panoramas.

### Key Performance Metrics
| Metric | Target | Result | Status |
|:---|:---|:---|:---|
| Initial Bundle (Gzipped) | < 300KB | ~280KB | 🟢 Pass |
| Project Load (50 scenes) | < 5s | ~4s | 🟢 Pass |
| Image Process (4K) | < 1s | ~500ms | 🟢 Pass |
| UI Responsiveness | 60 FPS | 60 FPS | 🟢 Pass |

## 3. Security & Stability Systems

### Build Standards
- **Zero Warnings Policy**: The build pipeline enforces a strict "Zero Warnings" policy (`"error": "+A"`). Any compiler warning is treated as a blocking error, ensuring code quality and preventing technical debt accumulation.

### Defense-in-Depth Strategy
- **Rust Sanitization**: Strict `sanitize_filename()` rejects directory traversal and null bytes.
- **Upload Hardening**: 100MB file size limits and shell metacharacter validation for safe command execution.
- **Network Security**: Rate limiting (30 req/sec) and environment-aware CORS (restricted in production).
- **XSS Prevention**: Strict CSP meta-tags and mandatory use of `textContent` in the frontend.

### Error Handling Philosophy
- **ReScript/Rust Types**: Errors are handled as values (Result/Option), preventing runtime crashes.
- **Backend Panic Hook**: A global panic hook captures unhandled Rust exceptions and routes them through the tracing system with full location metadata.
- **Graceful Degradation**: Failures in non-critical systems (like caching) do not interrupt the primary application flow.

### Sanitization Standards
To prevent filesystem vulnerabilities and ensure cross-platform compatibility, all file input/output must adhere to strict sanitization rules.

**1. Backend Filename Sanitization (`sanitize_filename`)**
Any filename processed by the Rust backend must pass the `sanitize_filename` check in `backend/src/api/utils.rs`:
- **Rejection Rules**:
  - Must not be empty.
  - Must not be an absolute path.
  - Must not contain parent directory traversal (`..`).
  - Must not address the root directory.
- **Replacement Rules**:
  - `/`, `\`, and `\0` (null byte) are replaced with `_`.
- **Output**: Returns only the filename component, stripping any directory path.

**2. Frontend Input Sanitization (`TourLogic.sanitizeName`)**
User-generated names (Tours, Scenes) are sanitized before being used in any context that might touch the filesystem (e.g., zip generation):
- **Trimming**: Whitespace is trimmed from start/end.
- **Character Whitelist**: Control characters (`\x00-\x1F\x7F`) and filesystem reserved characters (`< > : " / \ | ? *`) are replaced with `_`.
- **Formatting**: Multiple spaces/underscores are collapsed to a single `_`; leading/trailing underscores are removed.
- **Fallback**: Empty results default to `"Untitled"`.

**3. Project Export Filenames**
When generating project ZIP files for download, a strict alphanumeric subset is enforced to ensure maximum compatibility:
- **Format**: `Saved_RMX_[NAME]_v[VERSION]_[DATE].vt.zip`
- **Logic**:
  - `[NAME]`: Converted to lowercase.
  - **Strict Regex**: `/[^a-z0-9]/gi` is replaced with `_`.

## 4. Observability & Metrics

### Intelligent Telemetry
The system employs a priority-based, unified telemetry engine to balance debugging depth with backend performance. All logs (Frontend/Backend) are consolidated into a structured JSON sink (`diagnostic.log`).

- **Diagnostic Mode (Live)**: When toggled in the **About** dialog, the frontend switches to **Live Telemetry**, bypassing batching to stream all Trace/Debug logs immediately to the server.
- **Critical/High (Errors/Warnings)**: Always transmitted immediately to the backend for real-time alerting.
- **Medium (Info/Performance)**: Buffered in a client-side queue and dispatched in batches (default: every 5s or 50 entries) when not in Diagnostic Mode.
- **Low (Debug/Trace)**: Restricted to the browser console when Diagnostic Mode is OFF; broadcasted live when Diagnostic Mode is ON.
- **Reliability**: Implements exponential backoff (starting at 1s) for failed transmissions to ensure observability during transient network instability.

### System Monitoring
- **Visual Performance**: Throttled rendering (20fps during simulation) minimizes resource contention.
- **Real-time Tailer**: Dedicated tool `./scripts/tail-diagnostics.sh` provides a formatted, color-coded view of multi-source logs.
- **Log Categorization**: Structured logs track the visual pipeline (SCENE_SWAP, CROSSFADE_TRIGGER) to debug race conditions.
- **Turtle Logs**: Console warnings (🐢) highlight operations taking >500ms for developer awareness.

## 5. Teaser System & Video Pipeline

### Native Integration
- **FFmpeg Transcoding**: Native integration for WebM to MP4 conversion.
- **FFmpeg Core Caching**: Large binaries are cached in IndexedDB, reducing warm-start times from 30 seconds to near-instant.
- **Quality Control**: Visual quality is maintained via named constants (e.g., `WEBP_QUALITY`, `FFMPEG_CRF_QUALITY`).

---

# Part 2: Design System & Styling Architecture

This section defines the visual standards, accessibility requirements, and CSS architecture for the Robust Virtual Tour Builder.

## 1. Core Philosophy: Separation of Concerns

This project strictly enforces a **Separation of Concerns (SoC)** between Frontend Logic (ReScript) and Visual Presentation (CSS).

### ✅ The Golden Rule
**Frontend Logic (`.res`) handles STATE and BEHAVIOR.**
**CSS Files (`.css`) handle LOOK and FEEL.**

### ❌ Forbidden Patterns
- **Do NOT** use inline styles in ReScript (e.g., `style={makeStyle({"color": "red"})}`).
- **Do NOT** define color palettes or font sizes in ReScript constants.
- **Do NOT** mix layout logic with business logic.

## 2. Strategic Dual-Font System

For optimal readability and visual hierarchy, we use a two-font approach:

### Outfit (Display/Body Font)
- **Use for**: Headings, titles, body text, branding, progress indicators.
- **Characteristics**: Modern, geometric, high visual impact.
- **CSS Variable**: `var(--font-heading)` or `var(--font-body)`

### Inter (UI/Functional Font)
- **Use for**: Form inputs, buttons, labels, technical text, version numbers.
- **Characteristics**: Optimized for UI, excellent legibility at small sizes.
- **CSS Variable**: `var(--font-ui)`

### Performance Metrics
- **Optimization**: Reduced from 4 fonts to 2 (removed EB Garamond and Merriweather).
- **Impact**: ~50% reduction in font loading bandwidth (~40-60KB saved).

## 3. Standardized Typography & Sizing

### Accessible Font Scale (WCAG 2.1 AA)
Based on a 16px base, using CSS variables to ensure consistency.

| Variable | Size | Use Case |
|----------|------|----------|
| `--text-xs` | 12px | Fine print, captions, timestamps |
| `--text-sm` | 14px | UI labels, helper text, small buttons |
| `--text-base`| 16px | Body text, inputs, default size |
| `--text-lg` | 18px | Emphasized text, large buttons |
| `--text-xl` | 20px | Section headings |
| `--text-2xl`| 24px | Page headings, modal titles |
| `--text-3xl`| 30px | Hero headings |

### Responsive Sizing Techniques
- **Viewport Scaling**: `font-size: clamp(var(--text-sm), 3.5vw, var(--text-base));`
- **Content-Aware Scaling**: Sidebar filenames shrink from 16px to 14px as length increases to preserve layout integrity.

## 4. Color Palette & Design Tokens

Always use the variables defined in `css/variables.css`. **Never hardcode hex values.**

### Semantic Colors
- `var(--primary)`: Main brand color.
- `var(--secondary)`: Accent and supporting elements.
- `var(--danger)`: Error states and destructive actions.
- `var(--success)`: Positive feedback and completion states.

## 5. CSS Implementation Guidelines

### A. Semantic Classes
Describe *what* a component is, not just its appearance.
- **BAD**: `bg-red-500 text-white`
- **GOOD**: `.notification-error`

### B. State-Based Styling
Toggle CSS classes in ReScript instead of manipulating styles directly.
- **Example**: `.my-component.state-active { ... }`

### C. Exceptions for Inline Styles
Permitted **ONLY** for:
1. **Dynamic/Continuous Values**: Coordinate math (hotspots), progress bar percentages.
2. **External Assets**: User-uploaded background images.

## 6. Accessibility (ARIA & UX)

### Standards Compliance
- **WCAG 2.1 AA**: Minimum font size 12px; high contrast ratios.
- **Keyboard Navigation**: Full Tab/Enter support; `Escape` key closes all modals.
- **Screen Readers**: Descriptive ARIA labels (e.g., `aria-label="Save navigation link"`).
- **Focus Management**: Visible focus rings and auto-focusing primary inputs in modals.

### Handling Long Text
- **Visual**: `text-overflow: ellipsis` for containers.
- **Interaction**: Native tooltips (`title` attribute) provide the full text on hover.
