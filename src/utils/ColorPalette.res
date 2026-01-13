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

@val external parseInt: (string, int) => int = "parseInt"
@val @scope("Math") external floor: float => float = "floor"
@val @scope("Math") external max: (float, float) => float = "max"
@val @scope("Math") external min: (float, float) => float = "min"

let getGroupColor = (groupIdString: Nullable.t<string>) => {
  switch Nullable.toOption(groupIdString) {
  | None => "#f1f5f9"
  | Some(idStr) =>
     switch Belt.Int.fromString(idStr) {
     | Some(id) =>
       if id <= 0 { "#f1f5f9" }
       else {
         let idx = mod(id - 1, Array.length(colors))
         // Handle negative mod result in case id is 0 (though unlikely here)
         switch colors[idx] {
    | Some(c) => c
    | None => "#f1f5f9"
    }
       }
     | None => "#f1f5f9"
     }
  }
}

// Minimal implementation of darkenColor if needed, or rely on JS bindings if complex
// But it's just math.
let darkenColor = (hex: string, percent: float) => {
  let hexClean = if String.startsWith(hex, "#") {
    String.substring(hex, ~start=1, ~end=String.length(hex))
  } else {
    hex
  }
  
  let rStr = String.substring(hexClean, ~start=0, ~end=2)
  let gStr = String.substring(hexClean, ~start=2, ~end=4)
  let bStr = String.substring(hexClean, ~start=4, ~end=6)
  
  let r = parseInt(rStr, 16)->Float.fromInt
  let g = parseInt(gStr, 16)->Float.fromInt
  let b = parseInt(bStr, 16)->Float.fromInt
  
  let rNew = floor(r *. (1.0 -. percent))
  let gNew = floor(g *. (1.0 -. percent))
  let bNew = floor(b *. (1.0 -. percent))
  
  let rClamped = max(0.0, min(255.0, rNew))->Int.fromFloat
  let gClamped = max(0.0, min(255.0, gNew))->Int.fromFloat
  let bClamped = max(0.0, min(255.0, bNew))->Int.fromFloat
  
  let toHex = (c) => {
    let s = Int.toString(c, ~radix=16)
    if String.length(s) == 1 { "0" ++ s } else { s }
  }
  
  "#" ++ toHex(rClamped) ++ toHex(gClamped) ++ toHex(bClamped)
}
