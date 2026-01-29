let getEdgePower = (val, dz) => {
  let a = Math.abs(val)
  if a > dz {
    let s = val > 0.0 ? 1.0 : -1.0
    let n = (a -. dz) /. (1.0 -. dz)
    s *. (n *. n)
  } else {
    0.0
  }
}

let getBoost = vel => {
  let a = Math.abs(vel)
  if a > 500.0 {
    Math.min((a -. 500.0) /. 3000.0, 1.5)
  } else {
    0.0
  }
}
