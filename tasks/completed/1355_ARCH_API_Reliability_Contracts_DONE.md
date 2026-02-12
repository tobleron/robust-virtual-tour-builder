# [1355] API Reliability Contracts (Retry/Timeout/Abort/Notification)

## Objective
Implement a unified reliability contract for API interactions with enterprise-grade failure semantics.

## Scope
1. Classify retry behavior by error class/status code (retryable vs non-retryable).
2. Enforce timeout tiers and bounded exponential backoff with jitter.
3. Ensure cancellation propagates and terminates retries immediately.
4. Collapse per-attempt notification spam into incident-level deduped user feedback.

## Target Files
- `src/systems/Api/AuthenticatedClient.res`
- `src/utils/Retry.res`
- `src/utils/RequestQueue.res`
- `src/core/NotificationManager.res`
- `src/core/NotificationTypes.res`
- `src/systems/Resizer/ResizerUtils.res`

## Verification
- `npm run build`
- targeted tests with simulated 429/5xx/network offline/abort.

## Acceptance Criteria
- One user-visible notification chain per incident.
- Retries terminate on abort and respect retry policy classes.
- Request queue behavior remains bounded under bursts.
