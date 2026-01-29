/* src/systems/UploadTypes.res - Shared Types for Upload Pipeline */

open ReBindings

type file = File.t

type uploadItem = {
  id: Nullable.t<string>,
  original: file,
  mutable error: option<string>,
  mutable preview: option<file>,
  mutable tiny: option<file>,
  mutable quality: option<JSON.t>,
  mutable metadata: option<JSON.t>,
  mutable colorGroup: option<string>,
}

type processResult = {
  qualityResults: array<UploadReport.qualityItem>,
  duration: string,
  report: Types.uploadReport,
}
