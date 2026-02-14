type apiError = string

let validationReportWrapperDecoder = JsonCombinators.Json.Decode.object(field => {
  field.required("validationReport", JsonParsers.Shared.validationReport)
})

let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
  switch JsonCombinators.Json.decode(data, JsonParsers.Domain.project) {
  | Ok(_) => Ok(data)
  | Error(e) => Error("Invalid project structure: " ++ e)
  }
}
