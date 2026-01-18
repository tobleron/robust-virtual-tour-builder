/* src/systems/DownloadSystem.res */

open ReBindings

let cleanupDelay = Constants.blobUrlCleanupDelay

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
  let len = Array.length(parts)
  if len > 1 {
    switch Belt.Array.get(parts, len - 1) {
    | Some(ext) => "." ++ String.toLowerCase(ext)
    | None => ".dat"
    }
  } else {
    ".dat"
  }
}

let saveBlob = (blob: Blob.t, filename: string) => {
  Logger.info(
    ~module_="Download",
    ~message="SAVING_FILE",
    ~data={
      "filename": filename,
      "size": Blob.size(blob),
    },
    (),
  )

  /* Ensure MIME type */
  let blob = if Blob.type_(blob) == "" {
    Blob.newBlob([blob], {"type": "application/octet-stream"})
  } else {
    blob
  }

  let url = UrlUtils.safeCreateObjectURL(blob)
  let a = Dom.createElement("a")

  Dom.setDisplay(a, "none")
  Dom.setPointerEvents(a, "none")
  Dom.setAttribute(a, "href", url)
  Dom.setAttribute(a, "download", filename)
  Dom.setAttribute(a, "aria-hidden", "true")

  Dom.appendChild(Dom.documentBody, a)
  Dom.click(a)

  let _ = Window.setTimeout(() => {
    Dom.removeElement(a)
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
  Logger.info(
    ~module_="Download",
    ~message="SAVING_FILE_CONFIRMATION",
    ~data={
      "filename": filename,
      "size": Blob.size(blob),
    },
    (),
  )

  let hasShowSaveFilePicker = %raw(`typeof window.showSaveFilePicker !== 'undefined'`)

  if hasShowSaveFilePicker {
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
        let name = JsExn.name(e)->Option.getOr("UnknownError")
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
  let zipNullable: Nullable.t<JSZip.t> = Obj.magic(zip)
  if zipNullable == Nullable.null {
    Logger.error(~module_="Download", ~message="ZIP_MISSING", ())
  } else {
    let _ = JSZip.generateAsync(zip, {"type": "blob"})->Promise.then(content => {
      saveBlob(content, filename)
      Promise.resolve()
    })
  }
}
