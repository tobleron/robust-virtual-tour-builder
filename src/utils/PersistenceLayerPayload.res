/* src/utils/PersistenceLayerPayload.res */

open Types

type serializedSession = {
  version: int,
  timestamp: float,
  projectData: JSON.t,
}

type sliceManifest = {
  version: int,
  timestamp: float,
  slices: array<string>,
}

type logoSlice = {
  kind: string,
  url: option<string>,
}

type metadataSliceDecoded = {
  tourName: string,
  lastUsedCategory: string,
  sessionId: option<string>,
  nextSceneSequenceId: int,
  logo: option<logoSlice>,
}

let encodeMetadataSlice = (state: state): JSON.t =>
  JsonCombinators.Json.Encode.object([
    ("tourName", JsonCombinators.Json.Encode.string(state.tourName)),
    ("lastUsedCategory", JsonCombinators.Json.Encode.string(state.lastUsedCategory)),
    (
      "sessionId",
      switch state.sessionId {
      | Some(id) => JsonCombinators.Json.Encode.string(id)
      | None => JsonCombinators.Json.Encode.null
      },
    ),
    ("nextSceneSequenceId", JsonCombinators.Json.Encode.int(state.nextSceneSequenceId)),
    (
      "logo",
      switch state.logo {
      | Some(Blob(_)) =>
        JsonCombinators.Json.Encode.object([("kind", JsonCombinators.Json.Encode.string("blob"))])
      | Some(File(_)) =>
        JsonCombinators.Json.Encode.object([("kind", JsonCombinators.Json.Encode.string("file"))])
      | Some(Url(url)) =>
        JsonCombinators.Json.Encode.object([
          ("kind", JsonCombinators.Json.Encode.string("url")),
          ("url", JsonCombinators.Json.Encode.string(url)),
        ])
      | None => JsonCombinators.Json.Encode.null
      },
    ),
  ])

let signatureOfJson = (value: JSON.t): string => JsonCombinators.Json.stringify(value)

let normalizeProjectData = (projectData: JSON.t): option<JSON.t> => {
  switch JsonCombinators.Json.decode(projectData, JsonParsers.Domain.project) {
  | Ok(project) => Some(JsonParsers.Encoders.project(project))
  | Error(e) =>
    Logger.warnWithAppError(
      ~module_="Persistence",
      ~message="Persisted project payload failed validation",
      ~appError=SharedTypes.ValidationError({message: e, field: Some("projectData")}),
      ~operationContext="persistence_normalize_project",
      (),
    )
    None
  }
}

let buildProjectData = (state: state): JSON.t => {
  let project: project = {
    tourName: state.tourName,
    inventory: state.inventory,
    sceneOrder: state.sceneOrder,
    lastUsedCategory: state.lastUsedCategory,
    exifReport: state.exifReport,
    sessionId: state.sessionId,
    timeline: state.timeline,
    logo: state.logo,
    marketingComment: state.marketingComment,
    marketingPhone1: state.marketingPhone1,
    marketingPhone2: state.marketingPhone2,
    marketingForRent: state.marketingForRent,
    marketingForSale: state.marketingForSale,
    nextSceneSequenceId: state.nextSceneSequenceId,
  }
  JsonParsers.Encoders.project(project)
}

let buildSlices = (state: state): array<(string, JSON.t)> => {
  let inventorySlice = JsonCombinators.Json.Encode.object([
    ("inventory", JsonParsers.Encoders.inventory(state.inventory)),
  ])
  let sceneOrderSlice = JsonCombinators.Json.Encode.object([
    (
      "sceneOrder",
      JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(state.sceneOrder),
    ),
  ])
  let timelineSlice = JsonCombinators.Json.Encode.object([
    (
      "timeline",
      JsonCombinators.Json.Encode.array(JsonParsers.Encoders.timelineItem)(state.timeline),
    ),
  ])
  let metadataSlice = encodeMetadataSlice(state)

  [
    ("inventory", inventorySlice),
    ("sceneOrder", sceneOrderSlice),
    ("timeline", timelineSlice),
    ("metadata", metadataSlice),
  ]
}

let buildSignatures = (slices: array<(string, JSON.t)>): Dict.t<string> => {
  let signatures = Dict.make()
  slices->Belt.Array.forEach(((name, json)) => {
    Dict.set(signatures, name, signatureOfJson(json))
  })
  signatures
}

