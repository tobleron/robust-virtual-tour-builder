open Vitest

describe("FileSlicer", () => {
  test("normalizes chunk size to configured bounds", t => {
    t->expect(FileSlicer.normalizeChunkSize(128 * 1024))->Expect.toBe(FileSlicer.minChunkSizeBytes)
    t
    ->expect(FileSlicer.normalizeChunkSize(30 * 1024 * 1024))
    ->Expect.toBe(FileSlicer.maxChunkSizeBytes)
    t->expect(FileSlicer.normalizeChunkSize(2 * 1024 * 1024))->Expect.toBe(2 * 1024 * 1024)
  })

  test("computes total chunks with partial tail", t => {
    let chunkSize = 5 * 1024 * 1024
    let total = FileSlicer.totalChunksForSize(
      ~sizeBytes=12 * 1024 * 1024 + 256,
      ~chunkSizeBytes=chunkSize,
    )
    t->expect(total)->Expect.toBe(3)
  })

  test("returns correct range and size for final chunk", t => {
    let chunkSize = FileSlicer.minChunkSizeBytes
    let sizeBytes = chunkSize * 2 + 1
    let range = FileSlicer.chunkRangeForIndex(~sizeBytes, ~chunkSizeBytes=chunkSize, ~chunkIndex=2)
    let chunkLen = FileSlicer.chunkByteLengthForIndex(
      ~sizeBytes,
      ~chunkSizeBytes=chunkSize,
      ~chunkIndex=2,
    )

    switch (range, chunkLen) {
    | (Some((startOffset, endOffset)), Some(len)) =>
      t->expect(startOffset)->Expect.toBe(chunkSize * 2)
      t->expect(endOffset)->Expect.toBe(chunkSize * 2 + 1)
      t->expect(len)->Expect.toBe(1)
    | _ => failwith("Expected valid range and chunk size for final chunk")
    }
  })

  test("returns None for out-of-range chunk index", t => {
    let range = FileSlicer.chunkRangeForIndex(~sizeBytes=8, ~chunkSizeBytes=4, ~chunkIndex=4)
    t->expect(range)->Expect.toBe(None)
  })
})
