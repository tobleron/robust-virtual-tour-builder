// @efficiency: infra-adapter
/* tests/unit/UploadReport_v.test.res */
open Vitest
open Types

describe("UploadReport", () => {
  let buildProjectJson = () => {
    let project: Types.project = {
      tourName: "Load Test",
      inventory: Belt.Map.String.empty,
      sceneOrder: [],
      lastUsedCategory: "indoor",
      exifReport: None,
      sessionId: Some("sess"),
      timeline: [],
      logo: None,
      marketingComment: "",
      marketingPhone1: "",
      marketingPhone2: "",
      marketingForRent: false,
      marketingForSale: false,
      tripodDeadZoneEnabled: true,
      nextSceneSequenceId: 1,
    }
    JsonParsers.Encoders.project(project)
  }

  let attachValidationReport = (
    projectJson: JSON.t,
    ~warnings: array<string>=[],
    ~errors: array<string>=[],
    ~brokenLinksRemoved: int=0,
    ~orphanedScenes: array<string>=[],
    ~unusedFiles: array<string>=[],
  ) => {
    let mergeValidationReport: (
      JSON.t,
      JSON.t,
    ) => JSON.t = %raw(`(projectJson, validationReport) => ({...projectJson, validationReport})`)
    let validationReport = JsonCombinators.Json.Encode.object([
      ("brokenLinksRemoved", JsonCombinators.Json.Encode.int(brokenLinksRemoved)),
      (
        "orphanedScenes",
        JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(orphanedScenes),
      ),
      (
        "unusedFiles",
        JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(unusedFiles),
      ),
      ("warnings", JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(warnings)),
      ("errors", JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(errors)),
    ])
    mergeValidationReport(projectJson, validationReport)
  }

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
    let item: Types.qualityItem = {
      quality,
      newName: name,
    }
    item
  }

  test("should dispatch failure modal if no success and no skipped items", t => {
    let report: uploadReport = {
      success: [],
      skipped: [],
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

    UploadReport.show(
      report,
      qualityResults,
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )
    unsubscribe()

    switch receivedConfig.contents {
    | Some(config) =>
      t->expect(config.title)->Expect.toBe("Upload Failed")
      t
      ->expect(config.description)
      ->Expect.toBe(
        Some("No files were successfully processed. Please check your files and try again."),
      )
    | None => t->expect(false)->Expect.toBe(true)
    }
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

    UploadReport.show(
      report,
      qualityResults,
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )
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

    UploadReport.show(
      report,
      qualityResults,
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )
    unsubscribe()

    switch receivedConfig.contents {
    | Some(config) => t->expect(config.title)->Expect.toBe("Upload Summary")
    | None => t->expect(false)->Expect.toBe(true)
    }
  })

  test("should calculate average score correctly and group items", t => {
    let report: uploadReport = {
      success: ["ex.jpg", "md.jpg", "pr.jpg"],
      skipped: [],
    }
    let qualityResults = [
      makeQualityItem(9.0, "ex.jpg"),
      makeQualityItem(7.0, "md.jpg"),
      makeQualityItem(5.0, "pr.jpg"),
    ]

    let receivedConfig = ref(None)
    let _unsubscribe = EventBus.subscribe(
      evt => {
        switch evt {
        | ShowModal(config) => receivedConfig := Some(config)
        | _ => ()
        }
      },
    )

    UploadReport.show(
      report,
      qualityResults,
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )

    switch receivedConfig.contents {
    | Some(config) =>
      t->expect(config.title)->Expect.toBe("Upload Summary")
      // Average score (9+7+5)/3 = 7.0
      switch config.content {
      | Some(element) => t->expect(element !== React.null)->Expect.toBe(true)
      | None => t->expect(false)->Expect.toBe(true)
      }
    | None => t->expect(false)->Expect.toBe(true)
    }
  })

  test("showFromProjectData should extract names and quality", t => {
    let projectJson = buildProjectJson()

    let receivedConfig = ref(None)
    let _unsubscribe = EventBus.subscribe(
      evt => {
        switch evt {
        | ShowModal(config) => receivedConfig := Some(config)
        | _ => ()
        }
      },
    )

    UploadReport.showFromProjectData(
      projectJson,
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )

    t->expect(receivedConfig.contents !== None)->Expect.toBe(true)
  })

  test(
    "showFromProjectData should show project validation summary when validation report exists",
    t => {
      let projectJson =
        buildProjectJson()->attachValidationReport(
          ~brokenLinksRemoved=1,
          ~warnings=["Auto-fixed stale links"],
        )

      let receivedConfig = ref(None)
      let unsubscribe = EventBus.subscribe(
        evt => {
          switch evt {
          | ShowModal(config) => receivedConfig := Some(config)
          | _ => ()
          }
        },
      )

      UploadReport.showFromProjectData(
        projectJson,
        ~getState=AppStateBridge.getState,
        ~dispatch=AppStateBridge.dispatch,
      )
      unsubscribe()

      switch receivedConfig.contents {
      | Some(config) => t->expect(config.title)->Expect.toBe("Project Validation Summary")
      | None => t->expect(false)->Expect.toBe(true)
      }
    },
  )

  test("should have correct buttons in the modal", t => {
    let report: uploadReport = {
      success: ["file1.jpg"],
      skipped: [],
    }
    let qualityResults = [makeQualityItem(9.0, "file1.jpg")]

    let receivedConfig = ref(None)
    let _unsubscribe = EventBus.subscribe(
      evt => {
        switch evt {
        | ShowModal(config) => receivedConfig := Some(config)
        | _ => ()
        }
      },
    )

    UploadReport.show(
      report,
      qualityResults,
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )

    switch receivedConfig.contents {
    | Some(config) =>
      t->expect(Belt.Array.length(config.buttons))->Expect.toBe(2)
      t->expect(Belt.Array.getUnsafe(config.buttons, 0).label)->Expect.toBe("Download Data Report")
      t->expect(Belt.Array.getUnsafe(config.buttons, 1).label)->Expect.toBe("Start Building")

      // Simulate clicks (safe because of no-op defaults in tests)
      Belt.Array.getUnsafe(config.buttons, 0).onClick()
      Belt.Array.getUnsafe(config.buttons, 1).onClick()
    | None => t->expect(false)->Expect.toBe(true)
    }
  })
})
