/* src/utils/ColorPalette.res */

let colors = [
  "#f97316", // Orange 500
  "#ea580c", // Orange 600
  "#c2410c", // Orange 700
  "#9a3412", // Orange 800
  "#78350f", // Orange 900
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
        let idx = mod(id - 1, 5)
        "group-color-" ++ Int.toString(idx)
      }
    | None => "group-color-default"
    }
  }
}
