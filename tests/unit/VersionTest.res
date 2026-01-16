/* tests/unit/VersionTest.res */
open Version

let run = () => {
  Console.log("Running VersionTest...")

  /* Test getVersion */
  let v = getVersion()
  Console.log("Version: " ++ v)
  if v == "" {
    Console.error("VersionTest Failed: getVersion() returned empty string")
    Js.Exn.raiseError("VersionTest Failed")
  }

  /* Test getBuildInfo */
  let info = getBuildInfo()
  Console.log("Build Info: " ++ info)

  // Ensure it's a string, even if empty, though usually it has content
  if Js.typeof(info) != "string" {
    Console.error("VersionTest Failed: getBuildInfo() did not return a string")
    Js.Exn.raiseError("VersionTest Failed")
  }

  /* Test getFullVersion */
  let full = getFullVersion()
  Console.log("Full Version: " ++ full)

  if full != v ++ " " ++ info {
    Console.error(
      "VersionTest Failed: getFullVersion() mismatch. Expected: " ++
      v ++
      " " ++
      info ++
      ", Got: " ++
      full,
    )
    Js.Exn.raiseError("VersionTest Failed")
  }

  Console.log("VersionTest Passed")
}
