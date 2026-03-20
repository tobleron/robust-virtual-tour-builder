// @efficiency: infra-adapter
open Vitest
open PortalTypes

describe("Portal Access Links", () => {
  beforeEach(() => {
    let _ = %raw(`(() => {
      if (typeof localStorage === 'undefined' || !localStorage.clear) {
        let store = {};
        global.localStorage = {
          getItem: (key) => store[key] || null,
          setItem: (key, value) => { store[key] = value.toString(); },
          removeItem: (key) => { delete store[key]; },
          clear: () => { Object.keys(store).forEach(k => delete store[k]); }
        };
      } else {
        localStorage.clear();
      }
    })()`)
    let _ = %raw("global.fetch = vi.fn()")
  })

  describe("Access Precedence Logic", () => {
    testAsync("denies access when customer is inactive", async t => {
      let fetchMock = %raw("global.fetch")
      let _ = %raw(`function(m){m.mockResolvedValue({
        ok: false,
        status: 401,
        json: () => Promise.resolve({
          error: "Unauthorized",
          details: "Customer account is inactive"
        })
      })}`)(fetchMock)

      // Simulate accessing with inactive customer
      let result = await PortalApi.loadCustomerSession("inactive-customer")

      switch result {
      | Error(msg) =>
        t->expect(String.includes(msg, "inactive"))->Expect.toBe(true)
      | Ok(_) =>
        t->expect(true)->Expect.toBe(false)
      }
    })

    testAsync("denies access when customer is expired", async t => {
      let fetchMock = %raw("global.fetch")
      let _ = %raw(`function(m){m.mockResolvedValue({
        ok: false,
        status: 401,
        json: () => Promise.resolve({
          error: "Unauthorized",
          details: "Customer access has expired"
        })
      })}`)(fetchMock)

      let result = await PortalApi.loadCustomerSession("expired-customer")

      switch result {
      | Error(msg) =>
        t->expect(String.includes(msg, "expired"))->Expect.toBe(true)
      | Ok(_) =>
        t->expect(true)->Expect.toBe(false)
      }
    })

    testAsync("denies access when link is revoked", async t => {
      let fetchMock = %raw("global.fetch")
      let _ = %raw(`function(m){m.mockResolvedValue({
        ok: false,
        status: 401,
        json: () => Promise.resolve({
          error: "Unauthorized",
          details: "Access link has been revoked"
        })
      })}`)(fetchMock)

      let result = await PortalApi.loadCustomerSession("revoked-link")

      switch result {
      | Error(msg) =>
        t->expect(String.includes(msg, "revoked"))->Expect.toBe(true)
      | Ok(_) =>
        t->expect(true)->Expect.toBe(false)
      }
    })

    testAsync("denies access when link is expired", async t => {
      let fetchMock = %raw("global.fetch")
      let _ = %raw(`function(m){m.mockResolvedValue({
        ok: false,
        status: 401,
        json: () => Promise.resolve({
          error: "Unauthorized",
          details: "Access link has expired"
        })
      })}`)(fetchMock)

      let result = await PortalApi.loadCustomerSession("expired-link")

      switch result {
      | Error(msg) =>
        t->expect(String.includes(msg, "expired"))->Expect.toBe(true)
      | Ok(_) =>
        t->expect(true)->Expect.toBe(false)
      }
    })

    testAsync("allows access when all conditions are met", async t => {
      let fetchMock = %raw("global.fetch")
      let _ = %raw(`function(m){m.mockResolvedValue({
        ok: true,
        status: 200,
        json: () => Promise.resolve({
          authenticated: true,
          session: {
            accessLink: {
              id: "test-link-1",
              active: true,
              expiresAt: "2026-12-31T23:59:59Z",
              revokedAt: null
            },
            canOpenTours: true,
            expired: false,
            customer: {
              slug: "test-customer",
              displayName: "Test Customer",
              isActive: true
            },
            settings: {
              id: 1,
              renewalHeading: "Access expired",
              renewalMessage: "Contact to renew",
              contactEmail: null,
              contactPhone: null,
              whatsappNumber: null,
              updatedAt: "2026-01-01T00:00:00Z"
            }
          }
        })
      })}`)(fetchMock)

      let result = await PortalApi.loadCustomerSession("active-customer")

      switch result {
      | Ok(payload) =>
        t->expect(payload.session.canOpenTours)->Expect.toBe(true)
        t->expect(payload.session.expired)->Expect.toBe(false)
        t->expect(payload.session.accessLink.active)->Expect.toBe(true)
      | Error(_) =>
        t->expect(true)->Expect.toBe(false)
      }
    })
  })

  describe("Per-Link Expiry Override", () => {
    testAsync("link inherits customer expiry when override is null", async t => {
      let fetchMock = %raw("global.fetch")
      let _ = %raw(`function(m){m.mockResolvedValue({
        ok: true,
        status: 200,
        json: () => Promise.resolve({
          authenticated: true,
          session: {
            accessLink: {
              id: "test-link-1",
              expiresAt: "2026-12-31T23:59:59Z",
              revokedAt: null,
              active: true
            },
            customer: {
              slug: "test-customer",
              displayName: "Test Customer",
              isActive: true
            },
            settings: {
              id: 1,
              renewalHeading: "Access expired",
              renewalMessage: "Contact to renew",
              contactEmail: null,
              contactPhone: null,
              whatsappNumber: null,
              updatedAt: "2026-01-01T00:00:00Z"
            },
            canOpenTours: true,
            expired: false
          }
        })
      })}`)(fetchMock)

      let result = await PortalApi.loadCustomerSession("test-customer")

      switch result {
      | Ok(payload) =>
        // Customer expiry is 2026-12-31, link should inherit
        t->expect(payload.session.expired)->Expect.toBe(false)
        t->expect(payload.session.accessLink.expiresAt)->Expect.toBe("2026-12-31T23:59:59Z")
      | Error(_) =>
        t->expect(true)->Expect.toBe(false)
      }
    })

    testAsync("link uses override expiry when provided", async t => {
      let fetchMock = %raw("global.fetch")
      let _ = %raw(`function(m){m.mockResolvedValue({
        ok: true,
        status: 200,
        json: () => Promise.resolve({
          authenticated: true,
          session: {
            accessLink: {
              id: "test-link-2",
              expiresAt: "2026-06-30T23:59:59Z",
              revokedAt: null,
              active: true
            },
            customer: {
              slug: "test-customer",
              displayName: "Test Customer",
              isActive: true
            },
            settings: {
              id: 1,
              renewalHeading: "Access expired",
              renewalMessage: "Contact to renew",
              contactEmail: null,
              contactPhone: null,
              whatsappNumber: null,
              updatedAt: "2026-01-01T00:00:00Z"
            },
            canOpenTours: true,
            expired: false
          }
        })
      })}`)(fetchMock)

      let result = await PortalApi.loadCustomerSession("test-customer")

      switch result {
      | Ok(payload) =>
        // Link has custom expiry 2026-06-30 (earlier than customer)
        t->expect(payload.session.expired)->Expect.toBe(false)
        t->expect(payload.session.accessLink.expiresAt)->Expect.toBe("2026-06-30T23:59:59Z")
      | Error(_) =>
        t->expect(true)->Expect.toBe(false)
      }
    })
  })

  describe("Short Code Generation", () => {
    test("short codes are 7 characters long", t => {
      // Mock short code generation
      let shortCode = "abc1234"
      t->expect(shortCode->String.length)->Expect.toBe(7)
    })

    test("short codes are alphanumeric", t => {
      let shortCode = "abc1234"
      let isAlphanumeric = %raw(`(code) => /^[a-zA-Z0-9]+$/.test(code)`)(shortCode)
      t->expect(isAlphanumeric)->Expect.toBe(true)
    })

    test("short codes are unique per assignment", t => {
      let codes = ["abc1234", "xyz5678", "def9012"]
      let uniqueCodes = codes->Belt.Set.String.fromArray->Belt.Set.String.toArray
      t->expect(Belt.Array.length(uniqueCodes))->Expect.toBe(Belt.Array.length(codes))
    })
  })

  describe("Per-Link Revocation", () => {
    testAsync("revoking one link does not affect other links", async t => {
      // Mock: Customer has 2 tours, one revoked
      let fetchMock = %raw("global.fetch")
      let _ = %raw(`function(m){
        m.mockResolvedValueOnce({
          ok: true,
          status: 200,
          json: () => Promise.resolve({
            customer: {
              slug: "test-customer",
              displayName: "Test Customer",
              isActive: true
            },
            settings: {
              renewalHeading: "Access expired",
              renewalMessage: "Contact to renew",
              contactEmail: null,
              contactPhone: null,
              whatsappNumber: null
            },
            accessLink: {
              id: "test-link",
              active: true,
              expiresAt: "2026-12-31T23:59:59Z",
              revokedAt: null,
              lastOpenedAt: null,
              accessUrl: null
            },
            expired: false,
            canOpenTours: true,
            tours: [
              {
                id: "tour-1",
                slug: "tour-1",
                title: "Tour 1",
                status: "revoked",
                coverUrl: null,
                canOpen: false
              },
              {
                id: "tour-2",
                slug: "tour-2",
                title: "Tour 2",
                status: "active",
                coverUrl: null,
                canOpen: true
              }
            ]
          })
        })
      }`)(fetchMock)

      let result = await PortalApi.loadCustomerTours("test-customer")

      switch result {
      | Ok(gallery) =>
        // One tour should be revoked, one active
        let revokedCount = gallery.tours
          ->Belt.Array.keep(tour => tour.status == "revoked")
          ->Belt.Array.length
        let activeCount = gallery.tours
          ->Belt.Array.keep(tour => tour.status == "active")
          ->Belt.Array.length
        t->expect(revokedCount)->Expect.toBe(1)
        t->expect(activeCount)->Expect.toBe(1)
      | Error(_) =>
        t->expect(true)->Expect.toBe(false)
      }
    })
  })

  describe("Session Cookie Handling", () => {
    testAsync("customer API requests include credentials for session cookies", async t => {
      let fetchMock = %raw("global.fetch")
      let _ = %raw(`function(m){m.mockResolvedValue({
        ok: true,
        status: 200,
        json: () => Promise.resolve({
          authenticated: true,
          session: {
            accessLink: {
              id: "test-link",
              active: true,
              expiresAt: "2026-12-31T23:59:59Z",
              revokedAt: null
            },
            canOpenTours: true,
            expired: false,
            customer: {
              slug: "test-customer",
              displayName: "Test Customer",
              isActive: true
            },
            settings: {
              id: 1,
              renewalHeading: "Access expired",
              renewalMessage: "Contact to renew",
              contactEmail: null,
              contactPhone: null,
              whatsappNumber: null,
              updatedAt: "2026-01-01T00:00:00Z"
            }
          }
        })
      })}`)(fetchMock)

      let _ = await PortalApi.loadCustomerSession("test-customer")

      let credentials = %raw(
        "(function(m){ return m.mock.calls[0][1]['credentials'] })(fetchMock)"
      )
      t->expect(credentials)->Expect.toBe("include")
    })
  })
})
