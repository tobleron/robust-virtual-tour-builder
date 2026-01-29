// @efficiency: infra-adapter
open Vitest
open PanoramaClusterer
open UploadTypes

/* Mock setup */
%%raw(`
  globalThis.mockBatchCalculateSimilarity = () => Promise.resolve({ TAG: 0, _0: [] });

  vi.mock("../../src/systems/BackendApi.bs.js", () => ({
    batchCalculateSimilarity: (...args) => globalThis.mockBatchCalculateSimilarity(...args)
  }));
`)

describe("PanoramaClusterer", () => {
  testAsync("clusterScenes groups similar items", async t => {
    /* Setup items with quality data so pairs are generated */
    let qualityJson = %raw(`{
      "histogram": [1, 2, 3],
      "colorHist": {r:[], g:[], b:[]},
      "score": 1.0,
      "stats": {},
      "isBlurry": false
    }`)

    let item1 = {
      id: Nullable.make("id1"),
      original: Obj.magic({"name": "img1.jpg"}),
      error: None,
      preview: None,
      tiny: None,
      quality: Some(qualityJson),
      metadata: None,
      colorGroup: None,
    }

    let item2 = {
      id: Nullable.make("id2"),
      original: Obj.magic({"name": "img2.jpg"}),
      error: None,
      preview: None,
      tiny: None,
      quality: Some(qualityJson),
      metadata: None,
      colorGroup: None,
    }

    /* Mock backend response: High similarity between id1 and id2 */
    let setMockSim: 'a => unit = %raw(`(v) => globalThis.mockBatchCalculateSimilarity = () => Promise.resolve({TAG: "Ok", _0: v})`)
    let mockResults = %raw(`[{idA: "id2", idB: "id1", similarity: 0.9}]`)
    setMockSim(mockResults)

    let result = await clusterScenes(
      [item1, item2],
      ~existingScenes=[],
      ~updateProgress=(_, _, _, _) => (),
    )

    t->expect(Array.length(result))->Expect.toBe(2)

    let r1 = result[0]->Option.getOrThrow
    let r2 = result[1]->Option.getOrThrow

    /* They should be in the same group */
    t->expect(r1.colorGroup)->Expect.toEqual(Some("1"))
    t->expect(r2.colorGroup)->Expect.toEqual(Some("1"))
  })

  testAsync("clusterScenes separates dissimilar items", async t => {
    let qualityJson = %raw(`{ "histogram": [] }`) // minimal structure

    let item1 = {
      id: Nullable.make("id1"),
      original: Obj.magic({"name": "img1.jpg"}),
      error: None,
      preview: None,
      tiny: None,
      quality: Some(qualityJson),
      metadata: None,
      colorGroup: None,
    }

    let item2 = {
      id: Nullable.make("id2"),
      original: Obj.magic({"name": "img2.jpg"}),
      error: None,
      preview: None,
      tiny: None,
      quality: Some(qualityJson),
      metadata: None,
      colorGroup: None,
    }

    /* Mock backend response: Low similarity */
    let setMockSim: 'a => unit = %raw(`(v) => globalThis.mockBatchCalculateSimilarity = () => Promise.resolve({TAG: "Ok", _0: v})`)
    let mockResults = %raw(`[{idA: "id2", idB: "id1", similarity: 0.1}]`)
    setMockSim(mockResults)

    let result = await clusterScenes(
      [item1, item2],
      ~existingScenes=[],
      ~updateProgress=(_, _, _, _) => (),
    )

    let r1 = result[0]->Option.getOrThrow
    let r2 = result[1]->Option.getOrThrow

    /* They should be in DIFFERENT groups */
    t->expect(r1.colorGroup)->Expect.toEqual(Some("1"))
    t->expect(r2.colorGroup)->Expect.toEqual(Some("2"))
  })

  testAsync("clusterScenes matches existing scenes", async t => {
    let qualityJson = %raw(`{ "histogram": [] }`)

    let item1 = {
      id: Nullable.make("idNew"),
      original: Obj.magic({"name": "imgNew.jpg"}),
      error: None,
      preview: None,
      tiny: None,
      quality: Some(qualityJson),
      metadata: None,
      colorGroup: None,
    }

    let existingScene: Types.scene = {
      id: "idOld",
      name: "imgOld.jpg",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "outdoor",
      floor: "ground",
      label: "",
      quality: Some(qualityJson), // Must have quality to compare
      colorGroup: Some("5"), // Existing group
      _metadataSource: "default",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }

    /* Mock backend response: High similarity with existing */
    let setMockSim: 'a => unit = %raw(`(v) => globalThis.mockBatchCalculateSimilarity = () => Promise.resolve({TAG: "Ok", _0: v})`)
    let mockResults = %raw(`[{idA: "idNew", idB: "idOld", similarity: 0.8}]`)
    setMockSim(mockResults)

    let result = await clusterScenes(
      [item1],
      ~existingScenes=[existingScene],
      ~updateProgress=(_, _, _, _) => (),
    )

    let r1 = result[0]->Option.getOrThrow

    /* Should join existing group "5" */
    t->expect(r1.colorGroup)->Expect.toEqual(Some("5"))
  })
})
