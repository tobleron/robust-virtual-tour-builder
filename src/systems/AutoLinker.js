export function calculateReturnVector(pitch, yaw) {
  // Yaw: Rotate 180 degrees to look back
  const returnYaw = (yaw + 180) % 360;

  // Pitch: FORCE TO 0 (Eye Level)
  // Previously -28 (Floor), now corrected to 0 as requested.
  const returnPitch = 0;

  return {
    yaw: returnYaw,
    pitch: returnPitch,
  };
}
