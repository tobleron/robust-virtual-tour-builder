/* src/systems/AudioManager.res */

open ReBindings

/* Web Audio API Bindings */
type audioContext
type audioBuffer
type audioNode
type gainNode
type audioBufferSourceNode

@new @scope("window") external newAudioContext: unit => audioContext = "AudioContext"
@new @scope("window") external newWebkitAudioContext: unit => audioContext = "webkitAudioContext"

@send
external decodeAudioData: (audioContext, BrowserArrayBuffer.t) => Promise.t<audioBuffer> =
  "decodeAudioData"
@send external resume: audioContext => Promise.t<unit> = "resume"
@get external state: audioContext => string = "state"
@get external destination: audioContext => audioNode = "destination"

type audioParam = {mutable value: float}

@send external createBufferSource: audioContext => audioBufferSourceNode = "createBufferSource"
@send external createGain: audioContext => gainNode = "createGain"

@set external setBuffer: (audioBufferSourceNode, audioBuffer) => unit = "buffer"
@send external start: (audioBufferSourceNode, float) => unit = "start"
@send external connect: (audioNode, audioNode) => unit = "connect"
@send external connectParam: (audioNode, {..}) => unit = "connect" /* For gain param? */

/* GainNode specific */
@get external getGain: gainNode => {..} = "gain"

/* HTML Audio Element */
type audioElement
@new external newAudio: string => audioElement = "Audio"
@set external setVolume: (audioElement, float) => unit = "volume"
@set external setCurrentTime: (audioElement, float) => unit = "currentTime"
@send external play: audioElement => Promise.t<unit> = "play"

let clickSoundUrl = "sounds/click.wav"
let audioContext: ref<option<audioContext>> = ref(None)
let clickBuffer: ref<option<audioBuffer>> = ref(None)
let isInitialized = ref(false)
let clickAudio = newAudio(clickSoundUrl)

/* Set volume */
let _ = setVolume(clickAudio, 0.4)

let init = () => {
  if !isInitialized.contents {
    isInitialized := true

    let ctx = try {
      newAudioContext()
    } catch {
    | _ => newWebkitAudioContext()
    }
    audioContext := Some(ctx)

    let _ =
      Fetch.fetchSimple(clickSoundUrl)
      ->Promise.then(res => Fetch.arrayBuffer(res))
      ->Promise.then(buffer => decodeAudioData(ctx, buffer))
      ->Promise.then(decoded => {
        clickBuffer := Some(decoded)
        Promise.resolve()
      })
      ->Promise.catch(e => {
        Logger.warn(~module_="Audio", ~message="AUDIO_INIT_FAILED", ~data={"error": e}, ())
        Promise.resolve()
      })
  }
}

let playTick = () => {
  if !isInitialized.contents {
    setCurrentTime(clickAudio, 0.0)
    let _ = play(clickAudio)->Promise.catch(_ => Promise.resolve())
  } else {
    switch (audioContext.contents, clickBuffer.contents) {
    | (Some(ctx), Some(buffer)) =>
      if state(ctx) == "suspended" {
        let _ = resume(ctx)
      }
      let source = createBufferSource(ctx)
      setBuffer(source, buffer)
      let gainNode = createGain(ctx)

      let gainVal = getGain(gainNode)
      (Obj.magic(gainVal): audioParam).value = 0.4

      connect(Obj.magic(source), Obj.magic(gainNode))
      connect(Obj.magic(gainNode), destination(ctx))
      start(source, 0.0)

    | _ =>
      setCurrentTime(clickAudio, 0.0)
      let _ = play(clickAudio)->Promise.catch(_ => Promise.resolve())
    }
  }
}

let setupGlobalClickSounds = () => {
  let handleMouseDown = (e: Dom.event) => {
    let target = (Obj.magic(e): {"target": Dom.element})["target"]
    let selector = "button, .floor-circle, .label-menu-item, .header-menu-btn"

    switch Dom.closest(target, selector)->Nullable.toOption {
    | Some(_) =>
      init()
      playTick()
    | None => ()
    }
  }

  /* Use documentBody for capture listener since document type is opaque object */
  Dom.addEventListenerCapture(Dom.documentBody, "mousedown", handleMouseDown, true)
}
