/* src/utils/ColorPalette.res */

let colors = ["#f97316", "#ea580c", "#c2410c", "#9a3412", "#78350f"] // Orange 500 // Orange 600 // Orange 700 // Orange 800 // Orange 900
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
