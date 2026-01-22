/* tests/unit/ProjectManager_v.test.res */
open Vitest
open ProjectManager

test("ProjectManager: validateProjectStructure accepts valid project", t => {
  let validJson = JSON.parseOrThrow(`{
    "tourName": "My Tour",
    "scenes": []
  }`)

  let result = validateProjectStructure(validJson)
  t->expect(Result.isOk(result))->Expect.toBe(true)
})

test("ProjectManager: validateProjectStructure rejects missing scenes", t => {
  let invalidJson = JSON.parseOrThrow(`{
    "tourName": "My Tour"
  }`)

  let result = validateProjectStructure(invalidJson)
  t->expect(Result.isError(result))->Expect.toBe(true)
})

test("ProjectManager: validateProjectStructure rejects missing tourName", t => {
  let invalidJson = JSON.parseOrThrow(`{
    "scenes": []
  }`)

  let result = validateProjectStructure(invalidJson)
  t->expect(Result.isError(result))->Expect.toBe(true)
})

testAsync("ProjectManager: processLoadedProjectData handles valid response", async t => {
  let projectData = JSON.parseOrThrow(`{
    "tourName": "Loaded Tour",
    "scenes": [
      { "id": "s1", "name": "living.webp" }
    ],
    "deletedSceneIds": [],
    "timeline": []
  }`)

  let resultSessionData = Ok(("session_123", projectData))

  let resultPromise = processLoadedProjectData(
    resultSessionData,
    ~loadStartTime=Date.now(),
    ~onProgress=?None,
  )

  let result = await resultPromise

  switch result {
  | Ok(data) => {
      let dict = data->Obj.magic // JSON to dict
      t->expect(dict["tourName"])->Expect.toEqual(JSON.Encode.string("Loaded Tour"))

      let scenes = dict["scenes"]->JSON.Decode.array->Option.getOrThrow
      t->expect(scenes->Array.length)->Expect.toBe(1)

      let firstScene = scenes[0]->Option.getOrThrow->Obj.magic
      // Check if URL was reconstructed
      let url = firstScene["file"]->JSON.Decode.string->Option.getOrThrow
      t->expect(String.includes(url, "api/session/session_123/living.webp"))->Expect.toBe(true)
    }
  | Error(_msg) => t->expect(true)->Expect.toBe(false) // Workaround for fail
  }
})

testAsync("ProjectManager: processLoadedProjectData propagates error", async t => {
  let resultSessionData = Error("Backend Error")

  let resultPromise = processLoadedProjectData(
    resultSessionData,
    ~loadStartTime=Date.now(),
    ~onProgress=?None,
  )

  let result = await resultPromise
  t->expect(Result.isError(result))->Expect.toBe(true)
})
