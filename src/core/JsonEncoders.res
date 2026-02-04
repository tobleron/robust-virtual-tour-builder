/* src/core/JsonEncoders.res */

open JsonCombinators.Json

module Upload = {
  external castFileToJson: ReBindings.File.t => JSON.t = "%identity"
  external castBlobToJson: ReBindings.Blob.t => JSON.t = "%identity"
  let value = (v: JSON.t) => v

  let encodeFileFromTypes = (f: Types.file) => {
     switch f {
     | Url(s) => Encode.string(s)
     | File(file) => castFileToJson(file)
     | Blob(blob) => castBlobToJson(blob)
     }
  }

  let sceneItem = (
    ~id: string,
    ~originalName: string,
    ~name: string,
    ~original: Types.file,
    ~preview: Types.file,
    ~tiny: Types.file,
    ~quality: option<JSON.t>,
    ~metadata: option<JSON.t>,
    ~colorGroup: string
  ) => {
    Encode.object([
      ("id", Encode.string(id)),
      ("originalName", Encode.string(originalName)),
      ("name", Encode.string(name)),
      ("original", encodeFileFromTypes(original)),
      ("preview", encodeFileFromTypes(preview)),
      ("tiny", encodeFileFromTypes(tiny)),
      ("quality", Encode.option(value)(quality)),
      ("metadata", Encode.option(value)(metadata)),
      ("colorGroup", Encode.string(colorGroup))
    ])
  }
}
