open ReBindings

let decodeJson = (json, ~decoder, ~event: string, ~message: string): Promise.t<
  result<'a, string>,
> =>
  ApiHelpers.handleJsonDecode(
    ~module_="ExporterUpload",
    json,
    json => JsonCombinators.Json.decode(json, decoder),
    event,
    message,
  )

let encodeInitBody = (payloadBlob: Blob.t, ~filename: string, ~chunkSizeBytes: int) =>
  JsonCombinators.Json.Encode.object([
    ("filename", JsonCombinators.Json.Encode.string(filename)),
    ("sizeBytes", JsonCombinators.Json.Encode.int(Float.toInt(Blob.size(payloadBlob)))),
    ("chunkSizeBytes", JsonCombinators.Json.Encode.int(chunkSizeBytes)),
  ])

let encodeCompleteBody = (
  payloadBlob: Blob.t,
  ~filename: string,
  ~uploadId: string,
  ~totalChunks: int,
) =>
  JsonCombinators.Json.Encode.object([
    ("uploadId", JsonCombinators.Json.Encode.string(uploadId)),
    ("filename", JsonCombinators.Json.Encode.string(filename)),
    ("sizeBytes", JsonCombinators.Json.Encode.int(Float.toInt(Blob.size(payloadBlob)))),
    ("totalChunks", JsonCombinators.Json.Encode.int(totalChunks)),
  ])

let encodeAbortBody = (uploadId: string) =>
  JsonCombinators.Json.Encode.object([("uploadId", JsonCombinators.Json.Encode.string(uploadId))])

let chunkBounds = (payloadBlob: Blob.t, ~chunkIndex: int, ~chunkSizeBytes: int): result<
  (int, int),
  string,
> => {
  let totalSize = Float.toInt(Blob.size(payloadBlob))
  let start = chunkIndex * chunkSizeBytes
  let candidateEnd = start + chunkSizeBytes
  let end_ = if candidateEnd > totalSize {
    totalSize
  } else {
    candidateEnd
  }

  if start >= totalSize || end_ <= start {
    Error("Invalid chunk index " ++ Belt.Int.toString(chunkIndex))
  } else {
    Ok((start, end_))
  }
}

let buildChunkFormData = async (
  payloadBlob: Blob.t,
  ~filename: string,
  ~chunkIndex: int,
  ~chunkSizeBytes: int,
  ~blobSlice: (Blob.t, int, int) => Blob.t,
  ~sha256HexForBlob: Blob.t => Promise.t<string>,
): result<FormData.t, string> => {
  switch chunkBounds(payloadBlob, ~chunkIndex, ~chunkSizeBytes) {
  | Error(msg) => Error(msg)
  | Ok((start, end_)) =>
    let chunkBlob = blobSlice(payloadBlob, start, end_)
    let chunkByteLength = end_ - start
    let chunkSha256 = await sha256HexForBlob(chunkBlob)
    let formData = FormData.newFormData()
    FormData.append(formData, "chunkIndex", Belt.Int.toString(chunkIndex))
    FormData.append(formData, "chunkByteLength", Belt.Int.toString(chunkByteLength))
    FormData.append(formData, "chunkSha256", chunkSha256)
    FormData.appendWithFilename(
      formData,
      "chunk",
      chunkBlob,
      filename ++ ".part-" ++ Belt.Int.toString(chunkIndex),
    )
    Ok(formData)
  }
}
