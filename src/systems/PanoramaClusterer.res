/* src/systems/PanoramaClusterer.res */
open ReBindings
open SharedTypes

// Grouping logic for scenes.
let clusterScenes = (
  validProcessed: array<UploadTypes.uploadItem>,
  ~existingScenes: array<Types.scene>,
  ~updateProgress: (~eta: string=?, float, string, bool, string) => unit,
) => {
  updateProgress(95.0, "Syncing scene blocks...", true, "Clustering")
  Logger.debug(~module_="Clusterer", ~message="PHASE_START", ())

  let _ = Array.sort(validProcessed, (a, b) => {
    String.localeCompare(File.name(a.original), File.name(b.original))
  })

  let existingCount = Belt.Array.length(existingScenes)
  let lastExistingScene = if existingCount > 0 {
    Belt.Array.get(existingScenes, existingCount - 1)
  } else {
    None
  }

  // Build pairs for batch similarity
  let pairs: array<similarityPair> = []

  let addSimilarityPair = (idA, idB, histA, histB) => {
    let _ = Array.push(
      pairs,
      {
        idA,
        idB,
        histogramA: histA,
        histogramB: histB,
      },
    )
  }

  Belt.Array.forEachWithIndex(validProcessed, (i, current) => {
    let currentId = Nullable.toOption(current.id)->Option.getOr(File.name(current.original))
    let currentQ = current.quality

    switch currentQ {
    | Some(q) =>
      // Compare with last 3 in batch
      for j in 1 to 3 {
        let prevIdx = i - j
        if prevIdx >= 0 {
          switch Belt.Array.get(validProcessed, prevIdx) {
          | Some(prev) =>
            switch prev.quality {
            | Some(pq) =>
              let prevId = Nullable.toOption(prev.id)->Option.getOr(File.name(prev.original))
              addSimilarityPair(currentId, prevId, q, pq)
            | None => ()
            }
          | None => ()
          }
        }
      }

      // Compare with last existing
      switch lastExistingScene {
      | Some(lastS) =>
        switch lastS.quality {
        | Some(lq) =>
          let lastId = lastS.id
          addSimilarityPair(currentId, lastId, q, lq)
        | None => ()
        }
      | None => ()
      }
    | None => ()
    }
  })

  let similarityPromise = if Belt.Array.length(pairs) > 0 {
    BackendApi.batchCalculateSimilarity(pairs)
  } else {
    Promise.resolve(Ok([]))
  }

  similarityPromise->Promise.then(result => {
    let similarities = switch result {
    | Ok(s) => s
    | Error(msg) =>
      Logger.warn(~module_="Clusterer", ~message="Grouping failed: " ++ msg, ())
      []
    }
    // Build lookup map
    let simMap = Dict.make()
    Belt.Array.forEach(similarities, (result: similarityResult) => {
      let key = result.idA ++ "_" ++ result.idB
      Dict.set(simMap, key, result.similarity)
    })

    let getSimilarity = (idA, idB) => {
      Dict.get(simMap, idA ++ "_" ++ idB)->Option.getOr(0.0)
    }

    let lastGroupRef = ref(0)
    if existingCount > 0 {
      switch lastExistingScene {
      | Some(lastS) =>
        switch lastS.colorGroup {
        | Some(gStr) =>
          switch Belt.Int.fromString(gStr) {
          | Some(g) => lastGroupRef := g
          | None => ()
          }
        | None => ()
        }
      | None => ()
      }
    }

    // Proper sequential clustering with immutable items:
    let results = []

    Belt.Array.forEachWithIndex(validProcessed, (i, current) => {
      let foundMatch = ref(None)
      let currentId = Nullable.toOption(current.id)->Option.getOr(File.name(current.original))

      for j in 1 to 3 {
        if foundMatch.contents == None {
          let prevIdx = i - j
          if prevIdx >= 0 {
            // Look at RESULTS array which has the updated groups
            switch results[prevIdx] {
            | Some(prev: UploadTypes.uploadItem) =>
              let prevId = Nullable.toOption(prev.id)->Option.getOr(File.name(prev.original))
              let score = getSimilarity(currentId, prevId)
              if score > 0.65 {
                foundMatch := prev.colorGroup
              }
            | None => ()
            }
          }
        }
      }

      if foundMatch.contents == None && existingCount > 0 {
        switch lastExistingScene {
        | Some(lastS) =>
          let lastId = lastS.id
          let score = getSimilarity(currentId, lastId)
          if score > 0.65 {
            foundMatch := lastS.colorGroup
          }
        | None => ()
        }
      }

      let newGroup = switch foundMatch.contents {
      | Some(g) => Some(g)
      | None =>
        lastGroupRef := lastGroupRef.contents + 1
        Some(Belt.Int.toString(lastGroupRef.contents))
      }

      let newItem = {...current, colorGroup: newGroup}
      let _ = Array.push(results, newItem)
    })

    updateProgress(98.0, "Updating Sidebar...", true, "Finalizing")

    Promise.resolve(results)
  })
}
