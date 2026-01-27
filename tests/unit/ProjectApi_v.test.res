open Vitest
open ApiTypes
open ReBindings

describe("ProjectApi", () => {
  let setupFetch = (handler) => {
    let _ = %raw(`
      (handler) => {
        globalThis.fetch = (url, init) => handler(url, init)
      }
    `)(handler)
  }

  beforeEach(() => {
    let _ = %raw(`vi.clearAllMocks()`)
  })

  testAsync("importProject: success", async t => {
    setupFetch((url, _) => {
        if (String.includes(url, "/api/project/import")) {
           Promise.resolve(Obj.magic({
             "ok": true,
             "status": 200,
             "json": () => Promise.resolve({
                 "sessionId": "mock-id",
                 "projectData": %raw("{}")
             })
           }))
        } else {
            Promise.resolve(Obj.magic({"ok": false, "status": 404}))
        }
    })

    let mockFile: File.t = Obj.magic({"name": "test.zip"})
    let result = await ProjectApi.importProject(mockFile)

    switch result {
    | Ok(res) => t->expect(res.sessionId)->Expect.toBe("mock-id")
    | Error(msg) => failwith(msg)
    }
  })

  testAsync("validateProject: success", async t => {
    setupFetch((url, _) => {
        if (String.includes(url, "/api/project/validate")) {
           Promise.resolve(Obj.magic({
             "ok": true,
             "status": 200,
             "json": () => Promise.resolve({
                 "brokenLinksRemoved": 0,
                 "orphanedScenes": [],
                 "unusedFiles": [],
                 "warnings": [],
                 "errors": []
             })
           }))
        } else {
            Promise.resolve(Obj.magic({"ok": false, "status": 404}))
        }
    })

    let mockFile: File.t = Obj.magic({"name": "test.zip"})
    let result = await ProjectApi.validateProject(mockFile)

    switch result {
    | Ok(res) => t->expect(Array.length(res.errors))->Expect.toBe(0)
    | Error(msg) => failwith(msg)
    }
  })

  testAsync("loadProject: success", async t => {
    setupFetch((url, _) => {
        if (String.includes(url, "/api/project/load")) {
           Promise.resolve(Obj.magic({
             "ok": true,
             "status": 200,
             "blob": () => Promise.resolve(Obj.magic("mock-blob"))
           }))
        } else {
            Promise.resolve(Obj.magic({"ok": false, "status": 404}))
        }
    })

    let mockFile: File.t = Obj.magic({"name": "test.zip"})
    let result = await ProjectApi.loadProject(mockFile)

    switch result {
    | Ok(blob) => t->expect(blob)->Expect.toBe(Obj.magic("mock-blob"))
    | Error(msg) => failwith(msg)
    }
  })

  testAsync("saveProject: success", async t => {
    setupFetch((url, _) => {
        if (String.includes(url, "/api/project/save")) {
           Promise.resolve(Obj.magic({
             "ok": true,
             "status": 200,
             "blob": () => Promise.resolve(Obj.magic("mock-blob"))
           }))
        } else {
            Promise.resolve(Obj.magic({"ok": false, "status": 404}))
        }
    })

    let projectData = JSON.Encode.object(Dict.make())
    let result = await ProjectApi.saveProject(projectData)

    switch result {
    | Ok(blob) => t->expect(blob)->Expect.toBe(Obj.magic("mock-blob"))
    | Error(msg) => failwith(msg)
    }
  })

  testAsync("reverseGeocode: success", async t => {
    setupFetch((url, _) => {
        if (String.includes(url, "/api/geocoding/reverse")) {
           Promise.resolve(Obj.magic({
             "ok": true,
             "status": 200,
             "json": () => Promise.resolve({"address": "123 Main St"})
           }))
        } else {
            Promise.resolve(Obj.magic({"ok": false, "status": 404}))
        }
    })

    let result = await ProjectApi.reverseGeocode(10.0, 20.0)

    switch result {
    | Ok(addr) => t->expect(addr)->Expect.toBe("123 Main St")
    | Error(msg) => failwith(msg)
    }
  })

  testAsync("reverseGeocode: service unavailable", async t => {
    setupFetch((_, _) => {
        Promise.resolve(Obj.magic({
             "ok": false,
             "status": 503
        }))
    })

    let result = await ProjectApi.reverseGeocode(10.0, 20.0)

    switch result {
    | Error(msg) => t->expect(msg)->Expect.toBe("Geocoding service unavailable")
    | Ok(_) => failwith("Should have failed")
    }
  })
})
