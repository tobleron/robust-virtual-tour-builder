# System Robustness Patterns

**Version**: 1.0  
**Last Updated**: 2026-02-04  
**Status**: Active Standard

---

## Overview

This document outlines reusable architectural patterns for building robust, fault-tolerant systems. These patterns are language-agnostic and can be applied to any modern web application.

---

## 1. Circuit Breaker Pattern

### Purpose
Prevent cascading failures by detecting when a service is unhealthy and temporarily blocking requests to it.

### Implementation Strategy

```typescript
// Conceptual Implementation
class CircuitBreaker {
  states: 'CLOSED' | 'OPEN' | 'HALF_OPEN'
  failureThreshold: number
  resetTimeout: number
  
  async execute(fn: () => Promise<T>): Promise<Result<T>> {
    if (state === 'OPEN') {
      if (shouldAttemptReset()) {
        state = 'HALF_OPEN'
      } else {
        return Error('Circuit is OPEN')
      }
    }
    
    try {
      const result = await fn()
      onSuccess()
      return Ok(result)
    } catch (error) {
      onFailure()
      return Error(error)
    }
  }
}
```

### Key Metrics
- **Failure Threshold**: Number of consecutive failures before opening (typically 3-5)
- **Reset Timeout**: Time to wait before attempting recovery (typically 30-60s)
- **Half-Open Window**: Number of test requests to verify recovery (typically 1-3)

### Benefits
- Prevents resource exhaustion
- Provides graceful degradation
- Enables automatic recovery
- Improves system observability

---

## 2. Retry with Exponential Backoff

### Purpose
Automatically retry failed operations with increasing delays to handle transient failures without overwhelming recovering services.

### Implementation Strategy

```typescript
async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  config: {
    maxRetries: number,        // Default: 3
    initialDelayMs: number,    // Default: 1000
    maxDelayMs: number,        // Default: 30000
    backoffMultiplier: number, // Default: 2.0
    jitter: boolean            // Default: true
  }
): Promise<T> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn()
    } catch (error) {
      if (attempt === maxRetries || !isRetryable(error)) {
        throw error
      }
      
      const delay = calculateDelay(attempt, config)
      await sleep(delay)
    }
  }
}

function calculateDelay(attempt: number, config): number {
  const baseDelay = config.initialDelayMs * Math.pow(config.backoffMultiplier, attempt - 1)
  const capped = Math.min(baseDelay, config.maxDelayMs)
  
  if (config.jitter) {
    // Add 0-20% jitter to prevent thundering herd
    const jitterRange = capped * 0.2
    return capped + Math.random() * jitterRange
  }
  
  return capped
}
```

### Retryable vs Non-Retryable Errors
- **Retryable**: Network errors, 5xx server errors, timeouts
- **Non-Retryable**: 4xx client errors, authentication failures, validation errors

### Benefits
- Handles transient network failures
- Prevents thundering herd with jitter
- Respects server recovery time
- Improves success rate without manual intervention

---

## 3. Request Debouncing & Throttling

### Purpose
Control the rate of user-initiated actions to prevent UI lag and server overload.

### Debouncing
**Use Case**: Text input, search queries, auto-save

```typescript
function debounce<T>(fn: (...args: T[]) => void, delayMs: number) {
  let timeoutId: number | null = null
  
  return (...args: T[]) => {
    if (timeoutId) clearTimeout(timeoutId)
    timeoutId = setTimeout(() => fn(...args), delayMs)
  }
}
```

### Throttling
**Use Case**: Scroll events, resize handlers, rate-limited APIs

```typescript
function throttle<T>(fn: (...args: T[]) => void, intervalMs: number) {
  let lastRun = 0
  
  return (...args: T[]) => {
    const now = Date.now()
    if (now - lastRun >= intervalMs) {
      fn(...args)
      lastRun = now
    }
  }
}
```

### Benefits
- Reduces unnecessary computations
- Prevents UI freezing
- Respects API rate limits
- Improves perceived performance

---

## 4. Interaction Queue (Serialization)

### Purpose
Ensure critical state transitions happen sequentially, preventing race conditions.

### Implementation Strategy

