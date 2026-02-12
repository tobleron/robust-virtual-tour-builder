# Enterprise SLO Baseline Report

## Summary
This document establishes the initial reliability and performance baselines for the Robust Virtual Tour Builder, defining Service Level Indicators (SLIs) and Service Level Objectives (SLOs) for enterprise-grade operations.

## Correlation Identification Standard
To ensure end-to-end observability, the following identifiers are enforced:

| Field | Type | Description | Propagation |
|-------|------|-------------|-------------|
| `sessionId` | UUID | Unique browser session identifier. Persists until app reload. | `X-Session-ID` Header |
| `operationId` | UUID | Unique logical operation identifier (e.g., a multi-attempt upload). | `X-Operation-ID` Header |
| `requestId` | UUID | Unique physical request identifier for a single HTTP attempt. | `X-Request-ID` Header |

## Service Level Objectives (SLO)

| Flow | SLI (Metric) | Target (SLO) | Error Budget (per month) |
|------|--------------|--------------|--------------------------|
| **Availability** | Success rate of API requests (non-4xx/5xx) | > 99.9% | ~43 mins downtime |
| **Scene Switching** | Latency from click to panorama visible | p95 < 1.5s | 5% exceeding 1.5s |
| **Upload Pipeline** | Image processing + upload success rate | > 98% | 2% failed uploads |
| **Project Persistence** | Save/Load success rate | > 99.99% | ~4 mins downtime |
| **Interaction Stability** | Frontend long tasks (>50ms) per session | < 10 avg | N/A |

## Baseline Measurements (v5.0-current)
*Measurements based on current mainline stress testing (200 scenes, 4K textures).*

### 1. Latency (p95)
- **Scene Switch (Local Cache):** 120ms
- **Scene Switch (Network Load):** 850ms - 1.2s
- **Project Save (Large):** 1.8s
- **Image Optimization (4K):** 450ms (client-side)

### 2. Error Rates
- **Network Flakiness:** Observed ~1% in simulated high-latency environments.
- **Circuit Breaker Triggers:** < 0.1% of sessions.

### 3. Memory & Efficiency
- **Memory Trend:** Stable at ~250MB for 50 scenes; grows to ~600MB for 200 scenes.
- **Zombie Components:** None detected in current lifecycle audits.

## Threshold Contracts (CI Enforcement)
The following gates are to be enforced in future CI/CD pipeline tasks:
1. **Performance Gate:** Any PR increasing p95 Scene Switch latency by >10% must be flagged.
2. **Reliability Gate:** Any increase in unhandled exception rate in telemetry triggers automatic revert.
3. **Correlation Gate:** All new API endpoints MUST propagate `operationId` and `sessionId`.

---
*Created: 2026-02-12*
*Status: BASELINE_ESTABLISHED*
