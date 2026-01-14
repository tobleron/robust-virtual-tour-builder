/* src/systems/DownloadSystem.res */

open ReBindings

@module("../constants.js") external cleanupDelay: int = "BLOB_URL_CLEANUP_DELAY"

/* File System Access API Types */
type fileHandle
type writableStream

@send external createWritable: fileHandle => Promise.t<writableStream> = "createWritable"
@send external write: (writableStream, Blob.t) => Promise.t<unit> = "write"
@send external close: writableStream => Promise.t<unit> = "close"

type validFileTypes = {"description": string, "accept": dict<array<string>>}

type savePickerOptions = {
  suggestedName: string,
  types: array<validFileTypes>,
}

@scope("window") @val
external showSaveFilePicker: savePickerOptions => Promise.t<fileHandle> = "showSaveFilePicker"

/* Internal Helpers */
let getExtension = (filename: string) => {
  let parts = String.split(filename, ".")
  switch Belt.Array.get(parts, Belt.Array.length(parts) - 1) {
  | Some(ext) => "." ++ String.toLowerCase(ext)
  | None => ".dat"
  }
}

let saveBlob = (blob: Blob.t, filename: string) => {
  Logger.info(~module_="Download", ~message="SAVING_FILE", ~data={
    "filename": filename,
    "size": Blob.size(blob)
  }, ())

  /* Ensure MIME type */
  let blob = if Blob.type_(blob) == "" {
    Blob.newBlob([Obj.magic(blob)], {"type": "application/octet-stream"})
  } else {
    blob
  }

  let url = URL.createObjectURL(blob)
  let a = Dom.createElement("a")

  Dom.setDisplay(a, "none")
  Dom.setPointerEvents(a, "none")
  Dom.setAttribute(a, "href", url)
  Dom.setAttribute(a, "download", filename)
  Dom.setAttribute(a, "aria-hidden", "true")

  Dom.appendChild(Dom.documentBody, a)
  let _ = (Obj.magic(a): {..})["click"]()

  let _ = Window.setTimeout(() => {
    Dom.documentBody
    ->Obj.magic
    ->Dict.get("removeChild")
    ->Belt.Option.forEach(fn => {
      let _ = (Obj.magic(fn): Dom.element => unit)(a)
    })
    URL.revokeObjectURL(url)
  }, cleanupDelay)
}

let getFileHandle = async (filename: string, type_: string) => {
  let extension = getExtension(filename)
  let accept = Dict.make()
  Dict.set(accept, type_, [extension])

  let options = {
    suggestedName: filename,
    types: [
      {
        "description": "Project File",
        "accept": accept,
      },
    ],
  }

  await showSaveFilePicker(options)
}

let writeFileToHandle = async (handle: fileHandle, blob: Blob.t) => {
  let writable = await createWritable(handle)
  await write(writable, blob)
  await close(writable)
}

let saveBlobWithConfirmation = async (blob: Blob.t, filename: string) => {
  Logger.info(~module_="Download", ~message="SAVING_FILE_CONFIRMATION", ~data={
    "filename": filename,
    "size": Blob.size(blob)
  }, ())

  if Obj.magic(Window.window)["showSaveFilePicker"] !== %raw("undefined") {
    try {
      let mimeType = if Blob.type_(blob) == "" {
        "application/octet-stream"
      } else {
        Blob.type_(blob)
      }
      let handle = await getFileHandle(filename, mimeType)
      await writeFileToHandle(handle, blob)
      Logger.info(~module_="Download", ~message="SAVE_SUCCESS", ~data={"filename": filename}, ())
      true
    } catch {
    | JsExn(e) => {
        let name: string = Obj.magic(e)["name"]
        if name == "AbortError" {
          Logger.info(~module_="Download", ~message="SAVE_CANCELLED", ())
          JsError.throwWithMessage("USER_CANCELLED")
        } else {
          Logger.error(~module_="Download", ~message="SAVE_ERROR", ~data={"error": e}, ())
          JsError.throwWithMessage(Option.getOr(JsExn.message(e), "Save Failed"))
        }
      }
    | e => throw(e)
    }
  } else {
    Logger.info(~module_="Download", ~message="FALLBACK_SAVE", ())
    saveBlob(blob, filename)
    true
  }
}

let downloadZip = (zip: JSZip.t, filename: string) => {
  if Obj.magic(zip) == Nullable.null {
    Logger.error(~module_="Download", ~message="ZIP_MISSING", ())
  } else {
    let _ = JSZip.generateAsync(zip, {"type": "blob"})->Promise.then(content => {
      saveBlob(content, filename)
      Promise.resolve()
    })
  }
}
