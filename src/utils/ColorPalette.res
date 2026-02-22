/* src/utils/ColorPalette.res */

let colors = [
  "#3b82f6", // Blue 500
  "#ef4444", // Red 500
  "#10b981", // Emerald 500
  "#f59e0b", // Amber 500
  "#8b5cf6", // Violet 500
  "#ec4899", // Pink 500
  "#06b6d4", // Cyan 500
  "#84cc16", // Lime 500
]

let getGroupColor = (groupIdString: option<string>) => {
  switch groupIdString {
  | None => "#f1f5f9"
  | Some(idStr) =>
    switch Belt.Int.fromString(idStr) {
    | Some(id) =>
      if id <= 0 {
        "#f1f5f9"
      } else {
        let idx = mod(id - 1, Array.length(colors))
        switch colors[idx] {
        | Some(c) => c
        | None => "#f1f5f9"
        }
      }
    | None => "#f1f5f9"
    }
  }
}

let getGroupClass = (groupIdString: option<string>) => {
  switch groupIdString {
  | None => "group-color-default"
  | Some(idStr) =>
    switch Belt.Int.fromString(idStr) {
    | Some(id) =>
      if id <= 0 {
        "group-color-default"
      } else {
        let idx = mod(id - 1, Array.length(colors))
        "group-color-" ++ Int.toString(idx)
      }
    | None => "group-color-default"
    }
  }
}
