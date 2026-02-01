/* tests/unit/ProjectManager_RebuildUrl_v.test.res */
open Vitest
open Types

describe("ProjectManager - RebuildUrl Logic", () => {

  testAsync("rebuilds relative paths to backend URLs", async t => {
    let sessionId = "test-session"
    let relativePath = "images/scene1.jpg"

    let projectJson = JsonCombinators.Json.Encode.object([
      ("tourName", JsonCombinators.Json.Encode.string("Test Tour")),
      ("scenes", JsonCombinators.Json.Encode.array(x => x)([
        JsonCombinators.Json.Encode.object([
          ("id", JsonCombinators.Json.Encode.string("s1")),
          ("name", JsonCombinators.Json.Encode.string("Scene 1")),
          ("file", JsonCombinators.Json.Encode.string(relativePath)),
          ("hotspots", JsonCombinators.Json.Encode.array(x => x)([])),
          ("validationErrors", JsonCombinators.Json.Encode.array(x => x)([])),
          ("colorGroup", JsonCombinators.Json.Encode.string("0"))
        ])
      ])),
      ("lastUsedCategory", JsonCombinators.Json.Encode.string("default")),
      ("sessionId", JsonCombinators.Json.Encode.string(sessionId)),
      ("deletedSceneIds", JsonCombinators.Json.Encode.array(x => x)([])),
      ("timeline", JsonCombinators.Json.Encode.array(x => x)([]))
    ])

    // Mock localStorage for auth_token
    let _ = %raw(`
      globalThis.localStorage = {
        getItem: (key) => key === "auth_token" ? "mock-token" : null
      }
    `)

    // Mock Logger to prevent errors during operation tracking
    let _ = %raw(`
      globalThis.Logger = {
        startOperation: () => {},
        endOperation: () => {},
        info: () => {},
        error: () => {},
        castToJson: (obj) => obj
      }
    `)

    let result = await ProjectManager.Logic.processLoadedProjectData(
      Ok((sessionId, projectJson)),
      ~loadStartTime=0.0
    )

    switch result {
    | Ok((_sid, loadedJson)) =>
      switch JsonCombinators.Json.decode(loadedJson, JsonParsers.Domain.project) {
      | Ok(project) =>
        let scene = Belt.Array.get(project.scenes, 0)->Belt.Option.getExn
        switch scene.file {
        | Url(url) =>
          // Expect it to contain "/api/project/test-session/file/scene1.jpg"
          // and "token=mock-token"
          t->expect(String.includes(url, "/api/project/test-session/file/scene1.jpg"))->Expect.toBe(true)
          t->expect(String.includes(url, "token=mock-token"))->Expect.toBe(true)
        | _ => t->expect("Url variant")->Expect.toBe("Other variant")
        }
      | Error(e) => t->expect(e)->Expect.toBe("Success")
      }
    | Error(e) => t->expect(e)->Expect.toBe("Success")
    }
  })

  testAsync("keeps existing backend URLs but updates session ID", async t => {
    let sessionId = "new-session"
    let oldUrl = "http://backend/api/project/old-session/file/scene1.jpg?token=old"

    let projectJson = JsonCombinators.Json.Encode.object([
      ("tourName", JsonCombinators.Json.Encode.string("Test Tour")),
      ("scenes", JsonCombinators.Json.Encode.array(x => x)([
        JsonCombinators.Json.Encode.object([
          ("id", JsonCombinators.Json.Encode.string("s1")),
          ("name", JsonCombinators.Json.Encode.string("Scene 1")),
          ("file", JsonCombinators.Json.Encode.string(oldUrl)),
          ("hotspots", JsonCombinators.Json.Encode.array(x => x)([])),
          ("validationErrors", JsonCombinators.Json.Encode.array(x => x)([])),
           ("colorGroup", JsonCombinators.Json.Encode.string("0"))
        ])
      ])),
      ("lastUsedCategory", JsonCombinators.Json.Encode.string("default")),
      ("sessionId", JsonCombinators.Json.Encode.string(sessionId)),
      ("deletedSceneIds", JsonCombinators.Json.Encode.array(x => x)([])),
      ("timeline", JsonCombinators.Json.Encode.array(x => x)([]))
    ])

    let result = await ProjectManager.Logic.processLoadedProjectData(
      Ok((sessionId, projectJson)),
      ~loadStartTime=0.0
    )

    switch result {
    | Ok((_sid, loadedJson)) =>
      switch JsonCombinators.Json.decode(loadedJson, JsonParsers.Domain.project) {
      | Ok(project) =>
        let scene = Belt.Array.get(project.scenes, 0)->Belt.Option.getExn
        switch scene.file {
        | Url(url) =>
          t->expect(String.includes(url, "/api/project/new-session/file/scene1.jpg"))->Expect.toBe(true)
        | _ => t->expect("Url variant")->Expect.toBe("Other variant")
        }
      | Error(e) => t->expect(e)->Expect.toBe("Success")
      }
    | Error(e) => t->expect(e)->Expect.toBe("Success")
    }
  })

  testAsync("keeps external URLs", async t => {
    let sessionId = "test-session"
    let externalUrl = "https://example.com/image.jpg"

    let projectJson = JsonCombinators.Json.Encode.object([
      ("tourName", JsonCombinators.Json.Encode.string("Test Tour")),
      ("scenes", JsonCombinators.Json.Encode.array(x => x)([
        JsonCombinators.Json.Encode.object([
          ("id", JsonCombinators.Json.Encode.string("s1")),
          ("name", JsonCombinators.Json.Encode.string("Scene 1")),
          ("file", JsonCombinators.Json.Encode.string(externalUrl)),
          ("hotspots", JsonCombinators.Json.Encode.array(x => x)([])),
          ("validationErrors", JsonCombinators.Json.Encode.array(x => x)([])),
           ("colorGroup", JsonCombinators.Json.Encode.string("0"))
        ])
      ])),
      ("lastUsedCategory", JsonCombinators.Json.Encode.string("default")),
      ("sessionId", JsonCombinators.Json.Encode.string(sessionId)),
      ("deletedSceneIds", JsonCombinators.Json.Encode.array(x => x)([])),
      ("timeline", JsonCombinators.Json.Encode.array(x => x)([]))
    ])

    let result = await ProjectManager.Logic.processLoadedProjectData(
      Ok((sessionId, projectJson)),
      ~loadStartTime=0.0
    )

    switch result {
    | Ok((_sid, loadedJson)) =>
      switch JsonCombinators.Json.decode(loadedJson, JsonParsers.Domain.project) {
      | Ok(project) =>
        let scene = Belt.Array.get(project.scenes, 0)->Belt.Option.getExn
        switch scene.file {
        | Url(url) =>
          t->expect(url)->Expect.toBe(externalUrl)
        | _ => t->expect("Url variant")->Expect.toBe("Other variant")
        }
      | Error(e) => t->expect(e)->Expect.toBe("Success")
      }
    | Error(e) => t->expect(e)->Expect.toBe("Success")
    }
  })
})
