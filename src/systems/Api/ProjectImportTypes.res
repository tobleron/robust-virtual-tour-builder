/* src/systems/Api/ProjectImportTypes.res */

type importInitResponse = {
  uploadId: string,
  chunkSizeBytes: int,
  totalChunks: int,
  expiresAtEpochMs: float,
}

type importChunkResponse = {
  accepted: bool,
  nextExpectedChunk: int,
  receivedCount: int,
}

type importStatusResponse = {
  receivedChunks: array<int>,
  nextExpectedChunk: int,
  totalChunks: int,
  expiresAtEpochMs: float,
}

let decodeImportInitResponse = json =>
  JsonCombinators.Json.decode(
    json,
    JsonCombinators.Json.Decode.object(field => {
      {
        uploadId: field.required("uploadId", JsonCombinators.Json.Decode.string),
        chunkSizeBytes: field.required("chunkSizeBytes", JsonCombinators.Json.Decode.int),
        totalChunks: field.required("totalChunks", JsonCombinators.Json.Decode.int),
        expiresAtEpochMs: field.required("expiresAtEpochMs", JsonCombinators.Json.Decode.float),
      }
    }),
  )

let decodeImportChunkResponse = json =>
  JsonCombinators.Json.decode(
    json,
    JsonCombinators.Json.Decode.object(field => {
      {
        accepted: field.required("accepted", JsonCombinators.Json.Decode.bool),
        nextExpectedChunk: field.required("nextExpectedChunk", JsonCombinators.Json.Decode.int),
        receivedCount: field.required("receivedCount", JsonCombinators.Json.Decode.int),
      }
    }),
  )

let decodeImportStatusResponse = json =>
  JsonCombinators.Json.decode(
    json,
    JsonCombinators.Json.Decode.object(field => {
      {
        receivedChunks: field.required(
          "receivedChunks",
          JsonCombinators.Json.Decode.array(JsonCombinators.Json.Decode.int),
        ),
        nextExpectedChunk: field.required("nextExpectedChunk", JsonCombinators.Json.Decode.int),
        totalChunks: field.required("totalChunks", JsonCombinators.Json.Decode.int),
        expiresAtEpochMs: field.required("expiresAtEpochMs", JsonCombinators.Json.Decode.float),
      }
    }),
  )
