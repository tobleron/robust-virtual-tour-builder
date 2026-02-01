open Types

let parseTimelineItem = (json: JSON.t): timelineItem => {
  switch JsonCombinators.Json.decode(json, JsonParsers.Domain.timelineItem) {
  | Ok(v) => v
  | Error(_) => {
      id: "",
      linkId: "",
      sceneId: "",
      targetScene: "",
      transition: "fade",
      duration: 1000,
    }
  }
}

// Need timelineUpdate decoder in JsonParsers!
// I'll add a simplified local one or update JsonParsers.res
// For now, let's update JsonParsers.res to include timelineUpdate

// BUT, I can just inline it if it's small or use `object`.
// `timelineUpdate` is { transition: option<string>, duration: option<option<int>> }

let handleUpdateTimelineStep = (state: state, id: string, dataJson: JSON.t): state => {
  // Manual decode or add to JsonParsers. Let's do manual for speed and locality
  let transition = switch JsonCombinators.Json.decode(
    dataJson,
    JsonCombinators.Json.Decode.field(
      "transition",
      JsonCombinators.Json.Decode.option(JsonCombinators.Json.Decode.string),
    ),
  ) {
  | Ok(v) => v
  | Error(_) => None
  }

  let duration = switch JsonCombinators.Json.decode(
    dataJson,
    JsonCombinators.Json.Decode.field(
      "duration",
      JsonCombinators.Json.Decode.option(
        JsonCombinators.Json.Decode.option(JsonCombinators.Json.Decode.int),
      ),
    ),
  ) {
  | Ok(v) => v
  | Error(_) => None
  }

  let updateItem = t => {
    if t.id == id {
      {
        ...t,
        transition: transition->Belt.Option.getWithDefault(t.transition),
        duration: duration
        ->Belt.Option.flatMap(x => x)
        ->Belt.Option.getWithDefault(t.duration),
      }
    } else {
      t
    }
  }

  {...state, timeline: state.timeline->Belt.Array.map(updateItem)}
}
