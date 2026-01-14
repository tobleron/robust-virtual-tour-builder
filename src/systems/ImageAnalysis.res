type histogram = array<float>

type colorChannels = {"r": option<histogram>, "g": option<histogram>, "b": option<histogram>}

type qualityResult = {
  "histogram": option<histogram>,
  "colorHist": option<colorChannels>,
  "color_hist": option<colorChannels>,
}

let intersectBinned = (histA: histogram, histB: histogram, numBins: int) => {
  let binSize = 256.0 /. Int.toFloat(numBins)
  let binnedA = Belt.Array.make(numBins, 0.0)
  let binnedB = Belt.Array.make(numBins, 0.0)

  // Explicit loop 0..255 for standard 8-bit histograms
  for i in 0 to 255 {
    let binIdx = Float.toInt(Int.toFloat(i) /. binSize)
    if binIdx < numBins {
      let valA = Belt.Array.get(histA, i)->Belt.Option.getWithDefault(0.0)
      let valB = Belt.Array.get(histB, i)->Belt.Option.getWithDefault(0.0)

      let currentA = Belt.Array.get(binnedA, binIdx)->Belt.Option.getWithDefault(0.0)
      let currentB = Belt.Array.get(binnedB, binIdx)->Belt.Option.getWithDefault(0.0)

      binnedA[binIdx] = currentA +. valA
      binnedB[binIdx] = currentB +. valB
    }
  }

  let intersection = ref(0.0)
  let sumA = ref(0.0)

  for i in 0 to numBins - 1 {
    let valA = Belt.Array.get(binnedA, i)->Belt.Option.getWithDefault(0.0)
    let valB = Belt.Array.get(binnedB, i)->Belt.Option.getWithDefault(0.0)

    intersection := intersection.contents +. Math.min(valA, valB)
    sumA := sumA.contents +. valA
  }

  if sumA.contents > 0.0 {
    intersection.contents /. sumA.contents
  } else {
    0.0
  }
}

let calculateSimilarity = (resA: qualityResult, resB: qualityResult): float => {
  // Resolve colorHist vs color_hist to handle backend naming differences
  let cA = switch resA["colorHist"] {
  | Some(c) => Some(c)
  | None => resA["color_hist"]
  }

  let cB = switch resB["colorHist"] {
  | Some(c) => Some(c)
  | None => resB["color_hist"]
  }

  switch (cA, cB) {
  | (Some(colorA), Some(colorB)) =>
    let rA = colorA["r"]->Belt.Option.getWithDefault([])
    let rB = colorB["r"]->Belt.Option.getWithDefault([])

    let gA = colorA["g"]->Belt.Option.getWithDefault([])
    let gB = colorB["g"]->Belt.Option.getWithDefault([])

    let bA = colorA["b"]->Belt.Option.getWithDefault([])
    let bB = colorB["b"]->Belt.Option.getWithDefault([])

    let rSim = intersectBinned(rA, rB, 8)
    let gSim = intersectBinned(gA, gB, 8)
    let bSim = intersectBinned(bA, bB, 8)

    (rSim +. gSim +. bSim) /. 3.0

  | _ =>
    // Fallback to luminance histogram if color data is missing
    let hA = resA["histogram"]->Belt.Option.getWithDefault([])
    let hB = resB["histogram"]->Belt.Option.getWithDefault([])
    if Belt.Array.length(hA) > 0 && Belt.Array.length(hB) > 0 {
      intersectBinned(hA, hB, 8)
    } else {
      0.0
    }
  }
}
