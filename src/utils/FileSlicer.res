let defaultChunkSizeBytes = 5 * 1024 * 1024
let minChunkSizeBytes = 256 * 1024
let maxChunkSizeBytes = 10 * 1024 * 1024

@send
external sliceFileInternal: (BrowserBindings.File.t, float, float) => BrowserBindings.Blob.t =
  "slice"

let normalizeChunkSize = (chunkSizeBytes: int): int => {
  if chunkSizeBytes < minChunkSizeBytes {
    minChunkSizeBytes
  } else if chunkSizeBytes > maxChunkSizeBytes {
    maxChunkSizeBytes
  } else {
    chunkSizeBytes
  }
}

let totalChunksForSize = (~sizeBytes: int, ~chunkSizeBytes: int): int => {
  if sizeBytes <= 0 {
    0
  } else {
    let safeChunkSize = normalizeChunkSize(chunkSizeBytes)
    (sizeBytes + safeChunkSize - 1) / safeChunkSize
  }
}

let chunkRangeForIndex = (~sizeBytes: int, ~chunkSizeBytes: int, ~chunkIndex: int): option<(
  int,
  int,
)> => {
  if sizeBytes <= 0 || chunkIndex < 0 {
    None
  } else {
    let safeChunkSize = normalizeChunkSize(chunkSizeBytes)
    let startOffset = chunkIndex * safeChunkSize

    if startOffset >= sizeBytes {
      None
    } else {
      let endOffset = if startOffset + safeChunkSize < sizeBytes {
        startOffset + safeChunkSize
      } else {
        sizeBytes
      }
      Some((startOffset, endOffset))
    }
  }
}

let chunkByteLengthForIndex = (~sizeBytes: int, ~chunkSizeBytes: int, ~chunkIndex: int): option<
  int,
> => {
  switch chunkRangeForIndex(~sizeBytes, ~chunkSizeBytes, ~chunkIndex) {
  | Some((startOffset, endOffset)) => Some(endOffset - startOffset)
  | None => None
  }
}

let fileSizeBytes = (file: BrowserBindings.File.t): int =>
  Float.toInt(BrowserBindings.File.size(file))

let totalChunks = (file: BrowserBindings.File.t, ~chunkSizeBytes: int): int => {
  totalChunksForSize(~sizeBytes=fileSizeBytes(file), ~chunkSizeBytes)
}

let sliceChunk = (file: BrowserBindings.File.t, ~chunkSizeBytes: int, ~chunkIndex: int): option<
  BrowserBindings.Blob.t,
> => {
  switch chunkRangeForIndex(~sizeBytes=fileSizeBytes(file), ~chunkSizeBytes, ~chunkIndex) {
  | Some((startOffset, endOffset)) =>
    Some(sliceFileInternal(file, Belt.Int.toFloat(startOffset), Belt.Int.toFloat(endOffset)))
  | None => None
  }
}
