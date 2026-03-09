type retryClass =
  | Retryable
  | NonRetryable
  | Aborted

let extractCaptureInt = (error: string, pattern): option<int> => {
  switch String.match(error, pattern) {
  | Some(captures) =>
    switch Belt.Array.get(captures, 1) {
    | Some(Some(value)) => Belt.Int.fromString(value)
    | _ => None
    }
  | None => None
  }
}

let parseHttpStatusCode = (error: string): option<int> =>
  extractCaptureInt(error, /HttpError:\s*Status\s*(\d+)/i)

let parseRetryAfterSeconds = (error: string): option<int> =>
  switch extractCaptureInt(error, /RateLimited:\s*(\d+)/i) {
  | Some(seconds) => Some(seconds)
  | None => extractCaptureInt(error, /Retry-After:\s*(\d+)/i)
  }

let retryAfterDelayMs = (error: string): option<int> =>
  parseRetryAfterSeconds(error)->Option.map(seconds => Math.Int.max(0, seconds * 1000))

let isAbortError = (error: string): bool =>
  String.includes(error, "AbortError") || String.includes(error, "aborted")

let isRetryableStatus = (status: int): bool => {
  switch status {
  | 408
  | 425
  | 429
  | 500
  | 502
  | 503
  | 504 => true
  | _ => false
  }
}

let isRetryableNetworkError = (error: string): bool =>
  String.includes(error, "NetworkError") ||
  String.includes(error, "fetch failed") ||
  String.includes(error, "Failed to fetch") ||
  String.includes(error, "Network request failed") ||
  String.includes(error, "connection refused") ||
  String.includes(error, "ETIMEDOUT") ||
  String.includes(error, "TimeoutError")

let isRetryableError = (error: string): bool =>
  switch parseHttpStatusCode(error) {
  | Some(status) => isRetryableStatus(status)
  | None => isRetryableNetworkError(error)
  }

let classifyError = (error: string): retryClass =>
  if isAbortError(error) {
    Aborted
  } else if isRetryableError(error) {
    Retryable
  } else {
    NonRetryable
  }

let defaultShouldRetry = (error: string): bool =>
  switch classifyError(error) {
  | Retryable => true
  | NonRetryable
  | Aborted => false
  }
