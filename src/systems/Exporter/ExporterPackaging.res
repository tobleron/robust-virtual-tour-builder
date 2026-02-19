open ReBindings
open Types

let appendLogo = async (
  ~formData: FormData.t,
  ~logo: option<file>,
  ~authToken: option<string>,
): option<string> => {
  let logoFilename = ref(None)

  switch logo {
  | Some(File(f)) => {
      let name = "logo." ++ ExporterUtils.normalizeLogoExtension(f->File.name)
      FormData.appendWithFilename(formData, name, f, name)
      logoFilename := Some(name)
    }
  | Some(Blob(b)) => {
      let name = "logo.png"
      FormData.appendWithFilename(formData, name, b, name)
      logoFilename := Some(name)
    }
  | Some(Url(url)) =>
    if url == "" || !ExporterUtils.isLikelyImageUrl(url) {
      Logger.warn(
        ~module_="Exporter",
        ~message="LOGO_URL_SKIPPED_INVALID",
        ~data=Some({"url": url}),
        (),
      )
    } else {
      switch await ExporterUtils.fetchSceneUrlBlob(~url, ~authToken) {
      | Ok(logoBlob) =>
        if ExporterUtils.isLikelyImageBlob(~blob=logoBlob, ~urlHint=Some(url)) {
          let ext = switch ExporterUtils.filenameFromUrl(url) {
          | Some(fileName) => ExporterUtils.normalizeLogoExtension(fileName)
          | None => "png"
          }
          let name = "logo." ++ ext
          FormData.appendWithFilename(formData, name, logoBlob, name)
          logoFilename := Some(name)
        } else {
          Logger.warn(
            ~module_="Exporter",
            ~message="LOGO_URL_NOT_IMAGE",
            ~data=Some({"url": url, "blobType": logoBlob->Blob.type_}),
            (),
          )
        }
      | Error(msg) =>
        Logger.warn(
          ~module_="Exporter",
          ~message="LOGO_URL_FETCH_FAILED",
          ~data=Some({"url": url, "error": msg}),
          (),
        )
      }
    }
  | None => ()
  }

  if logoFilename.contents == None {
    try {
      let extensions = ["png", "jpg", "jpeg", "webp"]
      let rec findLogo = async exts => {
        switch exts {
        | list{} => ()
        | list{ext, ...rest} => {
            let filename = "logo." ++ ext
            let path = "/images/" ++ filename
            let res = await Fetch.fetchSimple(path)
            if Fetch.ok(res) {
              let logoBlob = await Fetch.blob(res)
              if ExporterUtils.isLikelyImageBlob(~blob=logoBlob, ~urlHint=Some(path)) {
                FormData.appendWithFilename(formData, filename, logoBlob, filename)
                logoFilename := Some(filename)
              } else {
                await findLogo(rest)
              }
            } else {
              await findLogo(rest)
            }
          }
        }
      }
      await findLogo(Belt.List.fromArray(extensions))
    } catch {
    | _ => Logger.warn(~module_="Exporter", ~message="LOGO_NOT_FOUND", ())
    }
  }

  logoFilename.contents
}

let appendTemplates = (
  ~formData: FormData.t,
  ~exportScenes: array<scene>,
  ~tourName: string,
  ~logoFilename: option<string>,
  ~version: string,
  ~projectData: option<JSON.t>=?,
): unit => {
  let html4k = TourTemplates.generateTourHTML(
    exportScenes,
    tourName,
    logoFilename,
    "4k",
    28,
    54,
    version,
  )
  let html2k = TourTemplates.generateTourHTML(
    exportScenes,
    tourName,
    logoFilename,
    "2k",
    28,
    50,
    version,
  )
  let htmlHd = TourTemplates.generateTourHTML(
    exportScenes,
    tourName,
    logoFilename,
    "hd",
    28,
    40,
    version,
  )
  let htmlIndex = TourTemplates.generateExportIndex(tourName, version, logoFilename)
  let embed = TourTemplates.generateEmbedCodes(tourName, Version.version)

  FormData.append(formData, "html_4k", html4k)
  FormData.append(formData, "html_2k", html2k)
  FormData.append(formData, "html_hd", htmlHd)
  FormData.append(formData, "html_index", htmlIndex)
  FormData.append(formData, "embed_codes", embed)
  projectData->Option.forEach(data =>
    FormData.append(formData, "project_data", JsonCombinators.Json.stringify(data))
  )
}

let appendLibraries = async (~formData: FormData.t): unit => {
  try {
    let panJSRes: result<Blob.t, string> = await ExporterUtils.fetchLib("pannellum.js")
    let panCSSRes: result<Blob.t, string> = await ExporterUtils.fetchLib("pannellum.css")
    switch (panJSRes, panCSSRes) {
    | (Ok(panJS), Ok(panCSS)) => {
        FormData.appendWithFilename(formData, "pannellum.js", panJS, "pannellum.js")
        FormData.appendWithFilename(formData, "pannellum.css", panCSS, "pannellum.css")
      }
    | (Error(e), _) | (_, Error(e)) =>
      Logger.error(~module_="Exporter", ~message="FETCH_LIBS_FAILED", ~data={"error": e}, ())
    }
  } catch {
  | exn =>
    let (msg, stack) = Logger.getErrorDetails(exn)
    Logger.error(
      ~module_="Exporter",
      ~message="FETCH_LIBS_FAILED",
      ~data={"error": msg, "stack": stack},
      (),
    )
  }
}

let appendScenes = async (
  ~formData: FormData.t,
  ~exportScenes: array<scene>,
  ~authToken: option<string>,
  ~progress: (float, float, string) => unit,
): result<unit, string> => {
  let totalScenes = Belt.Array.length(exportScenes)

  let rec appendScenesList = async (sceneList, idx) => {
    switch sceneList {
    | list{} => Ok()
    | list{s, ...rest} => {
        let sourceFile = switch s.originalFile {
        | Some(f) => f
        | None => s.file
        }

        let blobResult = switch sourceFile {
        | Blob(b) => Ok(b)
        | File(f) => Ok(UiHelpers.fileToBlob(File(f)))
        | Url(url) =>
          let initial = await ExporterUtils.fetchSceneUrlBlob(~url, ~authToken)
          switch initial {
          | Ok(_) => initial
          | Error(msg) =>
            let usingDevToken = switch authToken {
            | Some(t) => t == "dev-token"
            | None => false
            }
            if (
              Constants.isDebugBuild() &&
              !usingDevToken &&
              ExporterUtils.isUnauthorizedHttpError(msg)
            ) {
              await ExporterUtils.fetchSceneUrlBlob(~url, ~authToken=Some("dev-token"))
            } else {
              initial
            }
          }
        }

        switch blobResult {
        | Ok(fileBlob) =>
          FormData.appendWithFilename(formData, `scene_${Belt.Int.toString(idx)}`, fileBlob, s.name)
          let scenePct = 15.0 +. 25.0 *. Int.toFloat(idx + 1) /. Int.toFloat(totalScenes)
          progress(
            scenePct,
            100.0,
            "Packaging scene " ++
            Int.toString(idx + 1) ++
            " of " ++
            Int.toString(totalScenes) ++ "...",
          )
          await appendScenesList(rest, idx + 1)
        | Error(msg) => Error("Scene packaging failed for '" ++ s.name ++ "': " ++ msg)
        }
      }
    }
  }

  await appendScenesList(Belt.List.fromArray(exportScenes), 0)
}
