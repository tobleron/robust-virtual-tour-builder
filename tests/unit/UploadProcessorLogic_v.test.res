open Vitest
open UploadProcessorLogic

%%raw(`
  import { vi } from "vitest";
  import * as Resizer from "../../src/systems/Resizer.bs.js";
  vi.mock("../../src/systems/Resizer.bs.js", async (importOriginal) => {
    const actual = await importOriginal();
    return {
      ...actual,
      processAndAnalyzeImage: vi.fn(),
      getChecksum: vi.fn()
    };
  });
  globalThis.mockResizer = Resizer;
`)

@val
external setMockProcessResult: 'a => unit =
  "globalThis.mockResizer.processAndAnalyzeImage.mockResolvedValue"

describe("UploadProcessorLogic", () => {
  describe("validateFiles", () => {
    test(
      "should keep valid image files",
      t => {
        let f1: ReBindings.File.t = Obj.magic({"name": "test1.jpg", "type": "image/jpeg"})
        let f2: ReBindings.File.t = Obj.magic({"name": "test2.png", "type": "image/png"})
        let files = [f1, f2]
        let validated = validateFiles(files)
        t->expect(Array.length(validated))->Expect.toBe(2)
      },
    )

    test(
      "should skip invalid files",
      t => {
        let f1: ReBindings.File.t = Obj.magic({"name": "test.txt", "type": "text/plain"})
        let files = [f1]

        let notifications = []
        let unsubscribe = EventBus.subscribe(
          evt => {
            switch evt {
            | ShowNotification(msg, #Warning) => Array.push(notifications, msg)->ignore
            | _ => ()
            }
          },
        )

        let validated = validateFiles(files)
        unsubscribe()

        t->expect(Array.length(validated))->Expect.toBe(0)
        t->expect(Array.length(notifications))->Expect.toBe(1)
        t
        ->expect(String.includes(notifications[0]->Option.getOr(""), "Skipped invalid file"))
        ->Expect.toBe(true)
      },
    )
  })

  describe("filterDuplicates", () => {
    test(
      "should filter out existing scenes",
      t => {
        let mockItem: UploadProcessorTypes.uploadItem = {
          id: Nullable.make("existing-1"),
          original: Obj.magic({"name": "test.jpg"}),
          error: None,
          preview: None,
          tiny: None,
          quality: None,
          metadata: None,
          colorGroup: None,
        }

        let scene1: Types.scene = Obj.magic({"id": "existing-1"})
        let mockState: Types.state = {
          ...State.initialState,
          scenes: [scene1],
        }

        GlobalStateBridge.setState(mockState)

        let results = [mockItem]
        let unique = filterDuplicates(results)

        t->expect(Array.length(unique))->Expect.toBe(0)
      },
    )

    test(
      "should remove from deletedSceneIds if re-uploaded",
      t => {
        let mockItem: UploadProcessorTypes.uploadItem = {
          id: Nullable.make("deleted-1"),
          original: Obj.magic({"name": "test.jpg"}),
          error: None,
          preview: None,
          tiny: None,
          quality: None,
          metadata: None,
          colorGroup: None,
        }

        let mockState: Types.state = {
          ...State.initialState,
          deletedSceneIds: ["deleted-1"],
        }
        GlobalStateBridge.setState(mockState)

        let dispatched = []
        GlobalStateBridge.setDispatch(action => Array.push(dispatched, action)->ignore)

        let unique = filterDuplicates([mockItem])

        t->expect(Array.length(unique))->Expect.toBe(1)
        t->expect(Array.length(dispatched))->Expect.toBe(1)
        t->expect(dispatched[0])->Expect.toEqual(Some(Actions.RemoveDeletedSceneId("deleted-1")))
      },
    )
  })

  describe("processItem", () => {
    testAsync(
      "should update item with process results on success",
      t => {
        let mockFile: ReBindings.File.t = Obj.magic({"name": "test.jpg", "size": 1024.0})
        let item: UploadProcessorTypes.uploadItem = {
          id: Nullable.make("id-1"),
          original: mockFile,
          error: None,
          preview: None,
          tiny: None,
          quality: None,
          metadata: None,
          colorGroup: None,
        }

        let mockRes = {
          "preview": Obj.magic({"name": "preview.webp"}),
          "tiny": Some(Obj.magic({"name": "tiny.webp"})),
          "metadata": Obj.magic({"exif": "data"}),
          "quality": {
            "isBlurry": false,
            "stats": {
              "avgLuminance": 128,
              "sharpnessVariance": 100,
              "blackClipping": 0.0,
              "whiteClipping": 0.0,
            },
            "isSeverelyDark": false,
            "isDim": false,
            "score": 0.9,
            "analysis": Nullable.null,
            "histogram": [],
            "colorHist": {"r": [], "g": [], "b": []},
            "isSoft": false,
            "isSeverelyBright": false,
            "hasBlackClipping": false,
            "hasWhiteClipping": false,
            "issues": 0,
            "warnings": 0,
          },
        }

        setMockProcessResult(Promise.resolve(Ok(mockRes)))

        processItem(0, item)->Promise.then(
          res => {
            t->expect(res.preview)->Expect.toBeSome

            t->expect(res.error)->Expect.toBeNone

            Promise.resolve()
          },
        )
      },
    )

    testAsync(
      "should record error on processing failure",
      t => {
        let mockFile: ReBindings.File.t = Obj.magic({"name": "test.jpg", "size": 1024.0})

        let item: UploadProcessorTypes.uploadItem = {
          id: Nullable.make("id-2"),
          original: mockFile,
          error: None,
          preview: None,
          tiny: None,
          quality: None,
          metadata: None,
          colorGroup: None,
        }

        setMockProcessResult(Promise.resolve(Error("Simulated failure")))

        processItem(0, item)->Promise.then(
          res => {
            t->expect(res.error)->Expect.toEqual(Some("Simulated failure"))

            Promise.resolve()
          },
        )
      },
    )
  })
})
