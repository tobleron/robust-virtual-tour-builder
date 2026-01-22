# Security & Stability System

This document provides a comprehensive overview of the security architecture, audit findings, and implemented protections for the Robust Virtual Tour Builder.

---

## 1. Executive Summary

The project utilizes a **defense-in-depth** strategy, leveraging a memory-safe Rust backend for security-critical operations and a type-safe ReScript frontend. A comprehensive security audit conducted in early 2026 identified and resolved all critical vulnerabilities.

**Overall Risk Level:** 🟢 **LOW** (Post-Remediation)

---

## 2. Implemented Security Controls

### A. Backend Protections (Rust)
- **Path Traversal Protection**: Secure `sanitize_filename()` function rejects directory traversal (`..`), absolute paths, and null bytes.
- **Upload Size Limits**: Enforced `MAX_UPLOAD_SIZE` (100MB) across all processing endpoints to prevent Denial of Service (DoS) via memory exhaustion.
- **Safe Command Execution**: FFmpeg paths are validated against shell metacharacters to prevent Command Injection.
- **Integer Overflow Protection**: Saturating arithmetic used in image processing pipelines (e.g., luminance calculations).
- **Graceful Shutdown**: Handles OS signals to ensure clean session termination and temporary file cleanup.

### B. Network & API Security
- **Rate Limiting**: `actix-governor` limits requests to 30 per second with a burst size of 50 per IP.
- **Environment-Aware CORS**: 
  - *Development*: Permissive for rapid testing.
  - *Production*: Restricted to specific origins and the `file://` protocol for desktop compatibility.
- **Secure HTTP Headers**: 
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY` (Anti-Clickjacking)
  - `X-XSS-Protection: 1; mode=block`
  - `Referrer-Policy: strict-origin-when-cross-origin`

### C. Frontend Protections (ReScript/JS)
- **Content Security Policy (CSP)**: Strict meta-tag policy blocks unauthorized script execution and data exfiltration.
- **XSS Prevention**: `escapeHtml()` utility sanitizes all user-provided data (e.g., scene names) before injection into the DOM.
- **Input Sanitization**: `sanitizeName()` removes control characters and invalid filesystem characters from tour and scene labels.
- **Safe DOM APIs**: Mandatory use of `textContent` instead of `innerHTML` for dynamic text updates.
- **Improved Duplicate Detection**: SHA-256 hashing for files ≤10MB; sample-based hashing (start/middle/end) for larger files.

---

## 3. Audit Findings & Remediation History

### Critical Issues Fixed (2026-01-10)
| Issue | Risk | Status | Fix Details |
|:---|:---|:---|:---|
| Path Traversal | Arbitrary file write | ✅ FIXED | Implemented strict filename sanitization. |
| Memory Exhaustion | DoS | ✅ FIXED | Added 100MB upload limit per file. |
| XSS in Modals | Script injection | ✅ FIXED | Implemented HTML escaping for scene names. |
| Permissive CORS | CSRF / API Abuse | ✅ FIXED | Restricted origins in production builds. |

### Stability & Robustness Upgrades
- **Configurable Logging**: Log directories are now environment-aware (defaults to `../logs`).
- **Enhanced Error Context**: Backend errors now include file size and processing stage for easier debugging.
- **Race Condition Protection**: 300ms debounce window added to Simulation System to prevent rapid overlapping transitions.
- **Promise Rejection Handling**: Global `onunhandledrejection` handler prevents silent failures in production.

---

## 4. Security Architecture Highlights

1. **Rust Backend**: Eliminates buffer overflows and memory-management vulnerabilities.
2. **UUID-based Temp Files**: Prevents predictable file path attacks.
3. **Structured Error Handling**: Custom error types prevent sensitive internal data leakage to the client.
4. **Metadata Validation**: EXIF and WebP chunks are validated before parsing to prevent malformed data exploits.

---

## 5. Deployment Checklist

Before production deployment, verify:
- [ ] `LOG_DIR` environment variable is set.
- [ ] Production build is used (`cargo build --release`) to enable strict CORS.
- [ ] CSP meta-tags are present in `index.html`.
- [ ] Rate limiting is active on all endpoints.
- [ ] HTTPS is enforced at the network layer.

---
*Last Updated: 2026-01-18*
