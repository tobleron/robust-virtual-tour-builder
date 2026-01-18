# Logging, Telemetry & Simulation System

This document describes the hybrid logging architecture, automated simulation mode, and telemetry tracking systems used for observability and testing.

---

## 1. Logging Architecture (Hybrid Design)

The project uses a systematic hybrid design where the frontend catches and enriches logs with UI context, while the backend persists them to disk.

### Responsibility Split
- **Frontend (ReScript)**: Captures navigation states, user interactions (clicks, edits), and viewer events. Stores a 500-entry ring buffer in memory.
- **Backend (Rust)**: Persists logs to `logs/telemetry.log` (JSON) and `logs/error.log` (Plaintext). Implements log rotation and cleanup.

### Log Levels
- `trace`: High-frequency frame/animation ticks (hidden).
- `debug`: Step-by-step internal flow.
- `info`: Major lifecycle events (Initializations, Nav Complete).
- `warn`: Soft failures (Duplicate links, performance lag).
- `error`: Critical failures (Always forwarded to backend).
- `perf`: Timing data (Classified as 🐢 Slow, ⏱️ Moderate, or ⚡ Fast).

---

## 2. Simulation Mode (Auto-Tour)

Simulation Mode allows users to test the final tour navigation without leaving the builder.

### How It Works
- **Toggle**: Located in the viewer utility bar (Play icon ▶).
- **Behavior**: When active, "Jump Link" scenes (bridge scenes) automatically auto-navigate to their target after 500ms.
- **Safety**: Auto-navigation is suppressed when simulation mode is OFF, allowing users to edit jump link scenes without being redirected.

### Navigation Improvements
- **Debounced Viewport Saving**: 800ms timer prevents accidental camera view overwrites during rapid panning.
- **Smart Settings Persistence**: Tracks if metadata was set by default or by a user to prevent overriding intentional choices.
- **Centralized Tracking**: All scene transitions flow through a single `navigateToScene()` function for consistent telemetry.

---

## 3. Simulation Telemetry

During simulation/navigation, the system captures high-resolution telemetry to analyze transition smoothness.

### Key Events
1. **JOURNEY_START**: Logs initial camera position, momentum factors, and expected pan duration.
2. **CROSSFADE_TRIGGER**: Logs the exact moment (usually at 80% progress) when the scene swap begins.
3. **AUTOFORWARD_CHAIN**: Tracks the sequence of scenes in an auto-forward "bridge" path.
4. **JOURNEY_CANCELLED**: Logged if a user interrupts an automated pan with a manual click.

### Optimization Targets
- **Timing Delta**: Difference between actual and expected crossfade triggers should be near 0ms.
- **Pre-Animation Delay**: Should be minimized to ensure continuous motion between scenes.

---

## 4. Debugging & Testing

### Runtime Console Controls
- `DEBUG.enable()` / `DEBUG.disable()`: Toggle console output.
- `DEBUG.setLevel('debug')`: Increase verbosity.
- `DEBUG.downloadLog()`: Export the current session's log buffer as a JSON file.
- `DEBUG.getSummary()`: Get a count of logs per module.

### Manual Verification Workflow
1. Open Browser Console (F12).
2. Run `DEBUG.enable(); DEBUG.setLevel('trace');`.
3. Perform actions (Navigate, Upload, Edit).
4. Verify entries in `logs/telemetry.log` and `logs/error.log` on the server.
5. Check performance metrics (Look for 🐢 icons in the console).

---
*Last Updated: 2026-01-18*
