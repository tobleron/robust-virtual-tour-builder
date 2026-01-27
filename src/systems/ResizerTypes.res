/* src/systems/ResizerTypes.res */

open ReBindings
open SharedTypes

type processResult = {
  preview: File.t,
  tiny: option<File.t>,
  metadata: exifMetadata,
  qualityData: qualityAnalysis,
  checksumData: string,
}

type statusCallback = string => unit

@val @scope(("performance", "memory"))
external usedJSHeapSize: float = "usedJSHeapSize"
@val @scope(("performance", "memory"))
external totalJSHeapSize: float = "totalJSHeapSize"
@val @scope(("performance", "memory"))
external jsHeapSizeLimit: float = "jsHeapSizeLimit"
@val @scope("performance")
external now: unit => float = "now"

let getMemoryUsage = () => {
  try {
    let used = usedJSHeapSize /. 1024.0 /. 1024.0
    let total = totalJSHeapSize /. 1024.0 /. 1024.0
    let limit = jsHeapSizeLimit /. 1024.0 /. 1024.0

    {
      "used": Float.toFixed(used, ~digits=0) ++ "MB",
      "total": Float.toFixed(total, ~digits=0) ++ "MB",
      "limit": Float.toFixed(limit, ~digits=0) ++ "MB",
    }
  } catch {
  | _ => {"used": "N/A", "total": "N/A", "limit": "N/A"}
  }
}
