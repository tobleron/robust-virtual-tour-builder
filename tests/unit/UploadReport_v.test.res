open Vitest
open Types

describe("UploadReport", () => {
  let makeQualityItem = (score, name) => {
    let stats: SharedTypes.qualityStats = {
      avgLuminance: 128,
      blackClipping: 0.0,
      whiteClipping: 0.0,
      sharpnessVariance: 100,
    }
    let colorHist: SharedTypes.colorHist = {
      r: [],
      g: [],
      b: [],
    }
    let quality: SharedTypes.qualityAnalysis = {
      score,
      histogram: [],
      colorHist,
      stats,
      isBlurry: false,
      isSoft: false,
      isSeverelyDark: false,
      isSeverelyBright: false,
      isDim: false,
      hasBlackClipping: false,
      hasWhiteClipping: false,
      issues: 0,
      warnings: 0,
      analysis: Nullable.null,
    }
    {
      UploadReport.quality,
      newName: name,
    }
  }

  test("should not dispatch modal if no success and no skipped items", t => {
    let report: uploadReport = {
      success: [],
      skipped: [],
    }
    let qualityResults = []

    let dispatched = ref(false)
    let unsubscribe = EventBus.subscribe(
      evt => {
        switch evt {
        | ShowModal(_) => dispatched := true
        | _ => ()
        }
      },
    )

    UploadReport.show(report, qualityResults)
    unsubscribe()

    t->expect(dispatched.contents)->Expect.toBe(false)
  })

  test("should dispatch modal if there are success items", t => {
    let report: uploadReport = {
      success: ["file1.jpg"],
      skipped: [],
    }
    let qualityResults = [makeQualityItem(9.0, "file1.jpg")]

    let receivedConfig = ref(None)
    let unsubscribe = EventBus.subscribe(
      evt => {
        switch evt {
        | ShowModal(config) => receivedConfig := Some(config)
        | _ => ()
        }
      },
    )

    UploadReport.show(report, qualityResults)
    unsubscribe()

    switch receivedConfig.contents {
    | Some(config) => t->expect(config.title)->Expect.toBe("Upload Summary")
    | None => t->expect(false)->Expect.toBe(true) // Fail if no config received
    }
  })

  test("should dispatch modal if there are skipped items", t => {
    let report: uploadReport = {
      success: [],
      skipped: ["duplicate.jpg"],
    }
    let qualityResults = []

    let receivedConfig = ref(None)
    let unsubscribe = EventBus.subscribe(
      evt => {
        switch evt {
        | ShowModal(config) => receivedConfig := Some(config)
        | _ => ()
        }
      },
    )

    UploadReport.show(report, qualityResults)
    unsubscribe()

    switch receivedConfig.contents {
    | Some(config) => t->expect(config.title)->Expect.toBe("Upload Summary")
    | None => t->expect(false)->Expect.toBe(true)
    }
  })
})
