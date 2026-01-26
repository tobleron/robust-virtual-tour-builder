open Vitest
open ApiTypes
open ReBindings

describe("ProjectApi", () => {
  beforeEach(() => {
    let _ = %raw(`
      globalThis.fetch = (url, init) => {
        if (url.includes('/api/project/import')) {
           return Promise.resolve({
             ok: true,
             status: 200,
             json: () => Promise.resolve({sessionId: "mock-id", projectData: {}})
           });
        }
        return Promise.resolve({ ok: false, status: 404 });
      }
    `)
  })

  testAsync("importProject: should return success result", async t => {
    let mockFile: File.t = Obj.magic({"name": "test.zip"})
    let result = await ProjectApi.importProject(mockFile)

    switch result {
    | Ok(res) => t->expect(res.sessionId)->Expect.toBe("mock-id")
    | Error(msg) => failwith(msg)
    }
  })
})
