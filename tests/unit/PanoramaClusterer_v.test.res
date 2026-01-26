open Vitest

describe("PanoramaClusterer", () => {
  beforeEach(() => {
    let _ = %raw(`
      globalThis.BackendApi = {
        batchCalculateSimilarity: (pairs) => Promise.resolve({ TAG: 0, _0: [] })
      }
    `)
  })

  testAsync("clusterScenes handles empty batch", async t => {
    let result = await PanoramaClusterer.clusterScenes(
      [],
      ~existingScenes=[],
      ~updateProgress=(_, _, _, _) => (),
    )
    t->expect(Array.length(result))->Expect.toBe(0)
  })

  testAsync("clusterScenes assigns groups even if similarity fails", async t => {
    let item1 = {
      UploadProcessorTypes.id: Nullable.make("i1"),
      original: Obj.magic({"name": "f1.jpg"}),
      error: None,
      preview: None,
      tiny: None,
      quality: None,
      metadata: None,
      colorGroup: None,
    }
    let result = await PanoramaClusterer.clusterScenes(
      [item1],
      ~existingScenes=[],
      ~updateProgress=(_, _, _, _) => (),
    )
    t->expect(Array.length(result))->Expect.toBe(1)
    let res1 = Belt.Array.getExn(result, 0)
    t->expect(res1.colorGroup)->Expect.not->Expect.toEqual(None)
  })
})
