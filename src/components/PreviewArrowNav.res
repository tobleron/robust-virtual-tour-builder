let calculateNavParams = (hotspot: Types.hotspot) => {
  let navYaw = ref(0.0)
  let navPitch = ref(0.0)
  let navHfov = ref(90.0)

  // Return links deprecated - use targetYaw/targetPitch for all links
  switch hotspot.targetYaw {
  | Some(ty) =>
    navYaw := ty
    navPitch :=
      switch hotspot.targetPitch {
      | Some(p) => p
      | None => 0.0
      }
    navHfov :=
      switch hotspot.targetHfov {
      | Some(h) => h
      | None => 90.0
      }
  | None =>
    switch hotspot.viewFrame {
    | Some(vf) =>
      navYaw := vf.yaw
      navPitch := vf.pitch
      navHfov := vf.hfov
    | None => ()
    }
  }

  (navYaw.contents, navPitch.contents, navHfov.contents)
}
