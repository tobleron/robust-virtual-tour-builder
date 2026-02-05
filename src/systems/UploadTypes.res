/* src/systems/UploadTypes.res - Shared Types for Upload Pipeline */

open ReBindings

type file = File.t

type uploadItem = {
  id: Nullable.t<string>,
  original: file,
  error: option<string>,
  preview: option<file>,
  tiny: option<file>,
  quality: option<JSON.t>,
  metadata: option<JSON.t>,
  colorGroup: option<string>,
}

type processResult = {
  qualityResults: array<Types.qualityItem>,
  duration: string,
  report: Types.uploadReport,
}
