open Vitest

module RecoveryPrompt = RecoveryPrompt

test("formatBytes formats correctly", t => {
  t->expect(RecoveryPrompt.formatBytes(0.0))->Expect.toBe("0 Bytes")
  t->expect(RecoveryPrompt.formatBytes(100.0))->Expect.toBe("100.0 Bytes")
  t->expect(RecoveryPrompt.formatBytes(1024.0))->Expect.toBe("1.0 KB")
  t->expect(RecoveryPrompt.formatBytes(1536.0))->Expect.toBe("1.5 KB")
  t->expect(RecoveryPrompt.formatBytes(1048576.0))->Expect.toBe("1.0 MB")
})

test("RecoveryContext decodes correctly", t => {
  let json = JsonCombinators.Json.Encode.object([
    ("fileCount", JsonCombinators.Json.Encode.int(1)),
    ("fileNames", JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(["test.jpg"])),
    ("totalSizeBytes", JsonCombinators.Json.Encode.float(12345.0)),
  ])

  let result = JsonCombinators.Json.decode(json, RecoveryPrompt.RecoveryContext.decode)

  switch result {
  | Ok(ctx) =>
    t->expect(ctx.fileCount)->Expect.toBe(1)
    t->expect(ctx.fileNames)->Expect.toEqual(["test.jpg"])
    t->expect(ctx.totalSizeBytes)->Expect.toBe(12345.0)
  | Error(msg) => t->expect(msg)->Expect.toBe("Should not fail") // Fail explicitly
  }
})