```typescript
class InteractionQueue {
  private queue: Array<() => Promise<void>> = []
  private isProcessing: boolean = false
  
  async enqueue(action: () => Promise<void>): Promise<void> {
    this.queue.push(action)
    
    if (!this.isProcessing) {
      await this.processQueue()
    }
  }
  
  private async processQueue(): Promise<void> {
    this.isProcessing = true
    
    while (this.queue.length > 0) {
      const action = this.queue.shift()!
      try {
        await action()
      } catch (error) {
        console.error('Queue action failed:', error)
      }
    }
    
    this.isProcessing = false
  }
}
```

### Use Cases
- Scene transitions in 360 viewers
- Project save/load operations
- Navigation state changes
- Modal open/close sequences

### Benefits
- Prevents race conditions
- Ensures state consistency
- Simplifies async logic
- Provides natural error boundaries

---

## 5. Optimistic Updates with Rollback

### Purpose
Provide instant UI feedback while maintaining data consistency through automatic rollback on failure.

### Implementation Strategy

```typescript
async function executeOptimistically<T>(
  optimisticUpdate: () => void,
  serverAction: () => Promise<T>,
  rollback: () => void
): Promise<Result<T>> {
  // 1. Apply optimistic update immediately
  optimisticUpdate()
  
  try {
    // 2. Execute server action
    const result = await serverAction()
    return Ok(result)
  } catch (error) {
    // 3. Rollback on failure
    rollback()
    return Error(error)
  }
}
```

### State Snapshot Pattern

```typescript
class StateSnapshot<T> {
  private snapshots: Map<string, T> = new Map()
  
  capture(id: string, state: T): void {
    this.snapshots.set(id, deepClone(state))
  }
  
  restore(id: string): T | null {
    const snapshot = this.snapshots.get(id)
    if (snapshot) {
      this.snapshots.delete(id)
      return snapshot
    }
    return null
  }
}
```

### Benefits
- Instant UI feedback
- Automatic error recovery
- Maintains data consistency
- Improves perceived performance

---

## 6. Rate Limiting

### Purpose
Protect APIs and prevent abuse through sliding window rate limiting.

### Sliding Window Implementation

```typescript
class RateLimiter {
  private requests: number[] = []
  private limit: number
  private windowMs: number
  
  constructor(limit: number, windowMs: number) {
    this.limit = limit
    this.windowMs = windowMs
  }
  
  tryAcquire(): boolean {
    const now = Date.now()
    
    // Remove old requests outside window
    this.requests = this.requests.filter(
      timestamp => now - timestamp < this.windowMs
    )
    
    if (this.requests.length < this.limit) {
      this.requests.push(now)
      return true
    }
    
    return false
  }
}
```

### Benefits
- Prevents API abuse
- Protects server resources
- Provides fair usage
- Enables quota management

---

## 7. Graceful Degradation

### Purpose
Maintain core functionality when non-critical services fail.

### Strategies

1. **Feature Flags**: Disable non-critical features
2. **Fallback Content**: Show cached/default content
3. **Offline Mode**: Enable local-only operations
4. **Progressive Enhancement**: Build from basic to advanced

### Example

```typescript
async function loadWithFallback<T>(
  primary: () => Promise<T>,
  fallback: () => T
): Promise<T> {
  try {
    return await primary()
  } catch (error) {
    console.warn('Primary source failed, using fallback:', error)
    return fallback()
  }
}
```

---

## 8. Health Checks & Monitoring

### Purpose
Proactively detect and respond to system degradation.

### Key Metrics

- **Uptime**: Service availability percentage
- **Response Time**: P50, P95, P99 latencies
- **Error Rate**: Failed requests per time window
- **Throughput**: Requests per second

### Implementation

```typescript
class HealthMonitor {
  async checkHealth(): Promise<HealthStatus> {
    const checks = await Promise.all([
      this.checkDatabase(),
      this.checkCache(),
      this.checkExternalAPIs()
    ])
    
    return {
      status: checks.every(c => c.healthy) ? 'healthy' : 'degraded',
      checks: checks
    }
  }
}
```

---

## Best Practices

1. **Fail Fast**: Detect errors early and provide clear feedback
2. **Idempotency**: Ensure operations can be safely retried
3. **Timeouts**: Always set reasonable timeouts for async operations
4. **Logging**: Log all failures with context for debugging
5. **Testing**: Test failure scenarios, not just happy paths

---

## References

- [AWS Architecture Blog: Exponential Backoff](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)
- [Microsoft: Circuit Breaker Pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker)
- [Google SRE Book: Handling Overload](https://sre.google/sre-book/handling-overload/)
