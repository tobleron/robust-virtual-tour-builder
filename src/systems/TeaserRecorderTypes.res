/* src/systems/TeaserRecorderTypes.res */

let canvasWidth = Constants.Teaser.canvasWidth
let canvasHeight = Constants.Teaser.canvasHeight

type stream
type mediaRecorder
type blob = ReBindings.Blob.t

@val external requestAnimationFrame: (unit => unit) => int = "requestAnimationFrame"
@val external cancelAnimationFrame: int => unit = "cancelAnimationFrame"

/* Stream Bindings */
@send external captureStream: (ReBindings.Dom.element, int) => stream = "captureStream"

/* MediaRecorder Bindings */
@new external createMediaRecorder: (stream, {..}) => mediaRecorder = "MediaRecorder"
@send external start: (mediaRecorder, int) => unit = "start"
@send external stop: mediaRecorder => unit = "stop"
@get external state: mediaRecorder => string = "state"
@set external ondataavailable: (mediaRecorder, {..} => unit) => unit = "ondataavailable"
@set external onstop: (mediaRecorder, unit => unit) => unit = "onstop"
@send external pause: mediaRecorder => unit = "pause"
@send external resume: mediaRecorder => unit = "resume"

/* Canvas Context Extension */
@send
external drawImageScaled: (
  ReBindings.Canvas.context2d,
  ReBindings.Dom.element,
  float,
  float,
  float,
  float,
) => unit = "drawImage"
@send
external drawImagePos: (ReBindings.Canvas.context2d, ReBindings.Dom.element, float, float) => unit =
  "drawImage"
@send
external drawImageFull: (
  ReBindings.Canvas.context2d,
  ReBindings.Dom.element,
  float,
  float,
  float,
  float,
  float,
  float,
  float,
  float,
) => unit = "drawImage"

external asDynamic: 'a => {..} = "%identity"
external castToBlob: 'a => blob = "%identity"

type logoResult = {
  img: option<ReBindings.Dom.element>,
  loaded: bool,
}

type recorderState = {
  mutable mediaRecorder: option<mediaRecorder>,
  mutable chunks: array<blob>,
  mutable streamLoopId: option<int>,
  mutable startTime: float,
  mutable fpsBuffer: array<float>,
  mutable fadeOpacity: float,
  mutable isTeasing: bool,
  mutable ghostCanvas: option<ReBindings.Dom.element>,
  mutable ghostCtx: option<ReBindings.Canvas.context2d>,
  /* Snapshot handling */
  mutable snapshotCanvas: option<ReBindings.Dom.element>,
}

let internalState = {
  mediaRecorder: None,
  chunks: [],
  streamLoopId: None,
  startTime: 0.0,
  fpsBuffer: [],
  fadeOpacity: 0.0,
  isTeasing: false,
  ghostCanvas: None,
  ghostCtx: None,
  snapshotCanvas: None,
}
