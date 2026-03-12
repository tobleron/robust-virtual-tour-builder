open Vitest

@module("vitest") @scope("vi") external useFakeTimers: unit => unit = "useFakeTimers"
@module("vitest") @scope("vi") external useRealTimers: unit => unit = "useRealTimers"
@module("vitest") @scope("vi") external setSystemTime: float => unit = "setSystemTime"

describe("NetworkStatus", () => {
  beforeEach(() => {
    useFakeTimers()
    setSystemTime(1000.0)
    NetworkStatus.cleanup()
    NetworkStatus.skipProbe := true
    NetworkStatus.forceStatus(true)
  })

  afterEach(() => {
    NetworkStatus.cleanup()
    NetworkStatus.skipProbe := false
    useRealTimers()
  })

  test("reportBackendUnavailable enters recovering mode with retry metadata", t => {
    NetworkStatus.reportBackendUnavailable(~status=504, ~statusText="Gateway Timeout")

    let snapshot = NetworkStatus.getSnapshot()
    t->expect(snapshot.online)->Expect.toBe(false)
    t->expect(snapshot.phase)->Expect.toBe(NetworkStatus.RecoveringPhase)
    switch snapshot.reason {
    | NetworkStatus.BackendUnavailable(status, statusText) => {
        t->expect(status)->Expect.toBe(504)
        t->expect(statusText)->Expect.toBe("Gateway Timeout")
      }
    | _ => t->expect(true)->Expect.toBe(false)
    }
    t->expect(snapshot.attempt)->Expect.toBe(1)
    t->expect(snapshot.retryDelayMs)->Expect.toBe(Some(2000))
    t->expect(snapshot.nextRetryAtMs)->Expect.toBe(Some(3000.0))
  })

  test("reportRateLimited keeps connectivity online while exposing backoff", t => {
    NetworkStatus.reportRateLimited(~retryAfterSeconds=12)

    let snapshot = NetworkStatus.getSnapshot()
    t->expect(snapshot.online)->Expect.toBe(true)
    t->expect(snapshot.phase)->Expect.toBe(NetworkStatus.RateLimitedPhase)
    switch snapshot.reason {
    | NetworkStatus.BackendRateLimited(Some(seconds)) => t->expect(seconds)->Expect.toBe(12)
    | _ => t->expect(true)->Expect.toBe(false)
    }
    t->expect(snapshot.retryDelayMs)->Expect.toBe(Some(12000))
    t->expect(snapshot.nextRetryAtMs)->Expect.toBe(Some(13000.0))
  })

  test("reportRequestSuccess resets degraded state to healthy", t => {
    NetworkStatus.reportTransportFailure(~message="Failed to fetch")
    NetworkStatus.reportRequestSuccess()

    let snapshot = NetworkStatus.getSnapshot()
    t->expect(snapshot.online)->Expect.toBe(true)
    t->expect(snapshot.phase)->Expect.toBe(NetworkStatus.HealthyPhase)
    t->expect(snapshot.reason)->Expect.toEqual(NetworkStatus.Healthy)
    t->expect(snapshot.attempt)->Expect.toBe(0)
    t->expect(snapshot.retryDelayMs)->Expect.toBe(None)
  })

  test("subscribeSnapshot receives phase updates", t => {
    let seenPhases = ref([])
    let unsubscribe = NetworkStatus.subscribeSnapshot(snapshot => {
      Array.push(seenPhases.contents, snapshot.phase)
    })

    NetworkStatus.forceStatus(false)
    NetworkStatus.forceStatus(true)
    unsubscribe()

    t
    ->expect(seenPhases.contents)
    ->Expect.toEqual([NetworkStatus.BrowserOfflinePhase, NetworkStatus.HealthyPhase])
  })
})