let collectChangedSlices = (
  ~slices: array<(string, JSON.t)>,
  ~previousSignatures: Dict.t<string>,
): array<(string, JSON.t)> =>
  slices->Belt.Array.keepMap(((name, json)) => {
    let newSig = signatureOfJson(json)
    let oldSig = Dict.get(previousSignatures, name)->Option.getOr("")
    if newSig != oldSig {
      Some((name, json))
    } else {
      None
    }
  })

let buildManifest = (
  ~version: int,
  ~timestamp: float,
  ~slices: array<(string, JSON.t)>,
): sliceManifest => {
  version,
  timestamp,
  slices: slices->Belt.Array.map(((name, _)) => name),
}

let buildManifestJson = (manifest: sliceManifest): JSON.t =>
  JsonCombinators.Json.Encode.object([
    ("version", JsonCombinators.Json.Encode.int(manifest.version)),
    ("timestamp", JsonCombinators.Json.Encode.float(manifest.timestamp)),
    (
      "slices",
      JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(manifest.slices),
    ),
  ])

let decodeManifest = (json: JSON.t): option<sliceManifest> =>
  switch JsonCombinators.Json.decode(
    json,
    JsonCombinators.Json.Decode.object(field => {
      version: field.required("version", JsonCombinators.Json.Decode.int),
      timestamp: field.required("timestamp", JsonCombinators.Json.Decode.float),
      slices: field.required(
        "slices",
        JsonCombinators.Json.Decode.array(JsonCombinators.Json.Decode.string),
      ),
    }),
  ) {
  | Ok(v) => Some(v)
  | Error(_) => None
  }

let extractFromSlice = (_json: JSON.t, _key: string): option<JSON.t> =>
  %raw(`(function(json, key){
    if (!json || typeof json !== "object") return undefined;
    return Object.prototype.hasOwnProperty.call(json, key) ? json[key] : undefined;
  })(_json, _key)`)

let decodeMetadataSlice = (json: JSON.t): option<metadataSliceDecoded> =>
  switch JsonCombinators.Json.decode(
    json,
    JsonCombinators.Json.Decode.object(field => {
      tourName: field.required("tourName", JsonCombinators.Json.Decode.string),
      lastUsedCategory: field.required("lastUsedCategory", JsonCombinators.Json.Decode.string),
      sessionId: field.optional("sessionId", JsonCombinators.Json.Decode.string),
      nextSceneSequenceId: field.required("nextSceneSequenceId", JsonCombinators.Json.Decode.int),
      logo: field.optional(
        "logo",
        JsonCombinators.Json.Decode.object((sub): logoSlice => {
          kind: sub.required("kind", JsonCombinators.Json.Decode.string),
          url: sub.optional("url", JsonCombinators.Json.Decode.string),
        }),
      ),
    }),
  ) {
  | Ok(v) =>
    Some({
      tourName: v.tourName,
      lastUsedCategory: v.lastUsedCategory,
      sessionId: v.sessionId,
      nextSceneSequenceId: v.nextSceneSequenceId,
      logo: v.logo,
    })
  | Error(_) => None
  }

let reconstructProjectJson = (
  ~inventory: JSON.t,
  ~sceneOrder: JSON.t,
  ~timeline: JSON.t,
  ~metadata: metadataSliceDecoded,
): JSON.t =>
  JsonCombinators.Json.Encode.object([
    ("tourName", JsonCombinators.Json.Encode.string(metadata.tourName)),
    ("inventory", inventory),
    ("sceneOrder", sceneOrder),
    ("lastUsedCategory", JsonCombinators.Json.Encode.string(metadata.lastUsedCategory)),
    ("exifReport", JsonCombinators.Json.Encode.null),
    (
      "sessionId",
      switch metadata.sessionId {
      | Some(v) => JsonCombinators.Json.Encode.string(v)
      | None => JsonCombinators.Json.Encode.null
      },
    ),
    ("timeline", timeline),
    (
      "logo",
      switch metadata.logo {
      | Some({kind, url}) if kind == "url" =>
        JsonCombinators.Json.Encode.object([
          ("kind", JsonCombinators.Json.Encode.string("url")),
          ("url", JsonCombinators.Json.Encode.string(url->Option.getOr(""))),
        ])
      | _ => JsonCombinators.Json.Encode.null
      },
    ),
    ("nextSceneSequenceId", JsonCombinators.Json.Encode.int(metadata.nextSceneSequenceId)),
  ])
