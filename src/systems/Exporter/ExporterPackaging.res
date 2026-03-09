open ReBindings
open Types

type optimizedAsset = ExporterPackagingAssets.optimizedAsset = {blob: Blob.t, filename: string}
type marketingBannerPayload = ExporterPackagingTemplates.marketingBannerPayload = {
  showRent: bool,
  showSale: bool,
  body: string,
  phone1: string,
  phone2: string,
}

let normalizeMarketingValue = (value: string): string =>
  ExporterPackagingTemplates.normalizeMarketingValue(value)

let toWebpFilename = (name: string, ~fallback: string): string => {
  ExporterPackagingAssets.toWebpFilename(name, ~fallback)
}

let optimizeBlobAsWebp = async (
  ~blob: Blob.t,
  ~filenameHint: string,
  ~quality: float,
  ~maxWidth: float,
  ~maxHeight: float,
): result<optimizedAsset, string> =>
  await ExporterPackagingAssets.optimizeBlobAsWebp(
    ~blob,
    ~filenameHint,
    ~quality,
    ~maxWidth,
    ~maxHeight,
  )

let appendLogo = async (
  ~formData: FormData.t,
  ~logo: option<file>,
  ~authToken: option<string>,
  ~signal: option<BrowserBindings.AbortSignal.t>,
): option<string> => await ExporterPackagingAssets.appendLogo(~formData, ~logo, ~authToken, ~signal)

let appendTemplates = (
  ~formData: FormData.t,
  ~exportScenes: array<scene>,
  ~tourName: string,
  ~logoFilename: option<string>,
  ~version: string,
  ~projectData: option<JSON.t>=?,
  ~publishProfiles: array<string>,
): unit =>
  ExporterPackagingTemplates.appendTemplates(
    ~formData,
    ~exportScenes,
    ~tourName,
    ~logoFilename,
    ~version,
    ~projectData?,
    ~publishProfiles,
  )

let appendLibraries = async (
  ~formData: FormData.t,
  ~signal: option<BrowserBindings.AbortSignal.t>,
): unit => await ExporterPackagingSceneAssets.appendLibraries(~formData, ~signal)

let appendScenes = async (
  ~formData: FormData.t,
  ~exportScenes: array<scene>,
  ~authToken: option<string>,
  ~progress: (float, float, string) => unit,
  ~signal: option<BrowserBindings.AbortSignal.t>,
): result<unit, string> => {
  let totalScenes = Belt.Array.length(exportScenes)

  let rec appendScenesList = async (sceneList, idx, ~signal) => {
    let isAborted = switch signal {
    | Some(s) => BrowserBindings.AbortSignal.aborted(s)
    | None => false
    }
    if isAborted {
      Error("AbortError: Export cancelled by user")
    } else {
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
            let initial = await ExporterUtils.fetchSceneUrlBlob(~url, ~authToken, ~signal?)
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
                await ExporterUtils.fetchSceneUrlBlob(~url, ~authToken=Some("dev-token"), ~signal?)
              } else {
                initial
              }
            }
          }

          switch blobResult {
          | Ok(fileBlob) =>
            switch await ExporterPackagingAssets.optimizeBlobAsWebp(
              ~blob=fileBlob,
              ~filenameHint=s.name,
              ~quality=Constants.Media.exportSceneWebpQuality,
              ~maxWidth=Constants.Media.exportSceneMaxWidth,
              ~maxHeight=Constants.Media.exportSceneMaxWidth,
            ) {
            | Ok({blob: normalizedBlob, filename}) =>
              FormData.appendWithFilename(
                formData,
                `scene_${Belt.Int.toString(idx)}`,
                normalizedBlob,
                filename,
              )
              let scenePct = 15.0 +. 25.0 *. Int.toFloat(idx + 1) /. Int.toFloat(totalScenes)
              progress(
                scenePct,
                100.0,
                "Packaging scene " ++
                Int.toString(idx + 1) ++
                " of " ++
                Int.toString(totalScenes) ++ "...",
              )
              await appendScenesList(rest, idx + 1, ~signal)
            | Error(msg) => Error("Scene normalization failed for '" ++ s.name ++ "': " ++ msg)
            }
          | Error(msg) => Error("Scene packaging failed for '" ++ s.name ++ "': " ++ msg)
          }
        }
      }
    }
  }

  await appendScenesList(Belt.List.fromArray(exportScenes), 0, ~signal)
}
