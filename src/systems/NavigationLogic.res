open Types

let calculateCameraPosition = (
  ~progress: float,
  ~pathData: pathData
) => {
  let tdist = progress *. pathData.totalPathDistance
  let cp = ref(pathData.startPitch)
  let cy = ref(pathData.startYaw)
  let segs = pathData.segments
  let cov = ref(0.0)
  let found = ref(false)

  if pathData.totalPathDistance > 0.0 && Array.length(segs) > 0 {
    for i in 0 to Array.length(segs) - 1 {
      if !found.contents {
        segs[i]->Option.forEach(s => {
          if tdist <= cov.contents +. s.dist {
            let sp = s.dist > 0.0 ? (tdist -. cov.contents) /. s.dist : 0.0
            cp := s.p1.pitch +. s.pitchDiff *. sp
            cy := s.p1.yaw +. s.yawDiff *. sp
            found := true
          }
          cov := cov.contents +. s.dist
          if !found.contents {
            cp := s.p2.pitch
            cy := s.p2.yaw
          }
        })
      }
    }
  }
  (cp.contents, cy.contents)
}
