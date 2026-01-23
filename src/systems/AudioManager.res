/* src/systems/AudioManager.res */

open ReBindings

/* Web Audio API Bindings */
type audioContext
type audioBuffer
type audioNode
type audioParam = {mutable value: float}
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

@send external createBufferSource: audioContext => audioBufferSourceNode = "createBufferSource"
@send external createGain: audioContext => gainNode = "createGain"

@set external setBuffer: (audioBufferSourceNode, audioBuffer) => unit = "buffer"
@send external start: (audioBufferSourceNode, float) => unit = "start"

/* Subtyping via identity casts */
external asAudioNode: 'a => audioNode = "%identity"

@send external connect: (audioNode, audioNode) => unit = "connect"
@send external connectParam: (audioNode, audioParam) => unit = "connect"

/* GainNode specific */
@get external getGain: gainNode => audioParam = "gain"

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
let clickAudioRef: ref<option<audioElement>> = ref(None)

let getClickAudio = () => {
  switch clickAudioRef.contents {
  | Some(a) => a
  | None => {
      let a = newAudio(clickSoundUrl)
      setVolume(a, 0.4)
      clickAudioRef := Some(a)
      a
    }
  }
}

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
        Logger.warn(
          ~module_="Audio",
          ~message="AUDIO_INIT_FAILED",
          ~data=Logger.castToJson({"error": e}),
          (),
        )
        Promise.resolve()
      })
  }
}

let playTick = () => {
  if !isInitialized.contents {
    let a = getClickAudio()
    setCurrentTime(a, 0.0)
    let _ = play(a)->Promise.catch(_ => Promise.resolve())
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
      gainVal.value = 0.4

      connect(asAudioNode(source), asAudioNode(gainNode))
      connect(asAudioNode(gainNode), destination(ctx))
      start(source, 0.0)

    | _ =>
      let a = getClickAudio()
      setCurrentTime(a, 0.0)
      let _ = play(a)->Promise.catch(_ => Promise.resolve())
    }
  }
}

let setupGlobalClickSounds = () => {
  let handleMouseDown = (e: Dom.event) => {
    let target = Dom.target(e)
    let selector = "button, .floor-circle, .label-menu-item, .header-menu-btn"

    switch Dom.closest(target, selector)->Nullable.toOption {
    | Some(_) =>
      init()
      playTick()
    | None => ()
    }
  }

  /* Use documentBody for capture listener since document type is opaque object */
  let body = Dom.documentBody
  if (Obj.magic(body): bool) {
    try {
      Dom.addEventListenerCapture(body, "mousedown", handleMouseDown, true)
    } catch {
    | _ => ()
    }
  }
}
