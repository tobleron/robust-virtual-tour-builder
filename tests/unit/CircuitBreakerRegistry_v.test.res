open Vitest

describe("CircuitBreakerRegistry", () => {
  test("resolveDomainForUrl maps known endpoints", t => {
    t
    ->expect(CircuitBreakerRegistry.resolveDomainForUrl("/api/geocoding/reverse"))
    ->Expect.toBe(CircuitBreakerRegistry.Geocoding)
    t
    ->expect(CircuitBreakerRegistry.resolveDomainForUrl("/api/media/process-full"))
    ->Expect.toBe(CircuitBreakerRegistry.Upload)
    t
    ->expect(CircuitBreakerRegistry.resolveDomainForUrl("/api/project/create-tour-package"))
    ->Expect.toBe(CircuitBreakerRegistry.Export)
    t
    ->expect(CircuitBreakerRegistry.resolveDomainForUrl("/api/project/save"))
    ->Expect.toBe(CircuitBreakerRegistry.Project)
    t
    ->expect(CircuitBreakerRegistry.resolveDomainForUrl("/api/telemetry/batch"))
    ->Expect.toBe(CircuitBreakerRegistry.Telemetry)
  })

  test("bulkhead acquire/release enforces per-domain limit", t => {
    let domain = CircuitBreakerRegistry.Geocoding
    let limit = CircuitBreakerRegistry.getBulkheadLimit(domain)

    for _i in 1 to limit {
      t->expect(CircuitBreakerRegistry.tryAcquireBulkhead(domain))->Expect.toBe(true)
    }

    t->expect(CircuitBreakerRegistry.tryAcquireBulkhead(domain))->Expect.toBe(false)

    for _i in 1 to limit {
      CircuitBreakerRegistry.releaseBulkhead(domain)
    }

    t->expect(CircuitBreakerRegistry.tryAcquireBulkhead(domain))->Expect.toBe(true)
    CircuitBreakerRegistry.releaseBulkhead(domain)
  })

  test("getSnapshots returns initialized domain entries", t => {
    ignore(CircuitBreakerRegistry.getBreaker(CircuitBreakerRegistry.Upload))
    ignore(CircuitBreakerRegistry.getBreaker(CircuitBreakerRegistry.Project))

    let snapshots = CircuitBreakerRegistry.getSnapshots()
    let domains = snapshots->Belt.Array.map(s => s.domain)

    t->expect(domains->Belt.Array.some(d => d == "upload"))->Expect.toBe(true)
    t->expect(domains->Belt.Array.some(d => d == "project"))->Expect.toBe(true)
  })
})
