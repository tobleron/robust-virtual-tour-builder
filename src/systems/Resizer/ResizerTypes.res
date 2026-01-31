/* src/systems/Resizer/ResizerTypes.res */

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
