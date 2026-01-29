open Vitest
open ProjectManager.Logic

/* Mock setup */
%%raw(`
  globalThis.mockImportProject = () => Promise.resolve({ TAG: 1, _0: "Default Mock Error" });
  globalThis.mockHandleResponse = () => Promise.resolve({ TAG: 1, _0: "Default Mock Error" });

  vi.mock("../../src/systems/BackendApi.bs.js", () => ({
    importProject: (...args) => globalThis.mockImportProject(...args),
    handleResponse: (...args) => globalThis.mockHandleResponse(...args)
  }));

  globalThis.fetch = (url, options) => Promise.resolve({
    ok: true,
    blob: () => Promise.resolve(new Blob(["mock-zip-content"], {type: "application/zip"}))
  });

  globalThis.FormData = class FormData {
    constructor() { this.data = {} }
    append(key, value) { this.data[key] = value }
  };

  globalThis.File = class File {
    constructor(bits, name, options) {
      this.name = name
      this.size = bits.length
    }
  };
`)

describe("ProjectManagerLogic", () => {
  testAsync("createSavePackage success", async t => {
    let mockBlob = %raw(`new Blob(["zip"], {type: "application/zip"})`)
    let mockResponseObj = {"blob": () => Promise.resolve(mockBlob)}
    let mockSuccessResult = Ok(Obj.magic(mockResponseObj))

    let setTempResult: 'a => unit = %raw(`(v) => globalThis.tempResult = v`)
    setTempResult(mockSuccessResult)

    let _ = %raw(`
      globalThis.mockHandleResponse = (res) => Promise.resolve(globalThis.tempResult)
    `)

    let mockState: Types.state = {
      ...State.initialState,
      tourName: "Test Tour",
      scenes: [],
    }

    let result = await createSavePackage(mockState)

    t->expect(Result.isOk(result))->Expect.toBe(true)
  })

  testAsync("createSavePackage failure", async t => {
    let _ = %raw(`
      globalThis.mockHandleResponse = (res) => Promise.resolve({ TAG: 1, _0: "Save Failed" })
    `)

    let mockState: Types.state = {
      ...State.initialState,
      tourName: "Test Tour",
    }

    let result = await createSavePackage(mockState)

    t->expect(Result.isError(result))->Expect.toBe(true)
    switch result {
    | Error(msg) => t->expect(msg)->Expect.toBe("Save Failed")
    | Ok(_) => t->expect(false)->Expect.toBe(true)
    }
  })

  testAsync("loadProjectZip success", async t => {
    let mockProjectData = %raw(`{
      "tourName": "Imported Tour",
      "scenes": []
    }`)
    let mockSuccessData = {
      "sessionId": "sess_1",
      "projectData": Obj.magic(mockProjectData),
    }
    let mockSuccessResult = Ok(Obj.magic(mockSuccessData))

    let setTempResult: 'a => unit = %raw(`(v) => globalThis.tempResult = v`)
    setTempResult(mockSuccessResult)

    let _ = %raw(`
      globalThis.mockImportProject = (file) => Promise.resolve(globalThis.tempResult)
    `)

    let mockFile = %raw(`new File(["zip"], "project.zip")`)

    let result = await loadProjectZip(mockFile)

    t->expect(Result.isOk(result))->Expect.toBe(true)

    switch result {
    | Ok((sessionId, pd)) => {
        t->expect(sessionId)->Expect.toBe("sess_1")
        let dict = pd->Obj.magic
        t->expect(dict["tourName"])->Expect.toEqual(JSON.Encode.string("Imported Tour"))
      }
    | Error(_) => t->expect(false)->Expect.toBe(true)
    }
  })

  testAsync("loadProjectZip validation failure", async t => {
    let _ = %raw(`
      globalThis.mockImportProject = (file) => {
        const invalidProjectData = {
          "tourName": "Bad Tour"
          /* Missing scenes */
        }
        return Promise.resolve({
          TAG: 0,
          _0: { sessionId: "sess_1", projectData: invalidProjectData }
        })
      }
    `)

    let mockFile = %raw(`new File(["zip"], "project.zip")`)

    let result = await loadProjectZip(mockFile)

    t->expect(Result.isError(result))->Expect.toBe(true)
  })

  testAsync("loadProjectZip backend failure", async t => {
    let _ = %raw(`
      globalThis.mockImportProject = (file) => Promise.resolve({
        TAG: 1,
        _0: "Import Failed"
      })
    `)

    let mockFile = %raw(`new File(["zip"], "project.zip")`)

    let result = await loadProjectZip(mockFile)

    t->expect(Result.isError(result))->Expect.toBe(true)
    switch result {
    | Error(msg) => t->expect(msg)->Expect.toBe("Import Failed")
    | Ok(_) => t->expect(false)->Expect.toBe(true)
    }
  })
})
