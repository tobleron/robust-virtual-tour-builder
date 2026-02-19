open OperationJournal

module RecoveryContext = {
  type t = {
    fileCount: int,
    fileNames: array<string>,
    totalSizeBytes: float,
  }

  let decode = JsonCombinators.Json.Decode.object(field => {
    {
      fileCount: field.optional("fileCount", JsonCombinators.Json.Decode.int)->Option.getOr(0),
      fileNames: field.optional(
        "fileNames",
        JsonCombinators.Json.Decode.array(JsonCombinators.Json.Decode.string),
      )->Option.getOr([]),
      totalSizeBytes: field.optional("totalSizeBytes", JsonCombinators.Json.Decode.float)->Option.getOr(
        0.0,
      ),
    }
  })
}

let formatBytes = (bytes: float) => {
  if bytes == 0.0 {
    "0 Bytes"
  } else {
    let k = 1024.0
    let sizes = ["Bytes", "KB", "MB", "GB", "TB"]
    let i = Js.Math.floor_int(Math.log(bytes) /. Math.log(k))
    let i = if i < 0 {
      0
    } else if i >= Array.length(sizes) {
      Array.length(sizes) - 1
    } else {
      i
    }

    let size = sizes[i]->Option.getOr("Bytes")
    let value = bytes /. Math.pow(k, ~exp=Belt.Float.fromInt(i))
    let formatted = Float.toFixed(value, ~digits=1)
    formatted ++ " " ++ size
  }
}

@react.component
let make = (~entries: array<OperationJournal.journalEntry>) => {
  <div className="flex flex-col gap-3 p-2 text-sm text-slate-700">
    <div className="flex flex-col gap-2 max-h-60 overflow-y-auto">
      {entries
      ->Belt.Array.map(entry => {
        let resumable = RecoveryManager.canRetry(entry)
        let isUpload = entry.operation == "UploadImages"

        let content = if isUpload {
          let decoded = JsonCombinators.Json.decode(entry.context, RecoveryContext.decode)
          switch decoded {
          | Ok(ctx) =>
            let sizeStr = formatBytes(ctx.totalSizeBytes)
            if ctx.fileCount == 1 {
              let name = ctx.fileNames[0]->Option.getOr("Unknown file")
              <div className="flex flex-col gap-1">
                <span className="font-medium text-slate-800">
                  {React.string("1 image upload was interrupted")}
                </span>
                <span className="text-xs text-slate-500">
                  {React.string(name ++ ", " ++ sizeStr)}
                </span>
              </div>
            } else {
              <div className="flex flex-col gap-1">
                <span className="font-medium text-slate-800">
                  {React.string(
                    Belt.Int.toString(ctx.fileCount) ++ " image uploads were interrupted",
                  )}
                </span>
                <span className="text-xs text-slate-500">
                  {React.string("Total size: " ++ sizeStr)}
                </span>
              </div>
            }
          | Error(_) =>
            <span className="font-medium text-slate-800">
              {React.string("Upload interrupted (Unknown details)")}
            </span>
          }
        } else {
          <span className="font-medium text-slate-800">
            {React.string(entry.operation ++ " interrupted")}
          </span>
        }

        <div
          key=entry.id
          className="bg-slate-50 p-3 rounded border border-slate-200 flex flex-col gap-2">
          {content}
          <div className="flex justify-between items-center mt-1">
            <span className="text-xs text-slate-500">
              {if resumable {
                React.string("Your upload didn't complete. Would you like to try again?")
              } else {
                React.string("This operation cannot be resumed.")
              }}
            </span>
          </div>
        </div>
      })
      ->React.array}
    </div>
  </div>
}
