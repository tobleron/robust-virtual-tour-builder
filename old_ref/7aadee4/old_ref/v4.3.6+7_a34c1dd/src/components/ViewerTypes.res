type ratchetState = {
  mutable pitchOffset: float,
  mutable yawOffset: float,
  mutable maxPitchOffset: float,
  mutable minPitchOffset: float,
  mutable maxYawOffset: float,
  mutable minYawOffset: float,
}

type viewerKey = A | B
