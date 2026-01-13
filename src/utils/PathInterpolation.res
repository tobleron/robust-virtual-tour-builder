/* src/utils/PathInterpolation.res */

@scope("Math") @val external ceil: float => float = "ceil"
@scope("Math") @val external floor: float => float = "floor"

type point = {
  yaw: float,
  pitch: float,
}

let normalizeYaw = (yaw: float) => {
  let y = yaw % 360.0
  if y > 180.0 {
    y -. 360.0
  } else if y < -180.0 {
    y +. 360.0
  } else {
    y
  }
}

let interpolateCatmullRom = (p0, p1, p2, p3, t) => {
  let t2 = t *. t
  let t3 = t2 *. t

  let f0 = -0.5 *. t3 +. t2 -. 0.5 *. t
  let f1 = 1.5 *. t3 -. 2.5 *. t2 +. 1.0
  let f2 = -1.5 *. t3 +. 2.0 *. t2 +. 0.5 *. t
  let f3 = 0.5 *. t3 -. 0.5 *. t2

  let yaw = p0.yaw *. f0 +. p1.yaw *. f1 +. p2.yaw *. f2 +. p3.yaw *. f3
  let pitch = p0.pitch *. f0 +. p1.pitch *. f1 +. p2.pitch *. f2 +. p3.pitch *. f3

  {yaw, pitch}
}

let getCatmullRomSpline = (points: array<point>, totalSegments: int) => {
  if Array.length(points) < 2 {
    points
  } else {
    // 1. Prepare Points: Duplicate start and end
    let first = Belt.Array.getExn(points, 0)
    let last = Belt.Array.getExn(points, Array.length(points) - 1)
    
    let prefix = Belt.Array.concat([first], points)
    let rawPoints = Belt.Array.concat(prefix, [last])
    
    // 2. Unroll Points
    let unrolledPoints = []
    
    if Array.length(rawPoints) > 0 {
      let prevYaw = ref(Belt.Array.getExn(rawPoints, 0).yaw)
      
      Belt.Array.forEach(rawPoints, p => {
        let currentYaw = p.yaw
        let diff = ref(currentYaw -. prevYaw.contents)
        
        while diff.contents > 180.0 { diff := diff.contents -. 360.0 }
        while diff.contents < -180.0 { diff := diff.contents +. 360.0 }
        
        let absoluteYaw = prevYaw.contents +. diff.contents
        let _ = Array.push(unrolledPoints, {yaw: absoluteYaw, pitch: p.pitch})
        
        prevYaw := absoluteYaw
      })
    }
    
    // 3. Generate Spline Points
    let splinePoints = []
    let numSections = Array.length(unrolledPoints) - 3
    
    if numSections < 1 {
      points
    } else {
      let segmentsPerSection = ceil(Int.toFloat(totalSegments) /. Int.toFloat(numSections))
      
      for i in 0 to numSections - 1 {
        let p0 = Belt.Array.getExn(unrolledPoints, i)
        let p1 = Belt.Array.getExn(unrolledPoints, i + 1)
        let p2 = Belt.Array.getExn(unrolledPoints, i + 2)
        let p3 = Belt.Array.getExn(unrolledPoints, i + 3)
        
        for j in 0 to Float.toInt(segmentsPerSection) - 1 {
          let t = Int.toFloat(j) /. segmentsPerSection
          let pt = interpolateCatmullRom(p0, p1, p2, p3, t)
          let _ = Array.push(splinePoints, pt)
        }
      }
      
      // Add very last point
      let unrolledLen = Array.length(unrolledPoints)
      if unrolledLen >= 2 {
        let _ = Array.push(splinePoints, Belt.Array.getExn(unrolledPoints, unrolledLen - 2))
      }
      
      // 4. Normalize
      Belt.Array.map(splinePoints, p => {
        {
          yaw: normalizeYaw(p.yaw),
          pitch: p.pitch
        }
      })
    }
  }
}
