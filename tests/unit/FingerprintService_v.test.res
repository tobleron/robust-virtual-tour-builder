open Vitest

%%raw(`
  vi.mock('../../src/systems/Resizer.bs.js', () => ({
    getChecksum: (file) => Promise.resolve("hash_" + file.name)
  }));
`)

describe("FingerprintService", () => {
  beforeEach(() => {
    ()
  })

  testAsync("fingerprintFiles returns upload items with ids", async t => {
    let f1 = Obj.magic({"name": "f1.jpg"})
    let results = await FingerprintService.fingerprintFiles([f1])

    t->expect(Array.length(results))->Expect.toBe(1)
    let item = Belt.Array.getExn(results, 0)
    t->expect(Nullable.toOption(item.id))->Expect.toEqual(Some("hash_f1.jpg"))
  })

  test("filterDuplicates correctly identifies duplicates", t => {
    let existingScenes = [TestUtils.createMockScene(~id="id1", ())]
    let results = [
      {
        UploadProcessorTypes.id: Nullable.make("id1"),
        original: Obj.magic({"name": "f1.jpg"}),
        error: None,
        preview: None,
        tiny: None,
        quality: None,
        metadata: None,
        colorGroup: None,
      },
      {
        UploadProcessorTypes.id: Nullable.make("id2"),
        original: Obj.magic({"name": "f2.jpg"}),
        error: None,
        preview: None,
        tiny: None,
        quality: None,
        metadata: None,
        colorGroup: None,
      },
    ]

    let dupCount = ref(0)
    let filtered = FingerprintService.filterDuplicates(
      results,
      ~existingScenes,
      ~deletedIds=[],
      ~onDuplicate=c => dupCount := c,
      ~onRestore=_ => (),
    )

    t->expect(Array.length(filtered))->Expect.toBe(1)
    t->expect(dupCount.contents)->Expect.toBe(1)
  })
})
